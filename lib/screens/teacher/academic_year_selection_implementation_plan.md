# Academic Year Selection Functionality Implementation Plan

## Overview
This document outlines the implementation plan for the new academic year/semester selection functionality for the teacher grade entry flow.

## New Screens to Create

### 1. AcademicYearSelectionScreen
A new screen that allows teachers to select an academic year.

#### Features:
- Display list of academic years for the teacher's school
- Show academic year name, dates, and current status
- Navigate to SemesterSelectionScreen when an academic year is selected

#### Implementation:
- Create lib/screens/teacher/academic_year_selection_screen.dart
- Use TeacherService.getAcademicYears() to load academic years
- Display academic years in a scrollable list
- Pass selected academic year to SemesterSelectionScreen

### 2. SemesterSelectionScreen
A new screen that allows teachers to select a semester for a given academic year.

#### Features:
- Display list of semesters for the selected academic year
- Show semester name, number, dates, and current status
- Navigate to updated ClassesScreen when a semester is selected

#### Implementation:
- Create lib/screens/teacher/semester_selection_screen.dart
- Use TeacherService.getSemesters() filtered by academic year
- Display semesters in a scrollable list
- Pass selected semester to ClassesScreen

### 3. Updated ClassesScreen
Modify the existing ClassesScreen to work with selected academic year/semester.

#### Features:
- Display classes/subjects filtered by selected academic year/semester
- Show class name, subject name, and student count
- Navigate to TeacherGradesScreen when a class/subject is selected

#### Implementation:
- Update lib/screens/teacher/classes_screen.dart
- Add academicYear and semester parameters
- Filter classes/subjects by academic year/semester
- Pass academicYear and semester to TeacherGradesScreen

## Updated TeacherGradesScreen
Modify the existing TeacherGradesScreen to work with the new flow.

#### Features:
- Receive academicYear and semester as parameters
- Do not show semester selection dropdown
- Load grades using academic year/semester

#### Implementation:
- Update lib/screens/teacher/grades_screen.dart
- Add academicYear and semester parameters
- Remove semester selection functionality
- Update data loading to use academic year/semester

## Service Updates

### TeacherService
Update TeacherService to support the new functionality.

#### Methods to Add/Update:
1. getAcademicYears() - Already exists
2. getSemesters() - Already exists but may need filtering
3. getTeacherClassesAndSubjects() - May need to add filtering by academic year/semester
4. getGrades() - Update to include academic year filtering

## Navigation Updates

### TeacherDashboard
Update the Grades quick action to navigate to AcademicYearSelectionScreen instead of showing the class selection sheet.

### Navigation Flow
1. TeacherDashboard -> AcademicYearSelectionScreen
2. AcademicYearSelectionScreen -> SemesterSelectionScreen
3. SemesterSelectionScreen -> ClassesScreen
4. ClassesScreen -> TeacherGradesScreen

## Implementation Steps

### Step 1: Create AcademicYearSelectionScreen
- Create the widget file
- Implement academic year loading and display
- Add navigation to SemesterSelectionScreen

### Step 2: Create SemesterSelectionScreen
- Create the widget file
- Implement semester loading and display
- Add navigation to ClassesScreen

### Step 3: Update ClassesScreen
- Add academicYear and semester parameters
- Update data loading to filter by academic year/semester
- Update navigation to TeacherGradesScreen

### Step 4: Update TeacherGradesScreen
- Add academicYear and semester parameters
- Remove semester selection UI
- Update data loading to use academic year/semester

### Step 5: Update TeacherService
- Update methods as needed for new functionality
- Ensure proper data filtering

### Step 6: Update TeacherDashboard
- Update Grades quick action navigation
- Remove class selection sheet

### Step 7: Testing
- Test the complete flow
- Verify data loading and saving works correctly
- Ensure proper error handling

## File Structure Changes
```
lib/
  screens/
    teacher/
      academic_year_selection_screen.dart  [NEW]
      semester_selection_screen.dart        [NEW]
      classes_screen.dart                   [UPDATED]
      grades_screen.dart                    [UPDATED]
      teacher_dashboard.dart                [UPDATED]
  services/
    teacher_service.dart                  [UPDATED]
```

## Dependencies
- AcademicYear model (already exists)
- Semester model (already exists)
- TeacherClassSubject model (already exists)
- TeacherService (already exists, needs updates)

## Error Handling
- Handle cases where no academic years exist
- Handle cases where no semesters exist for an academic year
- Handle cases where no classes exist for academic year/semester combination
- Show appropriate error messages to the user

## Performance Considerations
- Implement proper loading states
- Use caching where appropriate
- Handle network errors gracefully
- Optimize database queries