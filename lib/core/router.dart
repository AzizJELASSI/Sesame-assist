// ─── SEASAME Assist-Pro — GoRouter ────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_completion_screen.dart';
import '../features/dashboard/screens/student_dashboard.dart';
import '../features/dashboard/screens/teacher_dashboard.dart';
import '../features/dashboard/screens/agent_dashboard.dart';
import '../features/dashboard/screens/admin_dashboard.dart';
import '../features/shared/widgets/app_shell.dart';
import '../features/tickets/screens/ticket_list_screen.dart';
import '../features/tickets/screens/ticket_create_screen.dart';
import '../features/tickets/screens/ticket_detail_screen.dart';
import '../features/tickets/screens/ai_ticket_chat_screen.dart';
import '../features/admin/screens/user_management_screen.dart';
import '../features/admin/screens/department_management_screen.dart';
import '../features/admin/screens/system_stats_screen.dart';
import '../features/agents/screens/agent_queue_screen.dart';
import '../features/admin/screens/sla_management_screen.dart';


// ── Route paths ───────────────────────────────────────────────────────────────
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String completeProfile = '/complete-profile';
  static const String dashboard = '/dashboard';
  static const String tickets = '/tickets';
  static const String ticketNew = '/tickets/new';
  static const String ticketAiChat = '/tickets/ai-chat';
  static String ticketDetail(String id) => '/tickets/$id';
  static const String agentQueue = '/agent-queue';
  static const String adminUsers = '/admin/users';
  static const String adminDepartments = '/admin/departments';
  static const String adminStats = '/admin/stats';
  static const String adminReports = '/admin/reports';
  static const String adminSla = '/admin/sla';
}

// ── Router provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final authValue = authState.valueOrNull;
      final isAuthenticated = authValue?.isAuthenticated ?? false;
      final profile = authValue?.profile;

      final isOnAuthPage = state.matchedLocation == AppRoutes.login;
      final isOnCompleteProfile =
          state.matchedLocation == AppRoutes.completeProfile;

      // Unauthenticated → login
      if (!isAuthenticated && !isOnAuthPage) return AppRoutes.login;

      // Authenticated on login → send somewhere useful
      if (isAuthenticated && isOnAuthPage) {
        final needsCompletion = profile == null ||
            (profile.fullName == null || profile.fullName!.trim().isEmpty);
        return needsCompletion ? AppRoutes.completeProfile : AppRoutes.dashboard;
      }

      // Authenticated but profile incomplete → must complete profile first
      if (isAuthenticated && !isOnCompleteProfile) {
        final needsCompletion = profile == null ||
            (profile.fullName == null || profile.fullName!.trim().isEmpty);
        if (needsCompletion) return AppRoutes.completeProfile;
      }

      // Profile complete, no need to stay on completion screen
      if (isAuthenticated && isOnCompleteProfile) {
        final needsCompletion = profile == null ||
            (profile.fullName == null || profile.fullName!.trim().isEmpty);
        if (!needsCompletion) return AppRoutes.dashboard;
      }

      // Splash with full auth
      if (isAuthenticated && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.dashboard;
      }

      // Non-admin trying to access admin routes
      if (profile != null &&
          !profile.isAdmin &&
          state.matchedLocation.startsWith('/admin')) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // ── Splash (no shell) ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),

      // ── Auth (no shell) ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),

      // ── Authenticated shell — sidebar wraps everything inside ────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Dashboard (role-adaptive)
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const _RoleDashboardWrapper(),
          ),

          // Tickets
          GoRoute(
            path: AppRoutes.tickets,
            builder: (context, state) => const TicketListScreen(),
          ),
          GoRoute(
            path: AppRoutes.ticketNew,
            builder: (context, state) => const TicketCreateScreen(),
          ),
          GoRoute(
            path: AppRoutes.ticketAiChat,
            builder: (context, state) => const AiTicketChatScreen(),
          ),
          GoRoute(
            path: '/tickets/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TicketDetailScreen(ticketId: id);
            },
          ),

          // Agent
          GoRoute(
            path: AppRoutes.agentQueue,
            builder: (context, state) => const AgentQueueScreen(),
          ),

          // Admin
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminDepartments,
            builder: (context, state) => const DepartmentManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminStats,
            builder: (context, state) => const SystemStatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminSla,
            builder: (context, state) => const SlaManagementScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ── Splash screen ─────────────────────────────────────────────────────────────
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ── Role-adaptive dashboard wrapper ──────────────────────────────────────────
class _RoleDashboardWrapper extends ConsumerWidget {
  const _RoleDashboardWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return switch (profile.role) {
      'admin' => const AdminDashboard(),
      'agent' => const AgentDashboard(),
      'teacher' => const TeacherDashboard(),
      _ => const StudentDashboard(),
    };
  }
}
