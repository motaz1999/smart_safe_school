-- Migration script to update existing user IDs to the hybrid format
-- This script should be run after deploying the updated functions

-- IMPORTANT: Backup your database before running this script!

-- Function to migrate admin IDs to hybrid format with limits
CREATE OR REPLACE FUNCTION migrate_admin_ids_hybrid()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    admin_record RECORD;
    new_user_id TEXT;
    school_id_formatted TEXT;
    sequential_number INTEGER;
BEGIN
    -- Process each admin user grouped by school
    FOR admin_record IN 
        SELECT id, user_id, school_id,
               ROW_NUMBER() OVER (PARTITION BY school_id ORDER BY created_at) as seq_num
        FROM profiles 
        WHERE user_type = 'admin'
    LOOP
        -- Format school ID as 3-digit number
        school_id_formatted := LPAD(admin_record.school_id::TEXT, 3, '0');
        
        -- Get sequential number (ensure it doesn't exceed limit of 10)
        sequential_number := LEAST(admin_record.seq_num, 10);
        
        -- Create new ID format
        new_user_id := 'ADM-' || school_id_formatted || '-' || 
                      LPAD(sequential_number::TEXT, 5, '0');
        
        -- Update the user ID
        UPDATE profiles 
        SET user_id = new_user_id 
        WHERE id = admin_record.id;
        
        RAISE NOTICE 'Updated admin % from % to %', admin_record.id, admin_record.user_id, new_user_id;
    END LOOP;
END;
$$;

-- Function to migrate teacher IDs to hybrid format with limits
CREATE OR REPLACE FUNCTION migrate_teacher_ids_hybrid()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    teacher_record RECORD;
    new_user_id TEXT;
    school_id_formatted TEXT;
    sequential_number INTEGER;
BEGIN
    -- Process each teacher user grouped by school
    FOR teacher_record IN 
        SELECT id, user_id, school_id,
               ROW_NUMBER() OVER (PARTITION BY school_id ORDER BY created_at) as seq_num
        FROM profiles 
        WHERE user_type = 'teacher'
    LOOP
        -- Format school ID as 3-digit number
        school_id_formatted := LPAD(teacher_record.school_id::TEXT, 3, '0');
        
        -- Get sequential number (ensure it doesn't exceed limit of 50)
        sequential_number := LEAST(teacher_record.seq_num, 50);
        
        -- Create new ID format
        new_user_id := 'TEA-' || school_id_formatted || '-' || 
                      LPAD(sequential_number::TEXT, 5, '0');
        
        -- Update the user ID
        UPDATE profiles 
        SET user_id = new_user_id 
        WHERE id = teacher_record.id;
        
        RAISE NOTICE 'Updated teacher % from % to %', teacher_record.id, teacher_record.user_id, new_user_id;
    END LOOP;
END;
$$;

-- Function to migrate student IDs to hybrid format with limits
CREATE OR REPLACE FUNCTION migrate_student_ids_hybrid()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    student_record RECORD;
    new_user_id TEXT;
    school_id_formatted TEXT;
    sequential_number INTEGER;
BEGIN
    -- Process each student user grouped by school
    FOR student_record IN 
        SELECT id, user_id, school_id,
               ROW_NUMBER() OVER (PARTITION BY school_id ORDER BY created_at) as seq_num
        FROM profiles 
        WHERE user_type = 'student'
    LOOP
        -- Format school ID as 3-digit number
        school_id_formatted := LPAD(student_record.school_id::TEXT, 3, '0');
        
        -- Get sequential number (ensure it doesn't exceed limit of 500)
        sequential_number := LEAST(student_record.seq_num, 500);
        
        -- Create new ID format
        new_user_id := 'STU-' || school_id_formatted || '-' || 
                      LPAD(sequential_number::TEXT, 5, '0');
        
        -- Update the user ID
        UPDATE profiles 
        SET user_id = new_user_id 
        WHERE id = student_record.id;
        
        RAISE NOTICE 'Updated student % from % to %', student_record.id, student_record.user_id, new_user_id;
    END LOOP;
END;
$$;

-- Function to run all migrations
CREATE OR REPLACE FUNCTION migrate_all_user_ids_hybrid()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Starting user ID migration to hybrid format...';
    
    -- Migrate admin IDs
    RAISE NOTICE 'Migrating admin IDs...';
    PERFORM migrate_admin_ids_hybrid();
    
    -- Migrate teacher IDs
    RAISE NOTICE 'Migrating teacher IDs...';
    PERFORM migrate_teacher_ids_hybrid();
    
    -- Migrate student IDs
    RAISE NOTICE 'Migrating student IDs...';
    PERFORM migrate_student_ids_hybrid();
    
    RAISE NOTICE 'User ID migration to hybrid format completed!';
END;
$$;

-- To run the migration, execute:
-- SELECT migrate_all_user_ids_hybrid();

-- To verify the migration, you can check a sample of records:
-- SELECT id, user_id, user_type, school_id FROM profiles ORDER BY school_id, user_type, user_id LIMIT 20;

-- Function to check for any users that exceeded their allocation limits
CREATE OR REPLACE FUNCTION check_user_allocation_limits()
RETURNS TABLE(
    school_id INTEGER,
    user_type TEXT,
    count BIGINT,
    limit_value INTEGER,
    exceeded BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH user_counts AS (
        SELECT 
            school_id,
            user_type,
            COUNT(*) as user_count
        FROM profiles
        GROUP BY school_id, user_type
    )
    SELECT 
        uc.school_id,
        uc.user_type,
        uc.user_count,
        CASE 
            WHEN uc.user_type = 'admin' THEN 10
            WHEN uc.user_type = 'teacher' THEN 50
            WHEN uc.user_type = 'student' THEN 500
            ELSE 0
        END as limit_value,
        CASE 
            WHEN (uc.user_type = 'admin' AND uc.user_count > 10) OR
                 (uc.user_type = 'teacher' AND uc.user_count > 50) OR
                 (uc.user_type = 'student' AND uc.user_count > 500)
            THEN TRUE
            ELSE FALSE
        END as exceeded
    FROM user_counts uc
    ORDER BY uc.school_id, uc.user_type;
END;
$$;

-- To check for any users that exceeded their allocation limits, execute:
-- SELECT * FROM check_user_allocation_limits() WHERE exceeded = TRUE;