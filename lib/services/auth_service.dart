import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/models.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print('🔑 AuthService: Attempting sign in for email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('✅ AuthService: Sign in successful, user ID: ${response.user?.id}');
      return response;
    } catch (e) {
      print('❌ AuthService: Sign in failed - $e');
      throw AuthException('Failed to sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  // Get user profile with role information
  Future<UserProfile?> getUserProfile() async {
    try {
      print('👤 AuthService: getUserProfile - Starting...');
      final user = currentUser;
      print('👤 AuthService: Getting profile for user: ${user?.id}');
      if (user == null) {
        print('❌ AuthService: No current user found');
        return null;
      }

      print('👤 AuthService: Calling get_user_profile RPC with user ID: ${user.id}');
      final response = await _supabase
          .rpc('get_user_profile', params: {'p_user_id': user.id});

      print('👤 AuthService: RPC response: $response');
      print('👤 AuthService: RPC response type: ${response.runtimeType}');
      if (response == null) {
        print('❌ AuthService: Null response from get_user_profile');
        return null;
      }
      
      if (response is List && response.isEmpty) {
        print('❌ AuthService: Empty response list from get_user_profile');
        return null;
      }
      
      if (response is List) {
        print('👤 AuthService: Response list length: ${response.length}');
        if (response.isNotEmpty) {
          print('👤 AuthService: First item in response: ${response[0]}');
        }
      }

      final profileData = response is List ? response[0] : response;
      print('👤 AuthService: Profile data: $profileData');
      print('👤 AuthService: Profile data type: ${profileData.runtimeType}');
      
      // Add email from auth.users
      if (user.email != null) {
        profileData['email'] = user.email;
        print('👤 AuthService: Added email to profile data: ${user.email}');
      } else {
        print('⚠️ AuthService: User email is null');
      }
      
      print('👤 AuthService: Creating UserProfile from profile data...');
      final userProfile = UserProfile.fromJson(profileData);
      print('✅ AuthService: User profile created successfully - Name: ${userProfile.name}, Role: ${userProfile.userType.name}');
      return userProfile;
    } catch (e, stackTrace) {
      print('❌ AuthService: Failed to get user profile - $e');
      print('❌ AuthService: Stack trace: $stackTrace');
      throw AuthException('Failed to get user profile: $e');
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('user_type')
          .eq('id', user.id)
          .single();

      return response['user_type'];
    } catch (e) {
      return null;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Create a new user profile (used by admin)
  Future<UserProfile> createUserProfile({
    required String email,
    required String password,
    required int schoolId,
    required UserType userType,
    required String name,
    required String userIdentifier,
    Gender? gender,
    String? phone,
    Map<String, dynamic>? permissions,
    String? classId,
    String? parentContact,
  }) async {
    try {
      // First create the auth user
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (authResponse.user == null) {
        throw AuthException('Failed to create auth user');
      }

      // Then create the profile
      final profileId = await _supabase.rpc('create_user_profile', params: {
        'p_user_id': authResponse.user!.id,
        'p_school_id': schoolId,
        'p_user_type': userType.name,
        'p_name': name,
        'p_user_identifier': userIdentifier,
        'p_phone': phone,
        'p_permissions': permissions,
        'p_class_id': classId,
        'p_parent_contact': parentContact,
        'p_gender': gender?.name,
      });

      // Get the created profile
      final profileResponse = await _supabase
          .rpc('get_user_profile', params: {'p_user_id': profileId});

      if (profileResponse == null || profileResponse.isEmpty) {
        throw AuthException('Failed to retrieve created profile');
      }

      final profileData = profileResponse[0];
      profileData['email'] = email;
      
      return UserProfile.fromJson(profileData);
    } catch (e) {
      throw AuthException('Failed to create user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      throw AuthException('Failed to update user profile: $e');
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AuthException('Failed to change password: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException('Failed to reset password: $e');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}