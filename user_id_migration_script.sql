-- Migration script to update existing user IDs to the new format
-- This script should be run after deploying the updated functions

-- IMPORTANT: Backup your database before running this script!

-- Function to migrate admin IDs to new format
CREATE OR REPLACE FUNCTION migrate_admin_ids()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    admin_record RECORD;
    new_user_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Process each admin user
    FOR admin_record IN 
        SELECT id, user_id, school_id 
        FROM profiles 
        WHERE user_type = 'admin' 
        AND user_id NOT LIKE 'ADM-%-%'
    LOOP
        -- Format school ID as 3-digit number
        school_id_formatted := LPAD(admin_record.school_id::TEXT, 3, '0');
        
        -- Extract sequential number from old ID
        -- Assuming old format is ADM00001, extract the 00001 part
        new_user_id := 'ADM-' || school_id_formatted || '-' || 
                      LPAD(SUBSTRING(admin_record.user_id FROM 4)::TEXT, 5, '0');
        
        -- Update the user ID
        UPDATE profiles 
        SET user_id = new_user_id 
        WHERE id = admin_record.id;
        
        RAISE NOTICE 'Updated admin % from % to %', admin_record.id, admin_record.user_id, new_user_id;
    END LOOP;
END;
$$;

-- Function to migrate teacher IDs to new format
CREATE OR REPLACE FUNCTION migrate_teacher_ids()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    teacher_record RECORD;
    new_user_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Process each teacher user
    FOR teacher_record IN 
        SELECT id, user_id, school_id 
        FROM profiles 
        WHERE user_type = 'teacher' 
        AND user_id NOT LIKE 'TEA-%-%'
    LOOP
        -- Format school ID as 3-digit number
        school_id_formatted := LPAD(teacher_record.school_id::TEXT, 3, '0');
        
        -- Extract sequential number from old ID
        -- Assuming old format is TEA00001, extract the 00001 part
        new_user_id := 'TEA-' || school_id_formatted || '-' || 
                      LPAD(SUBSTRING(teacher_record.user_id FROM 4)::TEXT, 5, '0');
        
        -- Update the user ID
        UPDATE profiles 
        SET user_id = new_user_id 
        WHERE id = teacher_record.id;
        
        RAISE NOTICE 'Updated teacher % from % to %', teacher_record.id, teacher_record.user_id, new_user_id;
    END LOOP;
END;
$$;

-- Function to migrate student IDs to new format
CREATE OR REPLACE FUNCTION migrate_student_ids()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    student_record RECORD;
    new_user_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Process each student user
    FOR student_record IN 
        SELECT id, user_id, school_id 
        FROM profiles 
        WHERE user_type = 'student' 
        AND user_id NOT LIKE 'STU-%-%'
    LOOP
        -- Format school ID as 3-digit number
        school_id_formatted := LPAD(student_record.school_id::TEXT, 3, '0');
        
        -- Extract sequential number from old ID
        -- Assuming old format is STU00001, extract the 00001 part
        new_user_id := 'STU-' || school_id_formatted || '-' || 
                      LPAD(SUBSTRING(student_record.user_id FROM 4)::TEXT, 5, '0');
        
        -- Update the user ID
        UPDATE profiles 
        SET user_id = new_user_id 
        WHERE id = student_record.id;
        
        RAISE NOTICE 'Updated student % from % to %', student_record.id, student_record.user_id, new_user_id;
    END LOOP;
END;
$$;

-- Function to run all migrations
CREATE OR REPLACE FUNCTION migrate_all_user_ids()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Starting user ID migration...';
    
    -- Migrate admin IDs
    RAISE NOTICE 'Migrating admin IDs...';
    PERFORM migrate_admin_ids();
    
    -- Migrate teacher IDs
    RAISE NOTICE 'Migrating teacher IDs...';
    PERFORM migrate_teacher_ids();
    
    -- Migrate student IDs
    RAISE NOTICE 'Migrating student IDs...';
    PERFORM migrate_student_ids();
    
    RAISE NOTICE 'User ID migration completed!';
END;
$$;

-- To run the migration, execute:
-- SELECT migrate_all_user_ids();

-- To verify the migration, you can check a sample of records:
-- SELECT id, user_id, user_type FROM profiles LIMIT 10;