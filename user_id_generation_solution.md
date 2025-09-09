# User ID Generation Solution

## Problem
The current user ID generation functions cause conflicts when multiple schools try to create users with the same ID. For example:
- School A creates admin with ID ADM00001
- School B tries to create admin and also gets ADM00001 (conflict!)

## Solution
Modify the ID format to include the school ID to ensure uniqueness across all schools:
- Admins: ADM-001-00001 (where 001 is the school ID, 00001 is the sequential number)
- Teachers: TEA-001-00001
- Students: STU-001-00001

## Updated Functions

### 1. Admin ID Generation Function
```sql
-- Function to generate the next admin ID in format ADM-001-00001
CREATE OR REPLACE FUNCTION generate_next_admin_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for admins in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'admin' 
    AND user_id LIKE 'ADM-' || school_id_formatted || '-%';
    
    -- Format as ADM-001-00001, ADM-001-00002, etc.
    formatted_id := 'ADM-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

### 2. Teacher ID Generation Function
```sql
-- Function to generate the next teacher ID in format TEA-001-00001
CREATE OR REPLACE FUNCTION generate_next_teacher_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for teachers in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'teacher' 
    AND user_id LIKE 'TEA-' || school_id_formatted || '-%';
    
    -- Format as TEA-001-00001, TEA-001-00002, etc.
    formatted_id := 'TEA-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

### 3. Student ID Generation Function
```sql
-- Function to generate the next student ID in format STU-001-00001
CREATE OR REPLACE FUNCTION generate_next_student_id(p_school_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_id INTEGER;
    formatted_id TEXT;
    school_id_formatted TEXT;
BEGIN
    -- Format school ID as 3-digit number
    school_id_formatted := LPAD(p_school_id::TEXT, 3, '0');
    
    -- Get the next sequential number for students in this school
    SELECT COALESCE(MAX(SUBSTRING(user_id FROM 9 FOR 5)::INTEGER), 0) + 1 INTO next_id
    FROM profiles 
    WHERE school_id = p_school_id 
    AND user_type = 'student' 
    AND user_id LIKE 'STU-' || school_id_formatted || '-%';
    
    -- Format as STU-001-00001, STU-001-00002, etc.
    formatted_id := 'STU-' || school_id_formatted || '-' || LPAD(next_id::TEXT, 5, '0');
    
    RETURN formatted_id;
END;
$$;
```

## Implementation Notes
1. The functions format the school ID as a 3-digit number (001, 002, etc.)
2. The sequential number is formatted as a 5-digit number (00001, 00002, etc.)
3. The functions extract the sequential number from existing IDs using the new format
4. The functions ensure uniqueness by including the school ID in the LIKE pattern

## Migration Considerations
1. Existing user IDs in the old format (ADM00001) will need to be updated
2. Any code that parses user IDs will need to be updated to handle the new format
3. Database constraints should be checked to ensure they still work with the new format