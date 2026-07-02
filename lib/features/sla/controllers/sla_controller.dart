// ─── SEASAME Assist-Pro — SLA Controller ──────────────────────────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/sla_policy.dart';
import '../../../core/supabase_client.dart';

// ── Fetch all SLA policies ────────────────────────────────────────────────────
class SlaPoliciesNotifier extends AsyncNotifier<List<SlaPolicy>> {
  @override
  Future<List<SlaPolicy>> build() async {
    final data = await SupabaseService.client
        .from('sla_policies')
        .select()
        .order('priority');
    return (data as List).map((e) => SlaPolicy.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// Updates a single policy's response & resolution hours by priority.
  Future<void> updatePolicy({
    required String priority,
    required int responseTimeH,
    required int resolutionTimeH,
  }) async {
    await SupabaseService.client.from('sla_policies').update({
      'response_time_h': responseTimeH,
      'resolution_time_h': resolutionTimeH,
    }).eq('priority', priority);
    await refresh();
  }
}

final slaPoliciesProvider =
    AsyncNotifierProvider<SlaPoliciesNotifier, List<SlaPolicy>>(
  SlaPoliciesNotifier.new,
);

// ── Convenience map: priority → policy ───────────────────────────────────────
final slaPolicyMapProvider =
    Provider<Map<String, SlaPolicy>>((ref) {
  final policies = ref.watch(slaPoliciesProvider).valueOrNull ?? [];
  return {for (final p in policies) p.priority: p};
});

// ── Breach alert list provider — tickets with breached/at-risk SLA ────────────
// (Used by admin/agent dashboards — fetched directly from Supabase)
final slaBreachTicketsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await SupabaseService.client
      .from('tickets')
      .select(
        '*,'
        'creator:profiles!tickets_created_by_fkey(full_name),'
        'assignee:profiles!tickets_assigned_to_fkey(full_name)',
      )
      .not('sla_resolution_due_at', 'is', null)
      .not('status', 'in', '("resolved","closed")')
      .order('sla_resolution_due_at', ascending: true)
      .limit(50);
  return (data as List).cast<Map<String, dynamic>>();
});
