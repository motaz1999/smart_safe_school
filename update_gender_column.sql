-- Update the gender column to use enum constraint
ALTER TABLE profiles 
ADD CONSTRAINT gender_check CHECK (gender IN ('male', 'female'));