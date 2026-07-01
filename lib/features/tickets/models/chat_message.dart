// ─── SEASAME Assist-Pro — Chat Message Model ──────────────────────────────────
import 'package:flutter/foundation.dart';

enum ChatRole { user, ai }

class ChatMessage {
  final String id;
  final String text;
  final ChatRole role;
  final DateTime timestamp;
  final bool isClarifying;
  final Map<String, dynamic>? draft; // The structured JSON draft if any

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.isClarifying = false,
    this.draft,
  });

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'parts': [
          {'text': text}
        ],
      };
}
