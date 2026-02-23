-- LaukAI — Menu Items Schema & Seed Data
-- Run: psql -U postgres -d laukai -f db/seed.sql

CREATE TABLE IF NOT EXISTS menu_items (
    id          SERIAL PRIMARY KEY,
    yolo_class  VARCHAR(50) UNIQUE NOT NULL,
    name        VARCHAR(100) NOT NULL,
    price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- Seed the 6 known YOLO classes with default prices
INSERT INTO menu_items (yolo_class, name, price) VALUES
    ('Chicken',    'Ayam',    2.00),
    ('Egg',        'Telur',   1.00),
    ('Fish',       'Ikan',    2.50),
    ('Rice',       'Nasi',    1.50),
    ('Sauce',      'Kuah',    0.50),
    ('Vegetables', 'Sayur',   1.00)
ON CONFLICT (yolo_class) DO NOTHING;
