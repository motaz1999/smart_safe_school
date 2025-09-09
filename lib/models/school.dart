import 'base_model.dart';

class School extends BaseModel {
  final int schoolId; // The actual integer ID from database
  final String name;
  final String? address;
  final String? phone;
  final String? email;

  School({
    required String stringId, // Keep string ID for BaseModel compatibility
    required this.schoolId, // Add integer id
    required super.createdAt,
    super.updatedAt,
    required this.name,
    this.address,
    this.phone,
    this.email,
  }) : super(id: stringId);

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      stringId: json['id'].toString(),
      schoolId: json['id'], // INTEGER from database
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
      'id': schoolId, // INTEGER
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  School copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    DateTime? updatedAt,
  }) {
    return School(
      stringId: id,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}