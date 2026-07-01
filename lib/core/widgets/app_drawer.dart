import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Text('SEASAME Assist-Pro', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(l10n.appTitle),
            onTap: () => context.go('/'),
          ),
          const Divider(),
          // Agent Queue
          ListTile(
            leading: const Icon(Icons.queue_rounded),
            title: Text(l10n.agentQueue),
            onTap: () => context.go('/agent-queue'),
          ),
          // Admin Section
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: Text(l10n.adminPanel),
            onTap: () => context.go('/admin'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group),
            title: Text(l10n.userManagement),
            onTap: () => context.go('/admin/users'),
          ),
          ListTile(
            leading: const Icon(Icons.apartment),
            title: Text(l10n.departmentManagement),
            onTap: () => context.go('/admin/departments'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(l10n.systemStats),
            onTap: () => context.go('/admin/stats'),
          ),
        ],
      ),
    );
  }
}
