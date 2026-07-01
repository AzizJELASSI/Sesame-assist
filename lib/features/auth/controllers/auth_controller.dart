// ─── SEASAME Assist-Pro — Auth Controller ─────────────────────────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/profile.dart';
import '../../../core/supabase_client.dart';
import '../../../core/enums/department_filiere.dart';

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final User? user;
  final Profile? profile;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && profile != null;

  AuthState copyWith({
    User? user,
    Profile? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      profile: clearUser ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Listen to Supabase auth changes and refresh state
    ref.onDispose(
      SupabaseService.authStateChanges.listen((event) {
        if (event.event == AuthChangeEvent.signedIn) {
          _refreshProfile();
        } else if (event.event == AuthChangeEvent.signedOut) {
          state = AsyncData(const AuthState());
        }
      }).cancel,
    );

    // Initial state: load profile if already signed in
    final user = SupabaseService.currentUser;
    if (user == null) return const AuthState();

    final profile = await _fetchProfile(user.id);
    return AuthState(user: user, profile: profile);
  }

  // ── Sign in ───────────────────────────────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AsyncData(
      state.valueOrNull?.copyWith(isLoading: true, clearError: true) ??
          const AuthState(isLoading: true),
    );

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('Sign in failed: no user returned');

      final profile = await _fetchProfile(user.id);
      state = AsyncData(AuthState(user: user, profile: profile));
    } on AuthException catch (e) {
      state = AsyncData(
        AuthState(error: e.message),
      );
    } catch (e) {
      state = AsyncData(
        AuthState(error: e.toString()),
      );
    }
  }

  // ── Update profile (used after first login to complete profile) ───────────────
  Future<void> updateProfile({
    required String fullName,
    Department? department,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    state = AsyncData(
      state.valueOrNull?.copyWith(isLoading: true, clearError: true) ??
          const AuthState(isLoading: true),
    );

    try {
      await SupabaseService.client.from('profiles').update({
        'full_name': fullName.trim(),
        'department_id': department?.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      final profile = await _fetchProfile(user.id);
      state = AsyncData(AuthState(user: user, profile: profile));
    } catch (e) {
      state = AsyncData(
        state.valueOrNull?.copyWith(
              isLoading: false,
              error: e.toString(),
            ) ??
            AuthState(error: e.toString()),
      );
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    state = const AsyncData(AuthState());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Future<void> _refreshProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final profile = await _fetchProfile(user.id);
    state = AsyncData(AuthState(user: user, profile: profile));
  }

  Future<Profile?> _fetchProfile(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) {
        throw Exception('Profile not found. The user account exists but the profile record is missing. Please sign up again or contact an administrator.');
      }
      return Profile.fromJson(data);
    } catch (e, st) {
      print('Error fetching profile: $e\n$st');
      throw Exception('Failed to fetch profile: $e');
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience provider: current profile (null if not authenticated)
final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull?.profile;
});

/// Convenience provider: is user authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).valueOrNull?.isAuthenticated ?? false;
});
