// ─── SEASAME Assist-Pro — Profile Completion Screen ────────────────────────────
// Shown to users on first login (created by admin) who have no name yet.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/department_filiere.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../controllers/auth_controller.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  Department? _department;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).updateProfile(
          fullName: _nameCtrl.text.trim(),
          department: _department,
        );
    // Router redirect will handle navigation to dashboard once profile is complete
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final authAsync = ref.watch(authControllerProvider);
    final isLoading = authAsync.valueOrNull?.isLoading ?? false;
    final error = authAsync.valueOrNull?.error;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.06),
                  scheme.surface,
                  scheme.tertiary.withValues(alpha: 0.04),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width > 600 ? 480 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Icon + heading ─────────────────────────────────────
                      Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [scheme.primary, scheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.manage_accounts_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.completeYourProfile,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.completeProfileHint,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.15, end: 0, curve: Curves.easeOut),

                      const SizedBox(height: 40),

                      // ── Form card ──────────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Full name
                                TextFormField(
                                  controller: _nameCtrl,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.fullName,
                                    prefixIcon: const Icon(
                                        Icons.person_outline_rounded),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? l10n.validationRequired
                                          : null,
                                ),
                                const SizedBox(height: 20),

                                // Department
                                DropdownButtonFormField<Department?>(
                                  value: _department,
                                  decoration: InputDecoration(
                                    labelText: l10n.department,
                                    prefixIcon: _department != null
                                        ? Icon(_department!.icon, size: 20)
                                        : const Icon(
                                            Icons.business_outlined,
                                            size: 20),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  items: [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(l10n.selectDepartment),
                                    ),
                                    ...Department.values.map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Row(
                                          children: [
                                            Icon(d.icon,
                                                size: 18,
                                                color: scheme.primary),
                                            const SizedBox(width: 8),
                                            Text(d.label),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _department = v),
                                ),

                                // Error banner
                                if (error != null) ...[
                                  const SizedBox(height: 14),
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
                                            color: scheme.onErrorContainer,
                                            size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            error,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    color: scheme
                                                        .onErrorContainer),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Submit button
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _submit,
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(l10n.saveAndContinue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(
                            begin: 0.12,
                            end: 0,
                            delay: 200.ms,
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 16),

                      // Sign out link
                      Center(
                        child: TextButton.icon(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: Text(l10n.signOut),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
