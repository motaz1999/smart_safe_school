# Updated Teacher Grades Screen Design

## Overview
This document describes the changes needed to update the TeacherGradesScreen to work with the new academic year/semester selection flow.

## Current Implementation
The current TeacherGradesScreen:
1. Receives a TeacherClassSubject object as a parameter
2. Automatically loads semesters and students when initialized
3. Allows teacher to select semester and grade number on the screen
4. Loads existing grades based on selected semester

## New Implementation Requirements
The updated TeacherGradesScreen should:
1. Receive selected academic year and semester as parameters
2. Not automatically load semesters (they're already selected)
3. Load students and existing grades for the selected academic year/semester
4. Allow teacher to enter grades for students
5. Save grades with the selected academic year/semester

## Parameter Changes
Current constructor:
```dart
TeacherGradesScreen({super.key, required this.classSubject});
```

New constructor:
```dart
TeacherGradesScreen({
  super.key, 
  required this.classSubject,
  required this.academicYear,
  required this.semester,
});
```

## Data Loading Changes
Current data loading:
1. Load semesters
2. Load students in class
3. Load existing grades for selected semester

New data loading:
1. Load students in class (same as before)
2. Load existing grades for the selected academic year/semester combination

## Service Method Updates
Need to update TeacherService.getGrades method to filter by academic year as well as semester:

Current method:
```dart
Future<List<Grade>> getGrades(String classId, String subjectId, String semesterId, int gradeNumber)
```

Updated method:
```dart
Future<List<Grade>> getGrades(
  String classId, 
  String subjectId, 
  String academicYearId,
  String semesterId, 
  int gradeNumber)
```

## UI Changes
1. Remove semester selection dropdown since it's now selected in the previous screen
2. Display selected academic year and semester in the header or info section
3. Keep grade number selection as is

## Implementation Plan

### Step 1: Update TeacherGradesScreen parameters
- Add academicYear and semester parameters
- Remove automatic semester loading
- Update UI to show selected academic year/semester

### Step 2: Update TeacherService.getGrades method
- Add academicYearId parameter
- Update database query to filter by academic year

### Step 3: Update data loading in TeacherGradesScreen
- Load students as before
- Load grades using new method with academic year filter

### Step 4: Update UI elements
- Remove semester selection dropdown
- Add display of selected academic year/semester
- Keep grade number selection

## Database Considerations
The current grades table likely doesn't have a direct reference to academic_year_id. We may need to:
1. Join through semester to get academic year
2. Or add academic_year_id to the grades table for easier querying

## Code Changes Summary

### TeacherGradesScreen
- New parameters: academicYear, semester
- Remove _semesters, _selectedSemester, _loadSemestersAndStudentsAndGrades
- Update _loadStudentsAndGrades to use selected academic year/semester
- Update UI to remove semester dropdown and show selected academic year/semester

### TeacherService
- Update getGrades method to include academicYearId parameter
- Update database query in getGrades

### Navigation
- Update navigation calls to pass academicYear and semester parameters