import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../auth_error_presentation.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/legal_acceptance_checkbox.dart';
import '../widgets/password_strength_indicator.dart';

/// A4 · Crear cuenta.
///
/// El diseño (Fase 2 · A4) ubica esta pantalla justo después del
/// onboarding, con un banner "tu plan ya está calculado". La Épica 3
/// (Onboarding) todavía no existe, así que [hasPendingPlan] llega en falso
/// desde el router por ahora — cuando el onboarding exista, pasará a
/// depender de si hay un plan generado sin guardar.
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key, this.hasPendingPlan = false});

  final bool hasPendingPlan;

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  bool _acceptedTerms = false;
  bool _showTermsError = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => _onBlur(_nameFocus, _validateName));
    _emailFocus.addListener(() => _onBlur(_emailFocus, _validateEmail));
    _passwordFocus.addListener(() => _onBlur(_passwordFocus, _validatePassword));
    _passwordController.addListener(() => setState(() {}));
  }

  void _onBlur(FocusNode node, VoidCallback validate) {
    if (!node.hasFocus) validate();
  }

  void _validateName() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? context.l10n.validationNameRequired : null;
    });
  }

  void _validateEmail() {
    final value = _emailController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _emailError = context.l10n.validationEmailRequired;
      } else if (!Validators.isValidEmail(value)) {
        _emailError = context.l10n.validationEmailInvalid;
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final value = _passwordController.text;
      if (value.isEmpty) {
        _passwordError = context.l10n.validationPasswordRequired;
      } else if (!Validators.isValidPassword(value)) {
        _passwordError = context.l10n.validationPasswordTooShort;
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _submit() async {
    _validateName();
    _validateEmail();
    _validatePassword();
    setState(() => _showTermsError = !_acceptedTerms);
    if (_nameError != null || _emailError != null || _passwordError != null || !_acceptedTerms) return;

    await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  /// Si venía de B9 ya hay una sesión anónima (con el plan ya en Firestore
  /// bajo ese `uid`) — `ensureAnonymousSession` no hace nada en ese caso. Si
  /// llegó aquí directo desde Login sin pasar por Onboarding, esto le da una
  /// sesión real igual, para que Plan/IA funcionen como invitado también por
  /// ese camino. `ensureAnonymousSession` no pasa por el `state` del
  /// controlador (ver su doc), así que el error se captura aquí: sin esto un
  /// fallo de Firebase quedaba como excepción no capturada y el botón no
  /// hacía nada.
  Future<void> _continueAsGuest() async {
    try {
      await ref.read(authControllerProvider.notifier).ensureAnonymousSession();
    } on AuthFailure catch (e) {
      debugPrint('Anonymous sign-in failed: ${e.code} — ${e.message}');
      if (!mounted) return;
      final message = mapAuthError(context.l10n, e).generalError ?? context.l10n.authErrorGeneric;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    await ref.read(onboardingRepositoryProvider).clearDraft();
    if (mounted) context.go(RoutePaths.root);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final presentation = mapAuthError(l10n, error);
          setState(() {
            _emailError = presentation.emailError ?? _emailError;
            _passwordError = presentation.passwordError ?? _passwordError;
          });
          if (presentation.generalError != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(presentation.generalError!)));
          }
        },
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space20,
            AppSpacing.space24,
            AppSpacing.space20,
            AppSpacing.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthBackButton(),
              const SizedBox(height: AppSpacing.space20),
              if (widget.hasPendingPlan) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.actionPrimarySurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: colors.actionPrimary, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Icon(AppIcons.check, size: 18, color: colors.onActionPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.authSignUpPlanReadyBanner,
                          style: AppTypography.label.copyWith(fontSize: 13, color: colors.onActionPrimarySurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space20),
              ],
              Text(l10n.authSignUpTitle, style: AppTypography.display.copyWith(fontSize: 28, color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.space20),
              AppTextField(
                label: l10n.fieldNameLabel,
                controller: _nameController,
                focusNode: _nameFocus,
                errorText: _nameError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.space12),
              AppTextField(
                label: l10n.fieldEmailLabel,
                controller: _emailController,
                focusNode: _emailFocus,
                errorText: _emailError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.space12),
              AppTextField(
                label: l10n.fieldPasswordLabel,
                controller: _passwordController,
                focusNode: _passwordFocus,
                kind: AppTextFieldKind.password,
                errorText: _passwordError,
                hintText: _passwordError == null ? l10n.authPasswordHintMin : null,
                showPasswordActionLabel: l10n.fieldShowPasswordAction,
                hidePasswordActionLabel: l10n.fieldHidePasswordAction,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              PasswordStrengthIndicator(password: _passwordController.text),
              const SizedBox(height: AppSpacing.space16),
              LegalAcceptanceCheckbox(
                value: _acceptedTerms,
                onChanged: (value) => setState(() {
                  _acceptedTerms = value;
                  _showTermsError = false;
                }),
              ),
              if (_showTermsError) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.validationTermsRequired,
                  style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.space20),
              AppButton(
                label: widget.hasPendingPlan ? l10n.authSignUpSubmitWithPlanButton : l10n.authSignUpSubmitButton,
                fullWidth: true,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.space20),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
                    child: Text(l10n.authLoginOrDivider, style: AppTypography.bodyM.copyWith(color: colors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: colors.border)),
                ],
              ),
              const SizedBox(height: AppSpacing.space20),
              // Desviación deliberada del canvas (A4 no muestra este botón,
              // solo A3/Login lo tiene) — confirmada con el usuario
              // 2026-10-05: `signInWithGoogle()` ya resuelve login vs.
              // registro server-side (Firebase decide según si el correo ya
              // tiene cuenta), así que tenerlo también aquí no agrega
              // trabajo nuevo y evita que alguien recién salido del
              // onboarding tenga que retroceder hasta Login para usarlo.
              // Solo Google, mismo motivo que en Login: Apple sigue
              // parqueado con la Épica 13 (cuenta de pago pendiente).
              AppButton(
                label: l10n.authLoginGoogleButton,
                variant: AppButtonVariant.neutral,
                fullWidth: true,
                isLoading: isLoading,
                onPressed: _signInWithGoogle,
              ),
              const SizedBox(height: AppSpacing.space12),
              Center(
                child: GestureDetector(
                  onTap: _continueAsGuest,
                  child: Text(
                    l10n.authSignUpGuestAction,
                    style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textDisabled),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
