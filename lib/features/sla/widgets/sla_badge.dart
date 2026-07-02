// ─── SEASAME Assist-Pro — SLA Badge Widget ────────────────────────────────────
// A compact, auto-refreshing countdown badge.
// Shows remaining business time to resolution deadline + SLA status colour.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/ticket.dart';
import '../../../core/enums/sla_status.dart';
import '../../../core/utils/business_hours.dart';

class SlaBadge extends StatefulWidget {
  final Ticket ticket;
  /// When true, renders a larger badge with a label row beneath the countdown.
  final bool expanded;

  const SlaBadge({super.key, required this.ticket, this.expanded = false});

  @override
  State<SlaBadge> createState() => _SlaBadgeState();
}

class _SlaBadgeState extends State<SlaBadge> {
  late int _remainingMinutes;
  late SlaStatus _status;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Re-compute every 60 seconds (business-hours countdown doesn't need sub-minute precision)
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  @override
  void didUpdateWidget(SlaBadge old) {
    super.didUpdateWidget(old);
    if (old.ticket != widget.ticket) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _remainingMinutes = widget.ticket.slaRemainingMinutes ?? 0;
      _status = widget.ticket.slaStatus;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ticket.slaResolutionDueAt == null) return const SizedBox.shrink();

    final color = _status.color;
    final isPaused = widget.ticket.isSlaPaused;
    final countdownText = isPaused
        ? '⏸ ${BusinessHours.formatRemaining(_remainingMinutes)}'
        : '⏱ ${BusinessHours.formatRemaining(_remainingMinutes)}';

    if (!widget.expanded) {
      // ── Compact chip (used on ticket cards) ──────────────────────────────
      return _CompactBadge(
        text: countdownText,
        color: color,
        isPaused: isPaused,
      );
    }

    // ── Expanded badge (used on ticket detail) ────────────────────────────
    return _ExpandedBadge(
      ticket: widget.ticket,
      status: _status,
      remainingMinutes: _remainingMinutes,
      countdownText: countdownText,
      color: color,
      isPaused: isPaused,
    );
  }
}

// ── Compact chip ──────────────────────────────────────────────────────────────
class _CompactBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isPaused;

  const _CompactBadge({
    required this.text,
    required this.color,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPaused ? 0.06 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isPaused ? 0.2 : 0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Expanded badge ────────────────────────────────────────────────────────────
class _ExpandedBadge extends StatelessWidget {
  final Ticket ticket;
  final SlaStatus status;
  final int remainingMinutes;
  final String countdownText;
  final Color color;
  final bool isPaused;

  const _ExpandedBadge({
    required this.ticket,
    required this.status,
    required this.remainingMinutes,
    required this.countdownText,
    required this.color,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Progress: how much of the total window has elapsed (0.0 → 1.0)
    double progress = 0.0;
    if (ticket.slaResolutionDueAt != null) {
      final totalMin = BusinessHours.elapsedBusinessMinutes(
          ticket.createdAt, ticket.slaResolutionDueAt!);
      if (totalMin > 0) {
        final elapsed = totalMin - remainingMinutes.clamp(0, totalMin);
        progress = (elapsed / totalMin).clamp(0.0, 1.0);
      } else {
        progress = 1.0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            children: [
              Icon(status.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'SLA — ${status.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              if (isPaused)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PAUSED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                countdownText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Progress bar ───────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 8),

          // ── Due date line ──────────────────────────────────────────────
          if (ticket.slaResolutionDueAt != null)
            Text(
              'Resolution due: ${_formatDue(ticket.slaResolutionDueAt!)}',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDue(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${months[local.month]} ${local.day}, ${local.year} · $h:$m';
  }
}
