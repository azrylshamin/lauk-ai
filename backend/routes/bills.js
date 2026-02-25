const { Router } = require("express");
const pool = require("../db/db");

const router = Router();

// Save a confirmed bill for the authenticated restaurant
router.post("/", async (req, res) => {
    const client = await pool.connect();
    try {
        const { items, total } = req.body;

        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({ error: "items array is required" });
        }

        await client.query("BEGIN");

        const { rows: billRows } = await client.query(
            "INSERT INTO bills (total, restaurant_id) VALUES ($1, $2) RETURNING *",
            [parseFloat(total), req.restaurantId]
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
            total: bill.total,
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

// List recent bills for the authenticated restaurant
router.get("/", async (req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT * FROM bills WHERE restaurant_id = $1 ORDER BY created_at DESC LIMIT 50",
            [req.restaurantId]
        );
        res.json(rows);
    } catch (err) {
        console.error("Bills fetch error:", err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
