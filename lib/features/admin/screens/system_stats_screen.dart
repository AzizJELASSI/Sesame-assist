// ─── SEASAME Assist-Pro — System Stats Screen ─────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/department_filiere.dart';
import '../../../core/supabase_client.dart';
import '../../../core/theme.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';


// ── Stats model ────────────────────────────────────────────────────────────────
class SystemStatsData {
  final int totalTickets;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final int closedTickets;
  final int totalUsers;
  final int totalAgents;
  final Map<String, int> byDepartment;
  final Map<String, int> byPriority;

  const SystemStatsData({
    required this.totalTickets,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.closedTickets,
    required this.totalUsers,
    required this.totalAgents,
    required this.byDepartment,
    required this.byPriority,
  });

  int get activeTickets => openTickets + inProgressTickets;
  double get resolutionRate =>
      totalTickets == 0 ? 0 : (resolvedTickets + closedTickets) / totalTickets;
}

// ── Provider ───────────────────────────────────────────────────────────────────
final systemStatsProvider = FutureProvider<SystemStatsData>((ref) async {
  final ticketsFuture = SupabaseService.client
      .from('tickets')
      .select('status, priority, department_id');

  final usersFuture = SupabaseService.client
      .from('profiles')
      .select('role');

  final results = await Future.wait([ticketsFuture, usersFuture]);

  final tickets = results[0] as List;
  final users = results[1] as List;

  // Ticket stats
  int open = 0, inProgress = 0, resolved = 0, closed = 0;
  final byDept = <String, int>{};
  final byPriority = <String, int>{};

  for (final t in tickets) {
    final status = t['status'] as String? ?? 'open';
    final dept = t['department_id'] as String? ?? 'unknown';
    final priority = t['priority'] as String? ?? 'medium';

    switch (status) {
      case 'open': open++; break;
      case 'in_progress': inProgress++; break;
      case 'resolved': resolved++; break;
      case 'closed': closed++; break;
    }
    byDept[dept] = (byDept[dept] ?? 0) + 1;
    byPriority[priority] = (byPriority[priority] ?? 0) + 1;
  }

  // User stats
  int agents = 0;
  for (final u in users) {
    if (u['role'] == 'agent') agents++;
  }

  return SystemStatsData(
    totalTickets: tickets.length,
    openTickets: open,
    inProgressTickets: inProgress,
    resolvedTickets: resolved,
    closedTickets: closed,
    totalUsers: users.length,
    totalAgents: agents,
    byDepartment: byDept,
    byPriority: byPriority,
  );
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class SystemStatsScreen extends ConsumerWidget {
  const SystemStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(systemStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.systemStats),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(systemStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              const SizedBox(height: 12),
              Text('${l10n.error}: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(systemStatsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (stats) => _StatsContent(stats: stats, l10n: l10n),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final SystemStatsData stats;
  final AppLocalizations l10n;
  const _StatsContent({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Overview Header ──────────────────────────────────────────────────
          Text(l10n.systemOverview,
              style: Theme.of(context).textTheme.titleMedium)
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),

          // ── Top stat cards ───────────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _StatCard(
                label: l10n.totalTickets,
                value: stats.totalTickets.toString(),
                icon: Icons.confirmation_number_rounded,
                color: scheme.primary,
                delay: 100,
              ),
              _StatCard(
                label: l10n.activeTickets,
                value: stats.activeTickets.toString(),
                icon: Icons.timelapse_rounded,
                color: AppTheme.statusColor('in_progress'),
                delay: 160,
              ),
              _StatCard(
                label: l10n.resolvedTickets,
                value: stats.resolvedTickets.toString(),
                icon: Icons.check_circle_rounded,
                color: AppTheme.statusColor('resolved'),
                delay: 220,
              ),
              _StatCard(
                label: l10n.closedTickets,
                value: stats.closedTickets.toString(),
                icon: Icons.cancel_rounded,
                color: AppTheme.statusColor('closed'),
                delay: 280,
              ),
              _StatCard(
                label: l10n.totalUsers,
                value: stats.totalUsers.toString(),
                icon: Icons.people_rounded,
                color: const Color(0xFF6366F1),
                delay: 340,
              ),
              _StatCard(
                label: l10n.totalAgents,
                value: stats.totalAgents.toString(),
                icon: Icons.support_agent_rounded,
                color: AppTheme.roleColor('agent'),
                delay: 400,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Resolution rate ──────────────────────────────────────────────────
          _ResolutionRateCard(stats: stats, l10n: l10n),

          const SizedBox(height: 24),

          // ── By Priority ──────────────────────────────────────────────────────
          Text(l10n.filterByPriority,
              style: Theme.of(context).textTheme.titleMedium)
              .animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 12),
          _BreakdownCard(
            items: [
              _BreakdownItem(
                  label: l10n.priorityHigh,
                  count: stats.byPriority['high'] ?? 0,
                  total: stats.totalTickets,
                  color: AppTheme.priorityColor('high')),
              _BreakdownItem(
                  label: l10n.priorityMedium,
                  count: stats.byPriority['medium'] ?? 0,
                  total: stats.totalTickets,
                  color: AppTheme.priorityColor('medium')),
              _BreakdownItem(
                  label: l10n.priorityLow,
                  count: stats.byPriority['low'] ?? 0,
                  total: stats.totalTickets,
                  color: AppTheme.priorityColor('low')),
            ],
            delay: 520,
          ),

          const SizedBox(height: 24),

          // ── By Department ────────────────────────────────────────────────────
          Text(l10n.departmentBreakdown,
              style: Theme.of(context).textTheme.titleMedium)
              .animate().fadeIn(delay: 600.ms, duration: 400.ms),
          const SizedBox(height: 12),
          _BreakdownCard(
            items: Department.values.map((d) => _BreakdownItem(
              label: d.label,
              count: stats.byDepartment[d.name] ?? 0,
              total: stats.totalTickets,
              color: scheme.primary,
            )).toList(),
            delay: 640,
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(
            begin: 0.1,
            end: 0,
            delay: Duration(milliseconds: delay),
            curve: Curves.easeOut);
  }
}

// ── Resolution Rate Card ───────────────────────────────────────────────────────
class _ResolutionRateCard extends StatelessWidget {
  final SystemStatsData stats;
  final AppLocalizations l10n;
  const _ResolutionRateCard({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (stats.resolutionRate * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Resolution Rate',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('$pct%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.statusColor('resolved'),
                    )),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: stats.resolutionRate,
                          minHeight: 10,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: AppTheme.statusColor('resolved'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.resolvedTickets + stats.closedTickets} / ${stats.totalTickets} tickets resolved',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 460.ms, duration: 400.ms);
  }
}

// ── Breakdown Card ────────────────────────────────────────────────────────────
class _BreakdownItem {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _BreakdownItem(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});
}

class _BreakdownCard extends StatelessWidget {
  final List<_BreakdownItem> items;
  final int delay;
  const _BreakdownCard({required this.items, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) {
            final pct = item.total == 0 ? 0.0 : item.count / item.total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Text(item.label,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor:
                            scheme.surfaceContainerHighest,
                        color: item.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 32,
                    child: Text(
                      item.count.toString(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}
