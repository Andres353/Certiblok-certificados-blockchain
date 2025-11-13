// lib/services/supabase/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://ndddetlmqfyctapgvjnn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kZGRldGxtcWZ5Y3RhcGd2am5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5NTY0NDAsImV4cCI6MjA3NTUzMjQ0MH0.ndB0VcFkA7Aj8LjKKLZAWxvBH1-Th_H1z-qF7S6-Cqs';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
