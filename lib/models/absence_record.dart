import 'base_model.dart';

class AbsenceRecord extends BaseModel {
  final String studentId;
  final String studentName;
  final String studentNumber;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final DateTime absenceDate;
  final String? notes;
  final String? reason;

  AbsenceRecord({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.absenceDate,
    this.notes,
    this.reason,
  });

  factory AbsenceRecord.fromJson(Map<String, dynamic> json) {
    return AbsenceRecord(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      studentNumber: json['student_number'] ?? '',
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? '',
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      teacherName: json['teacher_name'] ?? '',
      absenceDate: json['absence_date'] != null
          ? DateTime.parse(json['absence_date'])
          : DateTime.now(),
      notes: json['notes'],
      reason: json['reason'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'student_id': studentId,
      'student_name': studentName,
      'student_number': studentNumber,
      'class_id': classId,
      'class_name': className,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'absence_date': absenceDate.toIso8601String().split('T')[0],
      'notes': notes,
      'reason': reason,
    };
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[absenceDate.month - 1]} ${absenceDate.day.toString().padLeft(2, '0')}, ${absenceDate.year}';
  }

  String get displayReason {
    if (reason != null && reason!.isNotEmpty) {
      return reason!;
    }
    if (notes != null && notes!.isNotEmpty) {
      return notes!;
    }
    return 'No reason provided';
  }

  AbsenceRecord copyWith({
    String? studentId,
    String? studentName,
    String? studentNumber,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    DateTime? absenceDate,
    String? notes,
    String? reason,
    DateTime? updatedAt,
  }) {
    return AbsenceRecord(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      absenceDate: absenceDate ?? this.absenceDate,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbsenceRecord &&
        other.id == id &&
        other.studentId == studentId &&
        other.subjectId == subjectId &&
        other.absenceDate == absenceDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        studentId.hashCode ^
        subjectId.hashCode ^
        absenceDate.hashCode;
  }

  @override
  String toString() {
    return 'AbsenceRecord{id: $id, studentName: $studentName, className: $className, subjectName: $subjectName, absenceDate: $absenceDate}';
  }
}