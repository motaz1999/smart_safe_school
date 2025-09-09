# Teacher "My Class" Section Design Document

## Overview
This document outlines the design for the "My Class" section in the teacher dashboard, which will display the classes and subjects that a teacher is enrolled in, and provide functionality to add grades.

## UI Structure

### Main Dashboard Integration
The "My Class" section will be integrated into the existing teacher dashboard as a new quick action card and a dedicated screen.

### Quick Action Card
In the teacher dashboard's quick actions section, we'll add a new card:
- Title: "My Classes"
- Icon: Icons.class_
- Color: Colors.green
- Navigation: To the dedicated "My Classes" screen

### Dedicated "My Classes" Screen
A new screen that will display:
1. A list of classes and subjects the teacher is enrolled in
2. For each class/subject combination:
   - Class name
   - Subject name and code
   - Number of students in the class
   - Action buttons:
     * "Take Attendance" (existing functionality)
     * "Enter Grades" (new functionality)

### Class Details Modal
When a teacher taps on a class/subject item, a modal will show:
1. Class name and subject details
2. Student count
3. Action buttons:
   - "Take Attendance"
   - "Enter Grades"

### Grade Entry Screen
A new screen for entering grades with the following features:
1. Class and subject selection (pre-filled based on navigation)
2. Semester selection
3. Grade number selection (1 or 2)
4. Student list with grade input fields
5. Save functionality
6. Load existing grades if they exist

## Data Flow

### Loading Teacher's Classes and Subjects
1. On screen load, call TeacherService.getTeacherClassesAndSubjects()
2. Display the results in a list format
3. For each item, show class name, subject name, and subject code

### Loading Students for Grade Entry
1. When entering grades, call TeacherService.getStudentsInClass(classId, subjectId)
2. Display students in a list with input fields for grades

### Loading Existing Grades
1. When entering grades, call TeacherService.getGrades(classId, subjectId, semesterId, gradeNumber)
2. Pre-fill grade input fields with existing values

### Saving Grades
1. Collect all grade values from input fields
2. Create Grade objects for each student
3. Call TeacherService.saveGrades(grades)
4. Show success/error message

## UI Components

### TeacherClassSubjectCard
A reusable card component to display:
- Class name
- Subject name and code
- Student count (optional)
- Action buttons

### GradeEntryForm
A form component for entering grades:
- Student list with grade inputs
- Semester selector
- Grade number selector
- Save button

## Navigation Flow
1. Teacher Dashboard → Quick Actions → "My Classes" → My Classes Screen
2. My Classes Screen → Tap on class/subject → Class Details Modal
3. Class Details Modal → "Enter Grades" → Grade Entry Screen
4. Grade Entry Screen → Fill grades → Save → Back to My Classes Screen

## State Management
The screen will manage the following state:
- isLoading: bool (for showing loading indicators)
- error: String? (for showing error messages)
- teacherClassesAndSubjects: List<TeacherClassSubject> (the main data)
- selectedClassSubject: TeacherClassSubject? (for grade entry)
- students: List<UserProfile> (for grade entry)
- grades: List<Grade> (for grade entry)
- selectedSemesterId: String (for grade entry)
- selectedGradeNumber: int (1 or 2, for grade entry)

## Error Handling
- Show error messages in SnackBars
- Provide retry functionality for failed operations
- Handle empty states (no classes assigned to teacher)

## Responsive Design
- Use GridView for class/subject cards on larger screens
- Use ListView for smaller screens
- Ensure proper spacing and padding for all screen sizes