const express = require("express");
const cors = require("cors");
const multer = require("multer");
const FormData = require("form-data");
const fetch = require("node-fetch");

const app = express();
const PORT = process.env.PORT || 3000;
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || "http://localhost:8000";

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------
app.use(cors());
app.use(express.json());

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

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// Health check
app.get("/api/health", async (_req, res) => {
    try {
        const aiRes = await fetch(`${AI_SERVICE_URL}/health`);
        const aiHealth = await aiRes.json();
        res.json({
            status: "healthy",
            ai_service: aiHealth,
        });
    } catch (err) {
        res.json({
            status: "healthy",
            ai_service: { status: "unreachable", error: err.message },
        });
    }
});

// Proxy image to ai-service for prediction
app.post("/api/predict", upload.single("file"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }

        // Build a multipart form to forward to the ai-service
        const form = new FormData();
        form.append("file", req.file.buffer, {
            filename: req.file.originalname,
            contentType: req.file.mimetype,
        });

        // Forward confidence param if provided
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
        res.json(predictions);
    } catch (err) {
        console.error("Prediction error:", err);
        res.status(502).json({
            error: "Failed to reach AI service",
            detail: err.message,
        });
    }
});

// Get available food classes
app.get("/api/classes", async (_req, res) => {
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

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
    console.log(`Backend running at http://localhost:${PORT}`);
    console.log(`AI service URL: ${AI_SERVICE_URL}`);
});
