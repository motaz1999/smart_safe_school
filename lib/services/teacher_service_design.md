# Teacher Service Design Document

## Overview
This document outlines the design for a TeacherService that will handle teacher-specific functionality in the Smart Safe School application, including:
1. Fetching classes and subjects that a teacher is enrolled in
2. Managing grades for students
3. Other teacher-specific operations

## Service Structure
The TeacherService will follow the same pattern as other services in the application:
- Use Supabase client for database operations
- Include error handling with custom exceptions
- Follow async/await pattern for database operations
- Use the existing models (Grade, SchoolClass, Subject, etc.)

## Key Methods

### 1. Get Teacher's Classes and Subjects
```dart
Future<List<TeacherClassSubject>> getTeacherClassesAndSubjects() async
```
This method will fetch all classes and subjects that the currently logged-in teacher is assigned to through the timetable system.

### 2. Get Students in Class for Subject
```dart
Future<List<UserProfile>> getStudentsInClass(String classId, String subjectId) async
```
This method will fetch all students enrolled in a specific class for a specific subject.

### 3. Save Grades
```dart
Future<void> saveGrades(List<Grade> grades) async
```
This method will save or update grades for students.

### 4. Get Existing Grades
```dart
Future<List<Grade>> getGrades(String classId, String subjectId, String semesterId, int gradeNumber) async
```
This method will fetch existing grades for a specific class, subject, semester, and grade number.

## Data Models

### TeacherClassSubject
A model to represent the relationship between a teacher, class, and subject:
- classId: String
- className: String
- subjectId: String
- subjectName: String
- subjectCode: String

## Database Queries

### Get Teacher's Classes and Subjects
The service will query the timetable table to find all class/subject combinations assigned to the teacher:
```sql
SELECT DISTINCT 
    t.class_id,
    c.name as class_name,
    t.subject_id,
    s.name as subject_name,
    s.code as subject_code
FROM timetables t
JOIN classes c ON t.class_id = c.id
JOIN subjects s ON t.subject_id = s.id
WHERE t.teacher_id = [current_teacher_id]
```

### Get Students in Class for Subject
```sql
SELECT * FROM profiles 
WHERE class_id = [class_id] 
AND user_type = 'student'
```

### Save Grades
Use Supabase upsert operation to insert or update grades:
```dart
await _supabase.from('grades').upsert(gradesJson, onConflict: 'student_id,subject_id,semester_id,grade_number')
```

## Error Handling
The service will use a custom TeacherException class for error handling, similar to AdminException in AdminService.

## Dependencies
- Supabase client
- UserProfile model
- SchoolClass model
- Subject model
- Grade model
- SupabaseConfig