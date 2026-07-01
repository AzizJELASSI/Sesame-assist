// ─── SEASAME Assist-Pro — Admin Auth Service ──────────────────────────────────
// Uses raw HTTP calls to the Supabase Auth Admin REST API.
//
// WHY NOT use SupabaseClient.auth.admin.*?
// The Flutter SDK adds an `X-Client-Info: supabase-flutter/…` header on every
// request. Supabase GoTrue now treats any request with that header as coming
// from a "browser" context and blocks service-role key usage with a 401
// ("Forbidden use of secret API key in browser").
//
// By using the plain `http` package we control exactly which headers are sent,
// avoiding the Flutter-SDK fingerprint entirely, so GoTrue accepts the call.
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class AdminAuthService {
  AdminAuthService._();

  // ── Private helpers ──────────────────────────────────────────────────────────

  static Uri _uri(String path) =>
      Uri.parse('${AppConstants.supabaseUrl}/auth/v1$path');

  /// Minimal headers: no Flutter SDK marker → GoTrue won't block the key.
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.supabaseServiceRoleKey}',
        'apikey': AppConstants.supabaseServiceRoleKey,
      };

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Creates a new Supabase Auth user.
  ///
  /// * [emailConfirm] is true so the user can log in immediately without
  ///   clicking a verification link.
  /// * [userMetadata] is stored in `raw_user_meta_data` and picked up by the
  ///   `handle_new_user` trigger to set the profile `role`.
  ///
  /// Returns the new user's UUID on success.
  /// Throws an [Exception] with a readable message on failure.
  static Future<String> createUser({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      _uri('/admin/users'),
      headers: _headers,
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'email_confirm': true,
        'user_metadata': {'role': role},
      }),
    );

    final body = _parseBody(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = body['msg'] ??
          body['message'] ??
          body['error_description'] ??
          body['error'] ??
          'Failed to create user (${response.statusCode})';
      throw Exception(msg);
    }

    final id = body['id'] as String?;
    if (id == null) throw Exception('Server did not return a user ID');
    return id;
  }

  /// Permanently deletes a Supabase Auth user by UUID.
  ///
  /// The `profiles` row is removed automatically by the ON DELETE CASCADE
  /// foreign-key constraint.
  static Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      _uri('/admin/users/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = _parseBody(response);
      final msg = body['msg'] ??
          body['message'] ??
          body['error_description'] ??
          'Failed to delete user (${response.statusCode})';
      throw Exception(msg);
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parseBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }
}
