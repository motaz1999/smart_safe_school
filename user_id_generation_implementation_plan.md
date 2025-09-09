# User ID Generation Implementation Plan

## Overview
This document describes the implementation plan for resolving user ID conflicts by making IDs distinct by school. The solution involves modifying the ID generation functions to include the school ID in the user ID format.

## Current Problem
The current user ID generation functions cause conflicts when multiple schools try to create users with the same ID:
- School A creates admin with ID ADM00001
- School B tries to create admin and also gets ADM00001 (conflict!)

## Solution
Modify the ID format to include the school ID to ensure uniqueness across all schools:
- Admins: ADM-001-00001 (where 001 is the school ID, 00001 is the sequential number)
- Teachers: TEA-001-00001
- Students: STU-001-00001

## Implementation Steps

### 1. Update Database Functions

#### 1.1 Admin ID Generation Function
Update the `generate_next_admin_id` function to generate IDs in the format ADM-001-00001:
- Format school ID as 3-digit number (001, 002, etc.)
- Extract sequential number from existing IDs using the new format
- Generate new IDs with school prefix

#### 1.2 Teacher ID Generation Function
Update the `generate_next_teacher_id` function to generate IDs in the format TEA-001-00001:
- Format school ID as 3-digit number (001, 002, etc.)
- Extract sequential number from existing IDs using the new format
- Generate new IDs with school prefix

#### 1.3 Student ID Generation Function
Update the `generate_next_student_id` function to generate IDs in the format STU-001-00001:
- Format school ID as 3-digit number (001, 002, etc.)
- Extract sequential number from existing IDs using the new format
- Generate new IDs with school prefix

### 2. Data Migration

#### 2.1 Migration Script
Create a migration script to update existing user IDs to the new format:
- For each school, get all users ordered by creation date
- Update each user with a new ID in the format TYPE-SCHOOLID-SEQUENTIAL
- Preserve the sequential nature of IDs based on creation order

#### 2.2 Migration Process
1. Backup the database before migration
2. Run the migration script for each user type (admin, teacher, student)
3. Verify that all IDs have been updated correctly
4. Test the new ID generation functions with sample data

### 3. Application Code Updates

#### 3.1 ID Parsing Functions
Update any application code that parses user IDs to handle the new format:
- Extract user type from the prefix (ADM, TEA, STU)
- Extract school ID from the middle segment
- Extract sequential number from the suffix

#### 3.2 Validation Functions
Update validation functions to accept the new ID format:
- Modify regex patterns for ID validation
- Update any UI components that display or input user IDs

#### 3.3 User Creation Workflows
Update user creation workflows to use the new ID generation functions:
- Ensure the application calls the updated functions when creating new users
- Verify that the returned IDs are in the correct format

### 4. Testing Procedures

#### 4.1 Function Testing
Test each ID generation function:
- Verify that IDs are generated in the correct format
- Verify that sequential numbers are correctly incremented
- Verify that different schools get different sequential numbers

#### 4.2 Conflict Testing
Test that conflicts are resolved:
- Create users in different schools with the same sequential number
- Verify that all generated IDs are unique
- Verify that the UNIQUE constraint on the user_id field is maintained

#### 4.3 Edge Case Testing
Test edge cases:
- Create users in a school with no existing users
- Create many users in the same school to test sequential numbering
- Test with school IDs that have different numbers of digits

## Deployment Order
1. Create backup of database
2. Deploy updated ID generation functions
3. Run data migration script
4. Update application code
5. Test thoroughly
6. Deploy to production

## Rollback Plan
If issues occur during deployment:
1. Restore database from backup
2. Revert to old ID generation functions
3. Update application code to use old ID format
4. Verify system functionality

## Related Functions to Check
1. `create_user_profile` - Ensure it works with new ID format
2. `get_users_by_type` - Verify it returns correct user IDs
3. Any application code that parses or validates user IDs