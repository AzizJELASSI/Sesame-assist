// ─── SEASAME Assist-Pro — Agent Queue Screen ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/enums/department_filiere.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';

import '../../auth/controllers/auth_controller.dart';
import '../providers/agent_queue_provider.dart';

class AgentQueueScreen extends ConsumerStatefulWidget {
  const AgentQueueScreen({super.key});

  @override
  ConsumerState<AgentQueueScreen> createState() => _AgentQueueScreenState();
}

class _AgentQueueScreenState extends ConsumerState<AgentQueueScreen> {
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final queueState = ref.watch(agentQueueProvider);
    final filter = ref.watch(agentQueueFilterProvider);
    final selectedCount = queueState.selectedTicketIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agentQueue),
        actions: [
          // Filter toggle
          IconButton(
            icon: Badge(
              isLabelVisible: filter.department != null ||
                  filter.status != null ||
                  filter.priority != null,
              child: const Icon(Icons.filter_list_rounded),
            ),
            tooltip: l10n.filter,
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(agentQueueProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Bulk action bar ────────────────────────────────────────────────
          if (selectedCount > 0)
            _BulkActionBar(selectedCount: selectedCount)
                .animate()
                .slideY(begin: -0.5, end: 0, curve: Curves.easeOut, duration: 250.ms)
                .fadeIn(duration: 200.ms),

          // ── Filter panel ───────────────────────────────────────────────────
          if (_showFilters)
            _FilterPanel()
                .animate()
                .slideY(begin: -0.3, end: 0, curve: Curves.easeOut, duration: 250.ms)
                .fadeIn(duration: 200.ms),

          // ── Sort bar ───────────────────────────────────────────────────────
          _SortBar(filter: filter),

          // ── Ticket list ────────────────────────────────────────────────────
          Expanded(
            child: queueState.tickets.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 12),
                    Text('${l10n.error}: $e',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.read(agentQueueProvider.notifier).refresh(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 64, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(l10n.noTickets,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(agentQueueProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: tickets.length,
                    itemBuilder: (context, i) {
                      final ticket = tickets[i];
                      final isSelected = queueState.selectedTicketIds
                          .contains(ticket.id);
                      return _QueueTicketCard(
                        ticket: ticket,
                        isSelected: isSelected,
                        index: i,
                        onTap: () {
                          // If in selection mode, toggle; otherwise navigate
                          if (queueState.selectedTicketIds.isNotEmpty) {
                            ref
                                .read(agentQueueProvider.notifier)
                                .toggleSelection(ticket.id);
                          } else {
                            context.go(AppRoutes.ticketDetail(ticket.id));
                          }
                        },
                        onLongPress: () => ref
                            .read(agentQueueProvider.notifier)
                            .toggleSelection(ticket.id),
                        onCheckChanged: (_) => ref
                            .read(agentQueueProvider.notifier)
                            .toggleSelection(ticket.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bulk Action Bar ────────────────────────────────────────────────────────────
class _BulkActionBar extends ConsumerWidget {
  final int selectedCount;
  const _BulkActionBar({required this.selectedCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: scheme.onPrimaryContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.selectedCount(selectedCount),
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(agentQueueProvider.notifier).selectAll(),
            child: Text(l10n.selectAll,
                style: TextStyle(color: scheme.onPrimaryContainer)),
          ),
          TextButton(
            onPressed: () =>
                ref.read(agentQueueProvider.notifier).clearSelection(),
            child: Text(l10n.clearSelection,
                style: TextStyle(color: scheme.onPrimaryContainer)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.update_rounded, size: 18),
            label: Text(l10n.bulkUpdate),
            onPressed: () => _showBulkStatusSheet(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  void _showBulkStatusSheet(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final statuses = [
      ('open', l10n.statusOpen, Icons.radio_button_unchecked_rounded),
      ('in_progress', l10n.statusInProgress, Icons.timelapse_rounded),
      ('waiting_on_user', l10n.statusWaitingOnUser,
          Icons.hourglass_empty_rounded),
      ('resolved', l10n.statusResolved, Icons.check_circle_rounded),
      ('closed', l10n.statusClosed, Icons.cancel_rounded),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.bulkUpdateStatus,
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...statuses.map((s) {
                  final color = AppTheme.statusColor(s.$1);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(s.$3, color: color),
                    title: Text(s.$2,
                        style: TextStyle(color: color,
                            fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final ids =
                          ref.read(agentQueueProvider).selectedTicketIds;
                      await ref
                          .read(agentQueueProvider.notifier)
                          .bulkUpdateStatus(ids, s.$1);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Filter Panel ──────────────────────────────────────────────────────────────
class _FilterPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final filter = ref.watch(agentQueueFilterProvider);

    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Department filter
          _FilterChip<Department?>(
            label: filter.department?.label ?? l10n.allDepartments,
            isActive: filter.department != null,
            onTap: () => _showDeptPicker(context, ref, l10n, filter),
          ),
          // Status filter
          _FilterChip<String?>(
            label: _statusLabel(filter.status, l10n),
            isActive: filter.status != null,
            onTap: () => _showStatusPicker(context, ref, l10n, filter),
          ),
          // Priority filter
          _FilterChip<String?>(
            label: _priorityLabel(filter.priority, l10n),
            isActive: filter.priority != null,
            onTap: () => _showPriorityPicker(context, ref, l10n, filter),
          ),
          // Clear all
          if (filter.department != null ||
              filter.status != null ||
              filter.priority != null)
            ActionChip(
              avatar: const Icon(Icons.clear, size: 16),
              label: Text(l10n.clearSelection),
              onPressed: () => ref
                  .read(agentQueueFilterProvider.notifier)
                  .state = const AgentQueueFilter(),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String? status, AppLocalizations l10n) {
    if (status == null) return l10n.allStatuses;
    switch (status) {
      case 'open': return l10n.statusOpen;
      case 'in_progress': return l10n.statusInProgress;
      case 'waiting_on_user': return l10n.statusWaitingOnUser;
      case 'resolved': return l10n.statusResolved;
      case 'closed': return l10n.statusClosed;
      default: return status;
    }
  }

  String _priorityLabel(String? priority, AppLocalizations l10n) {
    if (priority == null) return l10n.allPriorities;
    switch (priority) {
      case 'high': return l10n.priorityHigh;
      case 'medium': return l10n.priorityMedium;
      case 'low': return l10n.priorityLow;
      default: return priority;
    }
  }

  void _showDeptPicker(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, AgentQueueFilter filter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filterByDepartment,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              title: Text(l10n.allDepartments),
              selected: filter.department == null,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(agentQueueFilterProvider.notifier).state =
                    filter.copyWith(clearDept: true);
              },
            ),
            ...Department.values.map((d) => ListTile(
                  title: Text(d.label),
                  selected: filter.department == d,
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(agentQueueFilterProvider.notifier).state =
                        filter.copyWith(department: d);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, AgentQueueFilter filter) {
    final statuses = [
      (null, l10n.allStatuses),
      ('open', l10n.statusOpen),
      ('in_progress', l10n.statusInProgress),
      ('waiting_on_user', l10n.statusWaitingOnUser),
      ('resolved', l10n.statusResolved),
      ('closed', l10n.statusClosed),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filterByStatus,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...statuses.map((s) => ListTile(
                  title: Text(s.$2),
                  selected: filter.status == s.$1,
                  leading: s.$1 != null
                      ? Icon(Icons.circle,
                          size: 12, color: AppTheme.statusColor(s.$1!))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(agentQueueFilterProvider.notifier).state = s.$1 == null
                        ? filter.copyWith(clearStatus: true)
                        : filter.copyWith(status: s.$1);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, AgentQueueFilter filter) {
    final priorities = [
      (null, l10n.allPriorities),
      ('high', l10n.priorityHigh),
      ('medium', l10n.priorityMedium),
      ('low', l10n.priorityLow),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filterByPriority,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...priorities.map((p) => ListTile(
                  title: Text(p.$2),
                  selected: filter.priority == p.$1,
                  leading: p.$1 != null
                      ? Icon(Icons.circle,
                          size: 12, color: AppTheme.priorityColor(p.$1!))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(agentQueueFilterProvider.notifier).state = p.$1 == null
                        ? filter.copyWith(clearPriority: true)
                        : filter.copyWith(priority: p.$1);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────────────────────
class _FilterChip<T> extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              Icon(Icons.check_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded,
                size: 18,
                color: isActive ? scheme.primary : scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Sort Bar ───────────────────────────────────────────────────────────────────
class _SortBar extends ConsumerWidget {
  final AgentQueueFilter filter;
  const _SortBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(l10n.sortBy,
              style: TextStyle(
                  fontSize: 13, color: scheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          ...QueueSortBy.values.map((s) {
            final isSelected = filter.sortBy == s;
            final label = switch (s) {
              QueueSortBy.newest => l10n.sortNewestFirst,
              QueueSortBy.oldest => l10n.sortOldestFirst,
              QueueSortBy.priority => l10n.sortByPriority,
            };
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(agentQueueFilterProvider.notifier).state =
                      filter.copyWith(sortBy: s);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Ticket Card ───────────────────────────────────────────────────────────────
class _QueueTicketCard extends StatelessWidget {
  final dynamic ticket; // Ticket model
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckChanged;

  const _QueueTicketCard({
    required this.ticket,
    required this.isSelected,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    required this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final priorityColor = AppTheme.priorityColor(ticket.priority as String);
    final statusColor = AppTheme.statusColor(ticket.status as String);
    final dateStr = DateFormat('MMM d, HH:mm')
        .format((ticket.createdAt as DateTime).toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primaryContainer.withValues(alpha: 0.5)
                : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Selection checkbox area
              SizedBox(
                width: 52,
                child: Checkbox(
                  value: isSelected,
                  onChanged: onCheckChanged,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              // Priority indicator stripe
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (ticket.status as String)
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            (ticket.department as Department?)?.icon ?? Icons.help_outline_rounded,
                            size: 12, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            (ticket.department as Department?)?.label ?? 'N/A',
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.schedule_rounded,
                              size: 12, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
              delay: Duration(milliseconds: index * 40), duration: 300.ms)
          .slideX(
              begin: 0.03,
              end: 0,
              delay: Duration(milliseconds: index * 40),
              curve: Curves.easeOut),
    );
  }
}
