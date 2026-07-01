// ─── SEASAME Assist-Pro — Department Management Screen ────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/department_filiere.dart';
import '../../../core/supabase_client.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';


// ── Provider for per-department ticket counts ──────────────────────────────────
final departmentStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final data = await SupabaseService.client
      .from('tickets')
      .select('department_id');
  final Map<String, int> counts = {};
  for (final row in data as List) {
    final dept = row['department_id'] as String? ?? 'unknown';
    counts[dept] = (counts[dept] ?? 0) + 1;
  }
  return counts;
});

class DepartmentManagementScreen extends ConsumerWidget {
  const DepartmentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(departmentStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.departmentManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(departmentStatsProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: Department.values.asMap().entries.map((entry) {
          final i = entry.key;
          final dept = entry.value;
          final ticketCount = statsAsync.valueOrNull?[dept.name] ?? 0;
          final isUnite = dept.name.startsWith('unite');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUnite
                        ? scheme.primary.withValues(alpha: 0.1)
                        : scheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(dept.icon,
                      color: isUnite ? scheme.primary : scheme.secondary,
                      size: 22),
                ),
                title: Text(dept.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  ticketCount == 0
                      ? 'No tickets yet'
                      : '$ticketCount ticket${ticketCount > 1 ? 's' : ''}',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnite
                        ? scheme.primaryContainer
                        : scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isUnite ? 'Unité' : 'Dépt.',
                    style: TextStyle(
                      color: isUnite
                          ? scheme.onPrimaryContainer
                          : scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(
                    delay: Duration(milliseconds: i * 60),
                    duration: 400.ms)
                .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: Duration(milliseconds: i * 60),
                    curve: Curves.easeOut),
          );
        }).toList(),
      ),
    );
  }
}
