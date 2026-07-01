// ─── SEASAME Assist-Pro — Ticket List Screen ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ticket.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/ticket_controller.dart';
import '../widgets/ticket_card.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  String _searchQuery = '';
  String? _statusFilter;
  String? _priorityFilter;

  List<Ticket> _filterTickets(List<Ticket> tickets) {
    return tickets.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == null || t.status == _statusFilter;
      final matchesPriority =
          _priorityFilter == null || t.priority == _priorityFilter;
      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(currentProfileProvider);

    // Use the appropriate provider based on role
    final AsyncValue<List<Ticket>> ticketsAsync;
    if (profile?.isAdmin == true) {
      ticketsAsync = ref.watch(allTicketsProvider);
    } else if (profile?.isAgent == true) {
      ticketsAsync = ref.watch(departmentTicketsProvider);
    } else {
      ticketsAsync = ref.watch(myTicketsProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.canManageTickets == true
            ? l10n.allTickets
            : l10n.myTickets),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, l10n, scheme),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'manual_ticket',
            onPressed: () => context.push(AppRoutes.ticketNew),
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(Icons.edit_rounded, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ai_ticket',
            onPressed: () => context.push(AppRoutes.ticketAiChat),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('AI Assistant'),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1, end: 0, curve: Curves.easeOut),

          // ── Filter chips ──────────────────────────────────────────────────────
          if (_statusFilter != null || _priorityFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_statusFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_statusFilter!.replaceAll('_', ' ')),
                        selected: true,
                        onSelected: (_) =>
                            setState(() => _statusFilter = null),
                        selectedColor:
                            AppTheme.statusColor(_statusFilter!).withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: AppTheme.statusColor(_statusFilter!),
                        ),
                      ),
                    ),
                  if (_priorityFilter != null)
                    FilterChip(
                      label: Text(_priorityFilter!),
                      selected: true,
                      onSelected: (_) =>
                          setState(() => _priorityFilter = null),
                      selectedColor: AppTheme.priorityColor(_priorityFilter!)
                          .withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: AppTheme.priorityColor(_priorityFilter!),
                      ),
                    ),
                ],
              ),
            ),

          // ── Ticket list ───────────────────────────────────────────────────────
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: scheme.error),
                    const SizedBox(height: 12),
                    Text(l10n.error),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        if (profile?.isAdmin == true) {
                          ref.invalidate(allTicketsProvider);
                        } else if (profile?.isAgent == true) {
                          ref.invalidate(departmentTicketsProvider);
                        } else {
                          ref.invalidate(myTicketsProvider);
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (tickets) {
                final filtered = _filterTickets(tickets);
                if (filtered.isEmpty) {
                  return _EmptyState(l10n: l10n, scheme: scheme);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    if (profile?.isAdmin == true) {
                      ref.invalidate(allTicketsProvider);
                    } else if (profile?.isAgent == true) {
                      ref.invalidate(departmentTicketsProvider);
                    } else {
                      ref.invalidate(myTicketsProvider);
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => TicketCard(
                      ticket: filtered[i],
                      animationIndex: i,
                      onTap: () => context.push(
                        AppRoutes.ticketDetail(filtered[i].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.filter,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),

              Text('Status', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['open', 'in_progress', 'waiting_on_user', 'resolved', 'closed']
                    .map((s) => FilterChip(
                          label: Text(s.replaceAll('_', ' ')),
                          selected: _statusFilter == s,
                          onSelected: (v) {
                            setModalState(() {});
                            setState(() =>
                                _statusFilter = v ? s : null);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['low', 'medium', 'high']
                    .map((p) => FilterChip(
                          label: Text(p),
                          selected: _priorityFilter == p,
                          onSelected: (v) {
                            setModalState(() {});
                            setState(() =>
                                _priorityFilter = v ? p : null);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final ColorScheme scheme;
  const _EmptyState({required this.l10n, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 40,
              color: scheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.noTickets,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            l10n.noTicketsHint,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
        );
  }
}
