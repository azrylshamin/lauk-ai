-- LaukAI — Seed Data (demo / development)
-- Run AFTER init.sql:  psql -U postgres -d laukai -f db/seed.sql
--
-- Creates a demo restaurant with default menu items
-- matching the 6 YOLO detection classes.

INSERT INTO restaurants (name, onboarding_completed)
VALUES ('Demo Restaurant', true)
ON CONFLICT DO NOTHING;

INSERT INTO menu_items (yolo_class, name, price, restaurant_id) VALUES
    ('Chicken',    'Ayam',  2.00, 1),
    ('Egg',        'Telur', 1.00, 1),
    ('Fish',       'Ikan',  2.50, 1),
    ('Rice',       'Nasi',  1.50, 1),
    ('Sauce',      'Kuah',  0.50, 1),
    ('Vegetables', 'Sayur', 1.00, 1)
ON CONFLICT (restaurant_id, yolo_class) DO NOTHING;
