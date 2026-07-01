import '../enums/department_filiere.dart';

// ─── SEASAME Assist-Pro — Ticket Model ────────────────────────────────────────
class Ticket {
  final String id;
  final String title;
  final String description;
  final String ticketType;
  final String priority; // 'low' | 'medium' | 'high'
  final String status; // 'open' | 'in_progress' | 'waiting_on_user' | 'resolved' | 'closed'
  final String createdBy;
  final String? assignedTo;
  final Department department;
  final DateTime? resolvedAt;
  final Map<String, dynamic>? aiDraft;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (populated via select with joins)
  final String? creatorName;
  final String? assigneeName;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.ticketType,
    required this.priority,
    required this.status,
    required this.createdBy,
    this.assignedTo,
    required this.department,
    this.resolvedAt,
    this.aiDraft,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
    this.assigneeName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Handle joined profile rows
    final creatorProfile = json['creator'] as Map<String, dynamic>?;
    final assigneeProfile = json['assignee'] as Map<String, dynamic>?;

    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      ticketType: json['ticket_type'] as String,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      department: Department.fromString(json['department_id'] as String?) ??
          Department.uniteIT,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      aiDraft: json['ai_draft'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      creatorName: creatorProfile?['full_name'] as String?,
      assigneeName: assigneeProfile?['full_name'] as String?,
    );
  }

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved' || status == 'closed';
  bool get isHighPriority => priority == 'high';
  bool get hasAiDraft => aiDraft != null;
}

// ─── TicketComment Model ───────────────────────────────────────────────────────
class TicketComment {
  final String id;
  final String ticketId;
  final String authorId;
  final String content;
  final bool isInternal;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatar;

  const TicketComment({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.content,
    required this.isInternal,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return TicketComment(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      isInternal: json['is_internal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: author?['full_name'] as String?,
      authorAvatar: author?['avatar_url'] as String?,
    );
  }
}
