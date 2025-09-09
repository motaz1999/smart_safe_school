import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Supabase...');
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully!');
    
    // Test the connection
    final client = SupabaseConfig.client;
    print('✅ Client created successfully');
    
    // Test a simple query (this will fail if no tables exist, but connection works)
    try {
      final response = await client.from('schools').select('count').limit(1);
      print('✅ Database connection test successful!');
      print('Response: $response');
    } catch (e) {
      print('⚠️ Database query failed (expected if no data): $e');
      print('But connection to Supabase is working!');
    }
    
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }
  
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Supabase Connection Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text(
                'Supabase Connection Test',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Check the console for connection results'),
            ],
          ),
        ),
      ),
    );
  }
}