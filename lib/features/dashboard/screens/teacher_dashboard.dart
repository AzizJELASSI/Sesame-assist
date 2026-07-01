// ─── SEASAME Assist-Pro — Teacher Dashboard ───────────────────────────────────
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

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final ticketsAsync = ref.watch(myTicketsProvider);

    final totalTickets = ticketsAsync.valueOrNull?.length ?? 0;
    final openTickets = ticketsAsync.valueOrNull
            ?.where((t) => t.status == 'open' || t.status == 'in_progress')
            .length ??
        0;
    final highPriority = ticketsAsync.valueOrNull
            ?.where((t) => t.isHighPriority && !t.isResolved)
            .length ??
        0;
    final resolvedTickets =
        ticketsAsync.valueOrNull?.where((t) => t.isResolved).length ?? 0;

    return DashboardScaffold(
      title: l10n.dashboard,
      selectedIndex: _selectedIndex,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.dashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.confirmation_number_outlined),
          selectedIcon: const Icon(Icons.confirmation_number_rounded),
          label: l10n.myTickets,
        ),
      ],
      onDestinationSelected: (i) {
        setState(() => _selectedIndex = i);
        if (i == 1) context.go(AppRoutes.tickets);
      },
      fab: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.ticketNew),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newTicket),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      children: [
        // ── Greeting ────────────────────────────────────────────────────────────
        Text(
          'Welcome back, ${profile?.displayName ?? ''} 👨‍🏫',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 4),
        Text(
          'Faculty Support Portal',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 28),

        // ── Stats grid ──────────────────────────────────────────────────────────
        Text('Overview', style: Theme.of(context).textTheme.titleMedium)
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
              label: l10n.totalTickets,
              value: totalTickets.toString(),
              icon: Icons.confirmation_number_rounded,
              color: scheme.primary,
              animationDelay: 200,
            ),
            StatCard(
              label: l10n.openTickets,
              value: openTickets.toString(),
              icon: Icons.pending_rounded,
              color: AppTheme.statusColor('open'),
              animationDelay: 280,
            ),
            StatCard(
              label: 'High Priority',
              value: highPriority.toString(),
              icon: Icons.priority_high_rounded,
              color: AppTheme.priorityColor('high'),
              animationDelay: 360,
            ),
            StatCard(
              label: l10n.resolvedTickets,
              value: resolvedTickets.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.statusColor('resolved'),
              animationDelay: 440,
            ),
          ],
        );
          },
        ),

        const SizedBox(height: 28),

        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium)
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms),
        const SizedBox(height: 12),

        QuickActionTile(
          icon: Icons.auto_awesome_rounded,
          label: 'AI Assistant',
          subtitle: 'Let AI help draft your ticket',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.go(AppRoutes.ticketAiChat),
          animationDelay: 560,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.computer_rounded,
          label: 'Report Classroom IT Issue',
          subtitle: 'Projector, PC, connectivity problems',
          color: AppTheme.statusColor('open'),
          onTap: () => context.go(AppRoutes.ticketNew),
          animationDelay: 640,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.meeting_room_outlined,
          label: 'Facility Maintenance',
          subtitle: 'Room, equipment, infrastructure',
          color: AppTheme.priorityColor('medium'),
          onTap: () => context.go(AppRoutes.ticketNew),
          animationDelay: 640,
        ),
        const SizedBox(height: 8),
        QuickActionTile(
          icon: Icons.people_outline_rounded,
          label: 'HR Request',
          subtitle: 'Leave, contract, administrative',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.go(AppRoutes.ticketNew),
          animationDelay: 720,
        ),
      ],
    );
  }
}
