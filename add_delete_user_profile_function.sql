-- Function to delete a user profile and all related data
CREATE OR REPLACE FUNCTION delete_user_profile(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_school_id INTEGER;
    user_type_var TEXT;
BEGIN
    -- Get user's school_id and type for validation
    SELECT school_id, user_type INTO user_school_id, user_type_var
    FROM profiles p
    WHERE p.id = p_user_id;
    
    -- Check if user exists
    IF user_school_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if current user has permission (is admin of the same school)
    IF get_user_school_id() != user_school_id OR get_user_role() != 'admin' THEN
        RAISE EXCEPTION 'Permission denied. Only admins can delete users from their school.';
    END IF;
    
    -- For teachers, delete related data first
    IF user_type_var = 'teacher' THEN
        -- Delete teacher_subjects entries
        DELETE FROM teacher_subjects WHERE teacher_id = p_user_id;
        
        -- Delete timetable entries
        DELETE FROM timetables WHERE teacher_id = p_user_id;
        
        -- Delete attendance records where this user is the teacher
        DELETE FROM attendance_records WHERE teacher_id = p_user_id;
        
        -- Delete grades where this user is the teacher
        DELETE FROM grades WHERE teacher_id = p_user_id;
    END IF;
    
    -- For students, delete related data
    IF user_type_var = 'student' THEN
        -- Delete attendance records where this user is the student
        DELETE FROM attendance_records WHERE student_id = p_user_id;
        
        -- Delete grades where this user is the student
        DELETE FROM grades WHERE student_id = p_user_id;
    END IF;
    
    -- Delete the profile (auth.users will be handled by CASCADE)
    DELETE FROM profiles WHERE id = p_user_id;
    
    RETURN TRUE;
END;
$$;