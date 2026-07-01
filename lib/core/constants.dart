// ─── SEASAME Assist-Pro — Supabase Constants ──────────────────────────────────
// Replace the placeholder values below with your actual Supabase project credentials.
// You can find them at: https://app.supabase.com → Project Settings → API

class AppConstants {
  AppConstants._();

  // ── Supabase ────────────────────────────────────────────────────────────────
  // 🔐 Load these values from your .env file or environment at runtime.
  // Never commit real credentials to source control.
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-project.supabase.co');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_ANON_KEY');

  /// Service-role key — bypasses RLS; used ONLY for admin auth operations
  /// (creating/deleting auth users). Never expose this to regular users.
  static const String supabaseServiceRoleKey =
      String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'YOUR_SERVICE_ROLE_KEY');

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
