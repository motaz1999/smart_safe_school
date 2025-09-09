import 'base_model.dart';

class Subject extends BaseModel {
  final int schoolId;
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

  Subject copyWith({
    int? schoolId,
    String? name,
    String? code,
    String? description,
    List<String>? teacherIds,
    List<String>? teacherNames,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      teacherIds: teacherIds ?? this.teacherIds,
      teacherNames: teacherNames ?? this.teacherNames,
    );
  }
}