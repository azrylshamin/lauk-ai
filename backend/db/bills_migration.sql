-- LaukAI — Bills Schema
-- Run: psql -U postgres -d laukai -f db/bills_migration.sql

CREATE TABLE IF NOT EXISTS bills (
    id          SERIAL PRIMARY KEY,
    total       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at  TIMESTAMP DEFAULT NOW()
);

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
