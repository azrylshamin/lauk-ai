-- LaukAI — Image URL migration
-- Run: psql -U postgres -d laukai -f db/image_migration.sql

ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE menu_items  ADD COLUMN IF NOT EXISTS image_url TEXT;
