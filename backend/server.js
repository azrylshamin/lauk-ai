require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });
const express = require("express");
const cors = require("cors");

// Route modules
const healthRoutes = require("./routes/health");
const predictRoutes = require("./routes/predict");
const menuItemsRoutes = require("./routes/menuItems");
const billsRoutes = require("./routes/bills");

const app = express();
const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------
app.use(cors());
app.use(express.json());

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------
app.use("/api/health", healthRoutes);
app.use("/api", predictRoutes);
app.use("/api/menu-items", menuItemsRoutes);
app.use("/api/bills", billsRoutes);

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
    console.log(`Backend running at http://localhost:${PORT}`);
    console.log(`AI service URL: ${process.env.AI_SERVICE_URL || "http://localhost:8000"}`);
});
