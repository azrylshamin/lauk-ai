const { Router } = require("express");
const fetch = require("node-fetch");

const router = Router();
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || "http://localhost:8000";

router.get("/", async (_req, res) => {
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

module.exports = router;
