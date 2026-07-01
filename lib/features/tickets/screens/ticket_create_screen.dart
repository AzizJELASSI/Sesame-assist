// ─── SEASAME Assist-Pro — Ticket Create Screen ────────────────────────────────
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/enums/department_filiere.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/ticket_controller.dart';
import '../widgets/attachment_tile.dart';

class TicketCreateScreen extends ConsumerStatefulWidget {
  const TicketCreateScreen({super.key});

  @override
  ConsumerState<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends ConsumerState<TicketCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _priority = 'medium';
  String? _ticketType;
  Department? _selectedDepartment;
  bool _isSubmitting = false;
  List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() {
        final existing = _selectedFiles.map((f) => f.name).toSet();
        final newFiles = result.files.where((f) => !existing.contains(f.name));
        _selectedFiles = [..._selectedFiles, ...newFiles];
      });
    }
  }

  // Ticket types by role
  List<(String, String, IconData)> get _ticketTypes {
    final profile = ref.read(currentProfileProvider);
    if (profile?.isTeacher == true) {
      return [
        ('classroom_it', 'Classroom IT', Icons.computer_rounded),
        ('hr_request', 'HR Request', Icons.people_rounded),
        ('facility', 'Facility', Icons.business_rounded),
        ('it_issue', 'IT Issue', Icons.wifi_rounded),
      ];
    }
    return [
      ('academic', 'Academic', Icons.school_rounded),
      ('it_issue', 'IT Issue', Icons.computer_rounded),
      ('facility', 'Facility', Icons.business_rounded),
      ('hr_request', 'HR Request', Icons.people_rounded),
    ];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ticketType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ticket type')),
      );
      return;
    }
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ticket = await ref
          .read(myTicketsProvider.notifier)
          .createTicket(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            ticketType: _ticketType!,
            priority: _priority,
            department: _selectedDepartment!,
            attachments: _selectedFiles,
          );

      if (mounted && ticket != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ticket created successfully!'),
            backgroundColor: AppTheme.statusColor('resolved'),
          ),
        );
        context.go(AppRoutes.ticketDetail(ticket.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newTicket),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Ticket type selector ───────────────────────────────────────────
            Text(l10n.ticketType, style: Theme.of(context).textTheme.titleSmall)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: _ticketTypes.map((t) {
                final isSelected = _ticketType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _ticketType = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary.withValues(alpha: 0.08)
                          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? scheme.primary
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t.$3,
                          size: 18,
                          color: isSelected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // ── Title ──────────────────────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.ticketTitle,
                prefixIcon: const Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.validationRequired : null,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 14),

            // ── Description ────────────────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.ticketDescription,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.validationRequired : null,
            ).animate().fadeIn(delay: 280.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Priority selector ──────────────────────────────────────────────
            Text(l10n.ticketPriority,
                    style: Theme.of(context).textTheme.titleSmall)
                .animate()
                .fadeIn(delay: 340.ms, duration: 400.ms),
            const SizedBox(height: 10),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;
                final color = AppTheme.priorityColor(p);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: p != 'high' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.1)
                              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : scheme.outlineVariant.withValues(alpha: 0.5),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: color,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected ? color : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 380.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Department ─────────────────────────────────────────────────────
            Text(l10n.department,
                    style: Theme.of(context).textTheme.titleSmall)
                .animate()
                .fadeIn(delay: 420.ms, duration: 400.ms),
            const SizedBox(height: 10),
            _DepartmentGrid(
              selected: _selectedDepartment,
              onChanged: (d) => setState(() => _selectedDepartment = d),
            ).animate().fadeIn(delay: 440.ms, duration: 400.ms),
            if (_selectedDepartment == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  l10n.validationRequired,
                  style: TextStyle(fontSize: 12, color: scheme.error),
                ),
              ),

            const SizedBox(height: 20),

            // ── Attachments ────────────────────────────────────────────────────
            AttachmentListSection(
              fileNames: _selectedFiles.map((f) => f.name).toList(),
              onAdd: _pickFiles,
              onRemove: (i) => setState(() => _selectedFiles.removeAt(i)),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Department Grid ────────────────────────────────────────────────────────────
class _DepartmentGrid extends StatelessWidget {
  final Department? selected;
  final ValueChanged<Department> onChanged;

  const _DepartmentGrid({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      children: Department.values.map((d) {
        final isSelected = selected == d;
        return GestureDetector(
          onTap: () => onChanged(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.08)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(d.icon,
                    size: 16,
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    d.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? scheme.primary : scheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
