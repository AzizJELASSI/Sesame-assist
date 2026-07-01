// ─── SEASAME Assist-Pro — AI Chat Controller ──────────────────────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/supabase_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/chat_message.dart';

final aiChatControllerProvider = StateNotifierProvider<AiChatController, AsyncValue<List<ChatMessage>>>((ref) {
  return AiChatController(ref);
});

class AiChatController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final Ref _ref;
  final _uuid = const Uuid();

  AiChatController(this._ref) : super(const AsyncData([])) {
    // Add initial greeting
    _addAiMessage('Hello! How can I help you draft a support ticket today?', isClarifying: true);
  }

  void reset() {
    state = const AsyncData([]);
    _addAiMessage('Hello! How can I help you draft a support ticket today?', isClarifying: true);
  }

  void _addAiMessage(String text, {bool isClarifying = false, Map<String, dynamic>? draft}) {
    final messages = state.valueOrNull ?? [];
    state = AsyncData([
      ...messages,
      ChatMessage(
        id: _uuid.v4(),
        text: text,
        role: ChatRole.ai,
        timestamp: DateTime.now(),
        isClarifying: isClarifying,
        draft: draft,
      )
    ]);
  }

  void _addUserMessage(String text) {
    final messages = state.valueOrNull ?? [];
    state = AsyncData([
      ...messages,
      ChatMessage(
        id: _uuid.v4(),
        text: text,
        role: ChatRole.user,
        timestamp: DateTime.now(),
      )
    ]);
  }

  Future<void> sendMessage(String text, String locale) async {
    _addUserMessage(text);
    
    // Set state to loading while keeping previous messages
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncLoading<List<ChatMessage>>().copyWithPrevious(AsyncData(currentMessages));

    try {
      final supabase = SupabaseService.client;
      final profile = _ref.read(currentProfileProvider);
      
      if (profile == null) throw Exception("User not found");

      // Build history for Gemini (excluding the latest message which is sent separately)
      // We only send user messages and ai messages. The edge function expects:
      // { role: "user" | "model", parts: [{text: ""}] }
      final history = currentMessages.map((m) {
        return {
          'role': m.role == ChatRole.user ? 'user' : 'model',
          'parts': [{'text': m.text}],
        };
      }).toList();

      final response = await supabase.functions.invoke(
        'process-ticket-intent',
        body: {
          'message': text,
          'role': profile.role,
          'history': history,
          'locale': locale,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to process intent: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      
      final isClarifying = data['is_clarifying'] as bool? ?? true;
      final clarifyingQuestion = data['clarifying_question'] as String?;
      final draft = data['draft'] as Map<String, dynamic>?;

      if (isClarifying && clarifyingQuestion != null) {
        _addAiMessage(clarifyingQuestion, isClarifying: true);
      } else if (!isClarifying && draft != null) {
        _addAiMessage('Here is a draft of your ticket. Does this look correct?', isClarifying: false, draft: draft);
      } else {
        _addAiMessage('I am having trouble understanding. Could you provide more details?', isClarifying: true);
      }
      
    } catch (e) {
      _addAiMessage('Sorry, I encountered an error: $e\n\nPlease check if your Gemini API key is set in Supabase secrets.', isClarifying: true);
    }
  }
}
