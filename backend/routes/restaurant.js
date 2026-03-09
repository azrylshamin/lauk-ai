const { Router } = require("express");
const pool = require("../db/db");
const { requireOwner } = require("../middleware/auth");

const router = Router();

// GET / — fetch the authenticated restaurant's profile
router.get("/", async (req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT id, name, address, phone, sst_enabled, sst_rate, sc_enabled, sc_rate, created_at FROM restaurants WHERE id = $1",
            [req.restaurantId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Restaurant not found" });
        }

        res.json(rows[0]);
    } catch (err) {
        console.error("Restaurant fetch error:", err);
        res.status(500).json({ error: err.message });
    }
});

// PATCH / — update restaurant profile (owner only)
router.patch("/", requireOwner, async (req, res) => {
    try {
        const { name, address, phone, sst_enabled, sst_rate, sc_enabled, sc_rate } = req.body;

        const fields = [];
        const values = [];
        let idx = 1;

        if (name !== undefined) {
            fields.push(`name = $${idx++}`);
            values.push(name.trim());
        }
        if (address !== undefined) {
            fields.push(`address = $${idx++}`);
            values.push(address.trim());
        }
        if (phone !== undefined) {
            fields.push(`phone = $${idx++}`);
            values.push(phone.trim());
        }
        if (sst_enabled !== undefined) {
            fields.push(`sst_enabled = $${idx++}`);
            values.push(Boolean(sst_enabled));
        }
        if (sst_rate !== undefined) {
            const rate = parseFloat(sst_rate);
            if (isNaN(rate) || rate < 0 || rate > 100) {
                return res.status(400).json({ error: "SST rate must be between 0 and 100" });
            }
            fields.push(`sst_rate = $${idx++}`);
            values.push(rate);
        }
        if (sc_enabled !== undefined) {
            fields.push(`sc_enabled = $${idx++}`);
            values.push(Boolean(sc_enabled));
        }
        if (sc_rate !== undefined) {
            const rate = parseFloat(sc_rate);
            if (isNaN(rate) || rate < 0 || rate > 100) {
                return res.status(400).json({ error: "Service charge rate must be between 0 and 100" });
            }
            fields.push(`sc_rate = $${idx++}`);
            values.push(rate);
        }

        if (fields.length === 0) {
            return res.status(400).json({ error: "Nothing to update" });
        }

        values.push(req.restaurantId);
        const { rows } = await pool.query(
            `UPDATE restaurants SET ${fields.join(", ")} WHERE id = $${idx} RETURNING id, name, address, phone, sst_enabled, sst_rate, sc_enabled, sc_rate, created_at`,
            values
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Restaurant not found" });
        }

        res.json(rows[0]);
    } catch (err) {
        console.error("Restaurant update error:", err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
