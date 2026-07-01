// ─── SEASAME Assist-Pro — User Management Screen ──────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/department_filiere.dart';
import '../../../core/models/profile.dart';
import '../../../core/supabase_client.dart';
import '../../../core/theme.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';


// ── Provider ───────────────────────────────────────────────────────────────────
final allUsersProvider = FutureProvider<List<Profile>>((ref) async {
  final data = await SupabaseService.client
      .from('profiles')
      .select('*')
      .order('created_at', ascending: false);
  return (data as List).map((json) => Profile.fromJson(json)).toList();
});

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allUsersProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l10n.createUser),
        onPressed: () => _showCreateUserDialog(context, ref, l10n),
      ),
      body: usersAsync.when(
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
                onPressed: () => ref.invalidate(allUsersProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(l10n.noUsersFound,
                  style: Theme.of(context).textTheme.titleMedium),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allUsersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: users.length,
              itemBuilder: (context, i) =>
                  _UserCard(user: users[i], index: i, onEdit: () {
                    _showEditUserDialog(context, ref, l10n, users[i]);
                  }, onDelete: () {
                    _confirmDelete(context, ref, l10n, users[i]);
                  }),
            ),
          );
        },
      ),
    );
  }

  // ── Create user (admin registers with email + password) ────────────────────
  void _showCreateUserDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CreateUserSheet(l10n: l10n, ref: ref),
    );
  }

  // ── Edit existing user profile ─────────────────────────────────────────────
  void _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Profile user,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _EditUserSheet(user: user, l10n: l10n, ref: ref),
    );
  }

  // ── Delete user ────────────────────────────────────────────────────────────
  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Profile user,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.client.functions.invoke(
                  'admin_user_manager',
                  body: {
                    'action': 'delete_user',
                    'target_user_id': user.id,
                  },
                );
                ref.invalidate(allUsersProvider);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.userDeleted)),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
                  );
                }
              }
            },
            child: Text(l10n.deleteConfirmBtn),
          ),
        ],
      ),
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final Profile user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final roleColor = AppTheme.roleColor(user.role);
    final isIncomplete = user.fullName == null || user.fullName!.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Text(
              user.initials,
              style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(user.displayName,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    if (isIncomplete) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Profile not yet completed',
                        child: Icon(Icons.pending_outlined,
                            size: 14,
                            color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              // Role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              if (user.department != null)
                Row(
                  children: [
                    Icon(user.department!.icon,
                        size: 12,
                        color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      user.department!.label,
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              Text(
                'ID: ${user.id.substring(0, 12)}…',
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_rounded),
                  title: Text('Edit'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_rounded,
                      color: Theme.of(ctx).colorScheme.error),
                  title: Text('Delete',
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error)),
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
              delay: Duration(milliseconds: index * 40), duration: 300.ms)
          .slideX(begin: 0.03, end: 0, curve: Curves.easeOut),
    );
  }
}

// ── Create User Sheet (email + password only) ─────────────────────────────────
class _CreateUserSheet extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _CreateUserSheet({required this.l10n, required this.ref});

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  Department? _department;
  String _role = 'student';
  bool _obscurePassword = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              Text(
                l10n.createUser,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'The user will set their name and department on first login.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.validationRequired;
                  }
                  if (!v.contains('@')) return l10n.validationEmail;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.validationRequired;
                  if (v.length < 6) return l10n.validationPasswordLength;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Full Name (Optional)
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${l10n.fullName} (Optional)',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Department dropdown (Optional)
              DropdownButtonFormField<Department?>(
                value: _department,
                decoration: InputDecoration(
                  labelText: '${l10n.department} (Optional)',
                  prefixIcon: _department != null
                      ? Icon(_department!.icon, size: 20)
                      : const Icon(Icons.business_outlined, size: 20),
                ),
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.selectDepartment)),
                  ...Department.values.map((d) => DropdownMenuItem(
                        value: d,
                        child: Row(
                          children: [
                            Icon(d.icon, size: 18, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(d.label),
                          ],
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _department = v),
              ),
              const SizedBox(height: 16),

              // Role dropdown
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  labelText: l10n.role,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(value: 'student', child: Text(l10n.roleStudent)),
                  DropdownMenuItem(value: 'teacher', child: Text(l10n.roleTeacher)),
                  DropdownMenuItem(value: 'agent', child: Text(l10n.roleAgent)),
                  DropdownMenuItem(value: 'admin', child: Text(l10n.roleAdmin)),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: scheme.onErrorContainer, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l10n.createUser),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Call Supabase Edge Function
      await SupabaseService.client.functions.invoke(
        'admin_user_manager',
        body: {
          'action': 'create_user',
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'role': _role,
          'full_name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          'department_id': _department?.name,
        },
      );

      widget.ref.invalidate(allUsersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.userSaved)),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _saving = false);
  }
}

// ── Edit User Sheet (name / role / department) ────────────────────────────────
class _EditUserSheet extends ConsumerStatefulWidget {
  final Profile user;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _EditUserSheet({
    required this.user,
    required this.l10n,
    required this.ref,
  });

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _role = 'student';
  Department? _department;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user.fullName ?? '';
    _role = widget.user.role;
    _department = widget.user.department;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              Text(
                l10n.editUser,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    InputDecoration(labelText: l10n.fullName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
              ),
              const SizedBox(height: 16),

              // Role dropdown
              DropdownButtonFormField<String>(
                value: _role,
                decoration:
                    InputDecoration(labelText: l10n.role),
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(
                      value: 'student', child: Text(l10n.roleStudent)),
                  DropdownMenuItem(
                      value: 'teacher', child: Text(l10n.roleTeacher)),
                  DropdownMenuItem(
                      value: 'agent', child: Text(l10n.roleAgent)),
                  DropdownMenuItem(
                      value: 'admin', child: Text(l10n.roleAdmin)),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),

              // Department dropdown
              DropdownButtonFormField<Department?>(
                value: _department,
                decoration: InputDecoration(
                  labelText: l10n.department,
                  prefixIcon: _department != null
                      ? Icon(_department!.icon, size: 20)
                      : const Icon(Icons.business_outlined, size: 20),
                ),
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(l10n.selectDepartment)),
                  ...Department.values.map((d) => DropdownMenuItem(
                        value: d,
                        child: Row(
                          children: [
                            Icon(d.icon,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(d.label),
                          ],
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _department = v),
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l10n.save),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await SupabaseService.client
          .from('profiles')
          .update({
            'full_name': _nameCtrl.text.trim(),
            'role': _role,
            'department_id': _department?.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.user.id);

      widget.ref.invalidate(allUsersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.userSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.l10n.error}: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }
}
