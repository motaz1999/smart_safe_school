-- Drop the existing function first
DROP FUNCTION IF EXISTS get_users_by_type(integer, text, integer, integer);

-- Create the updated function with class_id field
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
    email TEXT,
    class_id UUID,  -- Added class_id field
    class_name TEXT,
    gender TEXT,
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
        au.email::TEXT, -- Cast VARCHAR(255) to TEXT to fix type mismatch
        p.class_id,     -- Include class_id in the result
        c.name as class_name,
        p.gender,
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