import 'base_model.dart';

class TeacherClassSubject extends BaseModel {
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int studentCount;

  TeacherClassSubject({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.studentCount = 0,
  });

  factory TeacherClassSubject.fromJson(Map<String, dynamic> json) {
    return TeacherClassSubject(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      classId: json['class_id'] as String,
      className: json['class_name'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      studentCount: json['student_count'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'class_name': className,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'student_count': studentCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TeacherClassSubject copyWith({
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    int? studentCount,
    DateTime? updatedAt,
  }) {
    return TeacherClassSubject(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      studentCount: studentCount ?? this.studentCount,
    );
  }
}