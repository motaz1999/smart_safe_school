# Attendance Service Design

## Overview
This document outlines the design for an attendance service that will handle all operations related to attendance records in the Smart Safe School system.

## Requirements
- Save attendance records to the database
- Load existing attendance records for a class and date
- Update attendance records
- Handle error cases and provide meaningful feedback
- Support batch operations for multiple students

## Service Interface

### Methods

#### saveAttendanceRecords
Saves a list of attendance records to the database.

```dart
Future<void> saveAttendanceRecords(List<AttendanceRecord> records)
```

#### loadAttendanceRecords
Loads attendance records for a specific class, subject, and date.

```dart
Future<List<AttendanceRecord>> loadAttendanceRecords({
  required String classId,
  required String subjectId,
  required DateTime date,
})
```

#### updateAttendanceRecord
Updates a single attendance record.

```dart
Future<void> updateAttendanceRecord(AttendanceRecord record)
```

#### deleteAttendanceRecord
Deletes an attendance record.

```dart
Future<void> deleteAttendanceRecord(String recordId)
```

#### doesAttendanceExist
Checks if attendance has already been marked for a class, subject, and date.

```dart
Future<bool> doesAttendanceExist({
  required String classId,
  required String subjectId,
  required DateTime date,
})
```

## Implementation Details

### Database Integration
The service will use Supabase to interact with the database:
- Table: `attendance`
- Fields: `id`, `student_id`, `subject_id`, `teacher_id`, `attendance_date`, `is_present`, `notes`, `created_at`, `updated_at`

### Error Handling
The service will handle common error cases:
- Network connectivity issues
- Database constraints violations
- Invalid data formats
- Authentication issues

### Caching Strategy
To improve performance, the service may implement:
- In-memory caching for recently accessed records
- Batch operations for multiple records

## Data Models

The service will work with the existing `AttendanceRecord` model:
- `studentId`: ID of the student
- `subjectId`: ID of the subject
- `teacherId`: ID of the teacher
- `attendanceDate`: Date of the attendance
- `isPresent`: Whether the student was present
- `notes`: Optional notes about the attendance

## Usage Examples

### Saving Attendance Records
```dart
final records = [
  AttendanceRecord(
    id: '',
    createdAt: DateTime.now(),
    studentId: 'student_1',
    subjectId: 'subject_1',
    teacherId: 'teacher_1',
    attendanceDate: DateTime.now(),
    isPresent: true,
    notes: null,
  ),
  // ... more records
];

await attendanceService.saveAttendanceRecords(records);
```

### Loading Attendance Records
```dart
final records = await attendanceService.loadAttendanceRecords(
  classId: 'class_1',
  subjectId: 'subject_1',
  date: DateTime.now(),
);
```

## Integration Points

### With Attendance Screen
- The attendance screen will use this service to save and load records
- Error messages from the service will be displayed to the user

### With Database
- All database operations will be handled through this service
- The service will ensure data consistency and integrity

## Testing Strategy

### Unit Tests
- Test each method with valid and invalid inputs
- Test error handling scenarios
- Test edge cases (empty lists, null values, etc.)

### Integration Tests
- Test database operations with a test database
- Test the complete flow from UI to database
- Test concurrent access scenarios

## Performance Considerations

### Batch Operations
- Use batch inserts/updates when possible to reduce database round trips
- Implement pagination for large datasets

### Connection Management
- Reuse database connections where possible
- Handle connection timeouts gracefully

## Security Considerations

### Authentication
- Ensure only authorized users can access the service
- Validate user permissions for each operation

### Data Validation
- Validate all input data before processing
- Sanitize user input to prevent injection attacks

## Future Enhancements

### Reporting Features
- Add methods to generate attendance reports
- Support filtering by date range, student, class, or subject

### Notification System
- Notify teachers when attendance hasn't been marked
- Send reports to parents/guardians