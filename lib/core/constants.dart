// ─── SEASAME Assist-Pro — Supabase Constants ──────────────────────────────────
// Credentials are sourced from the .env file (already gitignored).
// String.fromEnvironment only works with --dart-define at compile time,
// so we embed them directly here for development builds.

class AppConstants {
  AppConstants._();

  // ── Supabase ────────────────────────────────────────────────────────────────
  static const String supabaseUrl =
      'https://gxthnubxezqvnblcewqo.supabase.co';
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY');

  /// Service-role key — bypasses RLS; used ONLY for admin auth operations
  /// (creating/deleting auth users). Never expose this to regular users.
  static const String supabaseServiceRoleKey =
      String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'YOUR_SUPABASE_SERVICE_ROLE_KEY');

  // ── Storage buckets ─────────────────────────────────────────────────────────
  static const String attachmentsBucket = 'ticket-attachments';

  // ── Edge Functions ───────────────────────────────────────────────────────────
  static const String edgeFnProcessTicket = 'process-ticket-intent';
  static const String edgeFnGenerateReport = 'generate-report';

  // ── Pagination ───────────────────────────────────────────────────────────────
  static const int ticketsPageSize = 20;

  // ── Supported locales ────────────────────────────────────────────────────────
  static const List<String> supportedLocaleCodes = ['en', 'fr', 'ar'];
}
