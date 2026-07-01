// ─── SEASAME Assist-Pro — Supabase Client Singleton ───────────────────────────
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

/// Call [SupabaseService.initialize] once inside [main] before [runApp].
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
    _initialized = true;
  }

  /// Shorthand accessor for the regular (anon-key) [SupabaseClient].
  static SupabaseClient get client => Supabase.instance.client;

  /// Currently authenticated user, or null if signed out.
  static User? get currentUser => client.auth.currentUser;

  /// Auth state change stream.
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ── Admin client (service-role key) ────────────────────────────────────────
  /// A separate [SupabaseClient] initialised with the service-role key.
  /// Use ONLY for admin Auth operations: [auth.admin.createUser] /
  /// [auth.admin.deleteUser].  Never use this client for regular data queries.
  static SupabaseClient? _adminClient;
  static SupabaseClient get adminClient {
    _adminClient ??= SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseServiceRoleKey,
    );
    return _adminClient!;
  }
}
