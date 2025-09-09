# Database Type Mismatch Fix

## Issue Description
The error occurred when calling the `get_users_by_type` RPC function:

```
PostgresException[message: structure of query does not match function result type void, code: 42804, details: Returned type character varying(255) does not match expected type text in column 5, hint: null]
```

## Root Cause
The issue was in the `get_users_by_type` function definition. Column 5 (the `email` field) had a type mismatch:

- **Function declared**: `email TEXT`
- **Actual database type**: `auth.users.email` is `character varying(255)` (VARCHAR(255))

PostgreSQL is strict about type matching in function return types, so this mismatch caused the error.

## Solution Applied
Fixed the function by casting the email field to TEXT in the SELECT query:

```sql
-- Before (causing error):
au.email,

-- After (fixed):
au.email::TEXT, -- Cast VARCHAR(255) to TEXT to fix type mismatch
```

## Files Updated
1. `complete_database_setup.sql` - Main database setup file
2. `final_database_schema.md` - Documentation
3. `fix_get_users_by_type.sql` - Standalone fix (VARCHAR approach)
4. `fix_get_users_by_type_alternative.sql` - Standalone fix (TEXT cast approach)

## How to Apply the Fix

### Option 1: Run the Updated Function (Recommended)
Execute this SQL in your Supabase SQL Editor:

```sql
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
        au.email::TEXT, -- Cast VARCHAR(255) to TEXT to fix type mismatch
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
```

### Option 2: Re-run Complete Setup
If you haven't made other changes, you can re-run the updated `complete_database_setup.sql` file.

## Verification
After applying the fix, the Flutter app should be able to:
1. Successfully call `AdminService.getStudents()`
2. Load the admin dashboard without errors
3. Display student lists properly

## Prevention
This type of issue can be prevented by:
1. Always checking the actual column types in PostgreSQL system tables
2. Using explicit type casting when there might be type mismatches
3. Testing RPC functions thoroughly before deployment

## Technical Notes
- PostgreSQL `TEXT` and `VARCHAR(n)` are similar but not identical types
- Function return types must match exactly with the actual returned data types
- Type casting with `::TEXT` is the safest approach for this scenario