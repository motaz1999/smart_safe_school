import 'base_model.dart';

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
    this.maxGrade = 20.0,
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

  Grade copyWith({
    String? studentId,
    String? subjectId,
    String? teacherId,
    String? semesterId,
    int? gradeNumber,
    double? gradeValue,
    double? maxGrade,
    String? notes,
    String? studentName,
    String? subjectName,
    String? subjectCode,
    String? teacherName,
    String? semesterName,
    DateTime? updatedAt,
  }) {
    return Grade(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      semesterId: semesterId ?? this.semesterId,
      gradeNumber: gradeNumber ?? this.gradeNumber,
      gradeValue: gradeValue ?? this.gradeValue,
      maxGrade: maxGrade ?? this.maxGrade,
      notes: notes ?? this.notes,
      studentName: studentName ?? this.studentName,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      teacherName: teacherName ?? this.teacherName,
      semesterName: semesterName ?? this.semesterName,
    );
  }
}