# Academic Year/Semester Selection Flow Testing Plan

## Overview
This document outlines the testing plan for the new academic year/semester selection flow for teacher grade entry.

## Test Scenarios

### 1. Academic Year Selection Screen
#### Test Case 1.1: Academic Years Load Successfully
- **Precondition**: Teacher is logged in and has academic years in their school
- **Action**: Navigate to AcademicYearSelectionScreen
- **Expected Result**: 
  - Academic years are displayed in a list
  - Each academic year shows name, dates, and current status
  - Loading indicator is shown while data is loading
- **Postcondition**: Teacher can select an academic year

#### Test Case 1.2: No Academic Years Available
- **Precondition**: Teacher is logged in but has no academic years in their school
- **Action**: Navigate to AcademicYearSelectionScreen
- **Expected Result**: 
  - Appropriate message is displayed indicating no academic years
  - Retry button is available
- **Postcondition**: Teacher can retry loading academic years

#### Test Case 1.3: Academic Year Selection
- **Precondition**: Academic years are displayed
- **Action**: Tap on an academic year
- **Expected Result**: 
  - Navigation to SemesterSelectionScreen
  - Selected academic year is passed to SemesterSelectionScreen
- **Postcondition**: Teacher is on SemesterSelectionScreen

#### Test Case 1.4: Network Error Handling
- **Precondition**: Network connection is unavailable
- **Action**: Navigate to AcademicYearSelectionScreen
- **Expected Result**: 
  - Error message is displayed
  - Retry button is available
- **Postcondition**: Teacher can retry loading academic years

### 2. Semester Selection Screen
#### Test Case 2.1: Semesters Load Successfully
- **Precondition**: Academic year is selected
- **Action**: Navigate to SemesterSelectionScreen
- **Expected Result**: 
  - Semesters for the selected academic year are displayed
  - Each semester shows name, number, dates, and current status
  - Loading indicator is shown while data is loading
- **Postcondition**: Teacher can select a semester

#### Test Case 2.2: No Semesters Available
- **Precondition**: Selected academic year has no semesters
- **Action**: Navigate to SemesterSelectionScreen
- **Expected Result**: 
  - Appropriate message is displayed indicating no semesters
  - Retry button is available
  - Back navigation is available
- **Postcondition**: Teacher can retry loading semesters or go back

#### Test Case 2.3: Semester Selection
- **Precondition**: Semesters are displayed
- **Action**: Tap on a semester
- **Expected Result**: 
  - Navigation to ClassesScreen
  - Selected academic year and semester are passed to ClassesScreen
- **Postcondition**: Teacher is on ClassesScreen

#### Test Case 2.4: Network Error Handling
- **Precondition**: Network connection is unavailable
- **Action**: Navigate to SemesterSelectionScreen
- **Expected Result**: 
  - Error message is displayed
  - Retry button is available
- **Postcondition**: Teacher can retry loading semesters

### 3. Classes Screen (Updated)
#### Test Case 3.1: Classes Load Successfully
- **Precondition**: Academic year and semester are selected
- **Action**: Navigate to ClassesScreen
- **Expected Result**: 
  - Classes/subjects for the teacher, filtered by academic year/semester, are displayed
  - Each class/subject shows name, code, and student count
  - Loading indicator is shown while data is loading
- **Postcondition**: Teacher can select a class/subject

#### Test Case 3.2: No Classes Available
- **Precondition**: Teacher has no classes for the selected academic year/semester
- **Action**: Navigate to ClassesScreen
- **Expected Result**: 
  - Appropriate message is displayed indicating no classes
  - Retry button is available
  - Back navigation is available
- **Postcondition**: Teacher can retry loading classes or go back

#### Test Case 3.3: Class/Subject Selection
- **Precondition**: Classes/subjects are displayed
- **Action**: Tap on a class/subject
- **Expected Result**: 
  - Navigation to TeacherGradesScreen
  - Selected academic year, semester, and class/subject are passed to TeacherGradesScreen
- **Postcondition**: Teacher is on TeacherGradesScreen

#### Test Case 3.4: Network Error Handling
- **Precondition**: Network connection is unavailable
- **Action**: Navigate to ClassesScreen
- **Expected Result**: 
  - Error message is displayed
  - Retry button is available
- **Postcondition**: Teacher can retry loading classes

### 4. Teacher Grades Screen (Updated)
#### Test Case 4.1: Grades Load Successfully
- **Precondition**: Academic year, semester, and class/subject are selected
- **Action**: Navigate to TeacherGradesScreen
- **Expected Result**: 
  - Students for the selected class are displayed
  - Existing grades for the selected academic year/semester are loaded
  - Academic year and semester are displayed in the UI
  - No semester selection dropdown is visible
- **Postcondition**: Teacher can enter grades

#### Test Case 4.2: No Students in Class
- **Precondition**: Selected class has no students
- **Action**: Navigate to TeacherGradesScreen
- **Expected Result**: 
  - Appropriate message is displayed indicating no students
  - Back navigation is available
- **Postcondition**: Teacher can go back to previous screen

#### Test Case 4.3: Grade Entry and Saving
- **Precondition**: Students and existing grades are loaded
- **Action**: 
  1. Enter grades for students
  2. Tap Save Grades button
- **Expected Result**: 
  - Grades are saved to the database with correct academic year/semester
  - Success message is displayed
  - Grades are updated in the UI
- **Postcondition**: Grades are saved in the database

#### Test Case 4.4: Invalid Grade Entry
- **Precondition**: Students are displayed
- **Action**: Enter invalid grade values (e.g., text, out of range numbers)
- **Expected Result**: 
  - Appropriate error message is displayed
  - Grades are not saved
- **Postcondition**: Teacher can correct grade values

#### Test Case 4.5: Network Error Handling
- **Precondition**: Network connection is unavailable
- **Action**: Try to save grades
- **Expected Result**: 
  - Error message is displayed
  - Grades are not saved
- **Postcondition**: Teacher can retry saving grades

### 5. Navigation Flow
#### Test Case 5.1: Complete Navigation Flow
- **Precondition**: Teacher is on TeacherDashboard
- **Action**: 
  1. Tap Grades quick action
  2. Select academic year
  3. Select semester
  4. Select class/subject
  5. Enter grades
  6. Save grades
  7. Navigate back through screens
- **Expected Result**: 
  - Each navigation step works correctly
  - Data is passed correctly between screens
  - Grades are saved with correct academic year/semester
- **Postcondition**: Teacher has successfully entered and saved grades

#### Test Case 5.2: Back Navigation
- **Precondition**: Teacher is on any screen in the flow
- **Action**: Use back button or back navigation
- **Expected Result**: 
  - Navigation goes back to previous screen
  - Data is preserved when appropriate
- **Postcondition**: Teacher is on the previous screen

### 6. Edge Cases
#### Test Case 6.1: Multiple Schools
- **Precondition**: Teacher belongs to multiple schools
- **Action**: Navigate through the flow
- **Expected Result**: 
  - Academic years, semesters, and classes are filtered by teacher's current school
- **Postcondition**: Correct data is displayed for the teacher's school

#### Test Case 6.2: Concurrent Access
- **Precondition**: Multiple teachers accessing the system
- **Action**: Navigate through the flow simultaneously
- **Expected Result**: 
  - Each teacher sees only their own data
  - No data leakage between teachers
- **Postcondition**: Data integrity is maintained

#### Test Case 6.3: Large Data Sets
- **Precondition**: Large number of academic years, semesters, or classes
- **Action**: Navigate through the flow
- **Expected Result**: 
  - All data is loaded and displayed correctly
  - Performance is acceptable
- **Postcondition**: System handles large data sets properly

## Test Data Requirements
- Multiple academic years with different date ranges
- Multiple semesters per academic year
- Classes with varying numbers of students
- Existing grades in the database
- Teachers with different access levels
- Schools with different configurations

## Test Environment
- Development environment with test database
- Staging environment with realistic data
- Mobile devices with different screen sizes
- Different network conditions (fast, slow, intermittent)

## Success Criteria
- All test cases pass
- No critical or high severity bugs
- Performance is acceptable
- User experience is smooth and intuitive
- Data integrity is maintained throughout the flow

## Test Tools
- Unit testing framework (Flutter test)
- Integration testing framework
- UI testing framework (Flutter driver or integration_test)
- Database testing tools
- Network simulation tools

## Test Schedule
1. Unit testing: 2 days
2. Integration testing: 3 days
3. UI testing: 2 days
4. Performance testing: 1 day
5. Bug fixing and retesting: 2 days

## Test Deliverables
- Test plan document (this document)
- Test cases and scripts
- Test execution reports
- Bug reports
- Test summary report