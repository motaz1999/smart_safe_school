import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Replace with your actual Supabase URL and anon key
  static const String supabaseUrl = 'https://tycjmxjiatsxtbldyaug.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5Y2pteGppYXRzeHRibGR5YXVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyNTcwMTcsImV4cCI6MjA2OTgzMzAxN30.FaTt03k5GcKuzewwDNWdgIvFKhD8EJR5HuvCxeg7iLU';
  // TODO: Replace with your actual service role key
  static const String supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5Y2pteGppYXRzeHRibGR5YXVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDI1NzAxNywiZXhwIjoyMDY5ODMzMDE3fQ.VHYy54KUEZKlVzvBp_Cd-aeHK8ppC3J7uEjPLxuwgmw'; // Replace with actual service role key
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Set to false in production
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  // Admin client for admin operations
  static SupabaseClient get adminClient {
    return SupabaseClient(supabaseUrl, supabaseServiceRoleKey);
  }
  
  static GoTrueClient get auth => client.auth;
}