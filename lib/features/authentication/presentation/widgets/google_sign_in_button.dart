import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';

/// Colores que exige la guía de marca de Google para "Sign in with Google"
/// (developers.google.com/identity/branding-guidelines) — no son tokens del
/// design system de la app y no deben usarse en ningún otro lado. Ver
/// "Google button" en `documentation/design_system.md`.
abstract final class _GoogleBrand {
  static const lightFill = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFF747775);
  static const lightText = Color(0xFF1F1F1F);
  static const darkFill = Color(0xFF131314);
  static const darkBorder = Color(0xFF8E918F);
  static const darkText = Color(0xFFE3E3E3);
}

/// Botón "Continuar con Google" (Login A3 y SignUp A4). No es una variante
/// de `AppButton` a propósito: la guía de Google pisa el estilo genérico de
/// botón social de Fase 2 — colores propios por tema, Roboto Medium 14/20
/// (la única excepción a la fuente única de la app) y la "G" oficial de
/// 20x20 con su padding por plataforma (Android 12·G·10·texto·12,
/// iOS 16·G·12·texto·16). Alto 52 y forma de píldora, como el resto.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;

  /// Igual que `AppButton`: el spinner reemplaza a la "G", el texto se queda
  /// y el ancho no salta.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? _GoogleBrand.darkFill : _GoogleBrand.lightFill;
    final border = isDark ? _GoogleBrand.darkBorder : _GoogleBrand.lightBorder;
    final text = isDark ? _GoogleBrand.darkText : _GoogleBrand.lightText;

    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final edgePadding = isIos ? 16.0 : 12.0;
    final iconGap = isIos ? 12.0 : 10.0;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: fill,
          disabledBackgroundColor: fill,
          foregroundColor: text,
          side: BorderSide(color: border),
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: edgePadding),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 20,
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 2, color: text),
                    )
                  : Image.asset(isDark ? AppAssets.googleGDark : AppAssets.googleGLight, width: 20, height: 20),
            ),
            SizedBox(width: iconGap),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
