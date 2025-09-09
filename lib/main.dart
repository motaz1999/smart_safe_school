import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_layout.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/student/student_main.dart';
import 'screens/privacy_policy_screen.dart';
import 'services/document_service.dart';

void main() async {
  print('🚀 App startup: Starting main()');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ App startup: WidgetsFlutterBinding.ensureInitialized() completed');
  
  // Initialize Supabase first and wait for it to complete
  try {
    print('🔍 App startup: Initializing Supabase...');
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully in main');
  } catch (e, stackTrace) {
    print('❌ Supabase initialization failed: $e');
    print('❌ Supabase initialization stack trace: $stackTrace');
  }
  
  // Initialize document service
  try {
    print('🔍 App startup: Initializing document service...');
    final documentService = DocumentService();
    await documentService.initialize();
    print('✅ Document service initialized successfully in main');
  } catch (e, stackTrace) {
    print('❌ Document service initialization failed: $e');
    print('❌ Document service initialization stack trace: $stackTrace');
    // Try to force create the bucket as a fallback
    try {
      print('🔄 Trying to force create documents bucket as fallback...');
      final documentService = DocumentService();
      await documentService.forceCreateDocumentsBucket();
      print('✅ Documents bucket created successfully as fallback');
    } catch (fallbackError, fallbackStack) {
      print('❌ Fallback bucket creation also failed: $fallbackError');
      print('❌ Fallback error stack trace: $fallbackStack');
    }
    
    // Try to manually insert bucket into database
    try {
      print('🔄 Trying to manually insert bucket into database...');
      final documentService = DocumentService();
      await documentService.manuallyInsertBucketInDatabase();
      print('✅ Bucket manually inserted into database');
    } catch (manualInsertError) {
      print('❌ Manual bucket insertion failed: $manualInsertError');
    }
  }
  
  // Run bucket diagnostic
  try {
    print('🔍 Running bucket diagnostic...');
    final documentService = DocumentService();
    await documentService.diagnoseBucketStatus();
  } catch (diagnosticError) {
    print('❌ Bucket diagnostic failed: $diagnosticError');
  }
  
  print('🚀 App startup: Running SmartSafeSchoolApp...');
  runApp(const SmartSafeSchoolApp());
}

class SmartSafeSchoolApp extends StatelessWidget {
  const SmartSafeSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
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
        routes: {
          '/login': (context) => const LoginScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🏠 AuthWrapper: Building with state - Loading: ${authProvider.isLoading}, Authenticated: ${authProvider.isAuthenticated}, Role: ${authProvider.userRole}');
        
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          print('⏳ AuthWrapper: Showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show login if not authenticated
        if (!authProvider.isAuthenticated) {
          print('🔐 AuthWrapper: User not authenticated, showing login screen');
          return const LoginScreen();
        }

        print('✅ AuthWrapper: User authenticated, routing to dashboard for role: ${authProvider.userRole}');
        
        // Route based on user role
        switch (authProvider.userRole) {
          case 'admin':
            print('👑 AuthWrapper: Navigating to Admin Dashboard');
            return const AdminLayout();
          case 'teacher':
            print('👨‍🏫 AuthWrapper: Navigating to Teacher Dashboard');
            return const TeacherDashboard();
          case 'student':
            print('👨‍🎓 AuthWrapper: Navigating to Student Portal');
            return const StudentMainScreen();
          default:
            print('❌ AuthWrapper: Invalid or null role: ${authProvider.userRole}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Access Denied - Invalid Role'),
                    const SizedBox(height: 16),
                    Text('Current role: ${authProvider.userRole ?? 'null'}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => authProvider.signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
