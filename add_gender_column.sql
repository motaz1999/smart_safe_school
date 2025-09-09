-- Add gender column to profiles table
ALTER TABLE profiles ADD COLUMN gender TEXT;

-- Update the constraint to remove parent_contact requirement
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS valid_student_data;
ALTER TABLE profiles ADD CONSTRAINT valid_student_data CHECK (
    user_type != 'student' OR (class_id IS NOT NULL)
);

-- Add constraint to limit gender values to 'male' or 'female' but allow NULL
ALTER TABLE profiles 
ADD CONSTRAINT gender_check CHECK (gender IS NULL OR gender IN ('male', 'female'));