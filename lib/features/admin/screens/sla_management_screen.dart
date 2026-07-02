// ─── SEASAME Assist-Pro — SLA Management Screen (Admin) ───────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/models/sla_policy.dart';
import '../../sla/controllers/sla_controller.dart';

class SlaManagementScreen extends ConsumerStatefulWidget {
  const SlaManagementScreen({super.key});

  @override
  ConsumerState<SlaManagementScreen> createState() =>
      _SlaManagementScreenState();
}

class _SlaManagementScreenState extends ConsumerState<SlaManagementScreen> {
  // Editable values: priority → {responseH, resolutionH}
  final Map<String, _PolicyDraft> _drafts = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final policiesAsync = ref.watch(slaPoliciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SLA Management'),
        actions: [
          if (_hasDirtyDrafts(policiesAsync.valueOrNull))
            TextButton.icon(
              onPressed: _saving ? null : _saveAll,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Changes'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary500,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: policiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (policies) {
          // Initialise drafts once
          for (final p in policies) {
            _drafts.putIfAbsent(
              p.priority,
              () => _PolicyDraft(p.responseTimeH, p.resolutionTimeH),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info banner ─────────────────────────────────────────────
                _InfoBanner().animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ── Policy cards ─────────────────────────────────────────────
                Text(
                  'Response & Resolution Targets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All times are in business hours (Mon–Fri, 08:00–18:00).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),

                ...policies.asMap().entries.map(
                      (entry) => _PolicyCard(
                        policy: entry.value,
                        draft: _drafts[entry.value.priority]!,
                        onChanged: (draft) => setState(
                            () => _drafts[entry.value.priority] = draft),
                        index: entry.key,
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: entry.key * 80),
                            duration: 350.ms,
                          ).slideY(
                            begin: 0.06,
                            end: 0,
                            delay: Duration(milliseconds: entry.key * 80),
                          ),
                    ),

                const SizedBox(height: 32),

                // ── Business hours note ─────────────────────────────────────
                _BusinessHoursNote(),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _hasDirtyDrafts(List<SlaPolicy>? policies) {
    if (policies == null) return false;
    for (final p in policies) {
      final d = _drafts[p.priority];
      if (d == null) continue;
      if (d.responseH != p.responseTimeH || d.resolutionH != p.resolutionTimeH) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final notifier = ref.read(slaPoliciesProvider.notifier);
      final entries = _drafts.entries.toList();
      for (final entry in entries) {
        await notifier.updatePolicy(
          priority: entry.key,
          responseTimeH: entry.value.responseH,
          resolutionTimeH: entry.value.resolutionH,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SLA policies saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Draft state ───────────────────────────────────────────────────────────────
class _PolicyDraft {
  int responseH;
  int resolutionH;
  _PolicyDraft(this.responseH, this.resolutionH);

  _PolicyDraft copyWith({int? responseH, int? resolutionH}) =>
      _PolicyDraft(responseH ?? this.responseH, resolutionH ?? this.resolutionH);
}

// ── Info banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.primary500, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Level Agreements',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SLA deadlines are automatically calculated and assigned to new tickets '
                  'at creation time using these targets. Changes apply to future tickets only.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Policy card ───────────────────────────────────────────────────────────────
class _PolicyCard extends StatefulWidget {
  final SlaPolicy policy;
  final _PolicyDraft draft;
  final ValueChanged<_PolicyDraft> onChanged;
  final int index;

  const _PolicyCard({
    required this.policy,
    required this.draft,
    required this.onChanged,
    required this.index,
  });

  @override
  State<_PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<_PolicyCard> {
  late TextEditingController _responseCtrl;
  late TextEditingController _resolutionCtrl;

  static const Map<String, Color> _priorityColors = {
    'low': Color(0xFF10B981),
    'medium': Color(0xFFF59E0B),
    'high': Color(0xFFEF4444),
  };

  static const Map<String, IconData> _priorityIcons = {
    'low': Icons.arrow_downward_rounded,
    'medium': Icons.remove_rounded,
    'high': Icons.arrow_upward_rounded,
  };

  Color get _color =>
      _priorityColors[widget.policy.priority] ?? AppColors.primary500;
  IconData get _icon =>
      _priorityIcons[widget.policy.priority] ?? Icons.circle;

  @override
  void initState() {
    super.initState();
    _responseCtrl =
        TextEditingController(text: widget.draft.responseH.toString());
    _resolutionCtrl =
        TextEditingController(text: widget.draft.resolutionH.toString());
  }

  @override
  void didUpdateWidget(_PolicyCard old) {
    super.didUpdateWidget(old);
    if (old.draft.responseH != widget.draft.responseH) {
      _responseCtrl.text = widget.draft.responseH.toString();
    }
    if (old.draft.resolutionH != widget.draft.resolutionH) {
      _resolutionCtrl.text = widget.draft.resolutionH.toString();
    }
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    _resolutionCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final r = int.tryParse(_responseCtrl.text) ?? widget.draft.responseH;
    final res = int.tryParse(_resolutionCtrl.text) ?? widget.draft.resolutionH;
    widget.onChanged(_PolicyDraft(r, res));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDirty = widget.draft.responseH != widget.policy.responseTimeH ||
        widget.draft.resolutionH != widget.policy.resolutionTimeH;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDirty
              ? _color.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.6),
          width: isDirty ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Priority header ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 16, color: _color),
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.policy.priority.toUpperCase()} Priority',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _color,
                ),
              ),
              const Spacer(),
              if (isDirty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Modified',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Two input fields side by side ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _HourField(
                  controller: _responseCtrl,
                  label: 'First Response',
                  icon: Icons.reply_rounded,
                  color: _color,
                  onChanged: (_) => _notifyChange(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HourField(
                  controller: _resolutionCtrl,
                  label: 'Resolution',
                  icon: Icons.check_circle_outline_rounded,
                  color: _color,
                  onChanged: (_) => _notifyChange(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hour input field ──────────────────────────────────────────────────────────
class _HourField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  const _HourField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _MaxValueFormatter(9999),
          ],
          onChanged: onChanged,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
          ),
          decoration: InputDecoration(
            suffixText: 'h',
            suffixStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  const _MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null || val > max) return old;
    return newValue;
  }
}

// ── Business hours note ───────────────────────────────────────────────────────
class _BusinessHoursNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.access_time_rounded,
              size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Business hours: Monday – Friday, 08:00 – 18:00\n'
              'The SLA clock pauses automatically when a ticket is in '
              '"Waiting on User" status.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
