# Épica 2 — Autenticación

## Qué hace

Email/contraseña con Firebase Auth: splash con guarda de sesión, welcome, login, registro y recuperar contraseña. El router redirige automáticamente según haya o no sesión activa.

**Estado: conectado a un proyecto de Firebase real** (`nutritionapp-eee08`, `FOUND-009` resuelto el 2026-09-11). Compila y pasa `flutter analyze`/`flutter build`. Pendiente: probarlo corriendo la app de verdad (`flutter run`) e intentar registro/login — solo se validó por compilación hasta ahora.

## Archivos clave

- `lib/features/authentication/domain/` — `AuthUser` (entidad), `AuthRepository` (contrato).
- `lib/features/authentication/data/` — `FirebaseAuthDataSource` (única clase del proyecto que importa `package:firebase_auth`), `AuthRepositoryImpl` (mapea `AuthException` → `AuthFailure`).
- `lib/features/authentication/presentation/providers/auth_providers.dart` — `authRepositoryProvider`, `authStateChangesProvider` (consumido por el router), `authControllerProvider` (`AsyncNotifier` para login/registro/reset, sin `riverpod_generator` — API manual, ver "Notas de arquitectura").
- `lib/features/authentication/presentation/auth_error_presentation.dart` — mapea códigos de Firebase a copy localizado, decidiendo a qué campo pertenece cada error.
- `lib/features/authentication/presentation/pages/` — `splash_page.dart`, `welcome_page.dart`, `login_page.dart`, `sign_up_page.dart`, `forgot_password_page.dart`.
- `lib/features/authentication/presentation/widgets/` — `AuthBackButton`, `LegalNoticeText`, `LegalAcceptanceCheckbox`, `PasswordStrengthIndicator` (específicos de esta feature, no forman parte de las 10 fichas base — ver `documentation/design_system.md`).
- `lib/core/router/go_router_refresh_stream.dart` — adapta el stream de auth a `Listenable` para que GoRouter re-evalúe `redirect` sin recrear el router.
- `lib/core/services/firebase_instances.dart` — provider crudo de `FirebaseAuth.instance`.
- `lib/core/widgets/firebase_setup_required_page.dart` — pantalla de desarrollador cuando `Firebase.initializeApp()` falla.

Diseño: `documentation/design_screens_auth.md` (specs completas de las 5 pantallas).

## Configuración de Firebase (FOUND-009)

`lib/firebase_options.dart` fue generado por `flutterfire configure` (proyecto `nutritionapp-eee08`, plataformas android/ios/web) y `main.dart` llama `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` dentro de un `try/catch`. Si esa llamada fallara (proyecto desconectado, credenciales revocadas), se muestra `FirebaseSetupRequiredPage` en vez de un crash críptico — ya no debería activarse en el uso normal, pero se deja como salvaguarda.

Nota: `android/app/google-services.json` sí se generó; `ios/Runner/GoogleService-Info.plist` no (se corrió `flutterfire configure` desde Windows). No bloquea Auth — `firebase_options.dart` provee las opciones de iOS directamente en Dart — pero si más adelante se necesita el plist nativo (p. ej. para Crashlytics), hay que regenerarlo corriendo `flutterfire configure` desde una Mac.

## Notas de arquitectura

- **Sin `Either`/`dartz`**: los repositorios lanzan `Failure` (no lo retornan envuelto); los controllers usan `AsyncValue.guard`, que ya da loading/data/error "gratis" vía Riverpod sin añadir una dependencia funcional nueva.
- **Sin codegen de Riverpod** en esta feature: `AuthController` usa la API manual de `AsyncNotifierProvider` en vez de `@riverpod` + `build_runner`. `riverpod_generator`/`freezed` siguen disponibles para cuando una entidad compleja los justifique.
- **`core/` nunca importa `features/`**: `HomePlaceholderPage` (en `core/widgets/`) recibe `onSignOut` como callback desde `app_router.dart` (la capa de composición, que sí puede conocer features) en vez de leer `authControllerProvider` directamente.
- **`AppTextField` se ajustó**: el toggle de contraseña ahora es texto ("Ver"/"Ocultar") en vez de ícono, porque la pantalla de Login real lo muestra así — más autoritativo que mi suposición inicial al construir el componente en la Épica 1.

## Reusado vs. nuevo

Reusado: `AppButton`, `AppTextField`, `Validators` (nuevo en `core/utils/`, genérico para todo el proyecto), tokens de tema. Nuevo y específico de esta feature (justificado, no se repite en otro lado todavía): `AuthBackButton`, `LegalNoticeText`, `LegalAcceptanceCheckbox`, `PasswordStrengthIndicator`.

## Known gaps (señalados, no decididos en silencio)

- **Sin Google/Apple sign-in**: el diseño los muestra en Login. Requieren paquetes adicionales (`google_sign_in`, `sign_in_with_apple`) y configuración de OAuth/Apple Developer que el usuario no ha provisto — se dejó fuera del MVP de esta épica. Agregar como tarea `AUTH-XXX` cuando se confirme que se quiere y haya credenciales.
- **Botón "Abrir mi correo"** en la confirmación de reset no abre realmente el cliente de correo (necesitaría `url_launcher`, no agregado); por ahora solo cierra la pantalla.
- **Enlaces de Términos/Privacidad** son visuales pero no navegan a ningún lado — no existe contenido legal real todavía.
- **Verificación de email** no implementada (Instrucciones.md la menciona como "cuando sea apropiado", no crítica para el MVP).
- **Modo invitado** ("Seguir sin cuenta") navega directo a Home sin persistir nada localmente — cuando exista Onboarding/Plan (Épicas 3/6), esto necesita guardar el progreso local real, como describe el canvas.
- **Sin tests** — diferido a la Épica 16 por pedido explícito del usuario.
