-- Add onboarding_completed flag to restaurants table
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;

-- Mark all existing restaurants as already onboarded
UPDATE restaurants SET onboarding_completed = true;
