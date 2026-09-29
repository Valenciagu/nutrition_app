# Chat de IA (G1) — resolviendo la pregunta abierta de la Épica 5

Estado: **completo** (2026-09-21), alcance v1 deliberadamente acotado (ver abajo).

## Contexto

Desde la Épica 5, `AIService.askNutritionQuestion` (y la Cloud Function `askNutritionAssistant` que lo respalda) existía sin ningún consumidor en `lib/` — "Open questions" en `TASKS.md` dejó explícitamente pendiente dónde vive un chat de IA general: ¿el tab "IA" se vuelve un chat real, o `askNutritionQuestion` termina embebido en otra pantalla? Esta tarea lo resuelve: el tab "IA" (hasta ahora `ComingSoonPage`) pasa a ser `AiChatPage`, siguiendo el mock **G1** del canvas ("Fases 5-12 - Entrega final", bloque Fase 7).

## Alcance v1 — qué SÍ y qué NO

G1 muestra "acciones ejecutables": chips indigo ("Recalcular mi día", "Ver la cena nueva") y una tarjeta de receta insertada en el chat. Eso necesita que el backend pueda proponer una ACCIÓN estructurada (no solo texto) y que el cliente sepa ejecutarla — `askNutritionAssistant` no hace eso hoy, solo devuelve `{answer, recommendsProfessionalConsult, safetyFallbackApplied}`. Construir esos chips como botones decorativos que no ejecutan nada real habría sido exactamente el tipo de feature fabricada que este proyecto evita en todos lados (mismo criterio que D2's tarjeta de sugerencia de IA, Épica 6, o el favorito ausente de D3, Épica 7). **Quedan fuera de v1**, documentado aquí, no oculto.

Lo que SÍ se construyó, real y funcional de punta a punta:
- Conversación de texto libre con el asistente de nutrición ya existente.
- **Continuidad de conversación real**: `askNutritionAssistant` ahora acepta un `history` opcional (últimos hasta 6 turnos) — el cliente reenvía sus propios intercambios previos como contexto en cada llamada; el servidor no guarda estado de conversación. Sin esto, cada mensaje habría sido una pregunta aislada sin memoria de lo que se dijo antes, lo cual no se siente como un chat de verdad. `history` se valida exactamente con el mismo criterio que `question` (longitud, cantidad de turnos) — nunca se confía en que el cliente reenvíe fielmente lo que el servidor le devolvió.
- Cupo diario visible (`remainingToday`), `recommendsProfessionalConsult`/`safetyFallbackApplied` mostrados de forma visible cuando aplican (Instrucciones.md §38 — nunca ocultarlos).
- Chips de sugerencia (atajos de preguntas frecuentes, no "acciones de IA") — tocar uno solo llena y envía esa pregunta, ningún comportamiento oculto.
- Estado de invitado (sin sesión) con CTA a registro, mismo patrón que Plan/Perfil.

## Arquitectura

- **Sin persistencia de conversación** (v1 deliberado): `chatControllerProvider` es `NotifierProvider.autoDispose` — el historial vive en memoria y se pierde al salir de la pantalla o cerrar la app. No existe ninguna colección de Firestore para chat. Justificación: ninguna otra feature de este proyecto persiste texto libre del usuario sin una razón de producto clara, y no hay una todavía aquí (¿cuánto tiempo guardar? ¿se puede borrar? son preguntas de producto sin resolver) — más honesto no fingir memoria a largo plazo que no existe.
- `AIService.askNutritionQuestion` ahora acepta `{List<ChatTurn> history = const []}` — `ChatTurn` es un `record` (`({String question, String answer})`), no una clase nueva, porque no necesita identidad ni comportamiento propio.
- `ChatMessage` (dominio) modela pendiente/error/quota-agotada como estados explícitos, no texto de error hardcodeado — la UI resuelve el copy final vía localización, consistente con la regla de "sin strings hardcodeados" del proyecto.
- Reuso: `AppStateBlock.empty` (estado de invitado), tokens `aiActionSurface`/`onAiAction` ya existentes (del quinto variant de `AppButton`) para el avatar del asistente — nada de hex nuevos inventados para "lo relacionado con IA". El campo de texto y el botón de enviar NO reusan `AppTextField`/`RoundIconButton`: el primero es rectangular 56px/radio 14 (no encaja con la píldora 50px/radio completo del mock), el segundo está pensado para flotar semitransparente sobre una foto (no un botón sólido verde) — construidos como widgets locales de la feature, mismo criterio que `DayStrip`/`WheelValueField` en otras features.

## Seguridad / privacidad

Nada nuevo respecto al pipeline ya existente de `askNutritionAssistant` (Épica 5): auth Firebase requerida, cuota server-side, capa de seguridad determinística además del auto-reporte del modelo. La única superficie nueva es `history`, tratada como el mismo tipo de entrada no confiable que `question` — nunca se asume que el cliente reenvía fielmente algo que esta misma función generó antes.

## Gaps documentados

- Sin memoria de conversación entre sesiones (ver arriba).
- Sin "acciones ejecutables" (recalcular el día, reemplazar una comida desde el chat) — necesitaría una nueva capacidad estructurada del backend, no solo UI.
- El subtítulo del header dice "Pregúntale sobre nutrición", no el "Conoce tu plan de hoy" literal del mock — el asistente hoy solo conoce `goal`/`avoidFoods` del perfil, no el plan del día; usar la copia literal del mock habría sido una afirmación de capacidad que el backend no tiene.

`flutter analyze`/`flutter build web --debug` limpios. `tsc --noEmit`/`npm run build` limpios en `functions/`. Sin cambios a `firestore.rules`/`storage.rules` — esta tarea no toca datos persistidos.
