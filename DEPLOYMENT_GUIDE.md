# July-June Academic Year System - Deployment Guide

## Overview
This guide provides step-by-step instructions to deploy the automatic July-June academic year system to your Smart Safe School application.

## Pre-Deployment Checklist

### 1. Backup Your Database
**CRITICAL**: Always backup your database before making changes.

```sql
-- In Supabase Dashboard, go to Settings > Database
-- Click "Create backup" or use pg_dump if you have direct access
```

### 2. Verify Current System
Check your current academic year setup:

```sql
-- Check existing academic years
SELECT s.name as school_name, ay.name as academic_year, ay.start_date, ay.end_date
FROM schools s
LEFT JOIN academic_years ay ON s.id = ay.school_id
ORDER BY s.name;

-- Check existing semesters
SELECT s.name as school_name, ay.name as academic_year, sem.name as semester, sem.start_date, sem.end_date
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id
JOIN semesters sem ON ay.id = sem.academic_year_id
ORDER BY s.name, sem.semester_number;
```

## Deployment Steps

### Step 1: Deploy Database Functions

1. **Open Supabase SQL Editor**
   - Go to your Supabase project dashboard
   - Navigate to "SQL Editor"

2. **Execute the Implementation Script**
   - Copy the entire content from [`july_june_academic_year_implementation.sql`](july_june_academic_year_implementation.sql)
   - Paste it into the SQL Editor
   - Click "Run" to execute

3. **Verify Function Creation**
   ```sql
   -- Check if functions were created successfully
   SELECT routine_name, routine_type 
   FROM information_schema.routines 
   WHERE routine_name LIKE '%july_june%' 
   OR routine_name IN ('create_academic_year_july_june', 'auto_create_academic_year_july_june');
   ```

### Step 2: Test the System

1. **Test Academic Year Logic**
   ```sql
   -- Test with different dates to verify logic
   SELECT * FROM test_academic_year_creation_july_june('2024-08-15'::DATE);
   SELECT * FROM test_academic_year_creation_july_june('2024-01-15'::DATE);
   SELECT * FROM test_academic_year_creation_july_june('2024-06-30'::DATE);
   SELECT * FROM test_academic_year_creation_july_june('2024-07-01'::DATE);
   ```

2. **Test School Creation**
   ```sql
   -- Test creating a school with automatic academic year
   SELECT * FROM create_school_with_academic_year_july_june(
       'Test Deployment School',
       'Test Address',
       '1234567890',
       'test@deployment.com'
   );
   ```

3. **Verify Results**
   ```sql
   -- Check the test school was created correctly
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
   WHERE s.name = 'Test Deployment School'
   ORDER BY sem.semester_number;
   ```

### Step 3: Migrate Existing Schools

The migration script runs automatically when you execute the main SQL file. It will:
- Create July-June academic years for schools that don't have them
- Skip schools that already have academic years
- Log the process with NOTICE messages

**Monitor the migration:**
```sql
-- Check migration results
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
```

### Step 4: Verify Flutter App Compatibility

1. **Test Flutter Application**
   - Launch your Flutter app
   - Navigate to teacher dashboard
   - Check academic year and semester display
   - Test semester selection for grade entry

2. **Key Areas to Test:**
   - Academic year selection screen
   - Semester selection screen
   - Current academic period display on dashboard
   - Grade entry functionality
   - Attendance marking

### Step 5: Clean Up Test Data

```sql
-- Remove test school if desired
DELETE FROM schools WHERE name = 'Test Deployment School';
```

## Post-Deployment Verification

### 1. Data Integrity Checks

```sql
-- Verify all schools have academic years
SELECT COUNT(*) as schools_without_academic_years
FROM schools s
LEFT JOIN academic_years ay ON s.id = ay.school_id
WHERE ay.id IS NULL;
-- Should return 0

-- Verify all academic years have 3 semesters
SELECT 
    ay.name as academic_year,
    COUNT(s.id) as semester_count
FROM academic_years ay
LEFT JOIN semesters s ON ay.id = s.academic_year_id
GROUP BY ay.name
HAVING COUNT(s.id) != 3;
-- Should return no results

-- Verify semester date ranges
SELECT 
    ay.name as academic_year,
    s.name as semester,
    s.start_date,
    s.end_date,
    CASE 
        WHEN s.semester_number = 1 AND (
            EXTRACT(MONTH FROM s.start_date) != 8 OR 
            EXTRACT(DAY FROM s.start_date) != 15 OR
            EXTRACT(MONTH FROM s.end_date) != 12 OR 
            EXTRACT(DAY FROM s.end_date) != 31
        ) THEN 'SEMESTER_1_DATE_ERROR'
        WHEN s.semester_number = 2 AND (
            EXTRACT(MONTH FROM s.start_date) != 1 OR 
            EXTRACT(DAY FROM s.start_date) != 1 OR
            EXTRACT(MONTH FROM s.end_date) != 3 OR 
            EXTRACT(DAY FROM s.end_date) != 31
        ) THEN 'SEMESTER_2_DATE_ERROR'
        WHEN s.semester_number = 3 AND (
            EXTRACT(MONTH FROM s.start_date) != 4 OR 
            EXTRACT(DAY FROM s.start_date) != 1 OR
            EXTRACT(MONTH FROM s.end_date) != 6 OR 
            EXTRACT(DAY FROM s.end_date) != 15
        ) THEN 'SEMESTER_3_DATE_ERROR'
        ELSE 'OK'
    END as status
FROM academic_years ay
JOIN semesters s ON ay.id = s.academic_year_id
WHERE ay.is_current = TRUE;
-- All should show 'OK'
```

### 2. Current Semester Logic Check

```sql
-- Update current semesters for all schools based on current date
DO $$
DECLARE
    school_record RECORD;
BEGIN
    FOR school_record IN SELECT id FROM schools LOOP
        PERFORM update_current_semester_july_june(school_record.id);
    END LOOP;
END $$;

-- Verify current semester is correct for current date
SELECT 
    s.name as school_name,
    ay.name as academic_year,
    sem.name as current_semester,
    sem.start_date,
    sem.end_date,
    CURRENT_DATE as today,
    CASE 
        WHEN CURRENT_DATE >= sem.start_date AND CURRENT_DATE <= sem.end_date 
        THEN 'CORRECT' 
        ELSE 'CHECK_NEEDED' 
    END as status
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id AND ay.is_current = TRUE
JOIN semesters sem ON ay.id = sem.academic_year_id AND sem.is_current = TRUE;
```

## Troubleshooting

### Common Issues

1. **Functions Not Created**
   - Check for SQL syntax errors in the output
   - Ensure you have proper permissions in Supabase
   - Try running functions individually

2. **Migration Didn't Run**
   - Check the NOTICE messages in SQL output
   - Verify schools exist in the database
   - Run migration script manually if needed

3. **Flutter App Shows Errors**
   - Check if existing RPC function names changed
   - Verify data structure matches expected format
   - Test service methods individually

4. **Wrong Current Semester**
   - Run `update_current_semester_july_june(school_id)` for affected schools
   - Check date logic in the function
   - Verify current date is within expected ranges

### Rollback Procedure

If you need to rollback:

1. **Restore Database Backup**
   ```sql
   -- Use your backup to restore previous state
   ```

2. **Or Remove New Functions**
   ```sql
   DROP FUNCTION IF EXISTS create_academic_year_july_june(INTEGER);
   DROP FUNCTION IF EXISTS create_school_with_academic_year_july_june(TEXT, TEXT, TEXT, TEXT);
   DROP FUNCTION IF EXISTS auto_create_academic_year_july_june();
   DROP FUNCTION IF EXISTS update_current_semester_july_june(INTEGER);
   DROP FUNCTION IF EXISTS test_academic_year_creation_july_june(DATE);
   DROP TRIGGER IF EXISTS create_academic_year_july_june_on_school_insert ON schools;
   ```

## Success Criteria

Your deployment is successful when:

- ✅ All database functions are created without errors
- ✅ Test queries return expected results
- ✅ All existing schools have July-June academic years
- ✅ All academic years have exactly 3 semesters with correct dates
- ✅ Current semester is correctly identified based on current date
- ✅ Flutter app displays new academic structure correctly
- ✅ All existing functionality (grades, attendance) works normally
- ✅ New schools automatically get academic years when created

## Monitoring

After deployment, monitor:

1. **New School Creation**: Verify academic years are auto-created
2. **Semester Transitions**: Check current semester updates correctly
3. **Grade Entry**: Ensure teachers can enter grades for new semesters
4. **Reports**: Verify academic period filtering works correctly

## Support

If you encounter issues:

1. Check the verification queries above
2. Review the troubleshooting section
3. Test individual components (functions, triggers, Flutter services)
4. Verify data integrity with the provided checks

The system is designed to be backward compatible and should not disrupt existing functionality while providing the new July-June academic year structure you requested.