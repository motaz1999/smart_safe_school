# Academic Year/Semester Selection Screen Design

## Overview
This document describes the design for a new screen that allows teachers to select an academic year and semester before entering grades for their classes.

## Current Flow
1. Teacher navigates to Grades screen
2. Grades screen automatically loads semesters and students
3. Teacher selects semester and grade number directly on the grades screen

## New Flow
1. Teacher selects academic year and semester first
2. Teacher then selects a subject/class combination
3. Teacher enters grades for students in that class

## Screen Components

### Academic Year Selection
- Display list of academic years for the teacher's school
- Each academic year shows:
  - Name (e.g., "2023-2024")
  - Start and end dates
  - Current status indicator

### Semester Selection
- After selecting an academic year, display semesters for that year
- Each semester shows:
  - Name (e.g., "Semester 1", "Term 2")
  - Semester number
  - Start and end dates
  - Current status indicator

### Subject/Class Selection
- After selecting a semester, display subjects/classes that the teacher teaches
- Each subject/class shows:
  - Class name
  - Subject name and code
  - Number of students in the class

## User Interface Design

### Academic Year Selection Screen
```
-------------------------------------
| Academic Year Selection          |
-------------------------------------
| Select an academic year:         |
|                                  |
| [2023-2024]     [Current]        |
| Start: 2023-09-01                |
| End: 2024-06-30                  |
|                                  |
| [2022-2023]                      |
| Start: 2022-09-01                |
| End: 2023-06-30                  |
|                                  |
| [2021-2022]                      |
| Start: 2021-09-01                |
| End: 2022-06-30                  |
-------------------------------------
```

### Semester Selection Screen
```
-------------------------------------
| Semester Selection               |
-------------------------------------
| Academic Year: 2023-2024         |
| Select a semester:               |
|                                  |
| [Semester 1]    [Current]        |
| Number: 1                        |
| Start: 2023-09-01                |
| End: 2024-01-15                  |
|                                  |
| [Semester 2]                     |
| Number: 2                        |
| Start: 2024-01-16                |
| End: 2024-06-30                  |
-------------------------------------
```

### Subject/Class Selection Screen
```
-------------------------------------
| Subject Selection                |
-------------------------------------
| Academic Year: 2023-2024         |
| Semester: Semester 1             |
| Select a subject/class:          |
|                                  |
| [Class 10A - Mathematics]        |
| Code: MATH101                    |
| Students: 25                     |
|                                  |
| [Class 10B - Mathematics]        |
| Code: MATH101                    |
| Students: 24                     |
|                                  |
| [Class 9A - Physics]             |
| Code: PHYS901                    |
| Students: 26                     |
-------------------------------------
```

## Navigation Flow
1. Teacher Dashboard -> Grades (button) -> Academic Year Selection
2. Academic Year Selection -> Semester Selection
3. Semester Selection -> Subject/Class Selection
4. Subject/Class Selection -> Grade Entry Screen

## Implementation Plan
1. Create new AcademicYearSelectionScreen widget
2. Create new SemesterSelectionScreen widget
3. Modify existing ClassesScreen to work with selected academic year/semester
4. Update TeacherGradesScreen to receive academic year/semester as parameters
5. Update navigation flow in TeacherDashboard

## Data Models Needed
- AcademicYear (already exists)
- Semester (already exists)
- TeacherClassSubject (already exists)

## Services Needed
- TeacherService.getAcademicYears() (already exists)
- TeacherService.getSemesters() (already exists)
- TeacherService.getTeacherClassesAndSubjects() (already exists)
- New method to get classes/subjects filtered by academic year and semester