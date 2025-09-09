# User ID Generation Update Implementation Guide

## Overview
This guide explains how to implement the updated user ID generation functions that make IDs distinct by school. The new format is:
- Admins: ADM-001-00001 (where 001 is the school ID, 00001 is the sequential number)
- Teachers: TEA-001-00001
- Students: STU-001-00001

## Files Included
1. `updated_user_id_functions.sql` - Updated database functions for ID generation
2. `user_id_migration_script.sql` - Script to migrate existing IDs to new format
3. `user_id_generation_update_summary.md` - Summary of changes and implementation steps

## Implementation Steps

### Step 1: Deploy Updated Functions
1. Open your Supabase project
2. Go to the SQL Editor
3. Run the `updated_user_id_functions.sql` file
4. This will update the existing functions with the new ID generation logic

### Step 2: Test New User Creation
1. Create new users (admin, teacher, student) through the application
2. Verify that they receive IDs in the new format:
   - Admins: ADM-001-00001
   - Teachers: TEA-001-00001
   - Students: STU-001-00001

### Step 3: Migrate Existing Data (Optional)
If you have existing users with the old ID format:
1. Backup your database
2. Run `user_id_migration_script.sql` in your Supabase SQL Editor
3. Execute `SELECT migrate_all_user_ids();` to run the migration

## Benefits of the New Format
1. **School Isolation**: User IDs are now unique across all schools
2. **Scalability**: Supports unlimited schools without ID conflicts
3. **Traceability**: School ID is embedded in the user ID for easy identification
4. **Sequential Numbering**: Each school maintains its own sequential numbering

## Testing Considerations
1. Verify that all existing application functionality still works with the new ID format
2. Test user creation for all user types
3. Test user search and filtering by ID
4. Verify that all database relationships still work correctly

## Rollback Plan
If issues occur:
1. Restore database from backup (if migration was performed)
2. Revert to old ID generation functions
3. Update any application code that was changed to work with new IDs
4. Verify system functionality