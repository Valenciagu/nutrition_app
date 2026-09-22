# Épica 11 — Perfil

Estado: **completa** (2026-09-20).

## Diseño

Leído de `Fases 5-12 - Entrega final.dc.html` (bloque "Fase 9 · Progreso · Fase 10 · Perfil", pantalla **J1**) vía `DesignSync` — no transcrito antes porque la Épica 0 lo dejó para cuando esta épica arrancara. **I1 (Progreso) NO se construyó** — se abre desde el anillo de Home, que todavía no tiene datos reales de seguimiento diario (Épica 6 lo cubre parcialmente, un historial de "días seguidos"/adherencia necesitaría su propia épica de analítica); queda fuera de alcance, no confundir con Perfil.

J1: header (avatar + objetivo/kcal) + tarjeta "Hazte Premium" + dos grupos de filas — "Mi alimentación" (Objetivo y datos / Preferencias y alergias / Recetas guardadas) y "Ajustes" (Recordatorios / Tema / Idioma / Privacidad y datos).

## Qué es real y qué es "muy pronto"

| Fila | Estado |
|---|---|
| Objetivo y datos | **Real** — edita goal/sexo/edad/altura/peso/actividad, escribe a Firestore |
| Preferencias y alergias | **Real** — edita gustos/alergias/tiempo de cocina/presupuesto |
| Recetas guardadas | Muy pronto — no existe ningún concepto de "favorito" en el dominio (misma decisión que D3, Épica 7: no fingir un botón sin datos reales detrás) |
| Hazte Premium | Muy pronto — Épica 13 no existe |
| Recordatorios | Muy pronto — Épica 12 no existe. El mock muestra "4 activos"; no se fabricó ese número, la fila no muestra ningún valor |
| Tema | Valor real ("Automático" = `ThemeMode.system`, ya lo que usa `main.dart`), no editable todavía |
| Idioma | Valor real (idioma actual del dispositivo/locale), no editable todavía |
| Privacidad y datos | **Real** — ver abajo |

## Objetivo y datos / Preferencias y alergias (edición real)

**Decisión de arquitectura clave**: estas pantallas NO reusan `onboardingControllerProvider` (el estado del asistente de registro). Ese provider dispara un guardado local (`shared_preferences`) en cada cambio y tiene un ciclo de vida pensado para "borrador antes de tener cuenta → migración a Firestore al registrarse" (Épica 3). Reusarlo tal cual para "editar un perfil YA existente" habría mezclado dos ciclos de vida distintos sobre el mismo estado global — un cambio hecho en Perfil podría haber quedado atrapado en el borrador local y disparado una migración inesperada en un futuro login. En su lugar: `profileEditControllerProvider`, un `Notifier` propio de Perfil (`.autoDispose`, sin guardado local), sembrado desde `userProfileProvider` (lectura directa de `users/{uid}.onboarding`) al entrar a la pantalla, y guardado explícito vía un nuevo método `OnboardingRepository.updateProfile` (mismo destino remoto que ya usaba `migrateDraftToProfile`, sin la parte de borrador).

**Reuso real, no una réplica de Onboarding**: `SelectableChip`, `WheelValueField`, `showIntWheelPicker`/`showDoubleWheelPicker`, y los catálogos/etiquetas de `onboarding_catalog.dart` (`foodLabel`, `allergenLabel`, y 4 funciones nuevas: `goalLabel`, `activityLevelLabel`, `cookingTimeLabel`, `budgetLabel`) se reusan directo. Lo que NO se reusa son los widgets de PASO completos (`GoalStep`, `PersonalDataStep`, etc.) — están acoplados a `onboardingControllerProvider` y pensados para una conversación de bienvenida (una pregunta por pantalla, auto-avance, tarjetas grandes), no para una pantalla de ajustes densa. Construir formularios de ajustes más compactos con las mismas piezas de entrada es la elección honesta, no un atajo.

**Fuera de alcance**: el horario de comidas (`mealSlots`) no es editable desde Perfil — la fila del diseño se llama "Preferencias y alergias", no "horarios", y D1/D2 (Plan) ya reflejan el ritmo fijado en Onboarding. Revisar si hace falta cuando/si el usuario lo pide.

## Privacidad y datos

Instrucciones.md §33-34 (privacidad: minimizar, ownership, borrado de cuenta/datos). Dos partes:

1. **Divulgación**: texto simple listando qué se guarda (perfil, planes/recetas generados, fotos analizadas) — sin tabla de campos exhaustiva, suficiente para cumplir la intención de "comunicar claramente".
2. **Eliminar cuenta** — Cloud Function nueva `deleteAccount` (`functions/src/account/deleteAccount.ts`), sin secretos/OpenAI de por medio. Borra, en orden: todas las subcolecciones de `users/{uid}` (`nutritionPlans`, `recipes`, `aiUsage`, `shoppingLists`, `foodAnalyses` — patrón recursivo por lotes, Firestore no borra subcolecciones en cascada), el documento `users/{uid}`, los archivos de Storage bajo `users/{uid}/` (best-effort — un fallo acá no bloquea el resto), y finalmente el usuario de Firebase Auth.

   **Por qué todo con el Admin SDK y no re-autenticación del cliente**: `user.delete()` del SDK de cliente exige un login reciente (Firebase lo fuerza por seguridad), lo que habría significado construir un diálogo de re-autenticación con contraseña. El Admin SDK no tiene esa restricción — la Cloud Function borra siempre al PROPIO `request.auth.uid` (nunca un uid que mande el cliente, no hay ningún parámetro de entrada), así que no hace falta re-autenticar para conseguir el mismo nivel de seguridad.

   Del lado del cliente: confirmación centrada (`showConfirmationDialog`, nuevo `core/widgets/` — cerraba un hueco que `app_bottom_sheet.dart` ya documentaba como pendiente: "destructive confirmations belong in a centered dialog", sin ningún consumidor real hasta ahora) → llama al callable → si tiene éxito, `FirebaseAuth.instance.signOut()` explícito (el usuario ya no existe server-side, pero el cliente no necesariamente lo nota hasta el próximo refresh de token; cerrar sesión local fuerza que `authStateChangesProvider`/el `redirect` del router reaccionen de inmediato) → el router manda a Welcome solo.

## Componentes nuevos/extendidos

- `QuickActionTile` — nuevo `trailingText` opcional (valor a la derecha en vez del chevron, p. ej. "Automático") — el mock nunca muestra ambos a la vez.
- `showConfirmationDialog` (`core/widgets/confirmation_dialog.dart`) — diálogo centrado genérico, primer consumidor real.
- `OnboardingRepository.updateProfile` — nuevo método, sin tocar el ciclo de vida de borrador/migración existente.

## Gaps documentados

- Sin recetas guardadas/favoritas (no existe el concepto).
- Tema/Idioma se muestran pero no son editables todavía (valores reales, no fabricados).
- Progreso (I1 del mock) no construido — necesita seguimiento diario real, fuera de esta épica.
- `mealSlots` (horario de comidas) no editable desde Perfil.

`flutter analyze` y `flutter build web --debug` limpios; `tsc`/`npm run build` limpios en `functions/` (9 Cloud Functions en total ahora).
