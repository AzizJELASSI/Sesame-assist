// ─── SEASAME Assist-Pro — Agent Queue Provider ────────────────────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/department_filiere.dart';
import '../../../core/models/ticket.dart';
import '../../../core/supabase_client.dart';
import '../../auth/controllers/auth_controller.dart';

const _ticketSelect = '''
  *,
  creator:profiles!tickets_created_by_fkey(full_name, avatar_url),
  assignee:profiles!tickets_assigned_to_fkey(full_name, avatar_url)
''';

// ── Filter State ───────────────────────────────────────────────────────────────
enum QueueSortBy { newest, oldest, priority }

class AgentQueueFilter {
  final Department? department;
  final String? status; // null = all
  final String? priority; // null = all
  final QueueSortBy sortBy;

  const AgentQueueFilter({
    this.department,
    this.status,
    this.priority,
    this.sortBy = QueueSortBy.newest,
  });

  AgentQueueFilter copyWith({
    Department? department,
    String? status,
    String? priority,
    QueueSortBy? sortBy,
    bool clearDept = false,
    bool clearStatus = false,
    bool clearPriority = false,
  }) {
    return AgentQueueFilter(
      department: clearDept ? null : (department ?? this.department),
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

// ── Agent Queue State ──────────────────────────────────────────────────────────
class AgentQueueState {
  final AsyncValue<List<Ticket>> tickets;
  final Set<String> selectedTicketIds;

  const AgentQueueState({
    this.tickets = const AsyncValue.loading(),
    this.selectedTicketIds = const {},
  });

  AgentQueueState copyWith({
    AsyncValue<List<Ticket>>? tickets,
    Set<String>? selectedTicketIds,
  }) {
    return AgentQueueState(
      tickets: tickets ?? this.tickets,
      selectedTicketIds: selectedTicketIds ?? this.selectedTicketIds,
    );
  }

  // Forward AsyncValue helpers for convenience
  bool get isLoading => tickets.isLoading;
  bool get hasError => tickets.hasError;
  List<Ticket> get data => tickets.valueOrNull ?? [];

  // ignore: missing_return
  T when<T>({
    required T Function() loading,
    required T Function(Object error, StackTrace? stackTrace) error,
    required T Function(List<Ticket> data) data_,
  }) {
    return tickets.when(
      loading: loading,
      error: error,
      data: data_,
    );
  }
}

// ── Filter Provider ────────────────────────────────────────────────────────────
final agentQueueFilterProvider =
    StateProvider<AgentQueueFilter>((ref) => const AgentQueueFilter());

// ── Notifier ───────────────────────────────────────────────────────────────────
class AgentQueueNotifier extends Notifier<AgentQueueState> {
  @override
  AgentQueueState build() {
    // Auto-fetch when filter changes
    ref.listen(agentQueueFilterProvider, (_, __) => _fetch());
    _fetch();
    return const AgentQueueState();
  }

  Future<void> _fetch() async {
    state = state.copyWith(tickets: const AsyncValue.loading());
    try {
      final filter = ref.read(agentQueueFilterProvider);
      final profile = ref.read(currentProfileProvider);

      // Determine which department to query
      final dept = filter.department ?? profile?.department;

      var query = SupabaseService.client
          .from('tickets')
          .select(_ticketSelect);

      if (dept != null) {
        query = query.eq('department_id', dept.name);
      }
      if (filter.status != null) {
        query = query.eq('status', filter.status!);
      }
      if (filter.priority != null) {
        query = query.eq('priority', filter.priority!);
      }

      // Sorting
      dynamic finalQuery;
      switch (filter.sortBy) {
        case QueueSortBy.newest:
          finalQuery = query.order('created_at', ascending: false);
          break;
        case QueueSortBy.oldest:
          finalQuery = query.order('created_at', ascending: true);
          break;
        case QueueSortBy.priority:
          // priority: high > medium > low  — use updated_at as tiebreaker
          finalQuery = query.order('priority', ascending: false)
              .order('created_at', ascending: false);
          break;
      }

      final data = await finalQuery;
      final tickets = (data as List).map((e) => Ticket.fromJson(e)).toList();

      // Sort by priority weight client-side for correctness
      if (filter.sortBy == QueueSortBy.priority) {
        tickets.sort((a, b) {
          const w = {'high': 2, 'medium': 1, 'low': 0};
          return (w[b.priority] ?? 0).compareTo(w[a.priority] ?? 0);
        });
      }

      state = state.copyWith(tickets: AsyncValue.data(tickets));
    } catch (e, st) {
      state = state.copyWith(tickets: AsyncValue.error(e, st));
    }
  }

  Future<void> refresh() => _fetch();

  void toggleSelection(String id) {
    final selected = Set<String>.from(state.selectedTicketIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    state = state.copyWith(selectedTicketIds: selected);
  }

  void selectAll() {
    state = state.copyWith(
      selectedTicketIds: state.data.map((t) => t.id).toSet(),
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedTicketIds: {});
  }

  Future<void> bulkUpdateStatus(Set<String> ids, String newStatus) async {
    if (ids.isEmpty) return;
    for (final id in ids) {
      await SupabaseService.client
          .from('tickets')
          .update({
            'status': newStatus,
            if (newStatus == 'resolved')
              'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }
    clearSelection();
    await refresh();
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await SupabaseService.client
        .from('tickets')
        .update({
          'status': newStatus,
          if (newStatus == 'resolved')
            'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    await refresh();
  }
}

final agentQueueProvider =
    NotifierProvider<AgentQueueNotifier, AgentQueueState>(
  AgentQueueNotifier.new,
);
