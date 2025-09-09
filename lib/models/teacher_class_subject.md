# TeacherClassSubject Model Design

## Overview
This document defines the TeacherClassSubject model which represents the relationship between a teacher, class, and subject.

## Purpose
The TeacherClassSubject model is used to:
1. Represent class/subject combinations that a teacher is assigned to
2. Provide necessary information for displaying in the UI
3. Enable navigation to grade entry and attendance screens

## Data Structure
```dart
class TeacherClassSubject {
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int studentCount;
  
  TeacherClassSubject({
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.studentCount = 0,
  });
}
```

## Fields Description

### classId
- Type: String
- Required: Yes
- Description: The unique identifier for the class

### className
- Type: String
- Required: Yes
- Description: The name of the class (e.g., "Grade 10A")

### subjectId
- Type: String
- Required: Yes
- Description: The unique identifier for the subject

### subjectName
- Type: String
- Required: Yes
- Description: The name of the subject (e.g., "Mathematics")

### subjectCode
- Type: String
- Required: Yes
- Description: The code of the subject (e.g., "MATH")

### studentCount
- Type: int
- Required: No (default: 0)
- Description: The number of students in the class

## Factory Methods

### fromJson
A factory method to create a TeacherClassSubject instance from a JSON map:
```dart
factory TeacherClassSubject.fromJson(Map<String, dynamic> json) {
  return TeacherClassSubject(
    classId: json['class_id'] as String,
    className: json['class_name'] as String,
    subjectId: json['subject_id'] as String,
    subjectName: json['subject_name'] as String,
    subjectCode: json['subject_code'] as String,
    studentCount: json['student_count'] as int? ?? 0,
  );
}
```

## Usage Examples

### Creating an Instance
```dart
final teacherClassSubject = TeacherClassSubject(
  classId: 'class-123',
  className: 'Grade 10A',
  subjectId: 'subject-456',
  subjectName: 'Mathematics',
  subjectCode: 'MATH',
  studentCount: 25,
);
```

### Using in a List
```dart
final List<TeacherClassSubject> teacherClasses = [
  TeacherClassSubject(
    classId: 'class-123',
    className: 'Grade 10A',
    subjectId: 'subject-456',
    subjectName: 'Mathematics',
    subjectCode: 'MATH',
    studentCount: 25,
  ),
  TeacherClassSubject(
    classId: 'class-789',
    className: 'Grade 9B',
    subjectId: 'subject-012',
    subjectName: 'Science',
    subjectCode: 'SCI',
    studentCount: 22,
  ),
];