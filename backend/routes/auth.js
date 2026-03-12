const { Router } = require("express");
const passport = require("passport");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const pool = require("../db/db");
const { authenticate, requireOwner } = require("../middleware/auth");
const { createUpload, destroyImage } = require("../middleware/upload");

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || "dev-secret-change-me";
const SALT_ROUNDS = 10;
const uploadProfile = createUpload("profiles");

/**
 * Helper — build a consistent user response shape.
 */
function userResponse(user, restaurantName) {
    return {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        profileImageUrl: user.profile_image_url || null,
        restaurantId: user.restaurant_id,
        restaurantName: restaurantName || "",
    };
}

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
            user: userResponse(user, restaurant.name),
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
            user: userResponse(user, rows[0]?.name),
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

        res.json(userResponse(req.user, rows[0]?.name));
    } catch (err) {
        console.error("Me error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// PATCH /profile — update current user's name and/or email
// ---------------------------------------------------------------------------
router.patch("/profile", authenticate, async (req, res) => {
    try {
        const { name, email } = req.body;

        if (!name || !email) {
            return res.status(400).json({ error: "name and email are required" });
        }

        const trimmedEmail = email.toLowerCase().trim();

        // Check email uniqueness (excluding current user)
        const { rows: existing } = await pool.query(
            "SELECT id FROM users WHERE email = $1 AND id != $2",
            [trimmedEmail, req.user.id]
        );
        if (existing.length > 0) {
            return res.status(409).json({ error: "Email already in use" });
        }

        const { rows } = await pool.query(
            `UPDATE users SET name = $1, email = $2 WHERE id = $3
             RETURNING id, email, name, role, profile_image_url, restaurant_id`,
            [name.trim(), trimmedEmail, req.user.id]
        );
        const user = rows[0];

        // Re-issue token since email may have changed
        const token = signToken(user);

        // Fetch restaurant name
        const { rows: restRows } = await pool.query(
            "SELECT name FROM restaurants WHERE id = $1",
            [user.restaurant_id]
        );

        res.json({
            token,
            user: userResponse(user, restRows[0]?.name),
        });
    } catch (err) {
        console.error("Profile update error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// POST /change-password — change current user's password
// ---------------------------------------------------------------------------
router.post("/change-password", authenticate, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res
                .status(400)
                .json({ error: "currentPassword and newPassword are required" });
        }

        if (newPassword.length < 6) {
            return res
                .status(400)
                .json({ error: "New password must be at least 6 characters" });
        }

        // Verify current password
        const match = await bcrypt.compare(
            currentPassword,
            req.user.password_hash
        );
        if (!match) {
            return res
                .status(401)
                .json({ error: "Current password is incorrect" });
        }

        // Hash and save new password
        const newHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
        await pool.query("UPDATE users SET password_hash = $1 WHERE id = $2", [
            newHash,
            req.user.id,
        ]);

        res.json({ message: "Password changed successfully" });
    } catch (err) {
        console.error("Change password error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// POST /profile/image — upload user profile image
// ---------------------------------------------------------------------------
router.post("/profile/image", authenticate, uploadProfile.single("image"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }

        // Destroy old image if exists
        const { rows: old } = await pool.query(
            "SELECT profile_image_url FROM users WHERE id = $1",
            [req.user.id]
        );
        await destroyImage(old[0]?.profile_image_url);

        const imageUrl = req.file.path;
        const { rows } = await pool.query(
            `UPDATE users SET profile_image_url = $1 WHERE id = $2
             RETURNING id, email, name, role, profile_image_url, restaurant_id`,
            [imageUrl, req.user.id]
        );

        const { rows: restRows } = await pool.query(
            "SELECT name FROM restaurants WHERE id = $1",
            [rows[0].restaurant_id]
        );

        res.json(userResponse(rows[0], restRows[0]?.name));
    } catch (err) {
        console.error("Profile image upload error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// DELETE /profile/image — remove user profile image
// ---------------------------------------------------------------------------
router.delete("/profile/image", authenticate, async (req, res) => {
    try {
        const { rows: current } = await pool.query(
            "SELECT profile_image_url FROM users WHERE id = $1",
            [req.user.id]
        );
        await destroyImage(current[0]?.profile_image_url);

        const { rows } = await pool.query(
            `UPDATE users SET profile_image_url = NULL WHERE id = $1
             RETURNING id, email, name, role, profile_image_url, restaurant_id`,
            [req.user.id]
        );

        const { rows: restRows } = await pool.query(
            "SELECT name FROM restaurants WHERE id = $1",
            [rows[0].restaurant_id]
        );

        res.json(userResponse(rows[0], restRows[0]?.name));
    } catch (err) {
        console.error("Profile image delete error:", err);
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
