const { Router } = require("express");
const pool = require("../db/db");
const { requireOwner } = require("../middleware/auth");

const router = Router();

// GET / — fetch the authenticated restaurant's profile
router.get("/", async (req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT id, name, address, phone, created_at FROM restaurants WHERE id = $1",
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
        const { name, address, phone } = req.body;

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

        if (fields.length === 0) {
            return res.status(400).json({ error: "Nothing to update" });
        }

        values.push(req.restaurantId);
        const { rows } = await pool.query(
            `UPDATE restaurants SET ${fields.join(", ")} WHERE id = $${idx} RETURNING id, name, address, phone, created_at`,
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
