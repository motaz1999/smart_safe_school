import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';

void main() async {
  print('🚀 Test App: Starting main()');
  
  try {
    print('🚀 Test App: Calling WidgetsFlutterBinding.ensureInitialized()');
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Test App: WidgetsFlutterBinding.ensureInitialized() completed');
  } catch (e, stackTrace) {
    print('❌ Test App: WidgetsFlutterBinding.ensureInitialized() failed: $e');
    print('❌ Test App: Stack trace: $stackTrace');
    return;
  }
  
  // Initialize Supabase first and wait for it to complete
  try {
    print('🔍 Test App: Initializing Supabase...');
    await SupabaseConfig.initialize();
    print('✅ Test App: Supabase initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Test App: Supabase initialization failed: $e');
    print('❌ Test App: Stack trace: $stackTrace');
    runApp(ErrorApp(errorMessage: 'Supabase initialization failed: $e'));
    return;
  }
  
  print('🚀 Test App: Running TestApp...');
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🎨 Test App: Building TestApp widget');
    return MaterialApp(
      title: 'Test App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text('Test App Running Successfully!'),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;
  
  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $errorMessage'),
            ],
          ),
        ),
      ),
    );
  }
}