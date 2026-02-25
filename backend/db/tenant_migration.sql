-- LaukAI — Tenant scoping migration
-- Run AFTER auth_migration.sql
-- Run: psql -U postgres -d laukai -f db/tenant_migration.sql

-- Add restaurant_id to menu_items
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS restaurant_id INTEGER REFERENCES restaurants(id);

-- Add restaurant_id to bills
ALTER TABLE bills ADD COLUMN IF NOT EXISTS restaurant_id INTEGER REFERENCES restaurants(id);

-- Replace global yolo_class uniqueness with per-restaurant uniqueness
ALTER TABLE menu_items DROP CONSTRAINT IF EXISTS menu_items_yolo_class_key;
ALTER TABLE menu_items ADD CONSTRAINT menu_items_restaurant_yolo UNIQUE (restaurant_id, yolo_class);

-- Index for fast tenant-scoped queries
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_bills_restaurant ON bills(restaurant_id);
