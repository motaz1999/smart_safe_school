import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../core/config/supabase_config.dart';
import '../models/models.dart';

class AdminService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final SupabaseClient _adminSupabase = SupabaseConfig.adminClient; // Admin client for admin operations

  // Get all students in the school
  Future<List<UserProfile>> getStudents({
    String? classId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      print('🔍 DEBUG: Getting students with params:');
      print('  - classId: $classId');
      print('  - searchQuery: $searchQuery');
      print('  - limit: $limit');
      print('  - offset: $offset');
      print('🔍 DEBUG: Getting current user school ID...');
      
      final schoolId = await _getCurrentUserSchoolId();
      print('🔍 DEBUG: School ID: $schoolId');
      
      print('🔍 DEBUG: Calling get_users_by_type RPC function...');
      final response = await _supabase.rpc('get_users_by_type', params: {
        'p_school_id': schoolId,
        'p_user_type': 'student',
        'p_limit': limit,
        'p_offset': offset,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while calling get_users_by_type RPC function');
          throw AdminException('Timeout while fetching students');
        },
      );
      
      print('🔍 DEBUG: RPC response type: ${response.runtimeType}');
      print('🔍 DEBUG: RPC response length: ${(response as List).length}');
      if ((response as List).isNotEmpty) {
        print('🔍 DEBUG: First record structure: ${response[0]}');
        print('🔍 DEBUG: First record keys: ${response[0].keys.toList()}');
        print('🔍 DEBUG: Email field type: ${response[0]['email'].runtimeType}');
      }
      
      // Add diagnostic logging for potential issues in mapping
      print('🔍 DEBUG: Mapping response to UserProfile objects...');
      final List<UserProfile> students = [];
      for (final item in response as List) {
        try {
          print('🔍 DEBUG: Mapping item: $item');
          final userProfile = UserProfile.fromJson(item);
          students.add(userProfile);
        } catch (itemError, itemStackTrace) {
          print('❌ DEBUG: Error mapping item to UserProfile: $itemError');
          print('❌ DEBUG: Item data: $item');
          print('❌ DEBUG: Item stack trace: $itemStackTrace');
          // Continue with other items rather than failing completely
        }
      }
      print('🔍 DEBUG: Successfully mapped ${students.length} students');
      return students;
    } catch (e, stackTrace) {
      print('🔍 DEBUG: Error in getStudents: $e');
      print('🔍 DEBUG: Error type: ${e.runtimeType}');
      print('🔍 DEBUG: Stack trace: $stackTrace');
      throw AdminException('Failed to get students: $e');
    }
  }

  // Get all teachers in the school
  Future<List<UserProfile>> getTeachers({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _supabase.rpc('get_users_by_type', params: {
        'p_school_id': await _getCurrentUserSchoolId(),
        'p_user_type': 'teacher',
        'p_limit': limit,
        'p_offset': offset,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while calling get_users_by_type RPC function for teachers');
          throw AdminException('Timeout while fetching teachers');
        },
      );
      
      return (response as List).map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      print('❌ DEBUG: Error in getTeachers: $e');
      throw AdminException('Failed to get teachers: $e');
    }
  }

  // Create a new student
  Future<UserProfile> createStudent({
    required String email,
    required String password,
    required String name,
    required String classId,
    required String parentContact,
    required Gender gender,
    String? phone,
    String? studentId, // Make studentId optional for auto-generation
  }) async {
    try {
      print('🔍 DEBUG: AdminService.createStudent - Creating student: $name');
      final schoolId = await _getCurrentUserSchoolId();
      print('🔍 DEBUG: AdminService.createStudent - School ID: $schoolId');
      
      // If studentId is not provided, generate one
      String finalStudentId = studentId ?? await _generateNextStudentId(schoolId);
      print('🔍 DEBUG: AdminService.createStudent - Final student ID: $finalStudentId');
      
      // Create auth user first with automatic email verification
      print('🔍 DEBUG: AdminService.createStudent - Creating auth user with email: $email');
      final authResponse = await _adminSupabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Automatically verify email
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while creating auth user');
          throw AdminException('Timeout while creating auth user');
        },
      );
      print('🔍 DEBUG: AdminService.createStudent - Auth response: ${authResponse.user?.id}');
      
      if (authResponse.user == null) {
        print('❌ DEBUG: AdminService.createStudent - Failed to create auth user');
        throw AdminException('Failed to create auth user');
      }
      
      // Create profile
      print('🔍 DEBUG: AdminService.createStudent - Creating profile...');
      final profileId = await _supabase.rpc('create_user_profile', params: {
        'p_user_id': authResponse.user!.id,
        'p_school_id': schoolId,
        'p_user_type': 'student',
        'p_name': name,
        'p_user_identifier': finalStudentId,
        'p_phone': phone,
        'p_permissions': null,
        'p_class_id': classId,
        'p_parent_contact': parentContact,
        'p_gender': gender.name,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while creating user profile');
          throw AdminException('Timeout while creating user profile');
        },
      );
      print('🔍 DEBUG: AdminService.createStudent - Profile created with ID: $profileId');
      
      // Get the created profile
      print('🔍 DEBUG: AdminService.createStudent - Retrieving created profile...');
      final profileResponse = await _supabase.rpc('get_user_profile', params: {
        'p_user_id': profileId,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while retrieving created profile');
          throw AdminException('Timeout while retrieving created profile');
        },
      );
      print('🔍 DEBUG: AdminService.createStudent - Profile response: $profileResponse');
      
      if (profileResponse == null || profileResponse.isEmpty) {
        print('❌ DEBUG: AdminService.createStudent - Failed to retrieve created profile');
        throw AdminException('Failed to retrieve created profile');
      }
      
      final profileData = profileResponse[0];
      profileData['email'] = email;
      print('🔍 DEBUG: AdminService.createStudent - Profile data: $profileData');
      
      final userProfile = UserProfile.fromJson(profileData);
      print('🔍 DEBUG: AdminService.createStudent - Created user profile: ${userProfile.name}');
      return userProfile;
    } catch (e) {
      print('❌ DEBUG: AdminService.createStudent - Error: $e');
      print('❌ DEBUG: AdminService.createStudent - Error type: ${e.runtimeType}');
      if (e is Error) {
        print('❌ DEBUG: AdminService.createStudent - Stack trace: ${e.stackTrace}');
      }
      throw AdminException('Failed to create student: $e');
    }
  }

  // Create a new teacher
  Future<UserProfile> createTeacher({
    required String email,
    required String password,
    required String name,
    required Gender gender,
    String? phone,
    List<String>? subjectIds,
    String? teacherId, // Make teacherId optional for auto-generation
  }) async {
    try {
      print('🔍 DEBUG: Creating teacher with name: $name, email: $email, teacherId: $teacherId');
      
      final schoolId = await _getCurrentUserSchoolId();
      print('🔍 DEBUG: School ID: $schoolId');
      
      // If teacherId is not provided, generate one
      String finalTeacherId = teacherId ?? await _generateNextTeacherId(schoolId);
      
      // Create auth user first with automatic email verification
      print('🔍 DEBUG: Creating auth user...');
      final authResponse = await _adminSupabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Automatically verify email
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while creating auth user for teacher');
          throw AdminException('Timeout while creating auth user for teacher');
        },
      );
      
      if (authResponse.user == null) {
        print('❌ DEBUG: Failed to create auth user');
        throw AdminException('Failed to create auth user');
      }
      print('✅ DEBUG: Auth user created with ID: ${authResponse.user!.id}');
      
      // Create profile
      print('🔍 DEBUG: Creating profile with RPC call...');
      final profileId = await _supabase.rpc('create_user_profile', params: {
        'p_user_id': authResponse.user!.id,
        'p_school_id': schoolId,
        'p_user_type': 'teacher',
        'p_name': name,
        'p_user_identifier': finalTeacherId,
        'p_phone': phone,
        'p_permissions': null,
        'p_class_id': null,
        'p_parent_contact': null,
        'p_gender': gender.name,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while creating teacher profile');
          throw AdminException('Timeout while creating teacher profile');
        },
      );
      print('✅ DEBUG: Profile created with ID: $profileId');
      
      // Assign subjects to teacher if provided
      if (subjectIds != null && subjectIds.isNotEmpty) {
        print('🔍 DEBUG: Assigning subjects to teacher...');
        for (final subjectId in subjectIds) {
          await _supabase.from('teacher_subjects').insert({
            'teacher_id': profileId,
            'subject_id': subjectId,
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('❌ DEBUG: Timeout while assigning subject to teacher');
              throw AdminException('Timeout while assigning subject to teacher');
            },
          );
        }
        print('✅ DEBUG: Subjects assigned to teacher');
      }
      
      // Get the created profile
      print('🔍 DEBUG: Retrieving created profile...');
      final profileResponse = await _supabase.rpc('get_user_profile', params: {
        'p_user_id': profileId,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while retrieving created teacher profile');
          throw AdminException('Timeout while retrieving created teacher profile');
        },
      );
      
      if (profileResponse == null || profileResponse.isEmpty) {
        print('❌ DEBUG: Failed to retrieve created profile');
        throw AdminException('Failed to retrieve created profile');
      }
      print('✅ DEBUG: Profile retrieved successfully');
      
      final profileData = profileResponse[0];
      profileData['email'] = email;
      
      print('✅ DEBUG: Teacher created successfully: $profileData');
      return UserProfile.fromJson(profileData);
    } catch (e) {
      print('❌ DEBUG: Error creating teacher: $e');
      throw AdminException('Failed to create teacher: $e');
    }
  }

  // Create a new admin
  Future<UserProfile> createAdmin({
    required String email,
    required String password,
    required String name,
    String? phone,
    Map<String, dynamic>? permissions,
    String? adminId, // Make adminId optional for auto-generation
  }) async {
    try {
      print('🔍 DEBUG: Creating admin with name: $name, email: $email, adminId: $adminId');
      
      final schoolId = await _getCurrentUserSchoolId();
      print('🔍 DEBUG: School ID: $schoolId');
      
      // If adminId is not provided, generate one
      String finalAdminId = adminId ?? await _generateNextAdminId(schoolId);
      
      // Create auth user first with automatic email verification
      print('🔍 DEBUG: Creating auth user...');
      final authResponse = await _adminSupabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Automatically verify email
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while creating auth user for admin');
          throw AdminException('Timeout while creating auth user for admin');
        },
      );
      
      if (authResponse.user == null) {
        print('❌ DEBUG: Failed to create auth user');
        throw AdminException('Failed to create auth user');
      }
      print('✅ DEBUG: Auth user created with ID: ${authResponse.user!.id}');
      
      // Create profile
      print('🔍 DEBUG: Creating profile with RPC call...');
      final profileId = await _supabase.rpc('create_user_profile', params: {
        'p_user_id': authResponse.user!.id,
        'p_school_id': schoolId,
        'p_user_type': 'admin',
        'p_name': name,
        'p_user_identifier': finalAdminId,
        'p_phone': phone,
        'p_permissions': permissions ?? {},
        'p_class_id': null,
        'p_parent_contact': null,
        'p_gender': null,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while creating admin profile');
          throw AdminException('Timeout while creating admin profile');
        },
      );
      print('✅ DEBUG: Profile created with ID: $profileId');
      
      // Get the created profile
      print('🔍 DEBUG: Retrieving created profile...');
      final profileResponse = await _supabase.rpc('get_user_profile', params: {
        'p_user_id': profileId,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while retrieving created admin profile');
          throw AdminException('Timeout while retrieving created admin profile');
        },
      );
      
      if (profileResponse == null || profileResponse.isEmpty) {
        print('❌ DEBUG: Failed to retrieve created profile');
        throw AdminException('Failed to retrieve created profile');
      }
      print('✅ DEBUG: Profile retrieved successfully');
      
      final profileData = profileResponse[0];
      profileData['email'] = email;
      
      print('✅ DEBUG: Admin created successfully: $profileData');
      return UserProfile.fromJson(profileData);
    } catch (e) {
      print('❌ DEBUG: Error creating admin: $e');
      throw AdminException('Failed to create admin: $e');
    }
  }

  // Helper method to generate the next student ID
  Future<String> _generateNextStudentId(int schoolId) async {
    try {
      // Get the current user's school ID
      final response = await _supabase.rpc('generate_next_student_id', params: {
        'p_school_id': schoolId,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while generating next student ID');
          throw AdminException('Timeout while generating next student ID');
        },
      );
      
      return response as String;
    } catch (e) {
      // If the function doesn't exist or fails, generate a fallback ID
      return 'STU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  // Helper method to generate the next teacher ID
  Future<String> _generateNextTeacherId(int schoolId) async {
    try {
      // Get the current user's school ID
      final response = await _supabase.rpc('generate_next_teacher_id', params: {
        'p_school_id': schoolId,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while generating next teacher ID');
          throw AdminException('Timeout while generating next teacher ID');
        },
      );
      
      return response as String;
    } catch (e) {
      // If the function doesn't exist or fails, generate a fallback ID
      return 'TEA${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  // Helper method to generate the next admin ID
  Future<String> _generateNextAdminId(int schoolId) async {
    try {
      // Get the current user's school ID
      final response = await _supabase.rpc('generate_next_admin_id', params: {
        'p_school_id': schoolId,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while generating next admin ID');
          throw AdminException('Timeout while generating next admin ID');
        },
      );
      
      return response as String;
    } catch (e) {
      // If the function doesn't exist or fails, generate a fallback ID
      return 'ADM${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  // Get all admins in the school
  Future<List<UserProfile>> getAdmins({String? searchQuery, int? limit, int? offset}) async {
    try {
      print('🔍 DEBUG: Getting admins with params:');
      print('  - searchQuery: $searchQuery');
      print('  - limit: $limit');
      print('  - offset: $offset');
      print('🔍 DEBUG: Getting current user school ID...');
      
      final schoolId = await _getCurrentUserSchoolId();
      print('🔍 DEBUG: School ID: $schoolId');
      
      print('🔍 DEBUG: Calling get_users_by_type RPC function...');
      final response = await _supabase.rpc('get_users_by_type', params: {
        'p_school_id': schoolId,
        'p_user_type': 'admin',
        'p_limit': limit,
        'p_offset': offset,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while getting admins');
          throw AdminException('Timeout while getting admins');
        },
      );
      
      print('🔍 DEBUG: RPC function response: $response');
      
      if (response == null) {
        return [];
      }
      
      // Handle both list and single object responses
      List<dynamic> data = response is List ? response : [response];
      
      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        data = data.where((item) {
          final itemData = item as Map<String, dynamic>;
          return itemData['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                 itemData['user_id'].toString().toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }
      
      // Convert to UserProfile objects
      final admins = data.map((item) {
        final itemData = item as Map<String, dynamic>;
        return UserProfile.fromJson({
          'id': itemData['id'],
          'school_id': itemData['school_id'],
          'user_type': 'admin',
          'name': itemData['name'],
          'user_id': itemData['user_id'],
          'phone': itemData['phone'],
          'email': itemData['email'],
          'permissions': itemData['permissions'],
          'school_name': itemData['school_name'],
          'class_name': itemData['class_name'],
          'created_at': itemData['created_at'],
        });
      }).toList();
      
      print('🔍 DEBUG: Converted ${admins.length} admins');
      return admins;
    } catch (e) {
      print('❌ DEBUG: Error getting admins: $e');
      throw AdminException('Failed to get admins: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while updating user profile');
              throw AdminException('Timeout while updating user profile');
            },
          );
    } catch (e) {
      print('❌ DEBUG: Error in updateUserProfile: $e');
      throw AdminException('Failed to update user profile: $e');
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      print('🔍 DEBUG: Deleting user profile with ID: $userId');
      
      // First call the database function to delete the user and all related data
      print('🔍 DEBUG: Calling delete_user_profile RPC function...');
      dynamic result;
      try {
        result = await _supabase.rpc('delete_user_profile', params: {
          'p_user_id': userId,
        }).timeout(
          const Duration(seconds: 10), // Reduced timeout
          onTimeout: () {
            print('❌ DEBUG: Timeout while calling delete_user_profile RPC function');
            throw AdminException('Timeout while deleting user profile from database');
          },
        );
      } catch (rpcError) {
        print('❌ DEBUG: RPC call failed with error: $rpcError');
        print('❌ DEBUG: RPC error type: ${rpcError.runtimeType}');
        rethrow;
      }
      
      if (result == true) {
        print('✅ DEBUG: User profile deleted successfully from database: $userId');
      } else {
        print('❌ DEBUG: Failed to delete user profile from database: $userId');
        print('❌ DEBUG: RPC function returned: $result');
        throw AdminException('Failed to delete user profile from database. Function returned: $result');
      }
      
      // Add a small delay to ensure database deletion is complete
      await Future.delayed(Duration(milliseconds: 50)); // Reduced delay
      
      // Then try to delete the user from the auth system
      try {
        print('🔍 DEBUG: Deleting user from auth system...');
        print('🔍 DEBUG: Current user role: ${_supabase.auth.currentUser?.role}');
        print('🔍 DEBUG: Current user ID: ${_supabase.auth.currentUser?.id}');
        print('🔍 DEBUG: Target user ID: $userId');
        
        // Check if the user exists in auth system
        try {
          print('🔍 DEBUG: Checking if user exists in auth system...');
          final userResponse = await _adminSupabase.auth.admin.getUserById(userId).timeout(
            const Duration(seconds: 5), // Reduced timeout
            onTimeout: () {
              print('❌ DEBUG: Timeout while checking user in auth system');
              throw AdminException('Timeout while checking user in auth system');
            },
          );
          print('🔍 DEBUG: User found in auth system: ${userResponse.user?.email}');
          print('🔍 DEBUG: User role: ${userResponse.user?.role}');
          print('🔍 DEBUG: User confirmation status: ${userResponse.user?.emailConfirmedAt}');
        } catch (e) {
          print('⚠️ DEBUG: User not found in auth system: $e');
          print('⚠️ DEBUG: Error type: ${e.runtimeType}');
          return; // If user doesn't exist in auth, we're done
        }
        
        // Try to delete the user from auth system
        print('🔍 DEBUG: Attempting to delete user from auth system...');
        await _adminSupabase.auth.admin.deleteUser(userId).timeout(
          const Duration(seconds: 5), // Reduced timeout
          onTimeout: () {
            print('❌ DEBUG: Timeout while deleting user from auth system');
            throw AdminException('Timeout while deleting user from auth system');
          },
        );
        print('✅ DEBUG: User deleted from auth system successfully: $userId');
      } catch (authError) {
        print('⚠️ DEBUG: Failed to delete user from auth system: $authError');
        print('⚠️ DEBUG: User profile was deleted from database but auth user may still exist');
        print('⚠️ DEBUG: Auth error type: ${authError.runtimeType}');
        print('⚠️ DEBUG: Auth error message: ${authError.toString()}');
        
        // Try to get more details about the user
        try {
          print('🔍 DEBUG: Checking if user still exists in auth system after delete attempt...');
          final userCheck = await _adminSupabase.auth.admin.getUserById(userId).timeout(
            const Duration(seconds: 5), // Reduced timeout
            onTimeout: () {
              print('❌ DEBUG: Timeout while checking user after delete attempt');
              throw AdminException('Timeout while checking user after delete attempt');
            },
          );
          print('🔍 DEBUG: User still exists in auth system: ${userCheck.user?.email}');
          // If we get here, the user still exists in auth system
          throw AdminException('User profile deleted from database but failed to delete auth user. Auth user may still exist.');
        } catch (checkError) {
          print('🔍 DEBUG: User no longer exists in auth system or check failed: $checkError');
          print('🔍 DEBUG: Check error type: ${checkError.runtimeType}');
        }
      }
    } on AdminException {
      // Re-throw AdminException as-is
      rethrow;
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error deleting user profile: $e');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      print('❌ DEBUG: Error stack trace: $stackTrace');
      
      // Provide more user-friendly error messages
      String userMessage = 'Failed to delete user profile. ';
      if (e.toString().contains('Timeout')) {
        userMessage += 'The operation timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('Permission')) {
        userMessage += 'You do not have permission to delete this user.';
      } else if (e.toString().contains('not found')) {
        userMessage += 'The user could not be found.';
      } else {
        userMessage += 'Please try again later.';
      }
      
      throw AdminException(userMessage);
    }
  }

  // Get all classes in the school
  Future<List<SchoolClass>> getClasses({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      final response = await _supabase
          .from('classes')
          .select('*')
          .eq('school_id', schoolId)
          .order('name')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while fetching classes from database');
              throw AdminException('Timeout while fetching classes');
            },
          );
      
      final classes = <SchoolClass>[];
      for (final classData in response) {
        // Get student count for each class
        final studentCount = await _supabase
            .from('profiles')
            .select('id')
            .eq('class_id', classData['id'])
            .eq('user_type', 'student')
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('❌ DEBUG: Timeout while fetching student count for class ${classData['id']}');
                throw AdminException('Timeout while fetching student count for class');
              },
            );
        
        classes.add(SchoolClass.fromJson({
          ...classData,
          'current_enrollment': studentCount.length,
        }));
      }
      
      return classes;
    } catch (e) {
      print('❌ DEBUG: Error in getClasses: $e');
      throw AdminException('Failed to get classes: $e');
    }
  }

  // Create a new class
  Future<SchoolClass> createClass({
    required String name,
    String? gradeLevel,
    int capacity = 30,
  }) async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      final response = await _supabase
          .from('classes')
          .insert({
            'school_id': schoolId,
            'name': name,
            'grade_level': gradeLevel,
            'capacity': capacity,
          })
          .select()
          .single()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while creating class');
              throw AdminException('Timeout while creating class');
            },
          );
      
      return SchoolClass.fromJson({
        ...response,
        'current_enrollment': 0,
      });
    } catch (e) {
      print('❌ DEBUG: Error in createClass: $e');
      throw AdminException('Failed to create class: $e');
    }
  }

  // Update class
  Future<void> updateClass(SchoolClass schoolClass) async {
    try {
      await _supabase
          .from('classes')
          .update(schoolClass.toJson())
          .eq('id', schoolClass.id)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while updating class');
              throw AdminException('Timeout while updating class');
            },
          );
    } catch (e) {
      print('❌ DEBUG: Error in updateClass: $e');
      throw AdminException('Failed to update class: $e');
    }
  }

  // Delete class
  Future<void> deleteClass(String classId) async {
    try {
      await _supabase
          .from('classes')
          .delete()
          .eq('id', classId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while deleting class');
              throw AdminException('Timeout while deleting class');
            },
          );
    } catch (e) {
      print('❌ DEBUG: Error in deleteClass: $e');
      throw AdminException('Failed to delete class: $e');
    }
  }

  // Get all subjects in the school
  Future<List<Subject>> getSubjects({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      print('🔍 DEBUG: getSubjects - Getting current user school ID...');
      final schoolId = await _getCurrentUserSchoolId();
      print('🔍 DEBUG: getSubjects - School ID: $schoolId');
      
      print('🔍 DEBUG: getSubjects - Querying subjects...');
      final response = await _supabase
          .from('subjects')
          .select('*')
          .eq('school_id', schoolId)
          .order('name')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while fetching subjects from database');
              throw AdminException('Timeout while fetching subjects');
            },
          );
      print('🔍 DEBUG: getSubjects - Response length: ${response.length}');
      
      print('🔍 DEBUG: getSubjects - Mapping response to Subject objects...');
      final result = response.map((json) => Subject.fromJson(json)).toList();
      print('🔍 DEBUG: getSubjects - Created ${result.length} Subject objects');
      return result;
    } catch (e) {
      print('❌ DEBUG: getSubjects - Error: $e');
      throw AdminException('Failed to get subjects: $e');
    }
  }

  // Create a new subject
  Future<Subject> createSubject({
    required String name,
    required String code,
    String? description,
    List<String>? teacherIds,
  }) async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      final response = await _supabase
          .from('subjects')
          .insert({
            'school_id': schoolId,
            'name': name,
            'code': code,
            'description': description,
          })
          .select()
          .single()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while creating subject');
              throw AdminException('Timeout while creating subject');
            },
          );
      
      final subjectId = response['id'];
      
      // Assign teachers to subject if provided
      if (teacherIds != null && teacherIds.isNotEmpty) {
        for (final teacherId in teacherIds) {
          await _supabase.from('teacher_subjects').insert({
            'teacher_id': teacherId,
            'subject_id': subjectId,
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('❌ DEBUG: Timeout while assigning teacher to subject');
              throw AdminException('Timeout while assigning teacher to subject');
            },
          );
        }
      }
      
      return Subject.fromJson(response);
    } catch (e) {
      print('❌ DEBUG: Error in createSubject: $e');
      throw AdminException('Failed to create subject: $e');
    }
  }

  // Update subject
  Future<void> updateSubject(Subject subject) async {
    try {
      await _supabase
          .from('subjects')
          .update(subject.toJson())
          .eq('id', subject.id)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while updating subject');
              throw AdminException('Timeout while updating subject');
            },
          );
    } catch (e) {
      print('❌ DEBUG: Error in updateSubject: $e');
      throw AdminException('Failed to update subject: $e');
    }
  }

  // Delete subject
  Future<void> deleteSubject(String subjectId) async {
    try {
      await _supabase
          .from('subjects')
          .delete()
          .eq('id', subjectId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while deleting subject');
              throw AdminException('Timeout while deleting subject');
            },
          );
    } catch (e) {
      print('❌ DEBUG: Error in deleteSubject: $e');
      throw AdminException('Failed to delete subject: $e');
    }
  }

  // Change user password (admin function)
  Future<void> changeUserPassword(String userId, String newPassword) async {
    try {
      print('🔍 DEBUG: AdminService.changeUserPassword - Changing password for user: $userId');
      
      // Use admin client to update user password
      await _adminSupabase.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(
          password: newPassword,
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while changing user password');
          throw AdminException('Timeout while changing user password');
        },
      );
      
      print('✅ DEBUG: AdminService.changeUserPassword - Password changed successfully for user: $userId');
    } catch (e) {
      print('❌ DEBUG: AdminService.changeUserPassword - Error: $e');
      print('❌ DEBUG: AdminService.changeUserPassword - Error type: ${e.runtimeType}');
      throw AdminException('Failed to change user password: $e');
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('🔍 DEBUG: Getting dashboard stats...');
      final schoolId = await _getCurrentUserSchoolId();
      print('🔍 DEBUG: School ID for stats: $schoolId');
      
      // Get counts for different entities
      print('🔍 DEBUG: Querying students count...');
      final studentsCount = await _supabase
          .from('profiles')
          .select('id')
          .eq('school_id', schoolId)
          .eq('user_type', 'student')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while fetching students count');
              throw AdminException('Timeout while fetching students count');
            },
          );
      print('🔍 DEBUG: Students count: ${studentsCount.length}');
      
      print('🔍 DEBUG: Querying teachers count...');
      final teachersCount = await _supabase
          .from('profiles')
          .select('id')
          .eq('school_id', schoolId)
          .eq('user_type', 'teacher')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while fetching teachers count');
              throw AdminException('Timeout while fetching teachers count');
            },
          );
      print('🔍 DEBUG: Teachers count: ${teachersCount.length}');
      
      print('🔍 DEBUG: Querying classes count...');
      final classesCount = await _supabase
          .from('classes')
          .select('id')
          .eq('school_id', schoolId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while fetching classes count');
              throw AdminException('Timeout while fetching classes count');
            },
          );
      print('🔍 DEBUG: Classes count: ${classesCount.length}');
      
      print('🔍 DEBUG: Querying subjects count...');
      final subjectsCount = await _supabase
          .from('subjects')
          .select('id')
          .eq('school_id', schoolId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ DEBUG: Timeout while fetching subjects count');
              throw AdminException('Timeout while fetching subjects count');
            },
          );
      print('🔍 DEBUG: Subjects count: ${subjectsCount.length}');
      
      final stats = {
        'students_count': studentsCount.length,
        'teachers_count': teachersCount.length,
        'classes_count': classesCount.length,
        'subjects_count': subjectsCount.length,
      };
      
      print('🔍 DEBUG: Dashboard stats completed: $stats');
      return stats;
    } catch (e) {
      print('🔍 DEBUG: Error in getDashboardStats: $e');
      print('🔍 DEBUG: Error type: ${e.runtimeType}');
      throw AdminException('Failed to get dashboard stats: $e');
    }
  }

  // Helper method to get current user's school ID
  Future<int> _getCurrentUserSchoolId() async {
    try {
      print('🔍 DEBUG: _getCurrentUserSchoolId - Getting current user...');
      final user = _supabase.auth.currentUser;
      print('🔍 DEBUG: _getCurrentUserSchoolId - Current user: ${user?.id}');
      if (user == null) {
        print('❌ DEBUG: _getCurrentUserSchoolId - User not authenticated');
        throw AdminException('User not authenticated');
      }

      print('🔍 DEBUG: _getCurrentUserSchoolId - Querying profile for school ID...');
      final response = await _supabase
          .from('profiles')
          .select('school_id')
          .eq('id', user.id)
          .single();
      print('🔍 DEBUG: _getCurrentUserSchoolId - Profile response: $response');
      
      // Add diagnostic logging for potential issues
      if (response == null) {
        print('❌ DEBUG: _getCurrentUserSchoolId - Response is null');
        throw AdminException('User profile not found');
      }
      
      if (!response.containsKey('school_id')) {
        print('❌ DEBUG: _getCurrentUserSchoolId - Response missing school_id key: ${response.keys.toList()}');
        throw AdminException('School ID not found in user profile');
      }
      
      final schoolIdValue = response['school_id'];
      print('🔍 DEBUG: _getCurrentUserSchoolId - School ID value: $schoolIdValue, type: ${schoolIdValue.runtimeType}');
      
      if (schoolIdValue == null) {
        print('❌ DEBUG: _getCurrentUserSchoolId - School ID value is null');
        throw AdminException('School ID is null in user profile');
      }
      
      // Handle potential type conversion issues
      final schoolId = schoolIdValue is int ? schoolIdValue : int.tryParse(schoolIdValue.toString());
      if (schoolId == null) {
        print('❌ DEBUG: _getCurrentUserSchoolId - Failed to parse school ID: $schoolIdValue');
        throw AdminException('Invalid school ID format: $schoolIdValue');
      }

      print('🔍 DEBUG: _getCurrentUserSchoolId - School ID: $schoolId');
      return schoolId;
    } catch (e, stackTrace) {
      print('❌ DEBUG: _getCurrentUserSchoolId - Error: $e');
      print('❌ DEBUG: _getCurrentUserSchoolId - Stack trace: $stackTrace');
      throw AdminException('Failed to get user school ID: $e');
    }
  }

  // Check if school has any subjects
  Future<bool> hasSubjects() async {
    try {
      final subjects = await getSubjects().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while checking if school has subjects');
          throw AdminException('Timeout while checking if school has subjects');
        },
      );
      return subjects.isNotEmpty;
    } catch (e) {
      print('❌ DEBUG: Error in hasSubjects: $e');
      throw AdminException('Failed to check if school has subjects: $e');
    }
  }

  // Create default subjects for a school
  Future<List<Subject>> createDefaultSubjects() async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      // Define default subjects
      final defaultSubjects = [
        {
          'name': 'الرياضيات',
          'code': 'MATH',
          'description': 'Mathematics curriculum covering algebra, geometry, and calculus'
        },
        {
          'name': 'الإنجليزية',
          'code': 'ENG',
          'description': 'English language and literature curriculum'
        },
        {
          'name': 'علوم',
          'code': 'SCI',
          'description': 'General science curriculum covering physics, chemistry, and biology'
        },
        {
          'name': 'العربية',
          'code': 'ARB',
          'description': 'Arabic language'
        },
        {
          'name': 'الفرنسية',
          'code': 'FRA',
          'description': 'French language'
        },
        {
          'name': 'التكنولوجية',
          'code': 'TEC',
          'description': 'Technology and computer science'
        },
        {
          'name': 'الإسلامية',
          'code': 'ISL',
          'description': 'Islamic studies and religion curriculum'
        },
        {
          'name': 'التربية المدنية',
          'code': 'SST',
          'description': 'Social studies and history curriculum'
        },
        {
          'name': 'التاريخ والجغرافيا',
          'code': 'GEO',
          'description': 'Geography and environmental studies'
        },
        {
          'name': 'الرسم',
          'code': 'ART',
          'description': 'Visual arts and creative expression'
        },
        {
          'name': 'التربية البدنية',
          'code': 'PE',
          'description': 'Physical fitness and sports education'
        },
        {
          'name': 'الإعلامية',
          'code': 'CS',
          'description': 'Introduction to computing and programming'
        }
      ];
      
      final createdSubjects = <Subject>[];
      
      // Create each default subject
      for (final subjectData in defaultSubjects) {
        final response = await _supabase
            .from('subjects')
            .insert({
              'school_id': schoolId,
              'name': subjectData['name'],
              'code': subjectData['code'],
              'description': subjectData['description'],
            })
            .select()
            .single()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                print('❌ DEBUG: Timeout while creating default subject');
                throw AdminException('Timeout while creating default subject');
              },
            );
            
        createdSubjects.add(Subject.fromJson(response));
      }
      
      return createdSubjects;
    } catch (e) {
      print('❌ DEBUG: Error in createDefaultSubjects: $e');
      throw AdminException('Failed to create default subjects: $e');
    }
  }

  // Check for teacher scheduling conflicts
  Future<bool> checkTeacherConflict({
    required String teacherId,
    required String dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? entryId, // Optional entry ID to exclude (for updates)
  }) async {
    try {
      final schoolId = await _getCurrentUserSchoolId();
      
      // Convert TimeOfDay to minutes for easier comparison
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      
      // Query for existing entries for this teacher on the same day
      final response = await _supabase
          .from('timetables')
          .select('id, start_time, end_time')
          .eq('teacher_id', teacherId)
          .eq('day_of_week', dayOfWeek)
          .eq('school_id', schoolId);
          
      // If we're updating an existing entry, exclude it from conflict check
      List<dynamic> filteredResponse = response;
      if (entryId != null) {
        filteredResponse = response.where((entry) => entry['id'] != entryId).toList();
      }
      
      // Check each entry for time conflicts
      for (final entry in filteredResponse) {
        // Get the start and end times for this entry
        final entryStartTimeStr = entry['start_time'] as String;
        final entryEndTimeStr = entry['end_time'] as String;
        
        // Parse time strings (format: "HH:MM:SS")
        final entryStartParts = entryStartTimeStr.split(':');
        final entryEndParts = entryEndTimeStr.split(':');
        
        final entryStartMinutes = int.parse(entryStartParts[0]) * 60 + int.parse(entryStartParts[1]);
        final entryEndMinutes = int.parse(entryEndParts[0]) * 60 + int.parse(entryEndParts[1]);
        
        // Check for time overlap
        if ((startMinutes < entryEndMinutes) && (endMinutes > entryStartMinutes)) {
          return true; // Conflict found
        }
      }
      
      return false; // No conflict found
    } catch (e) {
      print('❌ DEBUG: Error checking teacher conflict: $e');
      throw AdminException('Failed to check teacher conflict: $e');
    }
  }

  // Check if school has subjects and create default subjects if not
  Future<List<Subject>> initializeDefaultSubjectsIfNeeded() async {
    try {
      final hasSubjects = await this.hasSubjects().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while checking if school has subjects');
          throw AdminException('Timeout while checking if school has subjects');
        },
      );
      
      if (!hasSubjects) {
        return await createDefaultSubjects().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            print('❌ DEBUG: Timeout while creating default subjects');
            throw AdminException('Timeout while creating default subjects');
          },
        );
      }
      
      // If school already has subjects, return existing subjects
      return await getSubjects().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ DEBUG: Timeout while getting subjects');
          throw AdminException('Timeout while getting subjects');
        },
      );
    } catch (e) {
      print('❌ DEBUG: Error in initializeDefaultSubjectsIfNeeded: $e');
      throw AdminException('Failed to initialize default subjects: $e');
    }
  }
}

class AdminException implements Exception {
  final String message;
  AdminException(this.message);
  
  @override
  String toString() => message;
}