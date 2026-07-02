// ─── SEASAME Assist-Pro — SLA Breach List Widget ──────────────────────────────
// Shows at-risk and breached tickets for agents / admins.
// Used in dashboards as an alert panel.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/sla_status.dart';
import '../../../core/models/ticket.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/utils/business_hours.dart';
import '../controllers/sla_controller.dart';

class SlaBreachList extends ConsumerWidget {
  const SlaBreachList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final asyncData = ref.watch(slaBreachTicketsProvider);

    return asyncData.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        // Parse tickets and filter to only at-risk / breached
        final tickets = rows
            .map((r) {
              try {
                return Ticket.fromJson(r);
              } catch (_) {
                return null;
              }
            })
            .whereType<Ticket>()
            .where((t) =>
                t.slaStatus == SlaStatus.atRisk ||
                t.slaStatus == SlaStatus.breached)
            .toList()
          ..sort((a, b) {
            // Breached first, then by remaining minutes ascending
            if (a.slaStatus == SlaStatus.breached &&
                b.slaStatus != SlaStatus.breached) {
              return -1;
            }
            if (b.slaStatus == SlaStatus.breached &&
                a.slaStatus != SlaStatus.breached) {
              return 1;
            }
            return (a.slaRemainingMinutes ?? 0)
                .compareTo(b.slaRemainingMinutes ?? 0);
          });

        if (tickets.isEmpty) {
          return _EmptyState(scheme: scheme);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(count: tickets.length, scheme: scheme),
            const SizedBox(height: 12),
            ...tickets.asMap().entries.map((entry) => _SlaAlertRow(
                  ticket: entry.value,
                  index: entry.key,
                ).animate().fadeIn(
                      delay: Duration(milliseconds: entry.key * 50),
                      duration: 350.ms,
                    )),
          ],
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int count;
  final ColorScheme scheme;
  const _Header({required this.count, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timer_outlined,
            size: 18, color: const Color(0xFFEF4444)),
        const SizedBox(width: 8),
        Text(
          'SLA Alerts',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ColorScheme scheme;
  const _EmptyState({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: AppColors.primary500, size: 20),
          const SizedBox(width: 10),
          Text(
            'All tickets are within SLA',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual alert row ──────────────────────────────────────────────────────
class _SlaAlertRow extends StatelessWidget {
  final Ticket ticket;
  final int index;
  const _SlaAlertRow({required this.ticket, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = ticket.slaStatus;
    final color = status.color;
    final remaining = ticket.slaRemainingMinutes ?? 0;
    final isPaused = ticket.isSlaPaused;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.ticketDetail(ticket.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(status.icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),

            // Ticket info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ticket.priority.toUpperCase()} · ${ticket.department.label}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Countdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPaused
                      ? '⏸ ${BusinessHours.formatRemaining(remaining)}'
                      : '⏱ ${BusinessHours.formatRemaining(remaining)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
