# School ID Interval Solution

## Overview
This document describes a new approach to user ID generation where each school gets a specific interval of IDs:
- Students: 500 IDs per school
- Teachers: 50 IDs per school
- Admins: 10 IDs per school

## ID Allocation Strategy

### Students
- School 1: STU00001-STU00500
- School 2: STU00501-STU01000
- School 3: STU01001-STU01500
- Formula: STU + ((school_id - 1) * 500 + 1) to (school_id * 500)

### Teachers
- School 1: TEA00001-TEA00050
- School 2: TEA00051-TEA00100
- School 3: TEA00101-TEA00150
- Formula: TEA + ((school_id - 1) * 50 + 1) to (school_id * 50)

### Admins
- School 1: ADM00001-ADM00010
- School 2: ADM00011-ADM00020
- School 3: ADM00021-ADM00030
- Formula: ADM + ((school_id - 1) * 10 + 1) to (school_id * 10)

## Updated Functions

### 1. Admin ID Generation Function
```sql
-- Function to generate the next admin ID based on school interval (10 IDs per school)
CREATE OR REPLACE FUNCTION generate_next_admin_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    start_id INTEGER;
    end_id INTEGER;
    formatted_id TEXT;
BEGIN
    -- Calculate the start and end ID range for this school
    start_id := (p_school_id - 1) * 10 + 1;
    end_id := p_school_id * 10;
    
    -- Get the next available ID within this school's range
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 4)::INTEGER), start_id - 1) + 1 INTO next_id
    FROM profiles 
    WHERE user_type = 'admin' 
    AND SUBSTRING(user_id FROM 4)::INTEGER BETWEEN start_id AND end_id;
    
    -- Check if we've exceeded the school's allocation
    IF next_id > end_id THEN
        RAISE EXCEPTION 'School % has exceeded its admin ID allocation (max %)', p_school_id, end_id;
    END IF;
    
    -- Format as ADM00001, ADM00002, etc.
    formatted_id := 'ADM' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

### 2. Teacher ID Generation Function
```sql
-- Function to generate the next teacher ID based on school interval (50 IDs per school)
CREATE OR REPLACE FUNCTION generate_next_teacher_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    start_id INTEGER;
    end_id INTEGER;
    formatted_id TEXT;
BEGIN
    -- Calculate the start and end ID range for this school
    start_id := (p_school_id - 1) * 50 + 1;
    end_id := p_school_id * 50;
    
    -- Get the next available ID within this school's range
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 4)::INTEGER), start_id - 1) + 1 INTO next_id
    FROM profiles 
    WHERE user_type = 'teacher' 
    AND SUBSTRING(user_id FROM 4)::INTEGER BETWEEN start_id AND end_id;
    
    -- Check if we've exceeded the school's allocation
    IF next_id > end_id THEN
        RAISE EXCEPTION 'School % has exceeded its teacher ID allocation (max %)', p_school_id, end_id;
    END IF;
    
    -- Format as TEA00001, TEA00002, etc.
    formatted_id := 'TEA' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

### 3. Student ID Generation Function
```sql
-- Function to generate the next student ID based on school interval (500 IDs per school)
CREATE OR REPLACE FUNCTION generate_next_student_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    start_id INTEGER;
    end_id INTEGER;
    formatted_id TEXT;
BEGIN
    -- Calculate the start and end ID range for this school
    start_id := (p_school_id - 1) * 500 + 1;
    end_id := p_school_id * 500;
    
    -- Get the next available ID within this school's range
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 4)::INTEGER), start_id - 1) + 1 INTO next_id
    FROM profiles 
    WHERE user_type = 'student' 
    AND SUBSTRING(user_id FROM 4)::INTEGER BETWEEN start_id AND end_id;
    
    -- Check if we've exceeded the school's allocation
    IF next_id > end_id THEN
        RAISE EXCEPTION 'School % has exceeded its student ID allocation (max %)', p_school_id, end_id;
    END IF;
    
    -- Format as STU00001, STU00002, etc.
    formatted_id := 'STU' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

## Migration Considerations

### 1. Migration Strategy
- Existing users need to be reassigned to their school's ID range
- Users outside their school's range need to be handled appropriately
- Sequential numbering within each school's range must be maintained

### 2. Migration Process
1. Backup the database before migration
2. For each school and user type:
   - Identify users within the correct range (no change needed)
   - Identify users outside the correct range (need reassignment)
   - Reassign IDs to fit within the school's allocated range
3. Verify all IDs are within correct ranges
4. Test the new ID generation functions

## Limitations and Considerations

### 1. Hard Limits
- Each school has a hard limit on the number of users:
  - Admins: 10 per school
  - Teachers: 50 per school
  - Students: 500 per school

### 2. Scaling Issues
- This approach may not scale well for larger schools
- Schools with more than the allocated number of users will hit limits

### 3. Alternative Approach
- Consider a hybrid approach that combines school ID in the user ID with intervals for better scalability