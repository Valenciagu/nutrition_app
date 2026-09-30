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
- `lib/core/services/firebase_instances.dart` — provider crudo de `FirebaseAuth.instance`.
- `lib/core/widgets/firebase_setup_required_page.dart` — pantalla de desarrollador cuando `Firebase.initializeApp()` falla.

Diseño: `documentation/design_screens_auth.md` (specs completas de las 5 pantallas).

## Configuración de Firebase (FOUND-009)

`lib/firebase_options.dart` fue generado por `flutterfire configure` (proyecto `nutritionapp-eee08`, plataformas android/ios/web) y `main.dart` llama `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` dentro de un `try/catch`. Si esa llamada fallara (proyecto desconectado, credenciales revocadas), se muestra `FirebaseSetupRequiredPage` en vez de un crash críptico — ya no debería activarse en el uso normal, pero se deja como salvaguarda.

Nota: `android/app/google-services.json` sí se generó; `ios/Runner/GoogleService-Info.plist` no (se corrió `flutterfire configure` desde Windows). No bloquea Auth — `firebase_options.dart` provee las opciones de iOS directamente en Dart — pero si más adelante se necesita el plist nativo (p. ej. para Crashlytics), hay que regenerarlo corriendo `flutterfire configure` desde una Mac.

## Notas de arquitectura

- **Guarda de sesión del router sin condición de carrera**: `routerProvider` usa `ref.listen(authStateChangesProvider, ...)` para notificar a GoRouter (`refreshListenable`) — no una suscripción independiente a `.authStateChanges()`. Se intentó primero con un `GoRouterRefreshStream` genérico alimentado por una llamada nueva a `.authStateChanges()`, pero eso crea DOS suscripciones independientes al mismo stream de Firebase sin orden garantizado entre sí: el router podía "despertar" antes de que `authStateChangesProvider` ya tuviera el valor actualizado y, como nunca volvía a despertar, la app se quedaba pegada en Splash indefinidamente (bug real encontrado probando en el navegador). `ref.listen` sobre el propio provider garantiza que su caché ya está al día en el momento en que notifica.
- **Sin `Either`/`dartz`**: los repositorios lanzan `Failure` (no lo retornan envuelto); los controllers usan `AsyncValue.guard`, que ya da loading/data/error "gratis" vía Riverpod sin añadir una dependencia funcional nueva.
- **Sin codegen de Riverpod** en esta feature: `AuthController` usa la API manual de `AsyncNotifierProvider` en vez de `@riverpod` + `build_runner`. `riverpod_generator`/`freezed` siguen disponibles para cuando una entidad compleja los justifique.
- **`core/` nunca importa `features/`**: `HomePlaceholderPage` (en `core/widgets/`) recibe `onSignOut` como callback desde `app_router.dart` (la capa de composición, que sí puede conocer features) en vez de leer `authControllerProvider` directamente.
- **`AppTextField` se ajustó**: el toggle de contraseña ahora es texto ("Ver"/"Ocultar") en vez de ícono, porque la pantalla de Login real lo muestra así — más autoritativo que mi suposición inicial al construir el componente en la Épica 1.
- **`root` es accesible sin sesión solo en modo invitado (temporal)**: `redirect` deja entrar a `RoutePaths.root` sin sesión únicamente si `guestModeProvider` (en `auth_providers.dart`) está en `true`. Ese provider se activa desde "Empezar" (Welcome) y "Seguir sin cuenta" (SignUp) justo antes de navegar, y se resetea a `false` en `AuthController.signOut()`. Es necesario distinguir así porque "invitado navegando" y "usuario recién deslogueado" son indistinguibles solo mirando `authStateChangesProvider` (ambos en `null`) — sin esta bandera, cualquiera de las dos rutas de bug real encontradas probando aparecía: primero "Empezar" no hacía nada (rebotaba a Welcome porque `root` no era accesible sin sesión), y al arreglar eso de forma ingenua (dejar `root` siempre accesible sin sesión) "Cerrar sesión" dejaba de devolver a Welcome. Cuando exista Onboarding/Plan real con persistencia de invitado (Épicas 3/6), esta bandera probablemente se reemplace por un estado más completo.

## Reusado vs. nuevo

Reusado: `AppButton`, `AppTextField`, `Validators` (nuevo en `core/utils/`, genérico para todo el proyecto), tokens de tema. Nuevo y específico de esta feature (justificado, no se repite en otro lado todavía): `AuthBackButton`, `LegalNoticeText`, `LegalAcceptanceCheckbox`, `PasswordStrengthIndicator`.

## Known gaps (señalados, no decididos en silencio)

- **Google sign-in — construido 2026-09-30 (AUTH-103, mitad Google)**: `google_sign_in` nuevo, `FirebaseAuthDataSource.signInWithGoogle()` envuelve `GoogleSignIn` + `GoogleAuthProvider.credential`, un botón "Continuar con Google" en Login (`AppButtonVariant.neutral`, sin logo — no hay asset de marca de Google en el sistema de diseño, se prefirió texto plano a inventar uno). Requirió: registrar la huella SHA-1/SHA-256 del keystore de debug en el proyecto Firebase (`firebase apps:android:sha:create`), y que el usuario activara el proveedor "Google" en Firebase Console (paso de un solo clic, no automatizable por CLI). Cancelar el selector de cuentas se trata como no-op, no como error (`signInWithGoogle()` devuelve `false`, no lanza). `AnalyticsService.logLogin`/`logSignUp` ahora aceptan un `method` opcional ("email"/"google") para separar el embudo sin exponer texto libre.
- **Apple sign-in — sigue sin construir**: el diseño también lo muestra en Login. Necesita `sign_in_with_apple` + una cuenta de pago de Apple Developer Program (US$99/año) — deliberadamente parqueado junto con la Épica 13 (que necesita esa misma cuenta), no un gap técnico. Agregar cuando esa cuenta exista.
- **Botón "Abrir mi correo" — construido 2026-09-30 (AUTH-104)**: `url_launcher` nuevo, `launchUrl(Uri(scheme: 'mailto'))` (sin destinatario, solo abre el cliente/selector) — si nada puede manejarlo, cae al comportamiento anterior (cerrar la pantalla). Requirió declarar el esquema en ambas plataformas (`<queries>` en `AndroidManifest.xml`, `LSApplicationQueriesSchemes` en `Info.plist`) por las reglas de visibilidad de paquetes desde Android 11/iOS — sin eso, `launchUrl` no encuentra ningún manejador aunque sí haya una app de correo instalada.
- **Enlaces de Términos/Privacidad** son visuales pero no navegan a ningún lado — no existe contenido legal real todavía.
- **Verificación de email** no implementada (Instrucciones.md la menciona como "cuando sea apropiado", no crítica para el MVP).
- **Modo invitado** ("Seguir sin cuenta") navega directo a Home sin persistir nada localmente — cuando exista Onboarding/Plan (Épicas 3/6), esto necesita guardar el progreso local real, como describe el canvas.
- **Sin tests** — diferido a la Épica 16 por pedido explícito del usuario.
