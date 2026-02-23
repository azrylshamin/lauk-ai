require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });
const express = require("express");
const cors = require("cors");
const multer = require("multer");
const FormData = require("form-data");
const fetch = require("node-fetch");
const pool = require("./db/db");

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
// Helper — look up menu items by yolo_class names
// ---------------------------------------------------------------------------
async function lookupMenuItems(detections) {
    // Get all known menu items in one query
    const { rows: menuItems } = await pool.query("SELECT * FROM menu_items");
    const menuMap = new Map(menuItems.map((item) => [item.yolo_class, item]));

    let total = 0;
    const items = detections.map((det) => {
        const menuItem = menuMap.get(det.class);
        if (menuItem) {
            total += parseFloat(menuItem.price);
            return {
                name: menuItem.name,
                yolo_class: det.class,
                price: parseFloat(menuItem.price),
                confidence: det.confidence,
                bbox: det.bbox,
                known: true,
            };
        }
        return {
            name: "Unknown Item",
            yolo_class: det.class,
            price: null,
            confidence: det.confidence,
            bbox: det.bbox,
            known: false,
        };
    });

    return { items, total: Math.round(total * 100) / 100 };
}

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

// Proxy image to ai-service for prediction, then enrich with menu data
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

        // Enrich detections with menu item data
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
// Menu Items CRUD
// ---------------------------------------------------------------------------

// List all menu items
app.get("/api/menu-items", async (_req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT * FROM menu_items ORDER BY id"
        );
        res.json(rows);
    } catch (err) {
        console.error("Menu items fetch error:", err);
        res.status(500).json({ error: err.message });
    }
});

// Create a new menu item (assign unknown class)
app.post("/api/menu-items", async (req, res) => {
    try {
        const { yolo_class, name, price } = req.body;

        if (!yolo_class || !name || price == null) {
            return res
                .status(400)
                .json({ error: "yolo_class, name, and price are required" });
        }

        const { rows } = await pool.query(
            `INSERT INTO menu_items (yolo_class, name, price)
             VALUES ($1, $2, $3)
             RETURNING *`,
            [yolo_class, name, parseFloat(price)]
        );

        res.status(201).json(rows[0]);
    } catch (err) {
        // Handle duplicate yolo_class
        if (err.code === "23505") {
            return res
                .status(409)
                .json({ error: `Menu item for class "${req.body.yolo_class}" already exists` });
        }
        console.error("Menu item create error:", err);
        res.status(500).json({ error: err.message });
    }
});

// Update a menu item
app.patch("/api/menu-items/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { name, price } = req.body;

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

        if (fields.length === 0) {
            return res.status(400).json({ error: "Nothing to update" });
        }

        values.push(id);
        const { rows } = await pool.query(
            `UPDATE menu_items SET ${fields.join(", ")} WHERE id = $${idx} RETURNING *`,
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

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
    console.log(`Backend running at http://localhost:${PORT}`);
    console.log(`AI service URL: ${AI_SERVICE_URL}`);
});
