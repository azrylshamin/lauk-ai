const { Router } = require("express");
const pool = require("../db/db");
const { requireOwner } = require("../middleware/auth");
const { createUpload, destroyImage } = require("../middleware/upload");

const router = Router();
const uploadMenuItem = createUpload("menu-items");

// List all menu items for the authenticated restaurant
router.get("/", async (req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT * FROM menu_items WHERE restaurant_id = $1 ORDER BY id",
            [req.restaurantId]
        );
        res.json(rows);
    } catch (err) {
        console.error("Menu items fetch error:", err);
        res.status(500).json({ error: err.message });
    }
});

// Create a new menu item (assign unknown class) for the authenticated restaurant
router.post("/", async (req, res) => {
    try {
        const { yolo_class, name, price } = req.body;

        if (!yolo_class || !name || price == null) {
            return res
                .status(400)
                .json({ error: "yolo_class, name, and price are required" });
        }

        const { rows } = await pool.query(
            `INSERT INTO menu_items (yolo_class, name, price, restaurant_id)
             VALUES ($1, $2, $3, $4)
             RETURNING *`,
            [yolo_class, name, parseFloat(price), req.restaurantId]
        );

        res.status(201).json(rows[0]);
    } catch (err) {
        if (err.code === "23505") {
            return res
                .status(409)
                .json({ error: `Menu item for class "${req.body.yolo_class}" already exists` });
        }
        console.error("Menu item create error:", err);
        res.status(500).json({ error: err.message });
    }
});

// Update a menu item (only if it belongs to the authenticated restaurant)
router.patch("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { name, price, active, image_url } = req.body;

        const fields = [];
        const values = [];
        let idx = 1;

        if (name !== undefined) {
            fields.push(`name = $${idx++}`);
            values.push(name);
        }
        if (price !== undefined) {
            fields.push(`price = $${idx++}`);
            values.push(parseFloat(price));
        }
        if (active !== undefined) {
            fields.push(`active = $${idx++}`);
            values.push(Boolean(active));
        }
        if (image_url !== undefined) {
            fields.push(`image_url = $${idx++}`);
            values.push(image_url);
        }

        if (fields.length === 0) {
            return res.status(400).json({ error: "Nothing to update" });
        }

        values.push(id);
        values.push(req.restaurantId);
        const { rows } = await pool.query(
            `UPDATE menu_items SET ${fields.join(", ")} WHERE id = $${idx} AND restaurant_id = $${idx + 1} RETURNING *`,
            values
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Menu item not found" });
        }

        res.json(rows[0]);
    } catch (err) {
        console.error("Menu item update error:", err);
        res.status(500).json({ error: err.message });
    }
});

// POST /:id/image — upload menu item image
router.post("/:id/image", uploadMenuItem.single("image"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }

        const { id } = req.params;
        const imageUrl = req.file.path;

        const { rows } = await pool.query(
            `UPDATE menu_items SET image_url = $1 WHERE id = $2 AND restaurant_id = $3 RETURNING *`,
            [imageUrl, id, req.restaurantId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Menu item not found" });
        }

        res.json(rows[0]);
    } catch (err) {
        console.error("Menu item image upload error:", err);
        res.status(500).json({ error: err.message });
    }
});

// DELETE /:id/image — remove menu item image
router.delete("/:id/image", async (req, res) => {
    try {
        const { id } = req.params;

        const { rows: current } = await pool.query(
            "SELECT image_url FROM menu_items WHERE id = $1 AND restaurant_id = $2",
            [id, req.restaurantId]
        );

        if (current.length === 0) {
            return res.status(404).json({ error: "Menu item not found" });
        }

        await destroyImage(current[0].image_url);

        const { rows } = await pool.query(
            `UPDATE menu_items SET image_url = NULL WHERE id = $1 AND restaurant_id = $2 RETURNING *`,
            [id, req.restaurantId]
        );

        res.json(rows[0]);
    } catch (err) {
        console.error("Menu item image delete error:", err);
        res.status(500).json({ error: err.message });
    }
});

// Delete a menu item (only if it belongs to the authenticated restaurant, owner only)
router.delete("/:id", requireOwner, async (req, res) => {
    try {
        const { id } = req.params;

        const { rows } = await pool.query(
            "DELETE FROM menu_items WHERE id = $1 AND restaurant_id = $2 RETURNING *",
            [id, req.restaurantId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Menu item not found" });
        }

        res.json({ message: "Menu item deleted", item: rows[0] });
    } catch (err) {
        console.error("Menu item delete error:", err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
