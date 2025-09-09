# Automatic Academic Year Implementation - July to June System

## Overview
This document outlines the complete implementation plan for auto-generated academic years running from July 1st to June 30th with three specific semesters, replacing the current September-June system.

## Requirements Summary
- **Academic Year Period**: July 1st to June 30th of next year (01-07 to 30-06)
- **Auto-generation**: Based on current date, no manual management needed
- **Semester Structure**:
  - Semester 1: August 15 to December 31 (15-08 to 31-12)
  - Semester 2: January 1 to March 31 (01-01 to 31-03)  
  - Semester 3: April 1 to June 15 (01-04 to 15-06)
- **Unique IDs**: Keep current UUID system (already unique across schools)
- **Maintain Functionality**: Keep existing semester form and selection screens

## Current System Analysis

### Existing Implementation
1. **Database Functions**: 
   - `create_academic_year()` - Creates academic year with September-June dates
   - `create_school_with_academic_year_auto()` - Auto-creates with September dates
   - `get_current_semester()` - Gets current semester

2. **Flutter Models**: 
   - `AcademicYear` class with schoolId, name, startDate, endDate, isCurrent
   - `Semester` class with academicYearId, name, semesterNumber, startDate, endDate, isCurrent

3. **Flutter Services**:
   - `TeacherService.getCurrentAcademicPeriod()` - Gets current academic year/semester
   - `TeacherService.getSemesters()` - Gets all semesters
   - Grade management tied to semesters

### Changes Required
1. **Database Functions**: Update date logic from September-June to July-June
2. **Semester Dates**: Change from (15-09 to 31-12, 01-01 to 31-03, 01-04 to 10-06) to (15-08 to 31-12, 01-01 to 31-03, 01-04 to 15-06)
3. **Auto-generation Logic**: Update current date detection for July-June academic year
4. **Flutter Models**: No changes needed (compatible with new dates)
5. **Flutter Services**: No changes needed (will work with updated database functions)

## New Auto-Generation Logic Design

### Academic Year Determination
```
Current Date Logic:
- If current date >= July 1st: Academic Year = Current Year to Next Year
- If current date < July 1st: Academic Year = Previous Year to Current Year

Examples:
- Current date: August 15, 2024 → Academic Year: 2024-2025 (July 1, 2024 to June 30, 2025)
- Current date: May 20, 2024 → Academic Year: 2023-2024 (July 1, 2023 to June 30, 2024)
- Current date: June 30, 2024 → Academic Year: 2023-2024 (July 1, 2023 to June 30, 2024)
- Current date: July 1, 2024 → Academic Year: 2024-2025 (July 1, 2024 to June 30, 2025)
```

### Current Semester Detection
```
Date Range Logic:
- August 15 to December 31: Semester 1 is current
- January 1 to March 31: Semester 2 is current
- April 1 to June 15: Semester 3 is current
- June 16 to August 14: Summer break (Semester 1 upcoming)
```

### Semester Creation Logic
For each academic year, create three semesters:
1. **Semester 1**: August 15 of academic year start to December 31 of same year
2. **Semester 2**: January 1 of academic year end to March 31 of same year
3. **Semester 3**: April 1 of academic year end to June 15 of same year

## Database Implementation Plan

### 1. Updated Academic Year Creation Function
```sql
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
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW())::INTEGER;
    
    -- Determine academic year based on current date
    IF EXTRACT(MONTH FROM NOW()) >= 7 THEN
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
    
    IF EXTRACT(MONTH FROM NOW()) >= 8 AND EXTRACT(MONTH FROM NOW()) <= 12 THEN
        -- August 15 to December 31: Semester 1
        IF EXTRACT(MONTH FROM NOW()) = 8 AND EXTRACT(DAY FROM NOW()) >= 15 THEN
            current_semester_number := 1;
        ELSIF EXTRACT(MONTH FROM NOW()) > 8 THEN
            current_semester_number := 1;
        END IF;
    ELSIF EXTRACT(MONTH FROM NOW()) >= 1 AND EXTRACT(MONTH FROM NOW()) <= 3 THEN
        -- January 1 to March 31: Semester 2
        current_semester_number := 2;
    ELSIF EXTRACT(MONTH FROM NOW()) >= 4 AND EXTRACT(MONTH FROM NOW()) <= 6 THEN
        -- April 1 to June 15: Semester 3
        IF EXTRACT(MONTH FROM NOW()) < 6 OR (EXTRACT(MONTH FROM NOW()) = 6 AND EXTRACT(DAY FROM NOW()) <= 15) THEN
            current_semester_number := 3;
        END IF;
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
```

### 2. School Creation with Auto Academic Year
```sql
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
```

### 3. Trigger for Automatic Creation
```sql
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

-- Create trigger
DROP TRIGGER IF EXISTS create_academic_year_july_june_on_school_insert ON schools;
CREATE TRIGGER create_academic_year_july_june_on_school_insert
    AFTER INSERT ON schools
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_academic_year_july_june();
```

## Integration with Existing System

### Flutter Application Changes
1. **Models**: No changes needed - existing `AcademicYear` and `Semester` models are compatible
2. **Services**: No changes needed - existing services will work with updated database functions
3. **UI Screens**: No changes needed - existing semester selection screens will work with new data

### Backward Compatibility
- Existing semester selection functionality remains intact
- Grade management continues to work with semester-based structure
- Teacher dashboard displays auto-generated academic periods
- All existing UI components continue to function

## Benefits

1. **Fully Automatic**: No manual academic year management required
2. **Date-Driven**: Always current based on real-time date
3. **School-Specific**: Each school gets its own academic year automatically
4. **Consistent**: All schools follow the same July-June structure
5. **Maintains Functionality**: All existing features continue to work
6. **Low Maintenance**: Automatic transitions between academic years and semesters

## Testing Strategy

### Test Cases
1. **Date Boundary Testing**:
   - Test with dates before July 1st (should use previous year)
   - Test with dates after July 1st (should use current year)
   - Test semester detection for each date range

2. **Academic Year Creation**:
   - Verify correct academic year naming (YYYY-YYYY format)
   - Verify correct start/end dates (July 1 to June 30)
   - Verify only one academic year is marked as current per school

3. **Semester Creation**:
   - Verify Semester 1: August 15 to December 31
   - Verify Semester 2: January 1 to March 31
   - Verify Semester 3: April 1 to June 15
   - Verify correct current semester based on date

4. **Integration Testing**:
   - Test school creation triggers academic year creation
   - Test existing Flutter screens work with new data
   - Test grade management with new semester structure

## Migration Plan

### For Existing Schools
1. **Backup Current Data**: Preserve existing academic years and semesters
2. **Run Migration Script**: Create new July-June academic years for existing schools
3. **Update Current Flags**: Set appropriate current academic year/semester
4. **Verify Data Integrity**: Ensure all relationships are maintained

### Migration Script
```sql
-- Migration script to create July-June academic years for existing schools
DO $$
DECLARE
    school_record RECORD;
    new_year_id UUID;
BEGIN
    FOR school_record IN SELECT id FROM schools LOOP
        -- Create July-June academic year for each existing school
        SELECT create_academic_year_july_june(school_record.id) INTO new_year_id;
        
        RAISE NOTICE 'Created academic year % for school %', new_year_id, school_record.id;
    END LOOP;
END $$;
```

## Implementation Timeline

1. **Phase 1**: Update database functions and triggers
2. **Phase 2**: Test auto-generation logic with various dates
3. **Phase 3**: Run migration for existing schools
4. **Phase 4**: Verify Flutter application works with new system
5. **Phase 5**: Deploy and monitor

This implementation maintains all existing functionality while providing the requested automatic academic year management with July-June periods and the specified semester dates.