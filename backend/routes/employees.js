const { Router } = require("express");
const pool = require("../db/db");
const { requireOwner } = require("../middleware/auth");

const router = Router();

// GET / — list all users belonging to the authenticated restaurant
router.get("/", async (req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT id, email, name, role, created_at FROM users WHERE restaurant_id = $1 ORDER BY created_at",
            [req.restaurantId]
        );
        res.json(rows);
    } catch (err) {
        console.error("Employees fetch error:", err);
        res.status(500).json({ error: err.message });
    }
});

// DELETE /:id — remove a staff user (owner only, cannot remove yourself)
router.delete("/:id", requireOwner, async (req, res) => {
    try {
        const { id } = req.params;

        // Prevent owner from deleting themselves
        if (parseInt(id) === req.user.id) {
            return res.status(400).json({ error: "Cannot remove yourself" });
        }

        // Only delete staff in the same restaurant
        const { rows } = await pool.query(
            "DELETE FROM users WHERE id = $1 AND restaurant_id = $2 AND role = 'staff' RETURNING id, email, name",
            [id, req.restaurantId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Staff member not found or cannot be removed" });
        }

        res.json({ message: "Employee removed", employee: rows[0] });
    } catch (err) {
        console.error("Employee delete error:", err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
