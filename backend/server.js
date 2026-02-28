require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });
const express = require("express");
const cors = require("cors");

// Initialize Passport strategies (must be before routes)
require("./middleware/passport");

// Auth middleware
const { authenticate } = require("./middleware/auth");

// Route modules
const healthRoutes = require("./routes/health");
const authRoutes = require("./routes/auth");
const predictRoutes = require("./routes/predict");
const menuItemsRoutes = require("./routes/menuItems");
const billsRoutes = require("./routes/bills");
const restaurantRoutes = require("./routes/restaurant");
const employeesRoutes = require("./routes/employees");
const customerRoutes = require("./routes/customer");

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
// Public routes
app.use("/api/health", healthRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/customer", customerRoutes);

// Protected routes (require JWT)
app.use("/api/predict", authenticate, predictRoutes);
app.use("/api/menu-items", authenticate, menuItemsRoutes);
app.use("/api/bills", authenticate, billsRoutes);
app.use("/api/restaurant", authenticate, restaurantRoutes);
app.use("/api/employees", authenticate, employeesRoutes);

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
    console.log(`Backend running at http://localhost:${PORT}`);
    console.log(`AI service URL: ${process.env.AI_SERVICE_URL || "http://localhost:8000"}`);
});
