const { Router } = require("express");
const pool = require("../db/db");

const router = Router();

// ── Stats for the authenticated restaurant (today) ─────────────────────────
router.get("/stats", async (req, res) => {
    try {
        // Today's stats
        const { rows } = await pool.query(
            `SELECT
                COUNT(*)::int                          AS bill_count,
                COALESCE(SUM(total), 0)::numeric       AS revenue,
                COALESCE(AVG(total), 0)::numeric       AS average
             FROM bills
             WHERE restaurant_id = $1
               AND created_at::date = CURRENT_DATE`,
            [req.restaurantId]
        );

        // Yesterday's revenue for growth calculation
        const { rows: yesterdayRows } = await pool.query(
            `SELECT COALESCE(SUM(total), 0)::numeric AS revenue
             FROM bills
             WHERE restaurant_id = $1
               AND created_at::date = CURRENT_DATE - 1`,
            [req.restaurantId]
        );

        // Top selling item today
        const { rows: topItemRows } = await pool.query(
            `SELECT bi.name, SUM(bi.quantity)::int AS total_qty
             FROM bill_items bi
             JOIN bills b ON b.id = bi.bill_id
             WHERE b.restaurant_id = $1
               AND b.created_at::date = CURRENT_DATE
             GROUP BY bi.name
             ORDER BY total_qty DESC
             LIMIT 1`,
            [req.restaurantId]
        );

        // 3 most recent bills
        const { rows: recentRows } = await pool.query(
            `SELECT b.*,
                    (SELECT COALESCE(SUM(bi.quantity), 0)
                     FROM bill_items bi WHERE bi.bill_id = b.id)::int AS item_count
             FROM bills b
             WHERE b.restaurant_id = $1
             ORDER BY b.created_at DESC
             LIMIT 3`,
            [req.restaurantId]
        );

        const stats = rows[0];
        const todayRevenue = parseFloat(stats.revenue);
        const yesterdayRevenue = parseFloat(yesterdayRows[0].revenue);

        let revenueGrowth = null;
        if (yesterdayRevenue > 0) {
            revenueGrowth = parseFloat(
                (((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100).toFixed(1)
            );
        }

        res.json({
            billCount: stats.bill_count,
            revenue: parseFloat(Number(stats.revenue).toFixed(2)),
            average: parseFloat(Number(stats.average).toFixed(2)),
            accuracy: null, // placeholder — will be computed when AI feedback loop is ready
            revenueGrowth,
            topItem: topItemRows.length > 0 ? topItemRows[0].name : null,
            recentTransactions: recentRows,
        });
    } catch (err) {
        console.error("Stats fetch error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ── Single bill with line items ─────────────────────────────────────────────
router.get("/:id", async (req, res) => {
    try {
        const { rows: billRows } = await pool.query(
            "SELECT * FROM bills WHERE id = $1 AND restaurant_id = $2",
            [req.params.id, req.restaurantId]
        );

        if (billRows.length === 0) {
            return res.status(404).json({ error: "Bill not found" });
        }

        const bill = billRows[0];

        const { rows: items } = await pool.query(
            "SELECT id, name, price, quantity FROM bill_items WHERE bill_id = $1 ORDER BY id",
            [bill.id]
        );

        res.json({ ...bill, items });
    } catch (err) {
        console.error("Bill detail error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ── Save a confirmed bill ───────────────────────────────────────────────────
router.post("/", async (req, res) => {
    const client = await pool.connect();
    try {
        const { items } = req.body;

        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({ error: "items array is required" });
        }

        // Compute subtotal server-side
        const subtotal = Math.round(
            items.reduce((sum, item) => sum + parseFloat(item.price) * (item.quantity || 1), 0) * 100
        ) / 100;

        // Fetch restaurant tax settings
        const { rows: restRows } = await client.query(
            "SELECT sst_enabled, sst_rate, sc_enabled, sc_rate FROM restaurants WHERE id = $1",
            [req.restaurantId]
        );
        const rest = restRows[0];

        const sstAmount = rest.sst_enabled
            ? Math.round(subtotal * parseFloat(rest.sst_rate)) / 100
            : 0;
        const scAmount = rest.sc_enabled
            ? Math.round(subtotal * parseFloat(rest.sc_rate)) / 100
            : 0;
        const total = Math.round((subtotal + sstAmount + scAmount) * 100) / 100;

        await client.query("BEGIN");

        const { rows: billRows } = await client.query(
            "INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id) VALUES ($1, $2, $3, $4, $5) RETURNING *",
            [subtotal, sstAmount, scAmount, total, req.restaurantId]
        );
        const bill = billRows[0];

        for (const item of items) {
            await client.query(
                `INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity)
                 VALUES ($1, $2, $3, $4, $5)`,
                [
                    bill.id,
                    item.menu_item_id || null,
                    item.name,
                    parseFloat(item.price),
                    item.quantity || 1,
                ]
            );
        }

        await client.query("COMMIT");

        res.status(201).json({
            id: bill.id,
            subtotal: parseFloat(bill.subtotal),
            sst_amount: parseFloat(bill.sst_amount),
            sc_amount: parseFloat(bill.sc_amount),
            total: parseFloat(bill.total),
            created_at: bill.created_at,
        });
    } catch (err) {
        await client.query("ROLLBACK");
        console.error("Bill save error:", err);
        res.status(500).json({ error: err.message });
    } finally {
        client.release();
    }
});

// ── Void (delete) a bill ────────────────────────────────────────────────────
router.delete("/:id", async (req, res) => {
    const client = await pool.connect();
    try {
        const { rows } = await client.query(
            "SELECT id FROM bills WHERE id = $1 AND restaurant_id = $2",
            [req.params.id, req.restaurantId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Bill not found" });
        }

        await client.query("BEGIN");
        await client.query("DELETE FROM bill_items WHERE bill_id = $1", [req.params.id]);
        await client.query("DELETE FROM bills WHERE id = $1", [req.params.id]);
        await client.query("COMMIT");

        res.json({ message: "Bill voided successfully" });
    } catch (err) {
        await client.query("ROLLBACK");
        console.error("Bill delete error:", err);
        res.status(500).json({ error: err.message });
    } finally {
        client.release();
    }
});

// ── List recent bills with item count ───────────────────────────────────────
router.get("/", async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT b.*,
                    (SELECT COALESCE(SUM(bi.quantity), 0)
                     FROM bill_items bi WHERE bi.bill_id = b.id)::int AS item_count
             FROM bills b
             WHERE b.restaurant_id = $1
             ORDER BY b.created_at DESC
             LIMIT 100`,
            [req.restaurantId]
        );
        res.json(rows);
    } catch (err) {
        console.error("Bills fetch error:", err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
