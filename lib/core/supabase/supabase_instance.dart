import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInstance {
  const SupabaseInstance._();

  static SupabaseClient get client => Supabase.instance.client;
}

