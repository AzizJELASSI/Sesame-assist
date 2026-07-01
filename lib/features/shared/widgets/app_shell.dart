// ─── SEASAME Assist-Pro — App Shell (Global Sidebar Wrapper) ──────────────────
// Wraps ALL authenticated pages. On wide screens (≥ 800 px) it renders the
// persistent sidebar on the left and puts the page in the right panel.
// On narrow screens it simply passes through its child untouched.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';

// ── Nav-item descriptor ───────────────────────────────────────────────────────
class _NavEntry {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
  final List<String> roles; // empty = all roles

  const _NavEntry({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.roles = const [],
  });
}

const List<_NavEntry> _allNavEntries = [
  _NavEntry(
    route: AppRoutes.dashboard,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: _labelDashboard,
  ),
  _NavEntry(
    route: AppRoutes.tickets,
    icon: Icons.confirmation_number_outlined,
    selectedIcon: Icons.confirmation_number_rounded,
    label: _labelTickets,
  ),
  _NavEntry(
    route: AppRoutes.agentQueue,
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    label: _labelQueue,
    roles: ['agent'],
  ),
  _NavEntry(
    route: AppRoutes.adminUsers,
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    label: _labelUsers,
    roles: ['admin'],
  ),
  _NavEntry(
    route: AppRoutes.adminDepartments,
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment_rounded,
    label: _labelDepartments,
    roles: ['admin'],
  ),
  _NavEntry(
    route: AppRoutes.adminStats,
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    label: _labelStats,
    roles: ['admin'],
  ),
];

// Label functions (top-level so they can be const)
String _labelDashboard(AppLocalizations l) => l.dashboard;
String _labelTickets(AppLocalizations l) => l.myTickets;
String _labelQueue(AppLocalizations l) => l.queue;
String _labelUsers(AppLocalizations l) => l.users;
String _labelDepartments(AppLocalizations l) => l.departmentManagement;
String _labelStats(AppLocalizations l) => l.systemStats;

// ── Breakpoint ─────────────────────────────────────────────────────────────────
const double kSidebarBreakpoint = 800;

// ── AppShell ──────────────────────────────────────────────────────────────────
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < kSidebarBreakpoint) return child; // narrow → transparent pass-through

    final profile = ref.watch(currentProfileProvider);
    final l10n = AppLocalizations.of(context)!;
    final sidebarBg = AppColors.slate900;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Filter nav items by role
    final role = profile?.role ?? '';
    final entries = _allNavEntries.where((e) {
      if (e.roles.isEmpty) return true;
      return e.roles.contains(role);
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          // ── Persistent sidebar ──────────────────────────────────────────────
          _Sidebar(
            entries: entries,
            currentRoute: currentRoute,
            sidebarBg: sidebarBg,
            profile: profile,
            l10n: l10n,
            ref: ref,
          ),

          // ── Page content ────────────────────────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Sidebar widget ────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavEntry> entries;
  final String currentRoute;
  final Color sidebarBg;
  final dynamic profile; // UserProfile?
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _Sidebar({
    required this.entries,
    required this.currentRoute,
    required this.sidebarBg,
    required this.profile,
    required this.l10n,
    required this.ref,
  });

  bool _isActive(_NavEntry e) {
    // Exact match for dashboard; prefix match for others so sub-routes highlight
    if (e.route == AppRoutes.dashboard) return currentRoute == e.route;
    return currentRoute.startsWith(e.route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Brand ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SEASAME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Assist-Pro',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Nav items ──────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final active = _isActive(e);
                  return _SidebarItem(
                    icon: active ? e.selectedIcon : e.icon,
                    label: e.label(l10n),
                    isSelected: active,
                    onTap: () => context.go(e.route),
                  );
                },
              ),
            ),

            // ── User footer ───────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      profile?.initials ?? '?',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          profile?.role.toUpperCase() ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    tooltip: l10n.signOut,
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar nav item (with hover animation) ───────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary600.withValues(alpha: 0.1)
                : _hovering
                    ? AppColors.slate800.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: AppColors.primary500.withValues(alpha: 0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected
                    ? AppColors.primary500
                    : (_hovering ? AppColors.slate200 : AppColors.slate400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? AppColors.primary500
                        : (_hovering ? AppColors.slate200 : AppColors.slate400),
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
