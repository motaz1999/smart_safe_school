# Default Subjects Functionality Test Plan

This document outlines how to test the default subjects functionality that has been implemented.

## Test Scenarios

### 1. New School with No Subjects
**Expected Behavior**: When an admin first logs into a school that has no subjects, the system should automatically create the default subjects.

**Test Steps**:
1. Create a new school in the Supabase dashboard
2. Create an admin user for that school
3. Log in to the Flutter app as the admin
4. Navigate to the "Manage Subjects" screen
5. Verify that the default subjects are displayed:
   - Mathematics
   - English Language
   - Science
   - Social Studies
   - Geography
   - Art
   - Physical Education
   - Computer Science

### 2. School with Existing Subjects
**Expected Behavior**: When an admin logs into a school that already has subjects, the system should not create any new subjects.

**Test Steps**:
1. Ensure a school has existing subjects
2. Log in to the Flutter app as the admin
3. Navigate to the "Manage Subjects" screen
4. Verify that only the existing subjects are displayed
5. Verify that no new default subjects are created

### 3. Manual Initialization of Default Subjects
**Expected Behavior**: If for some reason the automatic initialization fails, there should be a way to manually trigger it.

**Note**: The current implementation automatically initializes default subjects, but in a future enhancement, we could add a manual button.

## Expected Default Subjects

The following subjects should be created automatically for new schools:

1. **Mathematics**
   - Code: MATH
   - Description: Mathematics curriculum covering algebra, geometry, and calculus

2. **English Language**
   - Code: ENG
   - Description: English language and literature curriculum

3. **Science**
   - Code: SCI
   - Description: General science curriculum covering physics, chemistry, and biology

4. **Social Studies**
   - Code: SST
   - Description: Social studies and history curriculum

5. **Geography**
   - Code: GEO
   - Description: Geography and environmental studies

6. **Art**
   - Code: ART
   - Description: Visual arts and creative expression

7. **Physical Education**
   - Code: PE
   - Description: Physical fitness and sports education

8. **Computer Science**
   - Code: CS
   - Description: Introduction to computing and programming

## Error Handling

If there are any errors during the default subjects creation process:
- The error should be displayed to the user
- The user should still be able to manually create subjects
- The system should not repeatedly try to create default subjects if they already exist

## Testing Tools

To verify the subjects in the database:
1. Use the Supabase dashboard to check the `subjects` table
2. Verify that subjects are created with the correct school_id
3. Verify that each subject has the correct name, code, and description

## Troubleshooting

If default subjects are not being created:
1. Check that the `initializeDefaultSubjectsIfNeeded()` method is being called
2. Verify that the `hasSubjects()` method is returning the correct value
3. Check the Supabase logs for any database errors
4. Ensure the admin user has the correct permissions to create subjects