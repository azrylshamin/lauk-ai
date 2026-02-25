const { Router } = require("express");
const passport = require("passport");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const pool = require("../db/db");
const { authenticate, requireOwner } = require("../middleware/auth");

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || "dev-secret-change-me";
const SALT_ROUNDS = 10;

/**
 * Helper — sign a JWT for a user.
 */
function signToken(user) {
    return jwt.sign(
        {
            userId: user.id,
            restaurantId: user.restaurant_id,
            email: user.email,
            role: user.role,
        },
        JWT_SECRET,
        { expiresIn: "24h" }
    );
}

// ---------------------------------------------------------------------------
// POST /register — create restaurant + owner user
// ---------------------------------------------------------------------------
router.post("/register", async (req, res) => {
    const client = await pool.connect();
    try {
        const { name, email, password, restaurantName } = req.body;

        if (!name || !email || !password || !restaurantName) {
            return res.status(400).json({
                error: "name, email, password, and restaurantName are required",
            });
        }

        // Check if email already exists
        const { rows: existing } = await client.query(
            "SELECT id FROM users WHERE email = $1",
            [email.toLowerCase()]
        );
        if (existing.length > 0) {
            return res.status(409).json({ error: "Email already registered" });
        }

        await client.query("BEGIN");

        // Create restaurant
        const { rows: restRows } = await client.query(
            "INSERT INTO restaurants (name) VALUES ($1) RETURNING *",
            [restaurantName.trim()]
        );
        const restaurant = restRows[0];

        // Create owner user
        const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
        const { rows: userRows } = await client.query(
            `INSERT INTO users (email, password_hash, name, role, restaurant_id)
             VALUES ($1, $2, $3, 'owner', $4) RETURNING id, email, name, role, restaurant_id`,
            [email.toLowerCase(), passwordHash, name.trim(), restaurant.id]
        );
        const user = userRows[0];

        await client.query("COMMIT");

        const token = signToken(user);

        res.status(201).json({
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                restaurantId: user.restaurant_id,
                restaurantName: restaurant.name,
            },
        });
    } catch (err) {
        await client.query("ROLLBACK");
        console.error("Register error:", err);
        res.status(500).json({ error: err.message });
    } finally {
        client.release();
    }
});

// ---------------------------------------------------------------------------
// POST /login
// ---------------------------------------------------------------------------
router.post("/login", (req, res, next) => {
    passport.authenticate("local", { session: false }, async (err, user, info) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!user) return res.status(401).json({ error: info?.message || "Invalid credentials" });

        // Fetch restaurant name
        const { rows } = await pool.query(
            "SELECT name FROM restaurants WHERE id = $1",
            [user.restaurant_id]
        );

        const token = signToken(user);

        res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                restaurantId: user.restaurant_id,
                restaurantName: rows[0]?.name || "",
            },
        });
    })(req, res, next);
});

// ---------------------------------------------------------------------------
// GET /me — return current user info
// ---------------------------------------------------------------------------
router.get("/me", authenticate, async (req, res) => {
    try {
        const { rows } = await pool.query(
            "SELECT name FROM restaurants WHERE id = $1",
            [req.user.restaurant_id]
        );

        res.json({
            id: req.user.id,
            email: req.user.email,
            name: req.user.name,
            role: req.user.role,
            restaurantId: req.user.restaurant_id,
            restaurantName: rows[0]?.name || "",
        });
    } catch (err) {
        console.error("Me error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// POST /invite — owner invites a staff user to their restaurant
// ---------------------------------------------------------------------------
router.post("/invite", authenticate, requireOwner, async (req, res) => {
    try {
        const { name, email, password } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({
                error: "name, email, and password are required",
            });
        }

        // Check if email already exists
        const { rows: existing } = await pool.query(
            "SELECT id FROM users WHERE email = $1",
            [email.toLowerCase()]
        );
        if (existing.length > 0) {
            return res.status(409).json({ error: "Email already registered" });
        }

        const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
        const { rows } = await pool.query(
            `INSERT INTO users (email, password_hash, name, role, restaurant_id)
             VALUES ($1, $2, $3, 'staff', $4) RETURNING id, email, name, role, restaurant_id`,
            [email.toLowerCase(), passwordHash, name.trim(), req.restaurantId]
        );

        res.status(201).json(rows[0]);
    } catch (err) {
        console.error("Invite error:", err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
