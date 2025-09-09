# Academic Year Adjustment Summary

## Overview
This document summarizes the changes needed to adjust the academic year and semester dates to start from August 1st of each year instead of the current September 15th.

## Current Implementation
The current implementation uses:
- Academic year starting on September 15th
- First semester: September 15 to December 31
- Second semester: January 1 to March 31
- Third semester: April 1 to June 10

## Updated Academic Year Structure
After the adjustment, the academic year structure will be:
- Academic year starting on August 1st
- First semester: August 1 to December 31
- Second semester: January 1 to March 31
- Third semester: April 1 to July 31

## Required Database Function Updates

### Updated create_academic_year_auto Function
The `create_academic_year_auto` function needs to be updated to use August 1st as the start date:

```sql
-- Function to create academic year with semesters based on current date (starting August 1st)
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
    -- If current date is before August 1, use previous year as start
    -- Otherwise, use current year as start
    IF EXTRACT(MONTH FROM NOW()) < 8 OR (EXTRACT(MONTH FROM NOW()) = 8 AND EXTRACT(DAY FROM NOW()) < 1) THEN
        academic_year_name := (current_year - 1) || '-' || current_year;
        start_date := MAKE_DATE(current_year - 1, 8, 1);
        end_date := MAKE_DATE(current_year, 7, 31);
    ELSE
        academic_year_name := current_year || '-' || (current_year + 1);
        start_date := MAKE_DATE(current_year, 8, 1);
        end_date := MAKE_DATE(current_year + 1, 7, 31);
    END IF;
    
    -- Insert academic year
    INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
    VALUES (NULL, academic_year_name, start_date, end_date, TRUE)
    RETURNING id INTO new_year_id;
    
    -- Set other years as not current (if any exist)
    UPDATE academic_years
    SET is_current = FALSE
    WHERE id != new_year_id;
    
    -- Create 3 semesters with updated dates
    -- First semester: August 1 to December 31
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
    
    -- Second semester: January 1 to March 31
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
    
    -- Third semester: April 1 to July 31
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
        MAKE_DATE(EXTRACT(YEAR FROM start_date)::INTEGER + 1, 7, 31),
        FALSE
    );
    
    RETURN new_year_id;
END;
$$;
```

### Updated create_school_with_academic_year_auto Function
The `create_school_with_academic_year_auto` function also needs to be updated:

```sql
-- Function to create a school with academic year and semesters automatically (starting August 1st)
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

## Implementation Steps

1. **Update Database Functions**:
   - Replace the existing `create_academic_year_auto` function with the updated version
   - Replace the existing `create_school_with_academic_year_auto` function with the updated version

2. **Test the Changes**:
   - Verify that academic years are created with the correct start date (August 1st)
   - Verify that semesters have the correct date ranges
   - Test with different current dates to ensure proper academic year determination

3. **Update Documentation**:
   - Update any documentation that references the academic year dates
   - Update comments in the code if needed

## Testing Plan

### Test Cases
1. **Date Boundary Testing**:
   - Test with dates before August 1 (should use previous year)
   - Test with dates after August 1 (should use current year)
   - Test with dates in each semester period

2. **Semester Date Verification**:
   - Verify first semester dates (August 1 to December 31)
   - Verify second semester dates (January 1 to March 31)
   - Verify third semester dates (April 1 to July 31)

3. **Academic Year Name Verification**:
   - Verify correct academic year naming based on date logic
   - Test year transitions

4. **Integration Testing**:
   - Test school creation with automatic academic year
   - Test that all semesters are created correctly
   - Verify current semester is properly marked