import 'base_model.dart';

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
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[attendanceDate.month - 1]} ${attendanceDate.day.toString().padLeft(2, '0')}, ${attendanceDate.year}';
  }

  AttendanceRecord copyWith({
    String? studentId,
    String? subjectId,
    String? teacherId,
    DateTime? attendanceDate,
    bool? isPresent,
    String? notes,
    String? studentName,
    String? subjectName,
    String? teacherName,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      isPresent: isPresent ?? this.isPresent,
      notes: notes ?? this.notes,
      studentName: studentName ?? this.studentName,
      subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}