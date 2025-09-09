-- Fix for the get_users_by_type function
-- The issue is that auth.users.email is VARCHAR(255) but function declares it as TEXT

CREATE OR REPLACE FUNCTION get_users_by_type(
    p_school_id INTEGER,
    p_user_type TEXT,
    p_limit INTEGER DEFAULT NULL,
    p_offset INTEGER DEFAULT NULL
)
RETURNS TABLE(
    id UUID,
    name TEXT,
    user_id TEXT,
    phone TEXT,
    email VARCHAR(255), -- Changed from TEXT to VARCHAR(255) to match auth.users.email
    class_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.user_id,
        p.phone,
        au.email,
        c.name as class_name,
        p.created_at
    FROM profiles p
    JOIN auth.users au ON p.id = au.id
    LEFT JOIN classes c ON p.class_id = c.id
    WHERE p.school_id = p_school_id 
    AND p.user_type = p_user_type
    ORDER BY p.name
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;