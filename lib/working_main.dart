import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'services/auth_service.dart';
import 'models/models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase first
  await SupabaseConfig.initialize();
  
  runApp(const SmartSafeSchoolApp());
}

class SmartSafeSchoolApp extends StatelessWidget {
  const SmartSafeSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkingAuthProvider(),
      child: MaterialApp(
        title: 'Smart Safe School',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class WorkingAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _currentUser;
  String? _userRole;
  bool _isLoading = true;
  String? _error;

  WorkingAuthProvider() {
    _initializeAuth();
  }

  // Getters
  UserProfile? get currentUser => _currentUser;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _initializeAuth() async {
    try {
      print('Initializing auth provider...');
      _setLoading(true);
      
      // Check current user
      if (_authService.isAuthenticated) {
        print('User is authenticated, loading profile...');
        await _loadUserProfile();
      } else {
        print('No authenticated user found');
        _setLoading(false);
      }
    } catch (e) {
      print('Auth initialization error: $e');
      _setError('Failed to initialize authentication: $e');
      _setLoading(false);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      print('Loading user profile...');
      _currentUser = await _authService.getUserProfile();
      _userRole = _currentUser?.userType.name;
      _error = null;
      print('Profile loaded: ${_currentUser?.name} (${_userRole})');
    } catch (e) {
      print('Failed to load user profile: $e');
      _setError('Failed to load user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      print('Attempting sign in for: $email');
      _setLoading(true);
      _error = null;
      
      await _authService.signIn(email, password);
      await _loadUserProfile();
      
      return true;
    } catch (e) {
      print('Sign in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out...');
      _setLoading(true);
      await _authService.signOut();
      _currentUser = null;
      _userRole = null;
      _error = null;
    } catch (e) {
      print('Sign out error: $e');
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  bool get isAdmin => _userRole == 'admin';
  bool get isTeacher => _userRole == 'teacher';
  bool get isStudent => _userRole == 'student';
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkingAuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper build - Loading: ${authProvider.isLoading}, Authenticated: ${authProvider.isAuthenticated}, Role: ${authProvider.userRole}');
        
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Show error if there's an error
        if (authProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${authProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry initialization
                      authProvider._initializeAuth();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show login if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Route based on user role
        switch (authProvider.userRole) {
          case 'admin':
            return const AdminDashboard();
          case 'teacher':
            return const Scaffold(
              body: Center(
                child: Text('Teacher Dashboard - Coming Soon'),
              ),
            );
          case 'student':
            return const Scaffold(
              body: Center(
                child: Text('Student Dashboard - Coming Soon'),
              ),
            );
          default:
            return const Scaffold(
              body: Center(
                child: Text('Access Denied - Invalid Role'),
              ),
            );
        }
      },
    );
  }
}