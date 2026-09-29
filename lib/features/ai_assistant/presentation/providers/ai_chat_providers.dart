import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/ai/ai_service.dart';
import '../../../../core/services/ai/firebase_ai_service.dart';
import '../../domain/entities/chat_message.dart';

const _maxHistoryTurns = 6;

class ChatState {
  const ChatState({this.messages = const [], this.remainingToday});

  final List<ChatMessage> messages;

  /// Cupo restante del último turno exitoso — `null` hasta el primer envío
  /// (nunca un valor fabricado antes de que el servidor lo confirme).
  final int? remainingToday;

  ChatState copyWith({List<ChatMessage>? messages, int? remainingToday}) {
    return ChatState(messages: messages ?? this.messages, remainingToday: remainingToday ?? this.remainingToday);
  }
}

/// Chat de IA (G1) — estado en memoria pura, sin persistencia (`.autoDispose`:
/// la conversación se pierde al salir de la pantalla, v1 deliberado, ver
/// `documentation/ai_assistant.md`). Cada turno reenvía los últimos
/// [_maxHistoryTurns] intercambios reales como contexto —
/// `askNutritionAssistant` no guarda estado de conversación del lado del
/// servidor.
final chatControllerProvider = NotifierProvider.autoDispose<ChatController, ChatState>(ChatController.new);

class ChatController extends AutoDisposeNotifier<ChatState> {
  int _nextId = 0;

  @override
  ChatState build() => const ChatState();

  String _newId() => '${_nextId++}';

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final history = _recentHistory(state.messages);
    final userMessage = ChatMessage(id: _newId(), role: ChatMessageRole.user, text: text);
    final pendingId = _newId();
    final pendingMessage = ChatMessage(id: pendingId, role: ChatMessageRole.assistant, text: '', isPending: true);
    state = state.copyWith(messages: [...state.messages, userMessage, pendingMessage]);

    try {
      final answer = await ref.read(aiServiceProvider).askNutritionQuestion(text, history: history);
      _replacePending(
        pendingId,
        (m) => m.copyWith(
          text: answer.answer,
          isPending: false,
          recommendsProfessionalConsult: answer.recommendsProfessionalConsult,
          safetyFallbackApplied: answer.safetyFallbackApplied,
        ),
      );
      state = state.copyWith(remainingToday: answer.remainingToday);
    } catch (error) {
      _replacePending(
        pendingId,
        (m) => m.copyWith(isPending: false, isError: true, isQuotaExceeded: error is AiQuotaExceededFailure),
      );
    }
  }

  void _replacePending(String id, ChatMessage Function(ChatMessage) update) {
    state = state.copyWith(
      messages: [for (final m in state.messages) if (m.id == id) update(m) else m],
    );
  }

  /// Últimos intercambios REALES (ni pendientes ni fallidos) — los mensajes
  /// se agregan siempre en pares (usuario, asistente), así que basta con
  /// recorrer de dos en dos.
  List<ChatTurn> _recentHistory(List<ChatMessage> messages) {
    final turns = <ChatTurn>[];
    for (var i = 0; i + 1 < messages.length; i += 2) {
      final userMsg = messages[i];
      final aiMsg = messages[i + 1];
      if (!aiMsg.isPending && !aiMsg.isError) {
        turns.add((question: userMsg.text, answer: aiMsg.text));
      }
    }
    if (turns.length > _maxHistoryTurns) return turns.sublist(turns.length - _maxHistoryTurns);
    return turns;
  }
}
