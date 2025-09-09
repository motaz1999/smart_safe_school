# Supabase Academic Year Functions

## Overview
This document contains the SQL functions needed to implement the automatic academic year and semester system in Supabase. These functions will automatically create academic years and semesters based on the current date without requiring manual management screens.

## Functions

### 1. create_academic_year_auto Function
This function automatically creates an academic year with semesters based on the current date.

```sql
-- Function to create academic year with semesters based on current date
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
```

### 2. create_school_with_academic_year_auto Function
This function creates a school and automatically sets up its academic year and semesters.

```sql
-- Function to create a school with academic year and semesters automatically
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
```

## How to Use These Functions

### Step 1: Create a School with Academic Year
To create a new school with its academic year and semesters automatically:

```sql
SELECT * FROM create_school_with_academic_year_auto(
    'New School Name',
    '123 Education Street',
    '+1234567890',
    'admin@newschool.com'
);
```

This will return the IDs of the created school and academic year.

### Step 2: Create Academic Year Only
If you already have a school and want to create an academic year for it:

```sql
SELECT create_academic_year_auto();
```

This will create an academic year with the three semesters based on the current date.

## Testing the Functions

### Test Case 1: Verify Academic Year Creation
```sql
-- Create a test school
SELECT * FROM create_school_with_academic_year_auto(
    'Test School',
    'Test Address',
    '1234567890',
    'test@test.com'
);

-- Check the created academic years and semesters
SELECT * FROM academic_years;
SELECT * FROM semesters;
```

### Test Case 2: Verify Semester Dates
```sql
-- Check that semesters have correct dates
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
ORDER BY s.name, sem.semester_number;
```

## Notes
1. These functions automatically determine the correct academic year based on the current date
2. The semester dates are fixed as per your requirements:
   - First semester: 15/09 to 31/12
   - Second semester: 01/01 to 31/03
   - Third semester: 01/04 to 10/06
3. No manual management screens are needed
4. The system handles academic year transitions automatically