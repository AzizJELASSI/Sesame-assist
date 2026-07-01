// ─── SEASAME Assist-Pro — AI Chat Screen (with Text-to-Speech) ─────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/enums/department_filiere.dart';
import 'package:seasame_assist_pro/l10n/generated/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../controllers/ai_chat_controller.dart';
import '../controllers/ticket_controller.dart';
import '../models/chat_message.dart';

class AiTicketChatScreen extends ConsumerStatefulWidget {
  const AiTicketChatScreen({super.key});

  @override
  ConsumerState<AiTicketChatScreen> createState() => _AiTicketChatScreenState();
}

class _AiTicketChatScreenState extends ConsumerState<AiTicketChatScreen>
    with SingleTickerProviderStateMixin {
  // ── Text input
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  // ── Speech-to-Text
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // ── Text-to-Speech
  late final FlutterTts _flutterTts;
  bool _isSpeaking = false;
  String? _speakingMessageId;

  // ── Ticket creation state
  bool _isCreatingTicket = false;

  // ── Pulse animation for speaking indicator
  late final AnimationController _pulseController;

  // ── Track message count to detect new AI messages
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initSpeech();
    _initTts();
  }

  // ── TTS init
  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() { _isSpeaking = false; _speakingMessageId = null; });
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() { _isSpeaking = false; _speakingMessageId = null; });
    });
    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      if (mounted) setState(() { _isSpeaking = false; _speakingMessageId = null; });
    });
  }

  String _localeToBcp47(String code) {
    switch (code) {
      case 'ar': return 'ar-SA';
      case 'fr': return 'fr-FR';
      default:   return 'en-US';
    }
  }

  Future<void> _speak(String text, {String? messageId, String locale = 'en'}) async {
    await _flutterTts.setLanguage(_localeToBcp47(locale));
    if (_isSpeaking) {
      await _flutterTts.stop();
      // Tapping the same bubble again = toggle off
      if (_speakingMessageId == messageId) return;
    }
    setState(() => _speakingMessageId = messageId);
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) setState(() { _isSpeaking = false; _speakingMessageId = null; });
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (e) {
        debugPrint('Speech error: ${e.errorMsg}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone Error: ${e.errorMsg}')),
          );
          setState(() => _isListening = false);
        }
      },
      onStatus: (s) {
        debugPrint('Speech status: $s');
        if ((s == 'notListening' || s == 'done') && mounted) {
          setState(() => _isListening = false);
          // Auto-send when the user stops talking
          if (_textController.text.trim().isNotEmpty) _sendMessage();
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    // Stop TTS before opening mic
    if (_isSpeaking) await _stopSpeaking();
    await _speechToText.listen(
      onResult: _onSpeechResult,
      cancelOnError: true,
      partialResults: true,
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _textController.text = result.recognizedWords;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  void _toggleListening() async {
    if (!_speechEnabled) {
      // Try initializing again
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available or permission was denied.')),
          );
        }
        return;
      }
    }

    if (_speechToText.isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final locale = Localizations.localeOf(context).languageCode;
    _textController.clear();
    
    ref.read(aiChatControllerProvider.notifier).sendMessage(text, locale);
    
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _confirmDraft(Map<String, dynamic> draft) async {
    setState(() => _isCreatingTicket = true);
    try {
      final department = Department.fromString(draft['department_id']?.toString());

      if (department == null) {
        throw Exception("Invalid department ID from AI: ${draft['department_id']}");
      }

      final String title = draft['title']?.toString() ?? 'Ticket';
      final String description = draft['description']?.toString() ?? '';
      final String ticketType = draft['ticket_type']?.toString() ?? 'it_issue';
      final String priority = draft['priority']?.toString().toLowerCase() ?? 'medium';

      final ticket = await ref.read(myTicketsProvider.notifier).createTicket(
            title: title,
            description: description,
            ticketType: ticketType,
            priority: priority,
            department: department,
            attachments: [],
          );

      if (mounted && ticket != null) {
        ref.read(aiChatControllerProvider.notifier).reset(); // clear chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ticket created successfully!'),
            backgroundColor: AppTheme.statusColor('resolved'),
          ),
        );
        // Replace current screen with the new ticket detail screen
        context.pushReplacement(AppRoutes.ticketDetail(ticket.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating ticket: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingTicket = false);
      }
    }
  }

  // ── Speaking pill widget
  Widget _buildSpeakingPill(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final opacity = 0.6 + 0.4 * _pulseController.value;
        return Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTap: _stopSpeaking,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded, size: 14,
                      color: scheme.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Speaking…',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatState = ref.watch(aiChatControllerProvider);

    // Auto-speak the latest AI message
    ref.listen<AsyncValue<List<ChatMessage>>>(aiChatControllerProvider, (_, next) {
      final messages = next.valueOrNull;
      if (messages == null) return;
      if (messages.length > _prevMessageCount) {
        _prevMessageCount = messages.length;
        final last = messages.last;
        if (last.role == ChatRole.ai && last.draft == null) {
          final locale = Localizations.localeOf(context).languageCode;
          _speak(last.text, messageId: last.id, locale: locale);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          if (_isSpeaking)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildSpeakingPill(scheme),
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _stopSpeaking();
            ref.read(aiChatControllerProvider.notifier).reset();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when(
              loading: () => _buildMessageList(chatState.valueOrNull ?? [], isLoading: true),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (messages) => _buildMessageList(messages, isLoading: false),
            ),
          ),
          _buildInputArea(scheme),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, {required bool isLoading}) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == messages.length) {
          return _buildTypingIndicator();
        }
        final message = messages[i];
        final isUser = message.role == ChatRole.user;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight: isUser ? const Radius.circular(0) : null,
                    bottomLeft: !isUser ? const Radius.circular(0) : null,
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isUser 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // ── Speaker button for AI messages
              if (!isUser) ...[
                const SizedBox(height: 4),
                _buildSpeakerButton(message),
              ],
              if (message.draft != null) ...[
                const SizedBox(height: 8),
                _buildDraftCard(message.draft!),
              ]
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: const Radius.circular(0)),
        ),
        child: const SizedBox(
          width: 40,
          height: 20,
          child: Center(
            child: LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms),
    );
  }

  // ── Per-message speaker/stop button
  Widget _buildSpeakerButton(ChatMessage message) {
    final isThisOne = _speakingMessageId == message.id && _isSpeaking;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        final locale = Localizations.localeOf(context).languageCode;
        _speak(message.text, messageId: message.id, locale: locale);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isThisOne
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isThisOne ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
              size: 13,
              color: isThisOne ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              isThisOne ? 'Stop' : 'Listen',
              style: TextStyle(
                fontSize: 11,
                color: isThisOne ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> draft) {
    final scheme = Theme.of(context).colorScheme;
    final priorityColor = AppTheme.priorityColor(draft['priority'] ?? 'medium');

    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ticket Draft',
                  style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (draft['priority'] ?? 'medium').toString().toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                ),
              )
            ],
          ),
          const Divider(height: 24),
          Text(draft['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(draft['description'] ?? '', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDraftChip(Icons.category, draft['ticket_type'] ?? 'Unknown'),
              _buildDraftChip(
                Department.fromString(draft['department_id']?.toString())?.icon ?? Icons.business,
                Department.fromString(draft['department_id']?.toString())?.label ?? (draft['department_id'] ?? 'Unknown'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isCreatingTicket ? null : () => _confirmDraft(draft),
              icon: _isCreatingTicket 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text(_isCreatingTicket ? 'Creating...' : 'Confirm & Create'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDraftChip(IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme scheme) {
    final isLoading = ref.watch(aiChatControllerProvider).isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Describe your issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isListening ? Colors.red.withValues(alpha: 0.1) : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? Colors.red : scheme.primary,
              ),
              onPressed: _toggleListening,
            ),
          ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded),
              color: scheme.onPrimary,
              onPressed: isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
