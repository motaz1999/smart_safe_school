import 'base_model.dart';

enum UserType { admin, teacher, student }

enum Gender { male, female }

class UserProfile extends BaseModel {
  final int schoolId;
  final UserType userType;
  final String name;
  final String userId; // admin_id, teacher_id, or student_id
  final String email;
  final String? phone;
  
  // Admin specific fields
  final Map<String, dynamic>? permissions;
  
  // Student specific fields
  final String? classId;
  final String? parentContact;
  final Gender? gender;
  
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
    this.gender,
    this.schoolName,
    this.className,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 DEBUG: UserProfile.fromJson - Input JSON: $json');
      
      // Validate required fields
      if (json['user_type'] == null) {
        print('❌ DEBUG: UserProfile.fromJson - Missing user_type in JSON');
      }
      
      if (json['gender'] != null && Gender.values.where((g) => g.name == json['gender']).isEmpty) {
        print('❌ DEBUG: UserProfile.fromJson - Invalid gender value: ${json['gender']}');
      }
      
      final userType = UserType.values.firstWhere(
        (e) => e.name == json['user_type'],
        orElse: () => UserType.student,
      );
      
      final gender = json['gender'] != null
          ? Gender.values.firstWhere(
              (g) => g.name == json['gender'],
              orElse: () => Gender.male)
          : null;
      
      final userProfile = UserProfile(
        id: json['id'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        schoolId: json['school_id'] ?? 0,
        userType: userType,
        name: json['name'] ?? '',
        userId: json['user_id'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        permissions: json['permissions'],
        classId: json['class_id'],
        parentContact: json['parent_contact'],
        gender: gender,
        schoolName: json['school_name'],
        className: json['class_name'],
      );
      
      print('✅ DEBUG: UserProfile.fromJson - Created profile: ${userProfile.name}, type: ${userProfile.userType.name}');
      return userProfile;
    } catch (e, stackTrace) {
      print('❌ DEBUG: UserProfile.fromJson - Error creating UserProfile: $e');
      print('❌ DEBUG: UserProfile.fromJson - Stack trace: $stackTrace');
      print('❌ DEBUG: UserProfile.fromJson - JSON data: $json');
      rethrow;
    }
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
      'gender': gender?.name,
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
    required int schoolId,
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
    required int schoolId,
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
    required int schoolId,
    required String name,
    required String studentId,
    required String email,
    required String classId,
    required String parentContact,
    required Gender gender,
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
      gender: gender,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  // Copy with method for updates
  UserProfile copyWith({
    int? schoolId,
    UserType? userType,
    String? name,
    String? userId,
    String? email,
    String? phone,
    Map<String, dynamic>? permissions,
    String? classId,
    String? parentContact,
    Gender? gender,
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
      gender: gender ?? this.gender,
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
    );
  }
}