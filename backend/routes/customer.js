const { Router } = require("express");
const multer = require("multer");
const FormData = require("form-data");
const fetch = require("node-fetch");
const pool = require("../db/db");
const lookupMenuItems = require("../helpers/lookupMenuItems");

const router = Router();
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || "http://localhost:8000";

// Multer — store uploaded files in memory (small images only)
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB max
    fileFilter: (_req, file, cb) => {
        if (file.mimetype.startsWith("image/")) {
            cb(null, true);
        } else {
            cb(new Error("Only image files are allowed"));
        }
    },
});

// GET /restaurants — list all restaurants (public)
router.get("/restaurants", async (_req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT id, name, address, phone FROM restaurants ORDER BY name"
        );
        res.json(rows);
    } catch (err) {
        console.error("Customer restaurant list error:", err);
        res.status(500).json({ error: err.message });
    }
});

// POST /restaurants/:id/estimate — upload image, detect food, return price estimate
router.post("/restaurants/:id/estimate", upload.single("file"), async (req, res) => {
    try {
        const restaurantId = parseInt(req.params.id, 10);
        if (isNaN(restaurantId)) {
            return res.status(400).json({ error: "Invalid restaurant ID" });
        }

        // Verify restaurant exists
        const { rows: restaurants } = await pool.query(
            "SELECT id FROM restaurants WHERE id = $1",
            [restaurantId]
        );
        if (restaurants.length === 0) {
            return res.status(404).json({ error: "Restaurant not found" });
        }

        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }

        // Proxy image to AI service
        const form = new FormData();
        form.append("file", req.file.buffer, {
            filename: req.file.originalname,
            contentType: req.file.mimetype,
        });

        const confidence = req.query.confidence || 0.25;
        const url = `${AI_SERVICE_URL}/predict?confidence=${confidence}`;

        const aiRes = await fetch(url, {
            method: "POST",
            body: form,
            headers: form.getHeaders(),
        });

        if (!aiRes.ok) {
            const errBody = await aiRes.json().catch(() => ({}));
            return res.status(aiRes.status).json({
                error: "AI service error",
                detail: errBody.detail || aiRes.statusText,
            });
        }

        const predictions = await aiRes.json();
        const { items, total } = await lookupMenuItems(predictions.detections, restaurantId);

        res.json({
            items,
            total,
            count: predictions.count,
        });
    } catch (err) {
        console.error("Customer estimate error:", err);
        res.status(502).json({
            error: "Failed to process estimate",
            detail: err.message,
        });
    }
});

module.exports = router;
