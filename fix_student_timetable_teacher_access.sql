-- Fix for students not being able to see teacher names in timetable
-- This adds a RLS policy to allow students to view teacher profiles (name only) for timetable purposes

-- Add policy to allow students to view teacher profiles in their school
DROP POLICY IF EXISTS "Students can view teacher profiles" ON profiles;
CREATE POLICY "Students can view teacher profiles" ON profiles
    FOR SELECT USING (
        school_id = get_user_school_id() AND
        get_user_role() = 'student' AND
        profiles.user_type = 'teacher'
    );

-- Verify the policy was created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'profiles' AND policyname = 'Students can view teacher profiles';