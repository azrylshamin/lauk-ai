-- LaukAI — Auth Schema (restaurants + users)
-- Run: psql -U postgres -d laukai -f db/auth_migration.sql

CREATE TABLE IF NOT EXISTS restaurants (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name          VARCHAR(100) NOT NULL,
    role          VARCHAR(10) NOT NULL DEFAULT 'staff'
                      CHECK (role IN ('owner', 'staff')),
    restaurant_id INTEGER NOT NULL REFERENCES restaurants(id),
    created_at    TIMESTAMP DEFAULT NOW()
);
