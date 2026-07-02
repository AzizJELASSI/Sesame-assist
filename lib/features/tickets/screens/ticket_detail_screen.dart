// ─── SEASAME Assist-Pro — Ticket Detail Screen ────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/ticket.dart';
import '../../../core/theme.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/ticket_controller.dart';
import '../widgets/attachment_tile.dart';
import '../widgets/comment_thread.dart';
import '../../agents/providers/agent_queue_provider.dart';
import '../../agents/providers/agents_list_provider.dart';
import '../widgets/ticket_card.dart';
import '../../sla/widgets/sla_badge.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ticketTitle), // "Title" or "Ticket Details" fallback? Wait, in EN arb there's "ticketTitle". Actually let's use l10n.ticketTitle or just keep it simple. Let's look for "ticketDetails" in ARB. Wait, it doesn't exist. I'll use "Ticket Details" literal if needed, but wait, l10n.ticketTitle is 'Title'. No, "Ticket Details" wasn't localized, so I will leave it or add it. I'll add "Ticket Details" and "Update Status" to ARBs later or use literal. I'll use l10n.updateStatus for tooltip.
        actions: [
          if (profile?.canManageTickets == true)
            ticketAsync.whenOrNull(
              data: (ticket) => IconButton(
                tooltip: l10n.updateStatus,
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _showStatusSheet(context, ref, ticket, l10n),
              ),
            ) ?? const SizedBox.shrink(),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading ticket: $e')),
        data: (ticket) {
          final priorityColor = AppTheme.priorityColor(ticket.priority);
          final statusColor = AppTheme.statusColor(ticket.status);
          final dateStr = DateFormat('MMM d, yyyy • HH:mm').format(ticket.createdAt.toLocal());
          final resolvedStr = ticket.resolvedAt != null
              ? DateFormat('MMM d, yyyy • HH:mm').format(ticket.resolvedAt!.toLocal())
              : null;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Status/Priority header ───────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: priorityColor),
                        const SizedBox(width: 6),
                        Text(
                          ticket.priority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      ticket.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),

              // ── SLA Badge ────────────────────────────────────────────────
              if (ticket.slaResolutionDueAt != null) ...[
                SlaBadge(ticket: ticket, expanded: true)
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 400.ms),
                const SizedBox(height: 20),
              ],

              // ── Title & Meta ────────────────────────────────────────────────
              Text(
                ticket.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _MetaItem(
                    icon: Icons.business_rounded,
                    label: ticket.department.label,
                    scheme: scheme,
                  ),
                  _MetaItem(
                    icon: Icons.calendar_today_rounded,
                    label: dateStr,
                    scheme: scheme,
                  ),
                  _MetaItem(
                    icon: Icons.category_rounded,
                    label: ticket.ticketType.replaceAll('_', ' '),
                    scheme: scheme,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // ── Description ─────────────────────────────────────────────────
              Text('Description', style: Theme.of(context).textTheme.titleSmall)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 24),
              
              // ── Creator / Assignee ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _UserRow(
                      label: l10n.ticketCreatedBy,
                      name: ticket.creatorName ?? 'Unknown User',
                      scheme: scheme,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    _UserRow(
                      label: l10n.ticketAssignedTo,
                      name: ticket.assigneeName ?? 'Unassigned',
                      scheme: scheme,
                      isEmpty: ticket.assigneeName == null,
                    ),
                    if (ticket.assignedTo != profile?.id && profile?.isAgent == true) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Assign to me'),
                          onPressed: () async {
                            await ref.read(departmentTicketsProvider.notifier)
                                .assignTicket(ticket.id, profile!.id);
                            ref.invalidate(ticketDetailProvider(ticket.id));
                            ref.invalidate(agentQueueProvider);
                          },
                        ),
                      ),
                    ],
                    if (profile?.isAdmin == true) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                          label: const Text('Assign Agent'),
                          onPressed: () => _showAssignAgentModal(context, ref, ticket.id, scheme),
                        ),
                      ),
                    ],
                    if (resolvedStr != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Resolved At', style: TextStyle(color: scheme.onSurfaceVariant)),
                          Text(resolvedStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // ── Attachments Section ─────────────────────────────────────────
              _AttachmentsSection(ticketId: ticket.id)
                  .animate()
                  .fadeIn(delay: 560.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // ── Comments Section ────────────────────────────────────────────
              Text('Conversation', style: Theme.of(context).textTheme.titleMedium)
                  .animate()
                  .fadeIn(delay: 620.ms, duration: 400.ms),
              const SizedBox(height: 8),
              
              CommentThread(
                ticketId: ticket.id,
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
        TicketChatInput(
          ticketId: ticket.id,
          canAddInternal: profile?.canManageTickets == true,
        ),
      ],
    );
  },
),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final String label;
  final String name;
  final ColorScheme scheme;
  final bool isEmpty;

  const _UserRow({
    required this.label,
    required this.name,
    required this.scheme,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        const Spacer(),
        if (!isEmpty)
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
            color: isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

// ── Attachments Section ───────────────────────────────────────────────────────
class _AttachmentsSection extends ConsumerWidget {
  final String ticketId;
  const _AttachmentsSection({required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(ticketAttachmentsProvider(ticketId));
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_rounded, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(l10n.attachments, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        attachmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('${l10n.error}: $e',
              style: TextStyle(color: scheme.error)),
          data: (attachments) {
            if (attachments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.noAttachments,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return Column(
              children: attachments
                  .asMap()
                  .entries
                  .map((e) => AttachmentTile(
                        attachment: e.value,
                        animationIndex: e.key,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Status update bottom sheet ────────────────────────────────────────────────
void _showStatusSheet(BuildContext context, WidgetRef ref, Ticket ticket, AppLocalizations l10n) {
  final statuses = [
    ('open', l10n.statusOpen, Icons.radio_button_unchecked_rounded),
    ('in_progress', l10n.statusInProgress, Icons.timelapse_rounded),
    ('waiting_on_user', l10n.statusWaitingOnUser, Icons.hourglass_empty_rounded),
    ('resolved', l10n.statusResolved, Icons.check_circle_rounded),
    ('closed', l10n.statusClosed, Icons.cancel_rounded),
  ];

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
            Text(l10n.updateStatus,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...statuses.map((s) {
              final isActive = ticket.status == s.$1;
              final color = AppTheme.statusColor(s.$1);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(s.$3,
                    color: isActive ? color : scheme.onSurfaceVariant),
                title: Text(
                  s.$2,
                  style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? color : scheme.onSurface,
                  ),
                ),
                trailing: isActive
                    ? Icon(Icons.check_rounded, color: color)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(departmentTicketsProvider.notifier)
                      .updateStatus(ticket.id, s.$1);
                  ref.invalidate(ticketDetailProvider(ticket.id));
                  ref.invalidate(agentQueueProvider);
                },
              );
            }),
          ],
        ),
      );
    },
  );
}

void _showAssignAgentModal(
  BuildContext context,
  WidgetRef ref,
  String ticketId,
  ColorScheme scheme,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final agentsAsync = ref.watch(allAgentsProvider);
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign Ticket to Agent',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              agentsAsync.when(
                data: (agents) {
                  if (agents.isEmpty) {
                    return const Center(child: Text('No agents found.'));
                  }
                  return Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: agents.length,
                      itemBuilder: (context, index) {
                        final agent = agents[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            backgroundImage: agent.avatarUrl != null
                                ? NetworkImage(agent.avatarUrl!)
                                : null,
                            child: agent.avatarUrl == null
                                ? Text(agent.initials)
                                : null,
                          ),
                          title: Text(agent.displayName),
                          subtitle: Text(agent.department?.name ?? 'No Dept'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await ref
                                .read(departmentTicketsProvider.notifier)
                                .assignTicket(ticketId, agent.id);
                            ref.invalidate(ticketDetailProvider(ticketId));
                            ref.invalidate(agentQueueProvider);
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      );
    },
  );
}
