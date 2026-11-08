import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central wrapper service for Supabase interactions.
/// Handles initialization from .env, credentials validation,
/// and graceful fallback to Demo Mode when credentials are not configured.
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;
  bool _isDemoMode = true;

  bool get isInitialized => _isInitialized;
  bool get isDemoMode => _isDemoMode;

  SupabaseClient? get client {
    if (_isDemoMode || !_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  GoTrueClient? get auth => client?.auth;
  SupabaseStorageClient? get storage => client?.storage;
  FunctionsClient? get functions => client?.functions;

  /// Returns a table reference if configured, otherwise null.
  PostgrestQueryBuilder? from(String table) {
    return client?.from(table);
  }

  /// Initialize Supabase from environment variables.
  /// Falls back to Demo Mode if keys are missing or initialization fails.
  Future<void> initialize() async {
    try {
      // Try to load .env if not loaded yet
      if (!dotenv.isInitialized) {
        try {
          await dotenv.load(fileName: '.env');
        } catch (e) {
          debugPrint('Notice: .env file not found or failed to load: $e. Using demo mode.');
        }
      }

      final url = dotenv.maybeGet('SUPABASE_URL')?.trim();
      final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY')?.trim();
      final forceDemo = (dotenv.maybeGet('DEMO_MODE') ?? 'false').toLowerCase() == 'true';

      if (forceDemo || url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
        debugPrint('[Mossy] Supabase credentials not found or DEMO_MODE=true. Running in Demo Mode.');
        _isDemoMode = true;
        _isInitialized = true;
        return;
      }

      // Initialize Supabase client
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );

      _isInitialized = true;
      _isDemoMode = false;
      debugPrint('[Mossy] Supabase initialized successfully in connected mode.');
    } catch (e, stack) {
      debugPrint('[Mossy] Failed to initialize Supabase: $e\n$stack');
      _isInitialized = true;
      _isDemoMode = true;
    }
  }

  /// Helper to invoke an Edge Function safely with error handling
  Future<Map<String, dynamic>?> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (_isDemoMode || client == null) {
      throw StateError('Cannot invoke edge function "$functionName" in demo mode.');
    }

    try {
      final response = await client!.functions
          .invoke(
            functionName,
            body: body,
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.status >= 200 && response.status < 300) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return {'data': data};
      } else {
        throw Exception(
            'Edge function "$functionName" returned status ${response.status}: ${response.data}');
      }
    } catch (e) {
      debugPrint('[Mossy] Error calling function $functionName: $e');
      rethrow;
    }
  }

  /// Force enable demo mode (useful for testing or guest flow)
  void setDemoMode(bool enable) {
    _isDemoMode = enable;
  }
}
