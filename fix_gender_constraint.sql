-- Fix gender constraint to allow NULL values
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS gender_check;
ALTER TABLE profiles ADD CONSTRAINT gender_check CHECK (gender IS NULL OR gender IN ('male', 'female'));