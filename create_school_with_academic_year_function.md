# Create School with Academic Year Function

## Overview
This document describes a new database function that automatically creates a school with its academic year and semesters.

## Function Implementation

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

## Usage
This function can be called when creating a new school to automatically set up the academic year structure:

```sql
SELECT * FROM create_school_with_academic_year(
    'New School Name',
    '123 Education Street',
    '+1234567890',
    'admin@newschool.com'
);
```

The function returns the IDs of the created school and academic year, which can be used for further operations.