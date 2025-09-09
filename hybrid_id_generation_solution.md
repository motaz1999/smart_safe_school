# Hybrid ID Generation Solution

## Overview
This document describes a hybrid approach to user ID generation that combines the benefits of both solutions:
1. Include the school ID in the user ID format for guaranteed uniqueness
2. Use intervals within each school for better organization
3. Provide better scalability than the pure interval approach

## ID Format
- Students: STU-001-00001 (School ID + Interval-based sequential number)
- Teachers: TEA-001-00001 (School ID + Interval-based sequential number)
- Admins: ADM-001-00001 (School ID + Interval-based sequential number)

## ID Allocation Strategy

### Students (500 IDs per school)
- School 1: STU-001-00001 to STU-001-00500
- School 2: STU-002-00001 to STU-002-00500
- School 3: STU-003-00001 to STU-003-00500

### Teachers (50 IDs per school)
- School 1: TEA-001-00001 to TEA-001-00050
- School 2: TEA-002-00001 to TEA-002-00050
- School 3: TEA-003-00001 to TEA-003-00050

### Admins (10 IDs per school)
- School 1: ADM-001-00001 to ADM-001-00010
- School 2: ADM-002-00001 to ADM-002-00010
- School 3: ADM-003-00001 to ADM-003-00010

## Updated Functions

### 1. Admin ID Generation Function
```sql
-- Function to generate the next admin ID with hybrid approach
CREATE OR REPLACE FUNCTION generate_next_admin_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    school_id_formatted TEXT;
    formatted_id TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for admins in this school (max 10)
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'admin' 
    AND user_id LIKE 'ADM-' || school_id_formatted || '-%';
    
    -- Check if we've exceeded the school's allocation
    IF next_id > 10 THEN
        RAISE EXCEPTION 'School % has exceeded its admin ID allocation (max 10)', p_school_id;
    END IF;
    
    -- Format as ADM-001-00001, ADM-001-00002, etc.
    formatted_id := 'ADM-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

### 2. Teacher ID Generation Function
```sql
-- Function to generate the next teacher ID with hybrid approach
CREATE OR REPLACE FUNCTION generate_next_teacher_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    school_id_formatted TEXT;
    formatted_id TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for teachers in this school (max 50)
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'teacher' 
    AND user_id LIKE 'TEA-' || school_id_formatted || '-%';
    
    -- Check if we've exceeded the school's allocation
    IF next_id > 50 THEN
        RAISE EXCEPTION 'School % has exceeded its teacher ID allocation (max 50)', p_school_id;
    END IF;
    
    -- Format as TEA-001-00001, TEA-001-00002, etc.
    formatted_id := 'TEA-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

### 3. Student ID Generation Function
```sql
-- Function to generate the next student ID with hybrid approach
CREATE OR REPLACE FUNCTION generate_next_student_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    school_id_formatted TEXT;
    formatted_id TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for students in this school (max 500)
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'student' 
    AND user_id LIKE 'STU-' || school_id_formatted || '-%';
    
    -- Check if we've exceeded the school's allocation
    IF next_id > 500 THEN
        RAISE EXCEPTION 'School % has exceeded its student ID allocation (max 500)', p_school_id;
    END IF;
    
    -- Format as STU-001-00001, STU-001-00002, etc.
    formatted_id := 'STU-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

## Benefits of Hybrid Approach

### 1. Guaranteed Uniqueness
- Including the school ID ensures uniqueness across all schools
- No conflicts even if schools have the same sequential numbers

### 2. Better Organization
- Clear identification of which school a user belongs to
- Sequential numbering within each school for easier management

### 3. Scalability with Limits
- Schools get dedicated ranges (10 admins, 50 teachers, 500 students)
- Hard limits prevent uncontrolled growth while providing adequate capacity

### 4. Easy Migration
- Existing users can be migrated to the new format
- Clear mapping between old and new ID formats

## Migration Strategy

### 1. Migration Process
1. Backup the database before migration
2. For each school and user type:
   - Identify existing users
   - Assign new IDs within the school's allocated range
   - Update user records with new IDs
3. Verify all IDs are correctly formatted
4. Test the new ID generation functions

### 2. Migration Script Example
```sql
-- Example migration for admins
CREATE OR REPLACE FUNCTION migrate_admin_ids_hybrid()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    admin_record RECORD;
    new_user_id TEXT;
    school_id_formatted TEXT;
    sequential_number INTEGER;
BEGIN
    -- Process each admin user grouped by school
    FOR admin_record IN 
        SELECT id, user_id, school_id,
               ROW_NUMBER() OVER (PARTITION BY school_id ORDER BY created_at) as seq_num
        FROM profiles 
        WHERE user_type = 'admin'
    LOOP
        -- Format school ID as 3-digit number
        school_id_formatted := LPAD(admin_record.school_id::TEXT, 3, '0');
        
        -- Get sequential number (ensure it doesn't exceed limit)
        sequential_number := LEAST(admin_record.seq_num, 10);
        
        -- Create new ID format
        new_user_id := 'ADM-' || school_id_formatted || '-' || 
                      LPAD(sequential_number::TEXT, 5, '0');
        
        -- Update the user ID
        UPDATE profiles 
        SET user_id = new_user_id 
        WHERE id = admin_record.id;
        
        RAISE NOTICE 'Updated admin % from % to %', admin_record.id, admin_record.user_id, new_user_id;
    END LOOP;
END;
$$;
```

## Implementation Steps

### 1. Deploy Updated Functions
- Replace existing ID generation functions with the new hybrid versions
- Test functions with sample data

### 2. Run Migration
- Execute migration scripts to update existing user IDs
- Verify all IDs are correctly formatted

### 3. Update Application Code
- Modify any code that parses or validates user IDs
- Update UI components that display user IDs

### 4. Testing
- Test new user creation with the hybrid ID format
- Verify existing functionality still works
- Test edge cases and error conditions

## Limitations and Considerations

### 1. Hard Limits
- Schools are limited to:
  - 10 admins
  - 50 teachers
  - 500 students
- These limits may need adjustment based on actual usage

### 2. Migration Complexity
- Existing users need to be reassigned to fit within limits
- Users exceeding limits need special handling

### 3. Future Scalability
- Consider making limits configurable if needed
- Monitor usage to determine if limits are adequate