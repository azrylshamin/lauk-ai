-- Tax & service charge settings for restaurants
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS sst_enabled BOOLEAN DEFAULT false;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS sst_rate    NUMERIC(5,2) DEFAULT 6.00;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS sc_enabled  BOOLEAN DEFAULT false;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS sc_rate     NUMERIC(5,2) DEFAULT 10.00;

-- Tax breakdown columns for bills
ALTER TABLE bills ADD COLUMN IF NOT EXISTS subtotal   NUMERIC(10,2);
ALTER TABLE bills ADD COLUMN IF NOT EXISTS sst_amount NUMERIC(10,2) DEFAULT 0;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS sc_amount  NUMERIC(10,2) DEFAULT 0;
