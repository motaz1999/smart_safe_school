-- Add gender column to profiles table
ALTER TABLE profiles ADD COLUMN gender TEXT;

-- Add constraint to limit gender values to 'male' or 'female' but allow NULL
ALTER TABLE profiles 
ADD CONSTRAINT gender_check CHECK (gender IS NULL OR gender IN ('male', 'female'));