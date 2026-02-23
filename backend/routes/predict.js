const { Router } = require("express");
const multer = require("multer");
const FormData = require("form-data");
const fetch = require("node-fetch");
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

// Proxy image to ai-service for prediction, then enrich with menu data
router.post("/predict", upload.single("file"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }

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
        const { items, total } = await lookupMenuItems(predictions.detections);

        res.json({
            items,
            total,
            count: predictions.count,
            image_size: predictions.image_size,
        });
    } catch (err) {
        console.error("Prediction error:", err);
        res.status(502).json({
            error: "Failed to reach AI service",
            detail: err.message,
        });
    }
});

// Get available food classes from AI service
router.get("/classes", async (_req, res) => {
    try {
        const aiRes = await fetch(`${AI_SERVICE_URL}/classes`);
        const data = await aiRes.json();
        res.json(data);
    } catch (err) {
        res.status(502).json({
            error: "Failed to reach AI service",
            detail: err.message,
        });
    }
});

module.exports = router;
