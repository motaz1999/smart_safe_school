# Academic Year and Semester Implementation Plan

## Overview
This document outlines the changes needed to implement the specific academic year semester structure requested:
- First semester: 15/09 to 31/12
- Second semester: 01/01 to 31/03
- Third semester: 01/04 to 10/06

## Current Implementation Analysis
The current `create_academic_year` function in `complete_database_setup.sql` divides the academic year into three equal parts based on the start and end dates provided. This doesn't match the specific semester dates requested.

## Proposed Changes

### 1. Modify create_academic_year Function
Update the `create_academic_year` function to create semesters with the specific dates:

```sql
-- Function to create academic year with semesters
CREATE OR REPLACE FUNCTION create_academic_year(
    p_school_id INTEGER,
    p_name TEXT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_year_id UUID;
BEGIN
    -- Insert academic year
    INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
    VALUES (p_school_id, p_name, p_start_date, p_end_date, TRUE)
    RETURNING id INTO new_year_id;
    
    -- Set other years as not current
    UPDATE academic_years 
    SET is_current = FALSE 
    WHERE school_id = p_school_id AND id != new_year_id;
    
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
        -- Set start date to 15/09 of the academic year
        MAKE_DATE(EXTRACT(YEAR FROM p_start_date)::INTEGER, 9, 15),
        -- Set end date to 31/12 of the academic year
        MAKE_DATE(EXTRACT(YEAR FROM p_start_date)::INTEGER, 12, 31),
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
        -- Set start date to 01/01 of the next year
        MAKE_DATE(EXTRACT(YEAR FROM p_start_date)::INTEGER + 1, 1, 1),
        -- Set end date to 31/03 of the next year
        MAKE_DATE(EXTRACT(YEAR FROM p_start_date)::INTEGER + 1, 3, 31),
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
        -- Set start date to 01/04 of the next year
        MAKE_DATE(EXTRACT(YEAR FROM p_start_date)::INTEGER + 1, 4, 1),
        -- Set end date to 10/06 of the next year
        MAKE_DATE(EXTRACT(YEAR FROM p_start_date)::INTEGER + 1, 6, 10),
        FALSE
    );
    
    RETURN new_year_id;
END;
$$;
```

### 2. Create a New Function for Automatic School Year Creation
Create a new function that automatically creates an academic year with the specified semesters when a school is created:

```sql
-- Function to create a school with academic year and semesters
CREATE OR REPLACE FUNCTION create_school_with_academic_year(
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
    current_year INTEGER;
BEGIN
    -- Insert school
    INSERT INTO schools (name, address, phone, email)
    VALUES (p_name, p_address, p_phone, p_email)
    RETURNING id INTO new_school_id;
    
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW())::INTEGER;
    
    -- Insert academic year
    INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
    VALUES (
        new_school_id, 
        current_year || '-' || (current_year + 1), 
        MAKE_DATE(current_year, 9, 15), 
        MAKE_DATE(current_year + 1, 6, 10), 
        TRUE
    )
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
        MAKE_DATE(current_year, 9, 15),
        MAKE_DATE(current_year, 12, 31),
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
        MAKE_DATE(current_year + 1, 1, 1),
        MAKE_DATE(current_year + 1, 3, 31),
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
        MAKE_DATE(current_year + 1, 4, 1),
        MAKE_DATE(current_year + 1, 6, 10),
        FALSE
    );
    
    RETURN QUERY SELECT new_school_id, new_year_id;
END;
$$;
```

## Implementation Steps
1. Update the `create_academic_year` function in the database with the new implementation
2. Create the new `create_school_with_academic_year` function in the database
3. Update the Flutter app to use these functions when creating schools and academic years

## Testing Plan
1. Test the modified `create_academic_year` function to ensure it creates semesters with the correct dates
2. Test the new `create_school_with_academic_year` function to ensure it creates schools with academic years and semesters
3. Verify that the existing functionality for managing academic years and semesters still works correctly