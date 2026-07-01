// ─── SEASAME Assist-Pro — Ticket Attachment Model ─────────────────────────────
class TicketAttachment {
  final String id;
  final String ticketId;
  final String filePath;
  final DateTime uploadedAt;

  const TicketAttachment({
    required this.id,
    required this.ticketId,
    required this.filePath,
    required this.uploadedAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      filePath: json['file_path'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_id': ticketId,
        'file_path': filePath,
        'uploaded_at': uploadedAt.toIso8601String(),
      };

  /// Returns just the file name from the storage path.
  String get fileName => filePath.split('/').last;

  /// Returns the file extension (lower-cased), e.g. "pdf", "png".
  String get extension => fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';

  /// Simple MIME-category helper used for icon selection.
  AttachmentFileType get fileType {
    switch (extension) {
      case 'pdf':
        return AttachmentFileType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return AttachmentFileType.image;
      case 'doc':
      case 'docx':
        return AttachmentFileType.word;
      case 'xls':
      case 'xlsx':
        return AttachmentFileType.excel;
      default:
        return AttachmentFileType.other;
    }
  }
}

enum AttachmentFileType { pdf, image, word, excel, other }
