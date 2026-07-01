// ─── SEASAME Assist-Pro — Shared Dashboard Scaffold ───────────────────────────
// This widget provides the page structure (AppBar, FAB, scrolling content) for
// the main dashboard screens.
// Note: The global persistent sidebar for wide screens is now handled by
// AppShell (via ShellRoute in the router). This widget only provides the
// bottom NavigationBar for mobile (narrow) screens.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme.dart';
import 'app_shell.dart' show kSidebarBreakpoint;

class DashboardScaffold extends ConsumerWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? fab;
  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int>? onDestinationSelected;

  const DashboardScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.fab,
    this.selectedIndex = 0,
    required this.destinations,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= kSidebarBreakpoint;
    
    final profile = ref.watch(currentProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...(actions ?? []),
          // Only show avatar menu in AppBar on narrow screens (since sidebar has it on wide)
          if (!isWide)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showProfileMenu(context, ref, l10n, scheme),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    profile?.initials ?? '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          if (isWide) const SizedBox(width: 8),
        ],
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 16,
              vertical: isWide ? 16 : 12,
            ),
            sliver: SliverList.list(children: children),
          ),
        ],
      ),
      floatingActionButton: fab,
      // Only show bottom navigation bar on narrow screens
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              destinations: destinations,
              onDestinationSelected: onDestinationSelected,
            ),
    );
  }

  void _showProfileMenu(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    final profile = ref.read(currentProfileProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Profile info
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              child: Text(
                profile?.initials ?? '?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile?.displayName ?? '',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            Text(
              profile?.role.toUpperCase() ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                // Using primary color fallback if AppTheme.roleColor isn't accessible here easily
                color: scheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(l10n.signOut),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authControllerProvider.notifier).signOut();
                if (ctx.mounted) ctx.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card (Moved from old DashboardScaffold) ──────────────────────────────
// Re-exporting these so dashboard screens don't break. In a real app,
// these should be moved to their own widget files.

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int animationDelay;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.0,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: animationDelay), duration: 400.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: animationDelay),
          curve: Curves.easeOut,
        );
  }
}

// ── Quick Action Button (Moved from old DashboardScaffold) ────────────────────
class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final int animationDelay;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: animationDelay), duration: 400.ms)
        .slideX(
          begin: 0.05,
          end: 0,
          delay: Duration(milliseconds: animationDelay),
          curve: Curves.easeOut,
        );
  }
}
