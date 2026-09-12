import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_error_presentation.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_back_button.dart';

/// A3 · Iniciar sesión.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => _onFieldBlur(_emailFocus, _validateEmailOnBlur));
    _passwordFocus.addListener(() => _onFieldBlur(_passwordFocus, _validatePasswordOnBlur));
  }

  void _onFieldBlur(FocusNode node, VoidCallback validate) {
    if (!node.hasFocus) validate();
  }

  void _validateEmailOnBlur() {
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

  void _validatePasswordOnBlur() {
    setState(() {
      _passwordError = _passwordController.text.isEmpty ? context.l10n.validationPasswordRequired : null;
    });
  }

  Future<void> _submit() async {
    _validateEmailOnBlur();
    _validatePasswordOnBlur();
    if (_emailError != null || _passwordError != null) return;

    await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            _emailError ??= presentation.emailError;
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
              const SizedBox(height: AppSpacing.space24),
              Text(l10n.authLoginTitle, style: AppTypography.display.copyWith(fontSize: 28, color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.space24),
              AppTextField(
                label: l10n.fieldEmailLabel,
                controller: _emailController,
                focusNode: _emailFocus,
                errorText: _emailError,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: AppSpacing.space12),
              AppTextField(
                label: l10n.fieldPasswordLabel,
                controller: _passwordController,
                focusNode: _passwordFocus,
                kind: AppTextFieldKind.password,
                errorText: _passwordError,
                showPasswordActionLabel: l10n.fieldShowPasswordAction,
                hidePasswordActionLabel: l10n.fieldHidePasswordAction,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () => context.push(RoutePaths.forgotPassword),
                    child: Text(
                      l10n.authLoginForgotPassword,
                      style: AppTypography.label.copyWith(fontSize: 13, color: colors.actionPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              AppButton(
                label: l10n.authLoginSubmitButton,
                fullWidth: true,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.space24),
              Center(
                child: GestureDetector(
                  onTap: () => context.push(RoutePaths.signUp),
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodyM.copyWith(fontSize: 13.5, color: colors.textSecondary),
                      children: [
                        TextSpan(text: l10n.authLoginSignUpPrompt),
                        TextSpan(
                          text: l10n.authLoginSignUpAction,
                          style: AppTypography.label.copyWith(fontSize: 13.5, color: colors.actionPrimary),
                        ),
                      ],
                    ),
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
