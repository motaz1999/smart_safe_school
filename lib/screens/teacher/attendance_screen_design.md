# Attendance Screen Design

## Overview
This document outlines the design for the attendance marking screen that teachers will use to mark attendance for their classes.

## Requirements
- Teachers should be able to mark attendance for students in a specific class and subject
- The screen should display a list of students with checkboxes for present/absent status
- Teachers should be able to add notes for absent students
- The screen should show class and subject information
- Attendance records should be saved to the database

## UI Components

### AppBar
- Title: "Mark Attendance"
- Back button to return to the previous screen

### Header Section
- Class name and subject name
- Date of the attendance (default to current date)
- Time slot information

### Student List
- List of students with:
  - Student name
  - Student ID
  - Checkbox for present/absent
  - Notes field for absent students

### Action Buttons
- Save button to save attendance records
- Cancel button to discard changes

## Data Flow

1. Teacher navigates from timetable screen to attendance screen
2. Screen loads class and subject information from timetable entry
3. Screen fetches list of students in the class
4. Teacher marks attendance for each student
5. Teacher saves attendance records to database

## Implementation Plan

### 1. Create Attendance Screen Widget
- Create a new StatefulWidget for the attendance screen
- Accept parameters for class ID, subject ID, and timetable entry

### 2. Load Student Data
- Fetch students enrolled in the specified class
- Display student information in a list

### 3. Attendance Marking UI
- Implement checkboxes for present/absent status
- Add notes field for absent students
- Provide visual feedback for saved changes

### 4. Save Functionality
- Create function to save attendance records to database
- Handle error cases and provide user feedback

## Integration Points

### From Timetable Screen
- Pass class ID, subject ID, and teacher ID when navigating to attendance screen

### Database Integration
- Save attendance records using the AttendanceRecord model
- Update existing records if attendance is already marked for the date

## Code Structure

```dart
class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String subjectId;
  final String teacherId;
  final String className;
  final String subjectName;
  
  const AttendanceScreen({
    Key? key,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.className,
    required this.subjectName,
  }) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Implementation details
}