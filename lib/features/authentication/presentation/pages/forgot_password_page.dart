import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_back_button.dart';

/// A5 · Recuperar contraseña.
///
/// El diseño solo especifica la pantalla de confirmación ("Revisa tu
/// correo"); el formulario de pedir el correo se construyó siguiendo el
/// mismo lenguaje visual de Login/SignUp (ver documentation/authentication.md
/// "known gaps"). La confirmación se muestra siempre igual exista o no la
/// cuenta — [AuthRepository.sendPasswordResetEmail] nunca lanza por cuenta
/// inexistente (ver auth_repository.dart).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  String? _emailError;
  String? _sentToEmail;

  Future<void> _submit() async {
    final value = _emailController.text.trim();
    setState(() {
      _emailError = value.isEmpty
          ? context.l10n.validationEmailRequired
          : !Validators.isValidEmail(value)
              ? context.l10n.validationEmailInvalid
              : null;
    });
    if (_emailError != null) return;

    await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email: value);
    if (!mounted) return;
    if (!ref.read(authControllerProvider).hasError) {
      setState(() => _sentToEmail = value);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space20,
            AppSpacing.space24,
            AppSpacing.space20,
            AppSpacing.space20,
          ),
          child: _sentToEmail == null
              ? _RequestForm(
                  emailController: _emailController,
                  emailError: _emailError,
                  isLoading: isLoading,
                  onSubmit: _submit,
                )
              : _SentConfirmation(email: _sentToEmail!, onResend: _submit),
        ),
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.emailController,
    required this.emailError,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final String? emailError;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBackButton(),
        const SizedBox(height: AppSpacing.space24),
        Text(
          l10n.authForgotPasswordTitle,
          style: AppTypography.display.copyWith(fontSize: 26, color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          l10n.authForgotPasswordSubtitle,
          style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.space24),
        AppTextField(label: l10n.fieldEmailLabel, controller: emailController, errorText: emailError),
        const SizedBox(height: AppSpacing.space20),
        AppButton(
          label: l10n.authForgotPasswordSubmitButton,
          fullWidth: true,
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _SentConfirmation extends StatefulWidget {
  const _SentConfirmation({required this.email, required this.onResend});

  final String email;
  final VoidCallback onResend;

  @override
  State<_SentConfirmation> createState() => _SentConfirmationState();
}

class _SentConfirmationState extends State<_SentConfirmation> {
  static const _resendCooldown = 60;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = _resendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// `mailto:` sin destinatario abre el cliente de correo por defecto del
  /// dispositivo (o el selector, si hay varios) — no compone un mensaje, solo
  /// abre la app. Si ninguna app maneja el esquema (p. ej. escritorio/web sin
  /// cliente configurado), simplemente vuelve a la pantalla anterior, el
  /// mismo comportamiento que tenía este botón antes de existir de verdad.
  Future<void> _openMailApp(BuildContext context) async {
    final launched = await launchUrl(Uri(scheme: 'mailto'));
    if (!launched && context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBackButton(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: colors.actionPrimarySurface, borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.center,
                  child: Icon(Icons.check, size: 28, color: colors.actionPrimary),
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  l10n.authForgotPasswordSentTitle,
                  style: AppTypography.display.copyWith(fontSize: 24, color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.space8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.authForgotPasswordSentMessage(widget.email),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppButton(
          label: l10n.authForgotPasswordOpenMailButton,
          fullWidth: true,
          onPressed: () => _openMailApp(context),
        ),
        const SizedBox(height: AppSpacing.space12),
        Center(
          child: _secondsLeft > 0
              ? Text(
                  l10n.authForgotPasswordResendCountdown(_secondsLeft),
                  style: AppTypography.label.copyWith(fontSize: 13.5, color: colors.textDisabled),
                )
              : GestureDetector(
                  onTap: () {
                    widget.onResend();
                    _startCountdown();
                  },
                  child: Text(
                    l10n.authForgotPasswordResendAction,
                    style: AppTypography.label.copyWith(fontSize: 13.5, color: colors.actionPrimary),
                  ),
                ),
        ),
      ],
    );
  }
}
