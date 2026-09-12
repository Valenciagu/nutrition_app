# Épica 2 — Autenticación

## Qué hace

Email/contraseña con Firebase Auth: splash con guarda de sesión, welcome, login, registro y recuperar contraseña. El router redirige automáticamente según haya o no sesión activa.

**Bloqueador de runtime, no de compilación:** esta feature compila y pasa `flutter analyze`/`flutter build`, pero **no puede probarse de extremo a extremo todavía** porque no hay un proyecto de Firebase conectado (`FOUND-009` en `TASKS.md`). Sin eso, `main.dart` muestra una pantalla de desarrollador ("Firebase no está configurado") en vez de la app — ver "Manejo del bloqueador" abajo.

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

## Manejo del bloqueador de Firebase

`main.dart` llama `Firebase.initializeApp()` dentro de un `try/catch` antes de `runApp`. Si falla (no hay `firebase_options.dart`/config nativa todavía), se muestra `FirebaseSetupRequiredPage` en vez de crashear con un stack trace críptico. Esto es intencional y temporal: en cuanto se corra `flutterfire configure` (FOUND-009), este catch deja de activarse y la app entra al flujo real.

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
