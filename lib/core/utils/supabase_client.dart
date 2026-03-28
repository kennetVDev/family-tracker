import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseClient {
  static final SupabaseClient _instance = SupabaseClient._internal();
  factory SupabaseClient() => _instance;
  SupabaseClient._internal();

  late SupabaseClient _client;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('SupabaseClient not initialized. Call initialize() first.');
    }
    return _client;
  }

  SupabaseClient get getClient => _client;
}
