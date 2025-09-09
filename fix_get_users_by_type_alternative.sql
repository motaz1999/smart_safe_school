-- Alternative fix for the get_users_by_type function
-- Cast the email field to TEXT to match the function return type

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
    email TEXT, -- Keep as TEXT
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
        au.email::TEXT, -- Cast VARCHAR(255) to TEXT
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