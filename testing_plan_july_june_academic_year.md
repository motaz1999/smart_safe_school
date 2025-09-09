# Testing Plan for July-June Academic Year System

## Overview
This document outlines comprehensive testing procedures for the new automatic July-June academic year system to ensure it works correctly across all scenarios.

## Test Categories

### 1. Database Function Testing

#### 1.1 Academic Year Creation Logic Testing

**Test Cases for Date-Based Academic Year Determination**:

```sql
-- Test Case 1: July 1st (Start of new academic year)
SELECT * FROM test_academic_year_creation_july_june('2024-07-01'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 1

-- Test Case 2: August 14th (Summer break, before Semester 1)
SELECT * FROM test_academic_year_creation_july_june('2024-08-14'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 1

-- Test Case 3: August 15th (Start of Semester 1)
SELECT * FROM test_academic_year_creation_july_june('2024-08-15'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 1

-- Test Case 4: December 31st (End of Semester 1)
SELECT * FROM test_academic_year_creation_july_june('2024-12-31'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 1

-- Test Case 5: January 1st (Start of Semester 2)
SELECT * FROM test_academic_year_creation_july_june('2025-01-01'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 2

-- Test Case 6: March 31st (End of Semester 2)
SELECT * FROM test_academic_year_creation_july_june('2025-03-31'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 2

-- Test Case 7: April 1st (Start of Semester 3)
SELECT * FROM test_academic_year_creation_july_june('2025-04-01'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 3

-- Test Case 8: June 15th (End of Semester 3)
SELECT * FROM test_academic_year_creation_july_june('2025-06-15'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 3

-- Test Case 9: June 30th (End of academic year)
SELECT * FROM test_academic_year_creation_july_june('2025-06-30'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 1 (upcoming)

-- Test Case 10: June 16th (Summer break)
SELECT * FROM test_academic_year_creation_july_june('2025-06-16'::DATE);
-- Expected: 2024-2025, July 1 2024 to June 30 2025, Semester 1 (upcoming)

-- Test Case 11: Before July 1st (Previous academic year)
SELECT * FROM test_academic_year_creation_july_june('2024-05-15'::DATE);
-- Expected: 2023-2024, July 1 2023 to June 30 2024, Semester 3
```

#### 1.2 School Creation with Academic Year Testing

```sql
-- Test automatic academic year creation when school is created
SELECT * FROM create_school_with_academic_year_july_june(
    'Test School Auto Creation',
    'Test Address',
    '1234567890',
    'test@autoschool.com'
);

-- Verify academic year and semesters were created
SELECT 
    s.name as school_name,
    ay.name as academic_year,
    ay.start_date,
    ay.end_date,
    sem.name as semester_name,
    sem.semester_number,
    sem.start_date as sem_start,
    sem.end_date as sem_end,
    sem.is_current
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id
JOIN semesters sem ON ay.id = sem.academic_year_id
WHERE s.name = 'Test School Auto Creation'
ORDER BY sem.semester_number;
```

#### 1.3 Current Semester Update Testing

```sql
-- Test current semester update function
SELECT update_current_semester_july_june(1);

-- Verify correct semester is marked as current
SELECT 
    s.name,
    s.semester_number,
    s.is_current,
    s.start_date,
    s.end_date
FROM semesters s
JOIN academic_years ay ON s.academic_year_id = ay.id
WHERE ay.school_id = 1 AND ay.is_current = TRUE
ORDER BY s.semester_number;
```

### 2. Edge Case Testing

#### 2.1 Leap Year Testing

```sql
-- Test leap year February 29th
SELECT * FROM test_academic_year_creation_july_june('2024-02-29'::DATE);
-- Expected: 2023-2024, Semester 2

-- Test non-leap year
SELECT * FROM test_academic_year_creation_july_june('2023-02-28'::DATE);
-- Expected: 2022-2023, Semester 2
```

#### 2.2 Year Boundary Testing

```sql
-- Test December 31st to January 1st transition
SELECT * FROM test_academic_year_creation_july_june('2024-12-31'::DATE);
SELECT * FROM test_academic_year_creation_july_june('2025-01-01'::DATE);

-- Test June 30th to July 1st transition (academic year change)
SELECT * FROM test_academic_year_creation_july_june('2024-06-30'::DATE);
SELECT * FROM test_academic_year_creation_july_june('2024-07-01'::DATE);
```

#### 2.3 Duplicate Prevention Testing

```sql
-- Test that duplicate academic years are not created
SELECT create_academic_year_july_june(1); -- First call
SELECT create_academic_year_july_june(1); -- Second call - should return existing

-- Verify only one academic year exists for current period
SELECT COUNT(*) as academic_year_count
FROM academic_years
WHERE school_id = 1 AND is_current = TRUE;
-- Expected: 1
```

### 3. Integration Testing

#### 3.1 Trigger Testing

```sql
-- Test that trigger creates academic year when school is inserted
INSERT INTO schools (name, address, phone, email)
VALUES ('Trigger Test School', 'Test Address', '9876543210', 'trigger@test.com');

-- Get the school ID
SELECT id FROM schools WHERE name = 'Trigger Test School';

-- Verify academic year was created automatically
SELECT 
    s.name as school_name,
    ay.name as academic_year,
    COUNT(sem.id) as semester_count
FROM schools s
LEFT JOIN academic_years ay ON s.id = ay.school_id
LEFT JOIN semesters sem ON ay.id = sem.academic_year_id
WHERE s.name = 'Trigger Test School'
GROUP BY s.name, ay.name;
-- Expected: 1 academic year with 3 semesters
```

#### 3.2 Multiple Schools Testing

```sql
-- Create multiple schools and verify each gets its own academic year
SELECT * FROM create_school_with_academic_year_july_june('School A', 'Address A', '111', 'a@test.com');
SELECT * FROM create_school_with_academic_year_july_june('School B', 'Address B', '222', 'b@test.com');
SELECT * FROM create_school_with_academic_year_july_june('School C', 'Address C', '333', 'c@test.com');

-- Verify each school has its own academic year
SELECT 
    s.name as school_name,
    ay.name as academic_year,
    ay.is_current,
    COUNT(sem.id) as semester_count
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id
JOIN semesters sem ON ay.id = sem.academic_year_id
WHERE s.name IN ('School A', 'School B', 'School C')
GROUP BY s.name, ay.name, ay.is_current
ORDER BY s.name;
-- Expected: Each school has 1 current academic year with 3 semesters
```

### 4. Performance Testing

#### 4.1 Bulk School Creation Testing

```sql
-- Test performance with multiple school creations
DO $$
DECLARE
    i INTEGER;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    
    FOR i IN 1..100 LOOP
        PERFORM create_school_with_academic_year_july_june(
            'Performance Test School ' || i,
            'Address ' || i,
            '555000' || LPAD(i::TEXT, 4, '0'),
            'perf' || i || '@test.com'
        );
    END LOOP;
    
    end_time := clock_timestamp();
    
    RAISE NOTICE 'Created 100 schools with academic years in % seconds', 
        EXTRACT(EPOCH FROM (end_time - start_time));
END $$;

-- Verify all schools were created correctly
SELECT COUNT(*) as total_schools,
       COUNT(DISTINCT ay.id) as total_academic_years,
       COUNT(sem.id) as total_semesters
FROM schools s
LEFT JOIN academic_years ay ON s.id = ay.school_id
LEFT JOIN semesters sem ON ay.id = sem.academic_year_id
WHERE s.name LIKE 'Performance Test School %';
-- Expected: 100 schools, 100 academic years, 300 semesters
```

### 5. Data Integrity Testing

#### 5.1 Referential Integrity Testing

```sql
-- Test that semesters are properly linked to academic years
SELECT 
    ay.name as academic_year,
    COUNT(s.id) as semester_count,
    MIN(s.semester_number) as min_semester,
    MAX(s.semester_number) as max_semester
FROM academic_years ay
LEFT JOIN semesters s ON ay.id = s.academic_year_id
GROUP BY ay.name
HAVING COUNT(s.id) != 3 OR MIN(s.semester_number) != 1 OR MAX(s.semester_number) != 3;
-- Expected: No results (all academic years should have exactly 3 semesters numbered 1, 2, 3)
```

#### 5.2 Date Consistency Testing

```sql
-- Test that semester dates are within academic year bounds
SELECT 
    ay.name as academic_year,
    ay.start_date as ay_start,
    ay.end_date as ay_end,
    s.name as semester,
    s.start_date as sem_start,
    s.end_date as sem_end,
    CASE 
        WHEN s.start_date < ay.start_date OR s.end_date > ay.end_date 
        THEN 'DATE_ERROR' 
        ELSE 'OK' 
    END as status
FROM academic_years ay
JOIN semesters s ON ay.id = s.academic_year_id
WHERE s.start_date < ay.start_date OR s.end_date > ay.end_date;
-- Expected: No results (all semester dates should be within academic year bounds)
```

#### 5.3 Current Flag Testing

```sql
-- Test that only one academic year is current per school
SELECT 
    school_id,
    COUNT(*) as current_academic_years
FROM academic_years
WHERE is_current = TRUE
GROUP BY school_id
HAVING COUNT(*) > 1;
-- Expected: No results (each school should have only one current academic year)

-- Test that only one semester is current per academic year
SELECT 
    ay.school_id,
    ay.name as academic_year,
    COUNT(*) as current_semesters
FROM academic_years ay
JOIN semesters s ON ay.id = s.academic_year_id
WHERE s.is_current = TRUE AND ay.is_current = TRUE
GROUP BY ay.school_id, ay.name
HAVING COUNT(*) > 1;
-- Expected: No results (each current academic year should have only one current semester)
```

### 6. Migration Testing

#### 6.1 Existing School Migration Testing

```sql
-- Create some test schools without academic years (simulating existing data)
INSERT INTO schools (name, address, phone, email) VALUES
('Existing School 1', 'Address 1', '111111', 'existing1@test.com'),
('Existing School 2', 'Address 2', '222222', 'existing2@test.com'),
('Existing School 3', 'Address 3', '333333', 'existing3@test.com');

-- Run migration script
DO $$
DECLARE
    school_record RECORD;
    new_year_id UUID;
    existing_count INTEGER;
BEGIN
    FOR school_record IN SELECT id, name FROM schools WHERE name LIKE 'Existing School %' LOOP
        SELECT COUNT(*) INTO existing_count
        FROM academic_years
        WHERE school_id = school_record.id;
        
        IF existing_count = 0 THEN
            SELECT create_academic_year_july_june(school_record.id) INTO new_year_id;
            RAISE NOTICE 'Created academic year % for school %', new_year_id, school_record.name;
        END IF;
    END LOOP;
END $$;

-- Verify migration results
SELECT 
    s.name as school_name,
    ay.name as academic_year,
    COUNT(sem.id) as semester_count
FROM schools s
LEFT JOIN academic_years ay ON s.id = ay.school_id
LEFT JOIN semesters sem ON ay.id = sem.academic_year_id
WHERE s.name LIKE 'Existing School %'
GROUP BY s.name, ay.name
ORDER BY s.name;
-- Expected: Each existing school should have 1 academic year with 3 semesters
```

### 7. Flutter Integration Testing

#### 7.1 Service Method Testing

**Test with Flutter Application**:

1. **Academic Year Retrieval**:
   - Call `TeacherService.getAcademicYears()`
   - Verify July-June academic years are returned
   - Check date formatting in UI

2. **Current Period Retrieval**:
   - Call `TeacherService.getCurrentAcademicPeriod()`
   - Verify correct current academic year and semester
   - Test with different current dates

3. **Semester Retrieval**:
   - Call `TeacherService.getSemesters()`
   - Verify new semester structure is returned
   - Check semester date ranges

#### 7.2 UI Component Testing

1. **Academic Year Selection Screen**:
   - Verify July-June academic years display correctly
   - Test academic year selection functionality

2. **Semester Selection Screen**:
   - Verify new semester dates display correctly
   - Test semester selection for grade entry

3. **Teacher Dashboard**:
   - Verify current academic period displays correctly
   - Test with different current dates

## Test Execution Checklist

### Pre-Deployment Testing
- [ ] Run all database function tests
- [ ] Execute edge case tests
- [ ] Perform integration tests
- [ ] Run performance tests
- [ ] Verify data integrity
- [ ] Test migration script

### Post-Deployment Testing
- [ ] Verify existing schools have academic years
- [ ] Test new school creation
- [ ] Verify Flutter app functionality
- [ ] Test grade entry with new semesters
- [ ] Verify attendance tracking works
- [ ] Test reporting functionality

### Rollback Testing
- [ ] Prepare rollback procedures
- [ ] Test rollback functionality
- [ ] Verify data restoration

## Expected Results Summary

### Database Level
- Academic years run from July 1 to June 30
- Three semesters with correct date ranges:
  - Semester 1: August 15 - December 31
  - Semester 2: January 1 - March 31
  - Semester 3: April 1 - June 15
- Automatic creation when schools are added
- Correct current semester based on date

### Application Level
- Flutter app displays new academic structure
- All existing functionality preserved
- Grade entry works with new semesters
- Attendance tracking functions correctly
- Reports show correct academic periods

### User Experience
- Seamless transition to new academic year structure
- No disruption to existing workflows
- Accurate academic period information
- Consistent behavior across all features

This comprehensive testing plan ensures the July-June academic year system works correctly across all scenarios and maintains data integrity while preserving existing functionality.