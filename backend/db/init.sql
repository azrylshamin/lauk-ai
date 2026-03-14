-- LaukAI — Full Database Schema
-- Sets up all tables from scratch.
-- Run: psql -U postgres -d laukai -f db/init.sql
--
-- After running this, optionally seed demo data with:
--   psql -U postgres -d laukai -f db/seed.sql

-- ============================================================
-- 1. Restaurants
-- ============================================================
CREATE TABLE IF NOT EXISTS restaurants (
    id                   SERIAL PRIMARY KEY,
    name                 VARCHAR(100) NOT NULL,
    image_url            TEXT,
    address              VARCHAR(255) DEFAULT '',
    sst_enabled          BOOLEAN      DEFAULT false,
    sst_rate             NUMERIC(5,2) DEFAULT 6.00,
    sc_enabled           BOOLEAN      DEFAULT false,
    sc_rate              NUMERIC(5,2) DEFAULT 10.00,
    onboarding_completed BOOLEAN      DEFAULT false,
    created_at           TIMESTAMP    DEFAULT NOW()
);

-- ============================================================
-- 1b. Store Hours (per-day operating hours for each restaurant)
-- ============================================================
CREATE TABLE IF NOT EXISTS store_hours (
    id            SERIAL PRIMARY KEY,
    restaurant_id INTEGER NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    day_of_week   SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    open_time     TIME NOT NULL,
    close_time    TIME NOT NULL,
    CONSTRAINT store_hours_unique_day UNIQUE (restaurant_id, day_of_week)
);

CREATE INDEX IF NOT EXISTS idx_store_hours_restaurant ON store_hours(restaurant_id);

-- ============================================================
-- 2. Users (multi-tenant, scoped to a restaurant)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name          VARCHAR(100) NOT NULL,
    role              VARCHAR(10)  NOT NULL DEFAULT 'staff'
                          CHECK (role IN ('owner', 'staff')),
    profile_image_url TEXT,
    restaurant_id     INTEGER NOT NULL REFERENCES restaurants(id),
    created_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 3. Menu items (per-restaurant, mapped to YOLO classes)
-- ============================================================
CREATE TABLE IF NOT EXISTS menu_items (
    id            SERIAL PRIMARY KEY,
    yolo_class    VARCHAR(50) NOT NULL,
    name          VARCHAR(100) NOT NULL,
    price         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    image_url     TEXT,
    active        BOOLEAN DEFAULT true,
    restaurant_id INTEGER REFERENCES restaurants(id),
    created_at    TIMESTAMP DEFAULT NOW(),
    CONSTRAINT menu_items_restaurant_yolo UNIQUE (restaurant_id, yolo_class)
);

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON menu_items(restaurant_id);

-- ============================================================
-- 4. Bills & bill items
-- ============================================================
CREATE TABLE IF NOT EXISTS bills (
    id            SERIAL PRIMARY KEY,
    total         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    subtotal      NUMERIC(10,2),
    sst_amount    NUMERIC(10,2) DEFAULT 0,
    sc_amount     NUMERIC(10,2) DEFAULT 0,
    restaurant_id INTEGER REFERENCES restaurants(id),
    created_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bills_restaurant ON bills(restaurant_id);

CREATE TABLE IF NOT EXISTS bill_items (
    id            SERIAL PRIMARY KEY,
    bill_id       INTEGER NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    menu_item_id  INTEGER REFERENCES menu_items(id) ON DELETE SET NULL,
    name          VARCHAR(100) NOT NULL,
    price         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    quantity      INTEGER NOT NULL DEFAULT 1,
    created_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON bill_items(bill_id);
