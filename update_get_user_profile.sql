-- Update get_user_profile function to include gender
CREATE OR REPLACE FUNCTION get_user_profile(p_user_id UUID)
RETURNS TABLE(
    id UUID,
    school_id INTEGER,
    user_type TEXT,
    name TEXT,
    user_id TEXT,
    phone TEXT,
    permissions JSONB,
    class_id UUID,
    parent_contact TEXT,
    gender TEXT,
    school_name TEXT,
    class_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.school_id,
        p.user_type,
        p.name,
        p.user_id,
        p.phone,
        p.permissions,
        p.class_id,
        p.parent_contact,
        p.gender,
        s.name as school_name,
        c.name as class_name
    FROM profiles p
    JOIN schools s ON p.school_id = s.id
    LEFT JOIN classes c ON p.class_id = c.id
    WHERE p.id = p_user_id;
END;
$$;