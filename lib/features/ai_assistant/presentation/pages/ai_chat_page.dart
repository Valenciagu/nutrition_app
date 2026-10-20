import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/ai_chat_providers.dart';

const List<String> _suggestionKeys = ['aiSuggestionDinner', 'aiSuggestionMoreProtein', 'aiSuggestionNoDairy'];

/// G1 · IA (canvas "Fases 5-12 - Entrega final", bloque Fase 7). Reemplaza
/// `ComingSoonPage` en el tab "IA" — resuelve la pregunta abierta de dónde
/// vive un chat general con `AIService.askNutritionQuestion` (Épica 5,
/// nunca consumido hasta ahora). Deliberadamente NO incluye las "acciones
/// ejecutables" del mock (chips "Recalcular mi día"/"Ver la cena nueva",
/// tarjeta de receta inline) — eso necesita que el backend pueda proponer
/// una acción estructurada, no solo texto; `askNutritionAssistant` no lo
/// hace hoy. Ver `documentation/ai_assistant.md`.
class AiChatPage extends ConsumerWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isLoggedIn = ref.watch(authStateChangesProvider).valueOrNull != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space20),
              child: AppStateBlock.empty(
                title: l10n.aiGuestTitle,
                message: l10n.aiGuestMessage,
                actionLabel: l10n.aiGuestCta,
                onAction: () => context.go(RoutePaths.signUp),
              ),
            ),
          ),
        ),
      );
    }

    return const _ChatScaffold();
  }
}

class _ChatScaffold extends ConsumerStatefulWidget {
  const _ChatScaffold();

  @override
  ConsumerState<_ChatScaffold> createState() => _ChatScaffoldState();
}

class _ChatScaffoldState extends ConsumerState<_ChatScaffold> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(chatControllerProvider.notifier).send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final chatState = ref.watch(chatControllerProvider);

    ref.listen(chatControllerProvider, (previous, next) {
      if (next.messages.length != previous?.messages.length) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.space24),
                        child: Text(
                          l10n.aiChatEmptyStateMessage,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyM.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) => _MessageBubble(message: chatState.messages[index]),
                    ),
            ),
            _Footer(
              controller: _textController,
              remainingToday: chatState.remainingToday,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space12, AppSpacing.space20, AppSpacing.space12),
      decoration: BoxDecoration(color: colors.surface, border: Border(bottom: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.aiActionSurface,
              border: Border.all(color: colors.onAiAction.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Icon(AppIcons.ai, size: 18, color: colors.onAiAction),
          ),
          const SizedBox(width: AppSpacing.space12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.aiChatTitle, style: AppTypography.titleS.copyWith(fontSize: 15.5, color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text(
                l10n.aiChatSubtitle,
                style: AppTypography.bodyM.copyWith(fontSize: 11.5, color: colors.actionPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isUser = message.role == ChatMessageRole.user;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.82 : 0.88)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? colors.actionPrimary : colors.surface,
        border: isUser ? null : Border.all(color: colors.border),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 18),
        ),
      ),
      child: message.isPending
          ? const _TypingDots()
          : Text(
              message.isError
                  ? (message.isQuotaExceeded ? l10n.aiChatQuotaExceededMessage : l10n.genericErrorMessage)
                  : message.text,
              style: AppTypography.bodyM.copyWith(
                fontSize: 14.5,
                height: 1.5,
                color: isUser ? Colors.white : (message.isError ? colors.error : colors.textPrimary),
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          bubble,
          if (!message.isPending && !message.isError && message.recommendsProfessionalConsult)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.aiChatProfessionalConsultNote,
                style: AppTypography.bodyM.copyWith(fontSize: 11.5, color: colors.warning),
              ),
            ),
          if (!message.isPending && !message.isError && message.safetyFallbackApplied)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.aiChatSafetyFallbackNote,
                style: AppTypography.bodyM.copyWith(fontSize: 11.5, color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Opacity(
                opacity: (0.3 + 0.7 * ((_controller.value + i / 3) % 1.0)).clamp(0.3, 1.0),
                child: Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: colors.onAiAction)),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller, required this.remainingToday, required this.onSend});

  final TextEditingController controller;
  final int? remainingToday;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space20,
        AppSpacing.space8,
        AppSpacing.space20,
        AppSpacing.space12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (remainingToday != null) ...[
            Text(
              l10n.aiChatRemainingToday(remainingToday!),
              style: AppTypography.bodyM.copyWith(fontSize: 11.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestionKeys.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = _suggestionLabel(l10n, _suggestionKeys[index]);
                return GestureDetector(
                  onTap: () => onSend(label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: Text(label, style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textPrimary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.only(left: 18),
                  decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: onSend,
                    style: AppTypography.bodyM.copyWith(fontSize: 14.5, color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.aiChatInputPlaceholder,
                      hintStyle: AppTypography.bodyM.copyWith(fontSize: 14.5, color: colors.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: colors.actionPrimary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onSend(controller.text),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(AppIcons.send, size: 20, color: colors.onActionPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _suggestionLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'aiSuggestionDinner' => l10n.aiSuggestionDinner,
      'aiSuggestionMoreProtein' => l10n.aiSuggestionMoreProtein,
      'aiSuggestionNoDairy' => l10n.aiSuggestionNoDairy,
      _ => '',
    };
  }
}
