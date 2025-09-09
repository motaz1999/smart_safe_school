import 'base_model.dart';

class SchoolClass extends BaseModel {
  final int schoolId;
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

  SchoolClass copyWith({
    int? schoolId,
    String? name,
    String? gradeLevel,
    int? capacity,
    int? currentEnrollment,
    DateTime? updatedAt,
  }) {
    return SchoolClass(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      capacity: capacity ?? this.capacity,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
    );
  }
}