-- Function to generate the next admin ID in format ADM00001, ADM00002, etc.
CREATE OR REPLACE FUNCTION generate_next_admin_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
BEGIN
    -- Get the next sequential number for admins in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 4)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'admin' 
    AND user_id LIKE 'ADM%';
    
    -- Format as ADM00001, ADM00002, etc.
    formatted_id := 'ADM' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;