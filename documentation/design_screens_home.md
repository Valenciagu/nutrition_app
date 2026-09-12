# Diseño — Fase 3 · Home

Transcripción de `Fase 3 - Home.dc.html` (Claude Design canvas, ver `desing.md`), pantallas C1-C6.

**Home no es un dashboard, es una recomendación.** Orden fijo de arriba a abajo: cómo vas hoy (anillo) → qué toca ahora (siguiente comida) → qué puedes hacer (acciones rápidas). Las estadísticas viven en Progreso, no en Home.

**Decisión de navegación confirmada con el usuario (2026-09-12):** 4 tabs + cámara central (Home · Plan · [cámara] · IA · Perfil) en vez de los 5 tabs del brief original. Progreso deja de ser tab — se abre desde el anillo de Home, es una consulta semanal, no diaria. La cámara es la acción más repetida del producto y ocupa el centro en vez de competir por un tab.

## C1 · Home, mañana, estado normal — NO IMPLEMENTADO (necesita Épica 6)
Saludo + racha (badge "12") + avatar. Card con anillo de kcal libres + 3 `MacroBar` (proteína/carbos/grasas). "Ahora toca": `MealCard` grande de la siguiente comida con botones Cocinar/Cambiar. "Acciones rápidas": grid 2x2 de accesos (Analizar comida, Tengo ingredientes, Lista de compra, Preguntar a la IA).

## C2 · Home, tarde, tras comida imprevista — NO IMPLEMENTADO (necesita Épica 6)
Igual que C1 pero con un `AISuggestionCard` (banda indigo) arriba: "Registraste una hamburguesa. Podemos equilibrar la cena..." con acciones "Recalcular mi día"/"Ahora no". Al pasarse de un macro, la barra se raya en su propio color — nunca rojo, nunca "te pasaste". Card de racha ("12 días seguidos").

## C3 · Home, primer día (empty) — IMPLEMENTADO
Saludo + avatar (sin racha, no hay nada que contar todavía). Card con el anillo **apagado** (borde uniforme, sin arco) mostrando solo la meta de kcal calculada en el Onboarding. "Tu primer día empieza aquí" + CTA "Analizar mi comida" (abre la hoja de acción C5). "Empieza por aquí": 3 filas (`QuickActionTile`) — plan del día, lista de compra, preguntar a la IA. Como hoy nadie tiene todavía seguimiento diario real (Épica 6 no existe), este es el único estado de Home que tiene sentido construir ahora — no es una limitación de esta épica, es honesto con el estado real de la app.

## C4 · Home, cargando — IMPLEMENTADO
Esqueleto que respeta la silueta real (mismo anillo, misma card) para que nada salte al llegar los datos. Implementado como `_HomeSkeleton` mientras `homeDailyCalorieGoalProvider` resuelve (solo perceptible para un usuario con sesión, ya que implica una lectura a Firestore).

## C5 · Acción central (bottom sheet) — IMPLEMENTADO (como UI; sin funcionalidad real detrás)
El botón de cámara no abre la cámara directamente — ofrece 3 caminos: Analizar mi comida, Tengo ingredientes, Registrar sin foto. Sheet a 28px de radio. Como Épica 8/9 (análisis de fotos) no existen, cada opción confirma la intención con un snackbar en vez de fallar en silencio.

## C6 · Home, dark mode — NO IMPLEMENTADO (hereda de C1)
Mismo layout que C1, superficies por color y no por sombra. No aplica todavía porque C1 mismo no está implementado.

## Notas de sistema (del propio diseño)

- **Jerarquía fija**: saludo → propuesta de la IA (solo si existe) → anillo del día → siguiente comida → acciones rápidas → racha. El orden no cambia con la hora; cambia el contenido de "ahora toca".
- **Componentes nuevos**: `QuickActionTile` (implementado, en `core/widgets/quick_action_tile.dart`) y `AISuggestionCard` (diferido a Épica 6 — necesita un evento real de "comida imprevista registrada"). `MealCard`, el anillo (`ProgressRing`, implementado) y los `MacroBar` (diferido a Épica 6 — no hay macros reales que trackear) vienen de Fase 1 sin cambios.
- **Sobre el objetivo**: al superar un macro, la barra se raya en su propio color y el anillo se queda lleno; no hay rojo, no hay "te pasaste". Al completar el día: pulso del anillo y count-up, sin confeti.
- **Navegación**: confirmado 4 tabs + cámara central (ver arriba).
