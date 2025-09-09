# Updated Flutter Models for Profile-Based Schema

## Updated Data Models

### Base Model (unchanged)
```dart
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BaseModel({
    required this.id,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson();
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### User Profile Model
```dart
enum UserType { admin, teacher, student }

class UserProfile extends BaseModel {
  final String schoolId;
  final UserType userType;
  final String name;
  final String userId; // admin_id, teacher_id, or student_id
  final String? phone;
  final String email; // from auth.users
  
  // Admin specific fields
  final Map<String, dynamic>? permissions;
  
  // Student specific fields
  final String? classId;
  final String? parentContact;
  
  // Additional fields for UI
  final String? schoolName;
  final String? className;

  UserProfile({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.schoolId,
    required this.userType,
    required this.name,
    required this.userId,
    required this.email,
    this.phone,
    this.permissions,
    this.classId,
    this.parentContact,
    this.schoolName,
    this.className,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      schoolId: json['school_id'],
      userType: UserType.values.firstWhere(
        (e) => e.name == json['user_type'],
      ),
      name: json['name'],
      userId: json['user_id'],
      email: json['email'] ?? '',
      phone: json['phone'],
      permissions: json['permissions'],
      classId: json['class_id'],
      parentContact: json['parent_contact'],
      schoolName: json['school_name'],
      className: json['class_name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'user_type': userType.name,
      'name': name,
      'user_id': userId,
      'phone': phone,
      'permissions': permissions,
      'class_id': classId,
      'parent_contact': parentContact,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isAdmin => userType == UserType.admin;
  bool get isTeacher => userType == UserType.teacher;
  bool get isStudent => userType == UserType.student;

  // Create specific user type instances
  static UserProfile createAdmin({
    required String id,
    required String schoolId,
    required String name,
    required String adminId,
    required String email,
    String? phone,
    Map<String, dynamic>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      schoolId: schoolId,
      userType: UserType.admin,
      name: name,
      userId: adminId,
      email: email,
      phone: phone,
      permissions: permissions ?? {},
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  static UserProfile createTeacher({
    required String id,
    required String schoolId,
    required String name,
    required String teacherId,
    required String email,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      schoolId: schoolId,
      userType: UserType.teacher,
      name: name,
      userId: teacherId,
      email: email,
      phone: phone,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  static UserProfile createStudent({
    required String id,
    required String schoolId,
    required String name,
    required String studentId,
    required String email,
    required String classId,
    required String parentContact,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      schoolId: schoolId,
      userType: UserType.student,
      name: name,
      userId: studentId,
      email: email,
      phone: phone,
      classId: classId,
      parentContact: parentContact,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  // Copy with method for updates
  UserProfile copyWith({
    String? schoolId,
    UserType? userType,
    String? name,
    String? userId,
    String? email,
    String? phone,
    Map<String, dynamic>? permissions,
    String? classId,
    String? parentContact,
    String? schoolName,
    String? className,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolId: schoolId ?? this.schoolId,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      permissions: permissions ?? this.permissions,
      classId: classId ?? this.classId,
      parentContact: parentContact ?? this.parentContact,
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
    );
  }
}
```

### School Model (unchanged)
```dart
class School extends BaseModel {
  final String name;
  final String? address;
  final String? phone;
  final String? email;

  School({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.name,
    this.address,
    this.phone,
    this.email,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

### Class Model
```dart
class SchoolClass extends BaseModel {
  final String schoolId;
  final String name;
  final String? gradeLevel;
  final int capacity;
  final int? currentEnrollment;

  SchoolClass({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.schoolId,
    required this.name,
    this.gradeLevel,
    this.capacity = 30,
    this.currentEnrollment,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      schoolId: json['school_id'],
      name: json['name'],
      gradeLevel: json['grade_level'],
      capacity: json['capacity'] ?? 30,
      currentEnrollment: json['current_enrollment'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'grade_level': gradeLevel,
      'capacity': capacity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isFull => currentEnrollment != null && currentEnrollment! >= capacity;
  int get availableSpots => capacity - (currentEnrollment ?? 0);
}
```

### Subject Model
```dart
class Subject extends BaseModel {
  final String schoolId;
  final String name;
  final String code;
  final String? description;
  final List<String>? teacherIds;
  final List<String>? teacherNames;

  Subject({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.schoolId,
    required this.name,
    required this.code,
    this.description,
    this.teacherIds,
    this.teacherNames,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      schoolId: json['school_id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      teacherIds: json['teacher_ids'] != null 
          ? List<String>.from(json['teacher_ids']) 
          : null,
      teacherNames: json['teacher_names'] != null 
          ? List<String>.from(json['teacher_names']) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'code': code,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

### Timetable Model
```dart
enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class TimetableEntry extends BaseModel {
  final String schoolId;
  final String classId;
  final String subjectId;
  final String teacherId;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  
  // Additional fields for UI
  final String? className;
  final String? subjectName;
  final String? subjectCode;
  final String? teacherName;

  TimetableEntry({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.className,
    this.subjectName,
    this.subjectCode,
    this.teacherName,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      schoolId: json['school_id'],
      classId: json['class_id'],
      subjectId: json['subject_id'],
      teacherId: json['teacher_id'],
      dayOfWeek: DayOfWeek.values.firstWhere(
        (e) => e.name == json['day_of_week'],
      ),
      startTime: _parseTime(json['start_time']),
      endTime: _parseTime(json['end_time']),
      className: json['class_name'],
      subjectName: json['subject_name'],
      subjectCode: json['subject_code'],
      teacherName: json['teacher_name'],
    );
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'class_id': classId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'day_of_week': dayOfWeek.name,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get timeRange => '${startTime.format(context)} - ${endTime.format(context)}';
  
  bool conflictsWith(TimetableEntry other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    
    final thisStart = startTime.hour * 60 + startTime.minute;
    final thisEnd = endTime.hour * 60 + endTime.minute;
    final otherStart = other.startTime.hour * 60 + other.startTime.minute;
    final otherEnd = other.endTime.hour * 60 + other.endTime.minute;
    
    return (thisStart < otherEnd && thisEnd > otherStart);
  }
}
```

### Attendance Model
```dart
class AttendanceRecord extends BaseModel {
  final String studentId;
  final String subjectId;
  final String teacherId;
  final DateTime attendanceDate;
  final bool isPresent;
  final String? notes;
  
  // Additional fields for UI
  final String? studentName;
  final String? subjectName;
  final String? teacherName;

  AttendanceRecord({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.attendanceDate,
    required this.isPresent,
    this.notes,
    this.studentName,
    this.subjectName,
    this.teacherName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      teacherId: json['teacher_id'],
      attendanceDate: DateTime.parse(json['attendance_date']),
      isPresent: json['is_present'],
      notes: json['notes'],
      studentName: json['student_name'],
      subjectName: json['subject_name'],
      teacherName: json['teacher_name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'is_present': isPresent,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get status => isPresent ? 'Present' : 'Absent';
  String get formattedDate => DateFormat('MMM dd, yyyy').format(attendanceDate);
}
```

### Grade Model
```dart
class Grade extends BaseModel {
  final String studentId;
  final String subjectId;
  final String teacherId;
  final String semesterId;
  final int gradeNumber; // 1 or 2
  final double gradeValue;
  final double maxGrade;
  final String? notes;
  
  // Additional fields for UI
  final String? studentName;
  final String? subjectName;
  final String? subjectCode;
  final String? teacherName;
  final String? semesterName;

  Grade({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.semesterId,
    required this.gradeNumber,
    required this.gradeValue,
    this.maxGrade = 100.0,
    this.notes,
    this.studentName,
    this.subjectName,
    this.subjectCode,
    this.teacherName,
    this.semesterName,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      teacherId: json['teacher_id'],
      semesterId: json['semester_id'],
      gradeNumber: json['grade_number'],
      gradeValue: (json['grade_value'] as num).toDouble(),
      maxGrade: (json['max_grade'] as num?)?.toDouble() ?? 100.0,
      notes: json['notes'],
      studentName: json['student_name'],
      subjectName: json['subject_name'],
      subjectCode: json['subject_code'],
      teacherName: json['teacher_name'],
      semesterName: json['semester_name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'semester_id': semesterId,
      'grade_number': gradeNumber,
      'grade_value': gradeValue,
      'max_grade': maxGrade,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get percentage => (gradeValue / maxGrade) * 100;
  String get formattedGrade => '${gradeValue.toStringAsFixed(1)}/${maxGrade.toStringAsFixed(0)}';
  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';
  
  String get letterGrade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }
}
```

### Academic Year and Semester Models
```dart
class AcademicYear extends BaseModel {
  final String schoolId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  AcademicYear({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.schoolId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      schoolId: json['school_id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isCurrent: json['is_current'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_current': isCurrent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Semester extends BaseModel {
  final String academicYearId;
  final String name;
  final int semesterNumber;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  Semester({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.academicYearId,
    required this.name,
    required this.semesterNumber,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      academicYearId: json['academic_year_id'],
      name: json['name'],
      semesterNumber: json['semester_number'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isCurrent: json['is_current'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academic_year_id': academicYearId,
      'name': name,
      'semester_number': semesterNumber,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_current': isCurrent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

## Key Changes from Previous Models

1. **Single UserProfile Model**: Replaces separate Admin, Teacher, Student models
2. **UserType Enum**: Type-safe way to handle different user types
3. **Conditional Fields**: Fields are nullable and only used when relevant to user type
4. **Factory Methods**: Easy creation of specific user types
5. **Helper Methods**: Convenient methods for checking user type and permissions
6. **Better Integration**: Works seamlessly with Supabase auth.users table

This approach is much cleaner and follows the updated database schema perfectly!