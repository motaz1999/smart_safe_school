-- Function to generate the next student ID in format STU00001, STU00002, etc.
CREATE OR REPLACE FUNCTION generate_next_student_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
BEGIN
    -- Get the next sequential number for students in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 4)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'student' 
    AND user_id LIKE 'STU%';
    
    -- Format as STU00001, STU00002, etc.
    formatted_id := 'STU' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;

-- Function to generate the next teacher ID in format TEA00001, TEA00002, etc.
CREATE OR REPLACE FUNCTION generate_next_teacher_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
BEGIN
    -- Get the next sequential number for teachers in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 4)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'teacher' 
    AND user_id LIKE 'TEA%';
    
    -- Format as TEA00001, TEA00002, etc.
    formatted_id := 'TEA' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;

-- Updated function to create a student with auto-generated ID
CREATE OR REPLACE FUNCTION create_student_with_auto_id(
    p_email TEXT,
    p_password TEXT,
    p_name TEXT,
    p_school_id INTEGER,
    p_class_id UUID,
    p_parent_contact TEXT,
    p_gender TEXT,
    p_phone TEXT DEFAULT NULL
)
RETURNS TABLE(
    profile_id UUID,
    user_id TEXT,
    email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    generated_student_id TEXT;
BEGIN
    -- Generate the student ID
    generated_student_id := generate_next_student_id(p_school_id);
    
    -- Create auth user
    -- Note: This needs to be done in the application layer since we can't create auth users from SQL functions
    -- For now, we'll assume the auth user is created in the app and we just create the profile
    
    -- Return the generated ID for the application to use
    RETURN QUERY
    SELECT NULL::UUID as profile_id, generated_student_id as user_id, p_email as email;
END;
$$;

-- Updated function to create a teacher with auto-generated ID
CREATE OR REPLACE FUNCTION create_teacher_with_auto_id(
    p_email TEXT,
    p_password TEXT,
    p_name TEXT,
    p_school_id INTEGER,
    p_gender TEXT,
    p_phone TEXT DEFAULT NULL
)
RETURNS TABLE(
    profile_id UUID,
    user_id TEXT,
    email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    generated_teacher_id TEXT;
BEGIN
    -- Generate the teacher ID
    generated_teacher_id := generate_next_teacher_id(p_school_id);
    
    -- Return the generated ID for the application to use
    RETURN QUERY
    SELECT NULL::UUID as profile_id, generated_teacher_id as user_id, p_email as email;
END;
$$;