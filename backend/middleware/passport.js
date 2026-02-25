require("dotenv").config({ path: require("path").resolve(__dirname, "../../.env") });
const passport = require("passport");
const { Strategy: LocalStrategy } = require("passport-local");
const { Strategy: JwtStrategy, ExtractJwt } = require("passport-jwt");
const bcrypt = require("bcrypt");
const pool = require("../db/db");

const JWT_SECRET = process.env.JWT_SECRET || "dev-secret-change-me";

// ---------------------------------------------------------------------------
// Local Strategy — email + password login
// ---------------------------------------------------------------------------
passport.use(
    new LocalStrategy(
        { usernameField: "email", passwordField: "password" },
        async (email, password, done) => {
            try {
                const { rows } = await pool.query(
                    "SELECT * FROM users WHERE email = $1",
                    [email.toLowerCase()]
                );

                if (rows.length === 0) {
                    return done(null, false, { message: "Invalid email or password" });
                }

                const user = rows[0];
                const match = await bcrypt.compare(password, user.password_hash);

                if (!match) {
                    return done(null, false, { message: "Invalid email or password" });
                }

                return done(null, user);
            } catch (err) {
                return done(err);
            }
        }
    )
);

// ---------------------------------------------------------------------------
// JWT Strategy — token from Authorization: Bearer <token>
// ---------------------------------------------------------------------------
passport.use(
    new JwtStrategy(
        {
            jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
            secretOrKey: JWT_SECRET,
        },
        async (payload, done) => {
            try {
                const { rows } = await pool.query(
                    "SELECT id, email, name, role, restaurant_id FROM users WHERE id = $1",
                    [payload.userId]
                );

                if (rows.length === 0) {
                    return done(null, false);
                }

                return done(null, rows[0]);
            } catch (err) {
                return done(err);
            }
        }
    )
);

module.exports = passport;
