-- =====================================================
-- Smart Safe School - July to June Academic Year System
-- Complete Database Implementation
-- =====================================================
-- 
-- This script implements automatic academic year generation
-- Academic Year: July 1st to June 30th
-- Semesters:
--   1. August 15 to December 31
--   2. January 1 to March 31  
--   3. April 1 to June 15
-- =====================================================

-- Function to create academic year with July-June dates and specific semester periods
CREATE OR REPLACE FUNCTION create_academic_year_july_june(p_school_id INTEGER)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_year_id UUID;
    current_year INTEGER;
    academic_year_name TEXT;
    start_date DATE;
    end_date DATE;
    current_semester_number INTEGER;
    today_date DATE;
BEGIN
    -- Get current date and year
    today_date := CURRENT_DATE;
    current_year := EXTRACT(YEAR FROM today_date)::INTEGER;
    
    -- Determine academic year based on current date
    IF EXTRACT(MONTH FROM today_date) >= 7 THEN
        -- July 1st or later: use current year as start
        academic_year_name := current_year || '-' || (current_year + 1);
        start_date := MAKE_DATE(current_year, 7, 1);
        end_date := MAKE_DATE(current_year + 1, 6, 30);
    ELSE
        -- Before July 1st: use previous year as start
        academic_year_name := (current_year - 1) || '-' || current_year;
        start_date := MAKE_DATE(current_year - 1, 7, 1);
        end_date := MAKE_DATE(current_year, 6, 30);
    END IF;
    
    -- Check if academic year already exists for this school
    IF EXISTS (
        SELECT 1 FROM academic_years 
        WHERE school_id = p_school_id AND name = academic_year_name
    ) THEN
        -- Return existing academic year ID
        SELECT id INTO new_year_id 
        FROM academic_years 
        WHERE school_id = p_school_id AND name = academic_year_name;
        
        RETURN new_year_id;
    END IF;
    
    -- Insert academic year
    INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
    VALUES (p_school_id, academic_year_name, start_date, end_date, TRUE)
    RETURNING id INTO new_year_id;
    
    -- Set other years as not current for this school
    UPDATE academic_years 
    SET is_current = FALSE 
    WHERE school_id = p_school_id AND id != new_year_id;
    
    -- Determine which semester should be current based on current date
    current_semester_number := 1; -- Default to semester 1
    
    -- Semester 1: August 15 to December 31
    IF (EXTRACT(MONTH FROM today_date) = 8 AND EXTRACT(DAY FROM today_date) >= 15) OR
       (EXTRACT(MONTH FROM today_date) >= 9 AND EXTRACT(MONTH FROM today_date) <= 12) THEN
        current_semester_number := 1;
    -- Semester 2: January 1 to March 31
    ELSIF EXTRACT(MONTH FROM today_date) >= 1 AND EXTRACT(MONTH FROM today_date) <= 3 THEN
        current_semester_number := 2;
    -- Semester 3: April 1 to June 15
    ELSIF EXTRACT(MONTH FROM today_date) >= 4 AND
          (EXTRACT(MONTH FROM today_date) < 6 OR
           (EXTRACT(MONTH FROM today_date) = 6 AND EXTRACT(DAY FROM today_date) <= 15)) THEN
        current_semester_number := 3;
    -- Summer break: June 16 to August 14 (default to semester 1 upcoming)
    ELSE
        current_semester_number := 1;
    END IF;
    
    -- Create Semester 1: August 15 to December 31
    INSERT INTO semesters (
        academic_year_id, 
        name, 
        semester_number, 
        start_date, 
        end_date,
        is_current
    )
    VALUES (
        new_year_id,
        'First Semester',
        1,
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER, 8, 15),
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER, 12, 31),
        CASE WHEN current_semester_number = 1 THEN TRUE ELSE FALSE END
    );
    
    -- Create Semester 2: January 1 to March 31
    INSERT INTO semesters (
        academic_year_id, 
        name, 
        semester_number, 
        start_date, 
        end_date,
        is_current
    )
    VALUES (
        new_year_id,
        'Second Semester',
        2,
        MAKE_DATE(EXTRACT(YEAR FROM end_date)::INTEGER, 1, 1),
        MAKE_DATE(EXTRACT(YEAR FROM end_date)::INTEGER, 3, 31),
        CASE WHEN current_semester_number = 2 THEN TRUE ELSE FALSE END
    );
    
    -- Create Semester 3: April 1 to June 15
    INSERT INTO semesters (
        academic_year_id, 
        name, 
        semester_number, 
        start_date, 
        end_date,
        is_current
    )
    VALUES (
        new_year_id,
        'Third Semester',
        3,
        MAKE_DATE(EXTRACT(YEAR FROM end_date)::INTEGER, 4, 1),
        MAKE_DATE(EXTRACT(YEAR FROM end_date)::INTEGER, 6, 15),
        CASE WHEN current_semester_number = 3 THEN TRUE ELSE FALSE END
    );
    
    RETURN new_year_id;
END;
$$;

-- Function to create a school with automatic July-June academic year
CREATE OR REPLACE FUNCTION create_school_with_academic_year_july_june(
    p_name TEXT,
    p_address TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL
)
RETURNS TABLE(school_id INTEGER, academic_year_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_school_id INTEGER;
    new_year_id UUID;
BEGIN
    -- Insert school
    INSERT INTO schools (name, address, phone, email)
    VALUES (p_name, p_address, p_phone, p_email)
    RETURNING id INTO new_school_id;
    
    -- Create academic year automatically
    SELECT create_academic_year_july_june(new_school_id) INTO new_year_id;
    
    RETURN QUERY SELECT new_school_id, new_year_id;
END;
$$;

-- Trigger function to automatically create academic year when school is created
CREATE OR REPLACE FUNCTION auto_create_academic_year_july_june()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_year_id UUID;
BEGIN
    -- Create academic year for the new school
    SELECT create_academic_year_july_june(NEW.id) INTO new_year_id;
    
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists and create new one
DROP TRIGGER IF EXISTS create_academic_year_july_june_on_school_insert ON schools;
CREATE TRIGGER create_academic_year_july_june_on_school_insert
    AFTER INSERT ON schools
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_academic_year_july_june();

-- Update the existing get_current_semester function to work with July-June system
CREATE OR REPLACE FUNCTION get_current_semester(p_school_id INTEGER)
RETURNS TABLE(
    semester_id UUID,
    semester_name TEXT,
    semester_number INTEGER,
    academic_year_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.semester_number,
        ay.name
    FROM semesters s
    JOIN academic_years ay ON s.academic_year_id = ay.id
    WHERE ay.school_id = p_school_id 
    AND s.is_current = TRUE
    AND ay.is_current = TRUE;
END;
$$;

-- Function to update current semester based on current date
CREATE OR REPLACE FUNCTION update_current_semester_july_june(p_school_id INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    today_date DATE;
    current_semester_number INTEGER;
    current_academic_year_id UUID;
BEGIN
    today_date := CURRENT_DATE;
    
    -- Get current academic year for the school
    SELECT id INTO current_academic_year_id
    FROM academic_years
    WHERE school_id = p_school_id AND is_current = TRUE;
    
    IF current_academic_year_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Determine which semester should be current
    -- Semester 1: August 15 to December 31
    IF (EXTRACT(MONTH FROM today_date) = 8 AND EXTRACT(DAY FROM today_date) >= 15) OR
       (EXTRACT(MONTH FROM today_date) >= 9 AND EXTRACT(MONTH FROM today_date) <= 12) THEN
        current_semester_number := 1;
    -- Semester 2: January 1 to March 31
    ELSIF EXTRACT(MONTH FROM today_date) >= 1 AND EXTRACT(MONTH FROM today_date) <= 3 THEN
        current_semester_number := 2;
    -- Semester 3: April 1 to June 15
    ELSIF EXTRACT(MONTH FROM today_date) >= 4 AND
          (EXTRACT(MONTH FROM today_date) < 6 OR
           (EXTRACT(MONTH FROM today_date) = 6 AND EXTRACT(DAY FROM today_date) <= 15)) THEN
        current_semester_number := 3;
    -- Summer break: June 16 to August 14 (default to semester 1)
    ELSE
        current_semester_number := 1;
    END IF;
    
    -- Update all semesters to not current
    UPDATE semesters 
    SET is_current = FALSE 
    WHERE academic_year_id = current_academic_year_id;
    
    -- Set the appropriate semester as current
    UPDATE semesters 
    SET is_current = TRUE 
    WHERE academic_year_id = current_academic_year_id 
    AND semester_number = current_semester_number;
    
    RETURN TRUE;
END;
$$;

-- Function to test academic year creation with different dates
CREATE OR REPLACE FUNCTION test_academic_year_creation_july_june(test_date DATE)
RETURNS TABLE(
    test_date_input DATE,
    academic_year_name TEXT,
    start_date DATE,
    end_date DATE,
    current_semester INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_year INTEGER;
    ay_name TEXT;
    ay_start DATE;
    ay_end DATE;
    current_sem INTEGER;
BEGIN
    current_year := EXTRACT(YEAR FROM test_date)::INTEGER;
    
    -- Determine academic year based on test date
    IF EXTRACT(MONTH FROM test_date) >= 7 THEN
        ay_name := current_year || '-' || (current_year + 1);
        ay_start := MAKE_DATE(current_year, 7, 1);
        ay_end := MAKE_DATE(current_year + 1, 6, 30);
    ELSE
        ay_name := (current_year - 1) || '-' || current_year;
        ay_start := MAKE_DATE(current_year - 1, 7, 1);
        ay_end := MAKE_DATE(current_year, 6, 30);
    END IF;
    
    -- Determine current semester
    IF (EXTRACT(MONTH FROM test_date) = 8 AND EXTRACT(DAY FROM test_date) >= 15) OR
       (EXTRACT(MONTH FROM test_date) >= 9 AND EXTRACT(MONTH FROM test_date) <= 12) THEN
        current_sem := 1;
    ELSIF EXTRACT(MONTH FROM test_date) >= 1 AND EXTRACT(MONTH FROM test_date) <= 3 THEN
        current_sem := 2;
    ELSIF EXTRACT(MONTH FROM test_date) >= 4 AND 
          (EXTRACT(MONTH FROM test_date) < 6 OR 
           (EXTRACT(MONTH FROM test_date) = 6 AND EXTRACT(DAY FROM test_date) <= 15)) THEN
        current_sem := 3;
    ELSE
        current_sem := 1; -- Summer break
    END IF;
    
    RETURN QUERY SELECT test_date, ay_name, ay_start, ay_end, current_sem;
END;
$$;

-- =====================================================
-- MIGRATION SCRIPT FOR EXISTING SCHOOLS
-- =====================================================

-- Run this to create July-June academic years for existing schools
DO $$
DECLARE
    school_record RECORD;
    new_year_id UUID;
    existing_count INTEGER;
BEGIN
    RAISE NOTICE 'Starting migration to July-June academic year system...';
    
    -- Loop through all existing schools
    FOR school_record IN SELECT id, name FROM schools LOOP
        -- Check if school already has a July-June academic year
        SELECT COUNT(*) INTO existing_count
        FROM academic_years
        WHERE school_id = school_record.id
        AND (name LIKE '%-20%' OR name LIKE '20%-20%');
        
        -- Only create if no academic year exists
        IF existing_count = 0 THEN
            -- Create July-June academic year for each existing school
            SELECT create_academic_year_july_june(school_record.id) INTO new_year_id;
            
            RAISE NOTICE 'Created academic year % for school % (%)', 
                new_year_id, school_record.id, school_record.name;
        ELSE
            RAISE NOTICE 'School % (%) already has academic year, skipping', 
                school_record.id, school_record.name;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Migration completed successfully!';
END $$;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify all schools have academic years
SELECT 
    s.id,
    s.name as school_name,
    ay.name as academic_year,
    ay.start_date,
    ay.end_date,
    COUNT(sem.id) as semester_count
FROM schools s
LEFT JOIN academic_years ay ON s.id = ay.school_id AND ay.is_current = TRUE
LEFT JOIN semesters sem ON ay.id = sem.academic_year_id
GROUP BY s.id, s.name, ay.name, ay.start_date, ay.end_date
ORDER BY s.id;

-- Verify semester structure
SELECT 
    s.name as school_name,
    ay.name as academic_year,
    sem.name as semester_name,
    sem.semester_number,
    sem.start_date,
    sem.end_date,
    sem.is_current
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id AND ay.is_current = TRUE
JOIN semesters sem ON ay.id = sem.academic_year_id
ORDER BY s.name, sem.semester_number;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Test the academic year creation logic with different dates
-- SELECT * FROM test_academic_year_creation_july_june('2024-08-15'::DATE);
-- SELECT * FROM test_academic_year_creation_july_june('2024-06-30'::DATE);
-- SELECT * FROM test_academic_year_creation_july_june('2024-07-01'::DATE);

-- Create a school with automatic academic year
-- SELECT * FROM create_school_with_academic_year_july_june(
--     'New Test School',
--     'Test Address',
--     '1234567890',
--     'test@school.com'
-- );

-- Get current semester for a school
-- SELECT * FROM get_current_semester(1);

-- Update current semester based on current date
-- SELECT update_current_semester_july_june(1);

-- =====================================================
-- DEPLOYMENT COMPLETE
-- =====================================================