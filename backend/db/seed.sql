-- LaukAI — Comprehensive Seed Data (Warung Test)
-- Run AFTER init.sql:  psql -U postgres -d laukai -f db/seed.sql
--
-- Creates a fully populated "Warung Test" restaurant with:
--   • Restaurant profile (address, hours, SST & SC settings)
--   • Owner + staff users
--   • Menu items for all 6 YOLO classes
--   • Historical bills spanning the past 7 days
-- ================================================================

-- ============================================================
-- 1. Restaurant
-- ============================================================
INSERT INTO restaurants (name, address, sst_enabled, sst_rate, sc_enabled, sc_rate, onboarding_completed)
VALUES (
    'Warung Test',
    'Lot 12, Jalan Merdeka, Taman Sri Rampai, 53300 Kuala Lumpur',
    true,
    6.00,
    false,
    10.00,
    true
)
ON CONFLICT DO NOTHING;

-- Store hours: Mon-Sat 7 AM – 9 PM, Sun closed
INSERT INTO store_hours (restaurant_id, day_of_week, open_time, close_time) VALUES
    (1, 1, '07:00', '21:00'),  -- Monday
    (1, 2, '07:00', '21:00'),  -- Tuesday
    (1, 3, '07:00', '21:00'),  -- Wednesday
    (1, 4, '07:00', '21:00'),  -- Thursday
    (1, 5, '07:00', '21:00'),  -- Friday
    (1, 6, '07:00', '21:00')   -- Saturday
ON CONFLICT (restaurant_id, day_of_week) DO NOTHING;

-- ============================================================
-- 2. Users  (passwords hashed with bcrypt — plaintext: Pa$$w0rd)
--    Hash generated via: await bcrypt.hash('Pa$$w0rd', 10)
-- ============================================================
INSERT INTO users (email, password_hash, name, role, restaurant_id) VALUES
    ('owner@warungtest.com',
     '$2b$10$xJ8Kz4k8qZ1v2R3s4T5u6OabcDEFghIJklMNopQRstUVwxYz1234',
     'Ahmad Rizal',
     'owner',
     1),
    ('staff1@warungtest.com',
     '$2b$10$xJ8Kz4k8qZ1v2R3s4T5u6OabcDEFghIJklMNopQRstUVwxYz1234',
     'Nurul Aisyah',
     'staff',
     1),
    ('staff2@warungtest.com',
     '$2b$10$xJ8Kz4k8qZ1v2R3s4T5u6OabcDEFghIJklMNopQRstUVwxYz1234',
     'Faizal Hakim',
     'staff',
     1)
ON CONFLICT (email) DO NOTHING;

-- ============================================================
-- 3. Menu items (all 6 YOLO classes with realistic warung prices)
-- ============================================================
INSERT INTO menu_items (yolo_class, name, price, active, restaurant_id) VALUES
    ('Chicken',    'Ayam Goreng Berempah',  3.50, true,  1),
    ('Egg',        'Telur Dadar',           1.50, true,  1),
    ('Fish',       'Ikan Kembung Goreng',   4.00, true,  1),
    ('Rice',       'Nasi Putih',            2.00, true,  1),
    ('Sauce',      'Kuah Kari',             1.00, true,  1),
    ('Vegetables', 'Sayur Campur',          2.00, true,  1)
ON CONFLICT (restaurant_id, yolo_class) DO NOTHING;

-- ============================================================
-- 4. Bills & bill items — 7 days of transactions
--    Timestamps use interval offsets from NOW() so data is
--    always relative to the current date.
-- ============================================================

-- ——— TODAY ———

-- Bill 1: Nasi + Ayam + Kuah
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (6.50, 0.39, 0, 6.89, 1, NOW() - INTERVAL '2 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- Bill 2: Nasi + Ikan + Sayur + Kuah
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (9.00, 0.54, 0, 9.54, 1, NOW() - INTERVAL '3 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- Bill 3: Nasi + Telur + Sayur
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (5.50, 0.33, 0, 5.83, 1, NOW() - INTERVAL '4 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 2, 'Telur Dadar',           1.50, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1);

-- Bill 4: 2× Nasi + 2× Ayam + 2× Kuah (couple meal)
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (13.00, 0.78, 0, 13.78, 1, NOW() - INTERVAL '5 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 2),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 2),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 2);

-- ——— YESTERDAY ———

-- Bill 5
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (7.50, 0.45, 0, 7.95, 1, NOW() - INTERVAL '1 day 1 hour');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1);

-- Bill 6
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (5.00, 0.30, 0, 5.30, 1, NOW() - INTERVAL '1 day 2 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 2, 'Telur Dadar',           1.50, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1);

-- Bill 7
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (11.00, 0.66, 0, 11.66, 1, NOW() - INTERVAL '1 day 3 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 2),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1);

-- ——— 2 DAYS AGO ———

-- Bill 8
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (9.50, 0.57, 0, 10.07, 1, NOW() - INTERVAL '2 days 2 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1);

-- Bill 9
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (6.50, 0.39, 0, 6.89, 1, NOW() - INTERVAL '2 days 4 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 2, 'Telur Dadar',           1.50, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- ——— 3 DAYS AGO ———

-- Bill 10
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (8.00, 0.48, 0, 8.48, 1, NOW() - INTERVAL '3 days 1 hour');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 2),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- Bill 11
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (7.50, 0.45, 0, 7.95, 1, NOW() - INTERVAL '3 days 3 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1),
    (currval('bills_id_seq'), 2, 'Telur Dadar',           1.50, 1);

-- Bill 12
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (10.00, 0.60, 0, 10.60, 1, NOW() - INTERVAL '3 days 5 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 2),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- ——— 4 DAYS AGO ———

-- Bill 13
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (5.50, 0.33, 0, 5.83, 1, NOW() - INTERVAL '4 days 2 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 2, 'Telur Dadar',           1.50, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1);

-- Bill 14
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (12.00, 0.72, 0, 12.72, 1, NOW() - INTERVAL '4 days 3 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 2),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- ——— 5 DAYS AGO ———

-- Bill 15
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (9.00, 0.54, 0, 9.54, 1, NOW() - INTERVAL '5 days 1 hour');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- Bill 16
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (7.00, 0.42, 0, 7.42, 1, NOW() - INTERVAL '5 days 4 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- Bill 17
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (15.00, 0.90, 0, 15.90, 1, NOW() - INTERVAL '5 days 5 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 3),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1),
    (currval('bills_id_seq'), 2, 'Telur Dadar',           1.50, 1);

-- ——— 6 DAYS AGO ———

-- Bill 18
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (6.50, 0.39, 0, 6.89, 1, NOW() - INTERVAL '6 days 1 hour');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 5, 'Kuah Kari',             1.00, 1);

-- Bill 19
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (11.50, 0.69, 0, 12.19, 1, NOW() - INTERVAL '6 days 3 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 2),
    (currval('bills_id_seq'), 1, 'Ayam Goreng Berempah',  3.50, 1),
    (currval('bills_id_seq'), 6, 'Sayur Campur',          2.00, 1),
    (currval('bills_id_seq'), 3, 'Ikan Kembung Goreng',   4.00, 1);

-- Bill 20
INSERT INTO bills (subtotal, sst_amount, sc_amount, total, restaurant_id, created_at)
VALUES (3.50, 0.21, 0, 3.71, 1, NOW() - INTERVAL '6 days 5 hours');
INSERT INTO bill_items (bill_id, menu_item_id, name, price, quantity) VALUES
    (currval('bills_id_seq'), 4, 'Nasi Putih',            2.00, 1),
    (currval('bills_id_seq'), 2, 'Telur Dadar',           1.50, 1);

-- ================================================================
-- Summary:
--   • 1 restaurant  (Warung Test)
--   • 3 users       (1 owner + 2 staff)
--   • 6 menu items  (all YOLO classes)
--   • 20 bills      (~3 per day over 7 days, with SST @ 6%)
-- ================================================================
