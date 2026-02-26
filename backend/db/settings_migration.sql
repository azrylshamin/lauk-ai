-- LaukAI — Settings feature migration
-- Run AFTER tenant_migration.sql
-- Run: psql -U postgres -d laukai -f db/settings_migration.sql

-- Add active/inactive toggle to menu_items
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;

-- Add restaurant profile fields
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS address VARCHAR(255) DEFAULT '';
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS phone VARCHAR(20) DEFAULT '';
