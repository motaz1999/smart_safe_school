import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _currentUser;
  String? _userRole;
  bool _isLoading = true;
  String? _error;

  AuthProvider() {
    _initializeAuth();
  }

  // Getters
  UserProfile? get currentUser => _currentUser;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      print('🔐 AuthProvider: Starting authentication initialization...');
      _setLoading(true);
      
      print('🔐 AuthProvider: Setting up auth state change listener...');
      // Listen to auth state changes
      _authService.authStateChanges.listen((AuthState data) {
        print('🔐 AuthProvider: Auth state changed - ${data.event}');
        _handleAuthStateChange(data);
      }, onError: (error) {
        print('❌ AuthProvider: Error in auth state change listener: $error');
        _setError('Auth state change error: $error');
      });

      print('🔐 AuthProvider: Checking current authentication status...');
      // Check current user
      if (_authService.isAuthenticated) {
        print('🔐 AuthProvider: User is authenticated, loading profile...');
        await _loadUserProfile();
      } else {
        print('🔐 AuthProvider: User is not authenticated, setting loading to false');
        _setLoading(false);
      }
    } catch (e, stackTrace) {
      print('❌ AuthProvider: Auth initialization error: $e');
      print('❌ AuthProvider: Auth initialization stack trace: $stackTrace');
      _setError('Failed to initialize authentication: $e');
      _setLoading(false);
    }
  }

  // Handle auth state changes
  void _handleAuthStateChange(AuthState authState) async {
    print('🔄 AuthProvider: Auth state changed - ${authState.event}');
    if (authState.event == AuthChangeEvent.signedIn) {
      print('✅ AuthProvider: User signed in, loading profile...');
      await _loadUserProfile();
    } else if (authState.event == AuthChangeEvent.signedOut) {
      print('👋 AuthProvider: User signed out');
      _currentUser = null;
      _userRole = null;
      _error = null;
      notifyListeners();
    }
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      print('👤 AuthProvider: Loading user profile...');
      _setLoading(true);
      
      print('👤 AuthProvider: Calling AuthService.getUserProfile()...');
      _currentUser = await _authService.getUserProfile();
      print('👤 AuthProvider: User profile loaded: ${_currentUser?.name}');
      print('👤 AuthProvider: User profile details - ID: ${_currentUser?.id}, Type: ${_currentUser?.userType.name}');
      
      _userRole = _currentUser?.userType.name;
      print('👤 AuthProvider: User role set to: $_userRole');
      
      _error = null;
      print('✅ AuthProvider: Profile loading completed successfully');
    } catch (e, stackTrace) {
      print('❌ AuthProvider: Failed to load user profile - $e');
      print('❌ AuthProvider: Stack trace: $stackTrace');
      _setError('Failed to load user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      print('🔐 AuthProvider: Starting sign in process...');
      _setLoading(true);
      _error = null;
      
      print('🔐 AuthProvider: Calling auth service sign in...');
      await _authService.signIn(email, password);
      print('✅ AuthProvider: Auth service sign in successful');
      
      print('🔐 AuthProvider: Loading user profile...');
      await _loadUserProfile();
      print('✅ AuthProvider: Sign in process completed successfully');
      
      return true;
    } catch (e) {
      print('❌ AuthProvider: Sign in failed - $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _currentUser = null;
      _userRole = null;
      _error = null;
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      await _authService.updateUserProfile(profile);
      _currentUser = profile;
      _error = null;
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword(String newPassword) async {
    try {
      _setLoading(true);
      await _authService.changePassword(newPassword);
      _error = null;
      return true;
    } catch (e) {
      _setError('Failed to change password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _authService.resetPassword(email);
      _error = null;
      return true;
    } catch (e) {
      _setError('Failed to reset password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _userRole == role;
  }

  // Check if user is admin
  bool get isAdmin => hasRole('admin');

  // Check if user is teacher
  bool get isTeacher => hasRole('teacher');

  // Check if user is student
  bool get isStudent => hasRole('student');
}