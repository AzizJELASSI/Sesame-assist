// ─── SEASAME Assist-Pro — Agent Dashboard ─────────────────────────────────────
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

class AgentDashboard extends ConsumerStatefulWidget {
  const AgentDashboard({super.key});

  @override
  ConsumerState<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends ConsumerState<AgentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final ticketsAsync = ref.watch(departmentTicketsProvider);

    final totalTickets = ticketsAsync.valueOrNull?.length ?? 0;
    final openTickets = ticketsAsync.valueOrNull
            ?.where((t) => t.status == 'open')
            .length ??
        0;
    final inProgressTickets = ticketsAsync.valueOrNull
            ?.where((t) => t.status == 'in_progress')
            .length ??
        0;
    final highPriority = ticketsAsync.valueOrNull
            ?.where((t) => t.isHighPriority && !t.isResolved)
            .length ??
        0;

    return DashboardScaffold(
      title: l10n.queue,
      selectedIndex: _selectedIndex,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.dashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.inbox_outlined),
          selectedIcon: const Icon(Icons.inbox_rounded),
          label: l10n.queue,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: l10n.reports,
        ),
      ],
      onDestinationSelected: (i) {
        setState(() => _selectedIndex = i);
        if (i == 1) context.go(AppRoutes.agentQueue);
      },
      children: [
        // ── Greeting ────────────────────────────────────────────────────────────
        Text(
          'Agent Portal 🎯',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 4),
        Text(
          'Hello, ${profile?.displayName ?? ''} — your queue',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 28),

        // ── Stats grid ──────────────────────────────────────────────────────────
        Text('Department Queue', style: Theme.of(context).textTheme.titleMedium)
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 600 ? 4 : 2;
            return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 4 ? 2.6 : 2.4,
          children: [
            StatCard(
              label: 'Total in Queue',
              value: totalTickets.toString(),
              icon: Icons.inbox_rounded,
              color: scheme.primary,
              animationDelay: 200,
            ),
            StatCard(
              label: 'Unassigned',
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
          ],
        );
          },
        ),

        const SizedBox(height: 28),

        Text('Actions', style: Theme.of(context).textTheme.titleMedium)
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms),
        const SizedBox(height: 12),

        QuickActionTile(
          icon: Icons.queue_rounded,
          label: 'Agent Queue',
          subtitle: 'Filter, sort and bulk update tickets',
          color: scheme.primary,
          onTap: () => context.go(AppRoutes.agentQueue),
          animationDelay: 560,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.warning_amber_rounded,
          label: 'High Priority Queue',
          subtitle: '$highPriority tickets need attention',
          color: AppTheme.priorityColor('high'),
          onTap: () => context.go(AppRoutes.agentQueue),
          animationDelay: 640,
        ),
      ],
    );
  }
}
