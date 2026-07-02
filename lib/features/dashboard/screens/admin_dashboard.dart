// ─── SEASAME Assist-Pro — Admin Dashboard ─────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../shared/widgets/dashboard_scaffold.dart';
import '../../tickets/controllers/ticket_controller.dart';
import '../../sla/widgets/sla_breach_list.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final ticketsAsync = ref.watch(allTicketsProvider);

    final totalTickets = ticketsAsync.valueOrNull?.length ?? 0;
    final openTickets = ticketsAsync.valueOrNull
            ?.where((t) => t.status == 'open')
            .length ??
        0;
    final inProgressTickets = ticketsAsync.valueOrNull
            ?.where((t) => t.status == 'in_progress')
            .length ??
        0;
    final resolvedTickets =
        ticketsAsync.valueOrNull?.where((t) => t.isResolved).length ?? 0;
    final highPriority = ticketsAsync.valueOrNull
            ?.where((t) => t.isHighPriority && !t.isResolved)
            .length ??
        0;

    return DashboardScaffold(
      title: 'Admin Panel',
      selectedIndex: _selectedIndex,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard_rounded),
          label: l10n.dashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.confirmation_number_outlined),
          selectedIcon: const Icon(Icons.confirmation_number_rounded),
          label: l10n.allTickets,
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_outline_rounded),
          selectedIcon: const Icon(Icons.people_rounded),
          label: l10n.users,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: l10n.reports,
        ),
      ],
      onDestinationSelected: (i) {
        setState(() => _selectedIndex = i);
        if (i == 1) context.go(AppRoutes.tickets);
        if (i == 2) context.go(AppRoutes.adminUsers);
        if (i == 3) context.go(AppRoutes.adminStats);
      },
      children: [
        // ── Greeting ────────────────────────────────────────────────────────────
        Text(
          'System Overview 🏫',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 4),
        Text(
          'Admin: ${profile?.displayName ?? ''}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 28),

        // ── Stats ───────────────────────────────────────────────────────────────
        Text('Platform Statistics', style: Theme.of(context).textTheme.titleMedium)
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 600 ? 3 : 2;
            return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 3 ? 2.4 : 2.2,
          children: [
            StatCard(
              label: l10n.totalTickets,
              value: totalTickets.toString(),
              icon: Icons.confirmation_number_rounded,
              color: scheme.primary,
              animationDelay: 200,
            ),
            StatCard(
              label: l10n.openTickets,
              value: openTickets.toString(),
              icon: Icons.fiber_new_rounded,
              color: AppTheme.statusColor('open'),
              animationDelay: 280,
            ),
            StatCard(
              label: 'In Progress',
              value: inProgressTickets.toString(),
              icon: Icons.timelapse_rounded,
              color: AppTheme.statusColor('in_progress'),
              animationDelay: 360,
            ),
            StatCard(
              label: 'High Priority',
              value: highPriority.toString(),
              icon: Icons.warning_amber_rounded,
              color: AppTheme.priorityColor('high'),
              animationDelay: 440,
            ),
            StatCard(
              label: l10n.resolvedTickets,
              value: resolvedTickets.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.statusColor('resolved'),
              animationDelay: 520,
            ),
            StatCard(
              label: 'Departments',
              value: '6',
              icon: Icons.business_rounded,
              color: const Color(0xFF6366F1),
              animationDelay: 600,
            ),
          ],
        );
          },
        ),

        const SizedBox(height: 28),

        // ── SLA Alerts ──────────────────────────────────────────────────────────
        const SlaBreachList()
            .animate()
            .fadeIn(delay: 620.ms, duration: 400.ms),

        const SizedBox(height: 28),

        Text('Administration', style: Theme.of(context).textTheme.titleMedium)
            .animate()
            .fadeIn(delay: 650.ms, duration: 400.ms),
        const SizedBox(height: 12),

        QuickActionTile(
          icon: Icons.people_rounded,
          label: l10n.users,
          subtitle: 'Manage roles and permissions',
          color: scheme.primary,
          onTap: () => context.go(AppRoutes.adminUsers),
          animationDelay: 700,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.confirmation_number_rounded,
          label: l10n.allTickets,
          subtitle: 'Monitor all tickets system-wide',
          color: AppTheme.statusColor('open'),
          onTap: () => context.go(AppRoutes.tickets),
          animationDelay: 780,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.apartment_rounded,
          label: l10n.departmentManagement,
          subtitle: 'View and manage departments',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.go(AppRoutes.adminDepartments),
          animationDelay: 860,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.bar_chart_rounded,
          label: l10n.systemStats,
          subtitle: 'Platform performance overview',
          color: const Color(0xFF10B981),
          onTap: () => context.go(AppRoutes.adminStats),
          animationDelay: 940,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.timer_rounded,
          label: 'SLA Management',
          subtitle: 'Configure response & resolution targets',
          color: const Color(0xFFF59E0B),
          onTap: () => context.go(AppRoutes.adminSla),
          animationDelay: 1020,
        ),
      ],
    );
  }
}
