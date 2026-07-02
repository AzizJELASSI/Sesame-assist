// ─── SEASAME Assist-Pro — Ticket Controller ───────────────────────────────────
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/models/ticket.dart';
import '../../../core/models/ticket_attachment.dart';
import '../../../core/supabase_client.dart';
import '../../../core/enums/department_filiere.dart';
import '../../../core/utils/business_hours.dart';
import '../../auth/controllers/auth_controller.dart';

// ── Base ticket query helper ───────────────────────────────────────────────────
const _ticketSelect = '''
  *,
  creator:profiles!tickets_created_by_fkey(full_name, avatar_url),
  assignee:profiles!tickets_assigned_to_fkey(full_name, avatar_url)
''';

// ── My Tickets (student/teacher) ───────────────────────────────────────────────
class MyTicketsNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await SupabaseService.client
        .from('tickets')
        .select(_ticketSelect)
        .eq('created_by', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Ticket.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<Ticket?> createTicket({
    required String title,
    required String description,
    required String ticketType,
    required String priority,
    required Department department,
    Map<String, dynamic>? aiDraft,
    List<PlatformFile> attachments = const [],
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    // ── Compute SLA deadlines from the policy for this priority ──────────────
    DateTime? slaResponseDueAt;
    DateTime? slaResolutionDueAt;
    try {
      final policyData = await SupabaseService.client
          .from('sla_policies')
          .select('response_time_h, resolution_time_h')
          .eq('priority', priority)
          .maybeSingle();
      if (policyData != null) {
        final now = DateTime.now();
        final responseH   = policyData['response_time_h']   as int;
        final resolutionH = policyData['resolution_time_h'] as int;
        slaResponseDueAt   = BusinessHours.addBusinessHours(now, responseH);
        slaResolutionDueAt = BusinessHours.addBusinessHours(now, resolutionH);
      }
    } catch (_) {
      // SLA policy fetch is non-critical; proceed without deadlines.
    }

    final response = await SupabaseService.client
        .from('tickets')
        .insert({
          'title': title,
          'description': description,
          'ticket_type': ticketType,
          'priority': priority,
          'department_id': department.name,
          'created_by': userId,
          if (aiDraft != null) 'ai_draft': aiDraft,
          if (slaResponseDueAt != null)
            'sla_response_due_at': slaResponseDueAt.toUtc().toIso8601String(),
          if (slaResolutionDueAt != null)
            'sla_resolution_due_at': slaResolutionDueAt.toUtc().toIso8601String(),
        })
        .select(_ticketSelect)
        .single();

    final ticket = Ticket.fromJson(response);

    // Upload attachments to storage and insert records
    if (attachments.isNotEmpty) {
      for (final file in attachments) {
        final bytes = file.bytes ?? Uint8List.fromList([]);
        if (bytes.isEmpty) continue;
        final storagePath = '${ticket.id}/${file.name}';
        await SupabaseService.client.storage
            .from(AppConstants.attachmentsBucket)
            .uploadBinary(storagePath, bytes);
        await SupabaseService.client.from('ticket_attachments').insert({
          'ticket_id': ticket.id,
          'file_path': storagePath,
        });
      }
    }

    // Prepend to list
    state.whenData((tickets) {
      state = AsyncData([ticket, ...tickets]);
    });

    return ticket;
  }
}

final myTicketsProvider =
    AsyncNotifierProvider<MyTicketsNotifier, List<Ticket>>(
  MyTicketsNotifier.new,
);

// ── Department Tickets (agent) ─────────────────────────────────────────────────
class DepartmentTicketsNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    final profile = ref.watch(currentProfileProvider);
    if (profile == null || profile.department == null) return [];

    final data = await SupabaseService.client
        .from('tickets')
        .select(_ticketSelect)
        .eq('department_id', profile.department!.name)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Ticket.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> updateStatus(String ticketId, String newStatus) async {
    final updates = <String, dynamic>{'status': newStatus};
    if (newStatus == 'resolved' || newStatus == 'closed') {
      updates['resolved_at'] = DateTime.now().toIso8601String();
    }
    
    await SupabaseService.client
        .from('tickets')
        .update(updates)
        .eq('id', ticketId);
    await refresh();
  }

  Future<void> assignTicket(String ticketId, String agentId) async {
    await SupabaseService.client
        .from('tickets')
        .update({'assigned_to': agentId, 'status': 'in_progress'})
        .eq('id', ticketId);
    await refresh();
  }
}

final departmentTicketsProvider =
    AsyncNotifierProvider<DepartmentTicketsNotifier, List<Ticket>>(
  DepartmentTicketsNotifier.new,
);

// ── All Tickets (admin) ────────────────────────────────────────────────────────
class AllTicketsNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    final data = await SupabaseService.client
        .from('tickets')
        .select(_ticketSelect)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Ticket.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final allTicketsProvider =
    AsyncNotifierProvider<AllTicketsNotifier, List<Ticket>>(
  AllTicketsNotifier.new,
);

// ── Single Ticket ──────────────────────────────────────────────────────────────
final ticketDetailProvider =
    FutureProvider.family<Ticket, String>((ref, id) async {
  final data = await SupabaseService.client
      .from('tickets')
      .select(_ticketSelect)
      .eq('id', id)
      .single();
  return Ticket.fromJson(data);
});

// ── Comments for a ticket ──────────────────────────────────────────────────────
final ticketCommentsProvider =
    FutureProvider.family<List<TicketComment>, String>((ref, ticketId) async {
  final data = await SupabaseService.client
      .from('ticket_comments')
      .select('*, author:profiles(full_name, avatar_url)')
      .eq('ticket_id', ticketId)
      .order('created_at');
  return (data as List).map((e) => TicketComment.fromJson(e)).toList();
});

// ── Attachments for a ticket ───────────────────────────────────────────────────
final ticketAttachmentsProvider =
    FutureProvider.family<List<TicketAttachment>, String>((ref, ticketId) async {
  final data = await SupabaseService.client
      .from('ticket_attachments')
      .select()
      .eq('ticket_id', ticketId)
      .order('uploaded_at');
  return (data as List).map((e) => TicketAttachment.fromJson(e)).toList();
});

/// Generates a signed download URL (1 hour expiry) for a storage path.
final attachmentSignedUrlProvider =
    FutureProvider.family<String, String>((ref, storagePath) async {
  final response = await SupabaseService.client.storage
      .from(AppConstants.attachmentsBucket)
      .createSignedUrl(storagePath, 3600);
  return response;
});

// ── Removed Departments Providers ──────────────────────────────────────────────
