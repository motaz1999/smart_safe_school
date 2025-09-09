-- Function to generate the next admin ID with hybrid approach
-- Admins: ADM-001-00001 to ADM-001-00010 (per school)
CREATE OR REPLACE FUNCTION generate_next_admin_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    school_id_formatted TEXT;
    formatted_id TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for admins in this school (max 10)
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'admin' 
    AND user_id LIKE 'ADM-' || school_id_formatted || '-%';
    
    -- Check if we've exceeded the school's allocation
    IF next_id > 10 THEN
        RAISE EXCEPTION 'School % has exceeded its admin ID allocation (max 10)', p_school_id;
    END IF;
    
    -- Format as ADM-001-00001, ADM-001-00002, etc.
    formatted_id := 'ADM-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;

-- Function to generate the next teacher ID with hybrid approach
-- Teachers: TEA-001-00001 to TEA-001-00050 (per school)
CREATE OR REPLACE FUNCTION generate_next_teacher_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    school_id_formatted TEXT;
    formatted_id TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for teachers in this school (max 50)
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'teacher' 
    AND user_id LIKE 'TEA-' || school_id_formatted || '-%';
    
    -- Check if we've exceeded the school's allocation
    IF next_id > 50 THEN
        RAISE EXCEPTION 'School % has exceeded its teacher ID allocation (max 50)', p_school_id;
    END IF;
    
    -- Format as TEA-001-00001, TEA-001-00002, etc.
    formatted_id := 'TEA-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;

-- Function to generate the next student ID with hybrid approach
-- Students: STU-001-00001 to STU-001-00500 (per school)
CREATE OR REPLACE FUNCTION generate_next_student_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    school_id_formatted TEXT;
    formatted_id TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for students in this school (max 500)
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'student' 
    AND user_id LIKE 'STU-' || school_id_formatted || '-%';
    
    -- Check if we've exceeded the school's allocation
    IF next_id > 500 THEN
        RAISE EXCEPTION 'School % has exceeded its student ID allocation (max 500)', p_school_id;
    END IF;
    
    -- Format as STU-001-00001, STU-001-00002, etc.
    formatted_id := 'STU-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;