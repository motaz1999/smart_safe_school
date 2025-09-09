# Database Fix Summary

## Issue
The attendance feature was failing with the error:
"Exception: Failed to load attendance records. PostgresException: message: Could not embed because more than one relationship was found for attendance_records and profiles. code: P0002701. detail: (cardinality: many-to-one, embedding: attendance_records with profiles, relationship: attendance_records.student_id->key using attendance_records(student_id) and profiles(id)), (cardinality: many-to-one, embedding: attendance_records with profiles, relationship: attendance_records.teacher_id->key using attendance_records(teacher_id) and profiles(id)). Hint: Try changing profiles to one of the following: profiles(attendance_records.student_id->key), profiles(attendance_records.teacher_id->key) Find the desired relationship in the details key"

## Root Cause
The database table `attendance_records` has two foreign keys to the `profiles` table:
1. `student_id` referencing `profiles.id`
2. `teacher_id` referencing `profiles.id`

When trying to join with `profiles`, the database doesn't know which foreign key to use.

## Fix Applied
Updated `lib/services/attendance_service.dart` to explicitly specify which foreign key to use when joining with the `profiles` table:

1. Updated the `loadAttendanceRecords` method to use explicit foreign key reference:
   ```dart
   .select('''
     *,
     student:profiles!attendance_records_student_id_fkey(name)
   ''')
   ```

This tells the database to specifically use the `student_id` foreign key when joining with the `profiles` table.

## Additional Issue - Missing updated_at Column
After fixing the relationship issue, another error occurred:
"Exception Failed to save attendance records. PostgresException: message: Could not find the updated_at column of attendance_records in the schema cache. code: P0003204. detail: null (hint: null)"

## Additional Root Cause
The `attendance_records` table in the database schema does not have an `updated_at` column, but the AttendanceRecord model's `toJson()` method was including it in the data sent to the database.

## Additional Fix Applied
Updated `lib/services/attendance_service.dart` to remove the `updated_at` field from the JSON data before sending it to the database:

1. Updated the `saveAttendanceRecords` method to exclude `updated_at`:
   ```dart
   final recordsJson = records.map((record) {
     final json = record.toJson();
     json.remove('updated_at'); // Remove updated_at as it's not in the table schema
     return json;
   }).toList();
   ```

2. Updated the `updateAttendanceRecord` method to exclude `updated_at`:
   ```dart
   // Convert record to JSON and remove updated_at field
   final json = record.toJson();
   json.remove('updated_at'); // Remove updated_at as it's not in the table schema
   ```

## Additional Issue - Invalid UUID Syntax
After fixing the updated_at column issue, another error occurred:
"Exception Failed to save attendance records. PostgresException: message: invalid input syntax for type uuid: "" code: 22P02. details: . Hint: null"

## Additional Root Cause
The AttendanceRecord model's `id` field was being set to an empty string `''` when creating new records. The database expected a valid UUID but received an empty string.

## Additional Fix Applied
Updated `lib/services/attendance_service.dart` to remove the `id` field when it's an empty string:
   ```dart
   final recordsJson = records.map((record) {
     final json = record.toJson();
     json.remove('updated_at'); // Remove updated_at as it's not in the table schema
     // Remove id if it's empty since the database will generate it
     if (json['id'] == '') {
       json.remove('id');
     }
     return json;
   }).toList();
   ```

The same fix was applied to the `updateAttendanceRecord` method.

## Additional Issue - UI-only Fields
After fixing the UUID issue, there was still an error with the upsert operation. This was caused by including UI-only fields (`student_name`, `subject_name`, `teacher_name`) in the database operations.

## Additional Fix Applied
Updated `lib/services/attendance_service.dart` to remove UI-only fields that don't exist in the database:
   ```dart
   final recordsJson = records.map((record) {
     final json = record.toJson();
     // Remove fields that don't exist in the attendance_records table
     json.remove('updated_at'); // Remove updated_at as it's not in the table schema
     // Remove id if it's empty since the database will generate it
     if (json['id'] == '') {
       json.remove('id');
     }
     // Remove UI-only fields that don't exist in the database
     json.remove('student_name');
     json.remove('subject_name');
     json.remove('teacher_name');
     return json;
   }).toList();
   ```

The same fix was applied to the `updateAttendanceRecord` method.

## Verification
The fix addresses the exact error message by explicitly specifying which relationship to use when joining the `attendance_records` table with the `profiles` table, by removing the `updated_at` field that doesn't exist in the database schema, by properly handling the `id` field for new records, and by removing UI-only fields that don't exist in the database. All database operations in the attendance service now properly handle the relationships and column constraints.