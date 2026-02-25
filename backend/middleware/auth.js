const passport = require("passport");

/**
 * JWT authentication guard.
 * Attaches `req.user` with { id, email, name, role, restaurant_id }.
 */
function authenticate(req, res, next) {
    passport.authenticate("jwt", { session: false }, (err, user) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!user) return res.status(401).json({ error: "Unauthorized" });
        req.user = user;
        req.restaurantId = user.restaurant_id;
        next();
    })(req, res, next);
}

/**
 * Owner-only guard. Must be used AFTER `authenticate`.
 */
function requireOwner(req, res, next) {
    if (req.user.role !== "owner") {
        return res.status(403).json({ error: "Owner access required" });
    }
    next();
}

module.exports = { authenticate, requireOwner };
