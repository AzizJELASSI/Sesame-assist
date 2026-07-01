// ─── SEASAME Assist-Pro — Attachment Tile Widget ──────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import '../../../core/models/ticket_attachment.dart';
import '../../../core/theme.dart';
import '../controllers/ticket_controller.dart';

class AttachmentTile extends ConsumerWidget {
  final TicketAttachment attachment;
  final int animationIndex;

  const AttachmentTile({
    super.key,
    required this.attachment,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final signedUrlAsync = ref.watch(
      attachmentSignedUrlProvider(attachment.filePath),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.attachmentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.attachmentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // ── File type icon ─────────────────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor(attachment.fileType).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _fileIcon(attachment.fileType),
              size: 20,
              color: _iconColor(attachment.fileType),
            ),
          ),
          const SizedBox(width: 12),

          // ── File name & size ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.extension.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Download button ────────────────────────────────────────────────
          signedUrlAsync.when(
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Icon(
              Icons.error_outline,
              color: scheme.error,
              size: 20,
            ),
            data: (url) => IconButton(
              tooltip: AppLocalizations.of(context)!.attachmentDownload,
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(
                Icons.download_rounded,
                color: AppTheme.attachmentColor,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * animationIndex), duration: 350.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  IconData _fileIcon(AttachmentFileType type) {
    switch (type) {
      case AttachmentFileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case AttachmentFileType.image:
        return Icons.image_rounded;
      case AttachmentFileType.word:
        return Icons.description_rounded;
      case AttachmentFileType.excel:
        return Icons.table_chart_rounded;
      case AttachmentFileType.other:
        return Icons.attach_file_rounded;
    }
  }

  Color _iconColor(AttachmentFileType type) {
    switch (type) {
      case AttachmentFileType.pdf:
        return const Color(0xFFEF4444); // red
      case AttachmentFileType.image:
        return const Color(0xFF3B82F6); // blue
      case AttachmentFileType.word:
        return const Color(0xFF2563EB); // indigo
      case AttachmentFileType.excel:
        return const Color(0xFF10B981); // green
      case AttachmentFileType.other:
        return const Color(0xFF6B7280); // gray
    }
  }
}

// ── Attachment list header widget (reused in create + detail) ─────────────────
class AttachmentListSection extends StatelessWidget {
  final List<String> fileNames;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const AttachmentListSection({
    super.key,
    required this.fileNames,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_rounded,
                size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              l10n.attachments,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l10n.addAttachment),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        if (fileNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...fileNames.asMap().entries.map((e) => _SelectedFileTile(
                name: e.value,
                onRemove: () => onRemove(e.key),
                scheme: scheme,
              )),
        ],
      ],
    );
  }
}

class _SelectedFileTile extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  final ColorScheme scheme;

  const _SelectedFileTile({
    required this.name,
    required this.onRemove,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.attachmentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.attachmentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_rounded,
              size: 16, color: AppTheme.attachmentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 18, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
