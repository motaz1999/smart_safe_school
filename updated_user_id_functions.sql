-- Function to generate the next admin ID in format ADM-001-00001
CREATE OR REPLACE FUNCTION generate_next_admin_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for admins in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'admin' 
    AND user_id LIKE 'ADM-' || school_id_formatted || '-%';
    
    -- Format as ADM-001-00001, ADM-001-00002, etc.
    formatted_id := 'ADM-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;

-- Function to generate the next teacher ID in format TEA-001-00001
CREATE OR REPLACE FUNCTION generate_next_teacher_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for teachers in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'teacher' 
    AND user_id LIKE 'TEA-' || school_id_formatted || '-%';
    
    -- Format as TEA-001-00001, TEA-001-00002, etc.
    formatted_id := 'TEA-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;

-- Function to generate the next student ID in format STU-001-00001
CREATE OR REPLACE FUNCTION generate_next_student_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for students in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'student' 
    AND user_id LIKE 'STU-' || school_id_formatted || '-%';
    
    -- Format as STU-001-00001, STU-001-00002, etc.
    formatted_id := 'STU-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;

-- Updated function to create a user profile with auto-generation support using new ID format
CREATE OR REPLACE FUNCTION create_user_profile(
    p_user_id UUID,
    p_school_id INTEGER,
    p_user_type TEXT,
    p_name TEXT,
    p_user_identifier TEXT DEFAULT NULL, -- Make this optional for auto-generation
    p_phone TEXT DEFAULT NULL,
    p_permissions JSONB DEFAULT '{}',
    p_class_id UUID DEFAULT NULL,
    p_parent_contact TEXT DEFAULT NULL,
    p_gender TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    final_user_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Validate user_type
    IF p_user_type NOT IN ('admin', 'teacher', 'student') THEN
        RAISE EXCEPTION 'Invalid user_type. Must be admin, teacher, or student';
    END IF;
    
    -- Validate required fields based on user_type
    IF p_user_type = 'student' AND (p_class_id IS NULL) THEN
        RAISE EXCEPTION 'Students must have class_id';
    END IF;
    
    -- Validate gender for students
    IF p_user_type = 'student' AND p_gender IS NULL THEN
        RAISE EXCEPTION 'Students must have gender specified';
    END IF;
    
    -- Validate gender values
    IF p_gender IS NOT NULL AND p_gender NOT IN ('male', 'female') THEN
        RAISE EXCEPTION 'Gender must be male or female';
    END IF;
    
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- If user_identifier is not provided, generate one based on user_type with new format
    IF p_user_identifier IS NULL THEN
        IF p_user_type = 'student' THEN
            -- Generate the next student ID with new format
            SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO final_user_id
            FROM profiles 
            WHERE school_id = p_school_id 
            AND user_type = 'student' 
            AND user_id LIKE 'STU-' || school_id_formatted || '-%';
            
            final_user_id := 'STU-' || school_id_formatted || '-' || LPAD(final_user_id::TEXT, 5, '0');
        ELSIF p_user_type = 'teacher' THEN
            -- Generate the next teacher ID with new format
            SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO final_user_id
            FROM profiles 
            WHERE school_id = p_school_id 
            AND user_type = 'teacher' 
            AND user_id LIKE 'TEA-' || school_id_formatted || '-%';
            
            final_user_id := 'TEA-' || school_id_formatted || '-' || LPAD(final_user_id::TEXT, 5, '0');
        ELSE
            -- Generate the next admin ID with new format
            SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO final_user_id
            FROM profiles 
            WHERE school_id = p_school_id 
            AND user_type = 'admin' 
            AND user_id LIKE 'ADM-' || school_id_formatted || '-%';
            
            final_user_id := 'ADM-' || school_id_formatted || '-' || LPAD(final_user_id::TEXT, 5, '0');
        END IF;
    ELSE
        final_user_id := p_user_identifier;
    END IF;
    
    INSERT INTO profiles (
        id, school_id, user_type, name, user_id, phone,
        permissions, class_id, parent_contact, gender
    )
    VALUES (
        p_user_id, p_school_id, p_user_type, p_name, final_user_id, p_phone,
        CASE WHEN p_user_type = 'admin' THEN p_permissions ELSE NULL END,
        CASE WHEN p_user_type = 'student' THEN p_class_id ELSE NULL END,
        CASE WHEN p_user_type = 'student' THEN p_parent_contact ELSE NULL END,
        p_gender
    );
    
    RETURN p_user_id;
END;
$$;