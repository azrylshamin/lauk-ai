const { Pool } = require("pg");

const pool = new Pool({
    connectionString:
        process.env.DATABASE_URL || "postgres://postgres:postgres@localhost:5432/laukai",
});

// Quick connectivity check on first import
pool.query("SELECT 1")
    .then(() => console.log("✅ Connected to PostgreSQL"))
    .catch((err) => console.error("❌ PostgreSQL connection error:", err.message));

module.exports = pool;
