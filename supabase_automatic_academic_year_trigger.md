# Supabase Automatic Academic Year Trigger

## Overview
This document contains the SQL code to create a trigger that automatically creates academic years and semesters when a school is added directly through the Supabase dashboard or any other method that inserts directly into the schools table.

## Trigger Function
This function will be called whenever a new school is inserted into the database:

```sql
-- Function to automatically create academic year when a school is created
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
```

## Trigger Creation
This trigger will fire after a school is inserted:

```sql
-- Create trigger to automatically create academic year when school is inserted
DROP TRIGGER IF EXISTS create_academic_year_on_school_insert ON schools;

CREATE TRIGGER create_academic_year_on_school_insert
    AFTER INSERT ON schools
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_academic_year_for_school();
```

## Complete Setup Script
Here's the complete script to set up automatic academic year creation:

```sql
-- 1. Create the trigger function
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

-- 2. Create the trigger
DROP TRIGGER IF EXISTS create_academic_year_on_school_insert ON schools;

CREATE TRIGGER create_academic_year_on_school_insert
    AFTER INSERT ON schools
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_academic_year_for_school();
```

## How It Works

### When Adding Schools Through Supabase Dashboard:
1. You insert a new school record directly in the Supabase dashboard
2. The trigger automatically fires after the insert
3. The academic year and semesters are automatically created with the correct dates
4. No additional steps are needed

### When Adding Schools Through Functions:
1. If you use the `create_school_with_academic_year_auto` function, it will work as before
2. The trigger will still fire, but it won't cause conflicts since the academic year creation is idempotent

## Testing the Trigger

### Test Case 1: Add School Through Dashboard Simulation
```sql
-- Insert a school directly (simulating dashboard insert)
INSERT INTO schools (name, address, phone, email)
VALUES (
    'Test School from Dashboard',
    '123 Test Street',
    '123-456-7890',
    'test@dashboard.com'
);

-- Check that academic year and semesters were created automatically
SELECT * FROM academic_years WHERE school_id = (SELECT id FROM schools WHERE name = 'Test School from Dashboard');
SELECT * FROM semesters WHERE academic_year_id = (SELECT id FROM academic_years WHERE school_id = (SELECT id FROM schools WHERE name = 'Test School from Dashboard'));
```

### Test Case 2: Verify Semester Dates
```sql
-- Check that semesters have correct dates for the new school
SELECT 
    s.name as school_name,
    ay.name as academic_year_name,
    ay.start_date as academic_year_start,
    ay.end_date as academic_year_end,
    sem.name as semester_name,
    sem.semester_number,
    sem.start_date as semester_start,
    sem.end_date as semester_end
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id
JOIN semesters sem ON ay.id = sem.academic_year_id
WHERE s.name = 'Test School from Dashboard'
ORDER BY sem.semester_number;
```

## Benefits of This Approach

1. **Fully Automatic**: Works with dashboard inserts, function calls, or any method of school creation
2. **Consistent**: Every school automatically gets the correct academic structure
3. **No Manual Steps**: No need to remember to call additional functions
4. **Robust**: Handles all methods of school creation
5. **Transparent**: Works behind the scenes without user intervention

## Notes
1. The trigger only fires for new school inserts, not updates
2. If you need to customize the academic year for a specific school, you can update it after creation
3. The trigger uses the same date logic as the manual functions for consistency