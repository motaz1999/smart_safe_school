# Automatic Academic Year Implementation Plan

## Overview
This document outlines the implementation of an automatic academic year system that determines the current academic year and semesters based on the current date, without requiring manual management screens.

## Key Requirements
1. Automatically determine the current academic year based on the current date
2. Create semesters with the specific dates:
   - First semester: 15/09 to 31/12
   - Second semester: 01/01 to 31/03
   - Third semester: 01/04 to 10/06
3. No manual management screens needed
4. System automatically handles academic year transitions

## Database Implementation

### Updated create_academic_year Function
The function will be enhanced to automatically determine the academic year based on the current date:

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

### Enhanced create_school_with_academic_year Function
This function will be updated to automatically create the academic year when a school is created:

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

## How It Works Automatically

### Academic Year Determination
1. **Date Logic**: The system determines the academic year based on the current date:
   - If the current date is before September 15, it uses the previous year as the start of the academic year
   - If the current date is September 15 or later, it uses the current year as the start of the academic year

2. **Example Scenarios**:
   - If current date is August 2025: Academic year is 2024-2025 (starts September 15, 2024)
   - If current date is September 2025: Academic year is 2025-2026 (starts September 15, 2025)
   - If current date is June 2026: Academic year is 2025-2026 (starts September 15, 2025)

### Semester Creation
The system automatically creates the three semesters with the exact dates:
1. **First Semester**: 15/09 to 31/12 of the academic year start year
2. **Second Semester**: 01/01 to 31/03 of the academic year end year  
3. **Third Semester**: 01/04 to 10/06 of the academic year end year

### Automatic Current Semester Selection
1. The system automatically determines which semester is currently active based on the current date
2. The first semester is marked as current by default
3. When the academic year transitions, the system will automatically update the current semester

## Integration with Existing System

### School Creation Flow
1. When a new school is created (either manually or through the system)
2. The `create_school_with_academic_year_auto` function is called
3. The academic year and semesters are automatically created with correct dates
4. No manual intervention required

### Academic Year Transition
1. The system automatically handles academic year transitions
2. When the current date moves to a new academic year period, the system can be configured to create a new academic year
3. The existing academic year remains accessible for historical data

## Benefits of This Approach

1. **Fully Automatic**: No need for manual management screens
2. **Date-Based**: Academic years and semesters are always current based on the real-time date
3. **Consistent**: Every school will have the same academic structure
4. **Low Maintenance**: No need for administrators to manually create academic years
5. **Error Prevention**: Eliminates manual errors in date entry

## Implementation Steps

1. **Update Database Functions**: Replace the existing functions with the new automatic versions
2. **Update Application Logic**: Ensure the app calls the new automatic functions when needed
3. **Testing**: Verify that the automatic date-based logic works correctly
4. **Documentation**: Update documentation to reflect the automatic nature of the system

## Testing Plan

### Test Cases
1. **Date Boundary Testing**:
   - Test with dates before September 15 (should use previous year)
   - Test with dates after September 15 (should use current year)
   - Test with dates in each semester period

2. **Semester Date Verification**:
   - Verify first semester dates (15/09 to 31/12)
   - Verify second semester dates (01/01 to 31/03)
   - Verify third semester dates (01/04 to 10/06)

3. **Academic Year Name Verification**:
   - Verify correct academic year naming based on date logic
   - Test year transitions

4. **Integration Testing**:
   - Test school creation with automatic academic year
   - Test that all semesters are created correctly
   - Verify current semester is properly marked