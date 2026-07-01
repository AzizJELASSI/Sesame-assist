// ─── SEASAME Assist-Pro — Comment Thread Widget ───────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/ticket.dart';
import '../../../core/supabase_client.dart';
import '../controllers/ticket_controller.dart';

class CommentThread extends ConsumerWidget {
  final String ticketId;

  const CommentThread({
    super.key,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final commentsAsync = ref.watch(ticketCommentsProvider(ticketId));

    return commentsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (comments) {
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start the conversation below.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _CommentBubble(
            comment: comments[i],
            isOwn: comments[i].authorId == SupabaseService.currentUser?.id,
          ),
        );
      },
    );
  }
}

// ── Ticket Chat Input ────────────────────────────────────────────────────────
class TicketChatInput extends ConsumerStatefulWidget {
  final String ticketId;
  final bool canAddInternal;

  const TicketChatInput({
    super.key,
    required this.ticketId,
    this.canAddInternal = false,
  });

  @override
  ConsumerState<TicketChatInput> createState() => _TicketChatInputState();
}

class _TicketChatInputState extends ConsumerState<TicketChatInput> {
  final _commentCtrl = TextEditingController();
  bool _isInternal = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.client.from('ticket_comments').insert({
        'ticket_id': widget.ticketId,
        'author_id': userId,
        'content': text,
        'is_internal': _isInternal,
      });

      _commentCtrl.clear();
      ref.invalidate(ticketCommentsProvider(widget.ticketId));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.canAddInternal)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Switch(
                    value: _isInternal,
                    onChanged: (v) => setState(() => _isInternal = v),
                    activeColor: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Internal note',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _isInternal
                              ? const Color(0xFF8B5CF6)
                              : scheme.onSurfaceVariant,
                          fontWeight: _isInternal ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _isInternal 
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: _isInternal
                        ? Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3))
                        : null,
                  ),
                  child: TextField(
                    controller: _commentCtrl,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _isInternal ? 'Type an internal note...' : 'Type a message...',
                      hintStyle: TextStyle(
                        color: _isInternal 
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                            : scheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 2), // Align with text field
                decoration: BoxDecoration(
                  color: _isInternal ? const Color(0xFF8B5CF6) : scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  color: scheme.onPrimary,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Comment Bubble ────────────────────────────────────────────────────────────
class _CommentBubble extends StatelessWidget {
  final TicketComment comment;
  final bool isOwn;

  const _CommentBubble({required this.comment, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('HH:mm').format(comment.createdAt.toLocal());
    final dateStr = DateFormat('MMM d').format(comment.createdAt.toLocal());

    // Define colors
    final Color bubbleColor;
    final Color textColor;
    final Color metaColor;

    if (comment.isInternal) {
      bubbleColor = const Color(0xFF8B5CF6).withValues(alpha: 0.15);
      textColor = scheme.onSurface;
      metaColor = const Color(0xFF8B5CF6);
    } else if (isOwn) {
      bubbleColor = scheme.primary;
      textColor = scheme.onPrimary;
      metaColor = scheme.onPrimary.withValues(alpha: 0.7);
    } else {
      bubbleColor = scheme.surfaceContainerHighest;
      textColor = scheme.onSurface;
      metaColor = scheme.onSurfaceVariant;
    }

    final initials = (comment.authorName ?? 'U')
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();

    return Padding(
      padding: EdgeInsets.only(
        left: isOwn ? 48.0 : 0,
        right: isOwn ? 0 : 48.0,
      ),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwn || comment.isInternal) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isOwn)
                          Text(
                            comment.authorName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (comment.isInternal) ...[
                          if (!isOwn) const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Internal Note',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isOwn ? const Radius.circular(4) : const Radius.circular(20),
                      bottomLeft: !isOwn ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    border: comment.isInternal
                        ? Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateStr, $timeStr',
                        style: TextStyle(
                          fontSize: 10,
                          color: metaColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isOwn) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
