const { Router } = require("express");
const pool = require("../db/db");
const { requireOwner } = require("../middleware/auth");
const { createUpload, destroyImage } = require("../middleware/upload");

const router = Router();
const uploadRestaurant = createUpload("restaurants");

// GET / — fetch the authenticated restaurant's profile
router.get("/", async (req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT id, name, address, phone, business_hours, sst_enabled, sst_rate, sc_enabled, sc_rate, image_url, onboarding_completed, created_at FROM restaurants WHERE id = $1",
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
        const { name, address, phone, business_hours, sst_enabled, sst_rate, sc_enabled, sc_rate, onboarding_completed } = req.body;

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
        if (business_hours !== undefined) {
            fields.push(`business_hours = $${idx++}`);
            values.push(business_hours.trim());
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

        if (onboarding_completed !== undefined) {
            fields.push(`onboarding_completed = $${idx++}`);
            values.push(Boolean(onboarding_completed));
        }

        if (fields.length === 0) {
            return res.status(400).json({ error: "Nothing to update" });
        }

        values.push(req.restaurantId);
        const { rows } = await pool.query(
            `UPDATE restaurants SET ${fields.join(", ")} WHERE id = $${idx} RETURNING id, name, address, phone, business_hours, sst_enabled, sst_rate, sc_enabled, sc_rate, image_url, onboarding_completed, created_at`,
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

// POST /image — upload restaurant profile image (owner only)
router.post("/image", requireOwner, uploadRestaurant.single("image"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }

        // Destroy the old image from Cloudinary before replacing
        const { rows: old } = await pool.query(
            "SELECT image_url FROM restaurants WHERE id = $1",
            [req.restaurantId]
        );
        await destroyImage(old[0]?.image_url);

        const imageUrl = req.file.path;

        const { rows } = await pool.query(
            `UPDATE restaurants SET image_url = $1 WHERE id = $2
             RETURNING id, name, address, phone, business_hours, sst_enabled, sst_rate, sc_enabled, sc_rate, image_url, onboarding_completed, created_at`,
            [imageUrl, req.restaurantId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Restaurant not found" });
        }

        res.json(rows[0]);
    } catch (err) {
        console.error("Restaurant image upload error:", err);
        res.status(500).json({ error: err.message });
    }
});

// DELETE /image — remove restaurant profile image (owner only)
router.delete("/image", requireOwner, async (req, res) => {
    try {
        const { rows: current } = await pool.query(
            "SELECT image_url FROM restaurants WHERE id = $1",
            [req.restaurantId]
        );

        if (current.length === 0) {
            return res.status(404).json({ error: "Restaurant not found" });
        }

        await destroyImage(current[0].image_url);

        const { rows } = await pool.query(
            `UPDATE restaurants SET image_url = NULL WHERE id = $1
             RETURNING id, name, address, phone, business_hours, sst_enabled, sst_rate, sc_enabled, sc_rate, image_url, onboarding_completed, created_at`,
            [req.restaurantId]
        );

        res.json(rows[0]);
    } catch (err) {
        console.error("Restaurant image delete error:", err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
