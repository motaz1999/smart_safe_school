import 'base_model.dart';

class AcademicYear extends BaseModel {
  final int schoolId;
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

  AcademicYear copyWith({
    int? schoolId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    DateTime? updatedAt,
  }) {
    return AcademicYear(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
    );
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

  Semester copyWith({
    String? academicYearId,
    String? name,
    int? semesterNumber,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    DateTime? updatedAt,
  }) {
    return Semester(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      academicYearId: academicYearId ?? this.academicYearId,
      name: name ?? this.name,
      semesterNumber: semesterNumber ?? this.semesterNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}