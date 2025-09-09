# Complete Academic Year Setup for Supabase

## Overview
This SQL script sets up the complete automatic academic year system for Smart Safe School. It includes functions to automatically create academic years and semesters with the specific dates:
- First semester: 15/09 to 31/12
- Second semester: 01/01 to 31/03
- Third semester: 01/04 to 10/06

The system works automatically whether schools are added through the dashboard, functions, or the app.

## Complete SQL Script

```sql
-- ==========================================
-- Smart Safe School Academic Year System
-- ==========================================

-- 1. Function to create academic year with semesters based on current date
CREATE OR REPLACE FUNCTION create_academic_year_auto()
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
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW())::INTEGER;
    
    -- Determine academic year name based on current date
    -- If current date is before September 15, use previous year as start
    -- Otherwise, use current year as start
    IF EXTRACT(MONTH FROM NOW()) < 9 OR (EXTRACT(MONTH FROM NOW()) = 9 AND EXTRACT(DAY FROM NOW()) < 15) THEN
        academic_year_name := (current_year - 1) || '-' || current_year;
        start_date := MAKE_DATE(current_year - 1, 9, 15);
        end_date := MAKE_DATE(current_year, 6, 10);
    ELSE
        academic_year_name := current_year || '-' || (current_year + 1);
        start_date := MAKE_DATE(current_year, 9, 15);
        end_date := MAKE_DATE(current_year + 1, 6, 10);
    END IF;
    
    -- Insert academic year
    INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
    VALUES (NULL, academic_year_name, start_date, end_date, TRUE)
    RETURNING id INTO new_year_id;
    
    -- Set other years as not current (if any exist)
    UPDATE academic_years 
    SET is_current = FALSE 
    WHERE id != new_year_id;
    
    -- Create 3 semesters with specific dates
    -- First semester: 15/09 to 31/12
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
        start_date,
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER, 12, 31),
        TRUE
    );
    
    -- Second semester: 01/01 to 31/03
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
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 1, 1),
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 3, 31),
        FALSE
    );
    
    -- Third semester: 01/04 to 10/06
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
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 4, 1),
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 6, 10),
        FALSE
    );
    
    RETURN new_year_id;
END;
$$;

-- 2. Function to create a school with academic year and semesters automatically
CREATE OR REPLACE FUNCTION create_school_with_academic_year_auto(
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
    SELECT create_academic_year_auto() INTO new_year_id;
    
    -- Update academic year with school_id
    UPDATE academic_years 
    SET school_id = new_school_id 
    WHERE id = new_year_id;
    
    RETURN QUERY SELECT new_school_id, new_year_id;
END;
$$;

-- 3. Function to automatically create academic year when a school is created
CREATE OR REPLACE FUNCTION auto_create_academic_year_for_school()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_year_id UUID;
    current_year INTEGER;
    academic_year_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW())::INTEGER;
    
    -- Determine academic year name based on current date
    -- If current date is before September 15, use previous year as start
    -- Otherwise, use current year as start
    IF EXTRACT(MONTH FROM NOW()) < 9 OR (EXTRACT(MONTH FROM NOW()) = 9 AND EXTRACT(DAY FROM NOW()) < 15) THEN
        academic_year_name := (current_year - 1) || '-' || current_year;
        start_date := MAKE_DATE(current_year - 1, 9, 15);
        end_date := MAKE_DATE(current_year, 6, 10);
    ELSE
        academic_year_name := current_year || '-' || (current_year + 1);
        start_date := MAKE_DATE(current_year, 9, 15);
        end_date := MAKE_DATE(current_year + 1, 6, 10);
    END IF;
    
    -- Insert academic year for the new school
    INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
    VALUES (NEW.id, academic_year_name, start_date, end_date, TRUE)
    RETURNING id INTO new_year_id;
    
    -- Create 3 semesters with specific dates
    -- First semester: 15/09 to 31/12
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
        start_date,
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER, 12, 31),
        TRUE
    );
    
    -- Second semester: 01/01 to 31/03
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
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 1, 1),
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 3, 31),
        FALSE
    );
    
    -- Third semester: 01/04 to 10/06
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
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 4, 1),
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 6, 10),
        FALSE
    );
    
    RETURN NEW;
END;
$$;

-- 4. Create trigger to automatically create academic year when school is inserted
DROP TRIGGER IF EXISTS create_academic_year_on_school_insert ON schools;

CREATE TRIGGER create_academic_year_on_school_insert
    AFTER INSERT ON schools
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_academic_year_for_school();

-- ==========================================
-- Usage Examples
-- ==========================================

-- To create a school with academic year and semesters:
-- SELECT * FROM create_school_with_academic_year_auto(
--     'School Name',
--     'School Address',
--     'Phone Number',
--     'email@school.com'
-- );

-- To create academic year and semesters only:
-- SELECT create_academic_year_auto();

-- To add a school directly through the dashboard (automatic):
-- Just insert into the schools table, the trigger will handle the rest
```

## How to Use This Script

1. Copy the entire SQL script above
2. Go to your Supabase project
3. Open the SQL Editor
4. Paste the script
5. Click "Run" to execute

## What This Script Does

1. **Creates three functions**:
   - `create_academic_year_auto()` - Creates academic year with semesters based on current date
   - `create_school_with_academic_year_auto()` - Creates school with academic year and semesters
   - `auto_create_academic_year_for_school()` - Trigger function for automatic creation

2. **Creates a trigger** that automatically fires when schools are inserted

3. **Provides usage examples** at the end

## Testing the Setup

After running the script, you can test it by:

1. **Adding a school through the dashboard**:
   - Go to the "schools" table in the Supabase dashboard
   - Click "Insert row"
   - Fill in school details
   - Click "Save"
   - Check that academic year and semesters were automatically created

2. **Using the functions directly**:
   ```sql
   SELECT * FROM create_school_with_academic_year_auto(
       'Test School',
       'Test Address',
       '1234567890',
       'test@test.com'
   );
   ```

## Notes

- All semester dates are fixed as per your requirements
- The system automatically determines the correct academic year based on the current date
- No manual management screens are needed
- Works with any method of school creation