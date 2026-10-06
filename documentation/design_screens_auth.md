# Design Reference — Auth Screens (Fase 2, Bloque A)

Transcrito de `Fase 2 - Auth y Onboarding.dc.html` (leído 2026-09-11), pantallas A1-A5. El Bloque B (Onboarding, B1-B9) de ese mismo archivo **no** está transcrito todavía — se lee cuando arranque la Épica 3, para no gastar contexto en algo que no se va a construir aún.

Regla general del bloque: fondo blanco, un único CTA verde por pantalla, campos de 56px, teclado siempre visible en formularios (el CTA queda anclado sobre el teclado, no se oculta).

## Flujo

```
Splash (A1) --[sin sesión]--> Welcome (A2) --"Empezar"--> Onboarding (Épica 3, aún no existe)
                                          \--"Ya tengo cuenta"--> Login (A3)
Login (A3) --"Crea tu cuenta"--> SignUp (A4)
Login (A3) --"¿Olvidaste tu contraseña?"--> ForgotPassword request --> Sent (A5)
Splash (A1) --[con sesión]--> Home
```

En el diseño original, SignUp (A4) vive *después* del onboarding (banner "tu plan ya está calculado"). Como la Épica 3 no existe todavía, se implementó accesible también directo desde Login, con el banner oculto por defecto (`hasPendingPlan: false`) — ver "Desviaciones" abajo.

## A1 · Splash

Fondo verde `actionPrimary` sólido, isotipo placeholder (círculo con "N"), nombre de la app, tagline, spinner. Máx. 1.2s; si hay sesión, transición directa a Home con fade 220ms (el logo no rebota).

## A2 · Welcome

Foto de comida a sangre en la mitad superior (placeholder rayado hasta tener banco de fotos real), headline + subtítulo, dos botones (`Empezar` primary, `Ya tengo cuenta` neutral), aviso legal. La foto promete comida, no software — "Empezar" no pide cuenta, va directo a onboarding.

## A3 · Iniciar sesión

Back button, título "Hola de nuevo", email + contraseña (toggle de texto "Ver", no ícono — así se ajustó `AppTextField`), link de recuperar contraseña, CTA "Entrar", divisor "o", botones Google/Apple, link a registro.

**Regla de seguridad explícita del diseño:** error de credenciales pinta el campo de **contraseña**, nunca el de email, con el mensaje "Revisa tu contraseña" — nunca "usuario no existe" (evita filtrar qué correos están registrados). Implementado en `auth_error_presentation.dart`.

## A4 · Crear cuenta (tras el onboarding)

Back button, banner de plan calculado (condicional), título, nombre + email + contraseña (con medidor de fuerza de 3 segmentos + hint), checkbox de aceptación legal, CTA cuyo texto depende del contexto ("Guardar mi plan" si hay plan pendiente, "Crear cuenta" si no), salida "Seguir sin cuenta" siempre visible (no es un dark pattern).

## A5 · Recuperar contraseña · enviado

Ícono de check, "Revisa tu correo", mensaje con el email destino, botón "Abrir mi correo", countdown de reenvío de 60s. **La confirmación es siempre idéntica exista o no la cuenta** — implementado silenciando `user-not-found` en `firebase_auth_data_source.dart`.

El formulario de *pedir* el correo (antes de este estado) no está pixel-especificado en el canvas — se construyó siguiendo el mismo lenguaje visual (título, subtítulo, campo, CTA) por consistencia.

## Desviaciones / extrapolaciones respecto al canvas

- **SignUp accesible antes del onboarding**: ver arriba. Cuando exista la Épica 3, `hasPendingPlan` debe pasar a depender de si hay un plan generado sin guardar.
- **Formulario de solicitud de reset**: no estaba en el canvas (solo el estado "enviado"), se construyó por consistencia visual.
- **Botón Google**: el canvas lo muestra en Login — construido 2026-09-30 (ver `documentation/authentication.md`), sin logo de marca (no hay asset de Google en el sistema de diseño sincronizado, se prefirió texto plano a inventar uno). **También agregado a SignUp/A4, 2026-10-05** — el canvas NO lo muestra ahí, es una desviación deliberada confirmada con el usuario (no una suposición silenciosa): `signInWithGoogle()` ya resuelve login-vs-registro server-side, así que no hay trabajo nuevo de backend, y evita que alguien que acaba de terminar el onboarding tenga que retroceder hasta Login para usarlo.
- **Botón Apple**: el canvas también lo muestra en Login. No se implementó — necesita una cuenta de pago de Apple Developer, parqueado junto con la Épica 13 (ver `documentation/authentication.md`), decisión señalada al usuario, no tomada en silencio.
