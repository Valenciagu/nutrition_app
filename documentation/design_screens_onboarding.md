# Diseño — Fase 2 · Bloque B (Onboarding conversacional)

Transcripción de `Fase 2 - Auth y Onboarding.dc.html` (Claude Design canvas, ver `desing.md`), pantallas B1-B9. Bloque A (Auth) está en `documentation/design_screens_auth.md`.

Mismo esqueleto en las 8 pantallas numeradas del diseño: `StepHeader` (volver + barra de progreso + contador "n/8") + pregunta grande + subtítulo de una línea + zona de respuesta + CTA anclado abajo. El botón se activa en cuanto hay respuesta válida; en preguntas de selección única pura, tocar una opción avanza sola tras 180 ms.

**Decisión de producto confirmada con el usuario (2026-09-12):** el registro ocurre DESPUÉS del onboarding (B9 → A4), no antes. Sube la conversión del embudo pero exige persistir el perfil localmente y migrarlo a Firestore al crear la cuenta — ver `documentation/onboarding.md`.

## B1 · Objetivo (selección única)
"¿Cuál es tu objetivo?" — 4 tarjetas con foto: Perder grasa / Ganar músculo / Mantener peso / Comer más saludable. Selección = borde 1.5px verde + fondo + check, nunca solo color.

## B2 · Datos personales (único paso con "teclado")
"Cuéntanos de ti" — segmented Hombre/Mujer/Otro, luego Edad/Altura/Peso: al tocar un campo se abre un selector de rueda (no el teclado numérico). Toggle Métrico/Imperial. Peso actual viene resaltado (borde 2px) como el campo más importante.

## B3 · Nivel de actividad (selección única)
"¿Qué tan activo eres?" — Sedentario/Ligero/Moderado/Alto/Atleta. Primera aparición de un cálculo "vivo": una tarjeta indigo (`aiActionSurface`) muestra una estimación de calorías que reacciona a la opción elegida ("Con 'Moderado' tu estimación ronda las 2.100 kcal diarias").

## B4 · Alimentos que te gustan (multiselección, mínimo 5)
"¿Qué te gusta comer?" — grid de 3 columnas con foto por alimento (Pollo, Carne, Pescado, Huevos, Aguacate, Arroz, Legumbres, Pasta, Tofu), scroll interno, CTA anclado abajo. El contador "4 de 5 seleccionados" sustituye a cualquier mensaje de error.

## B5 · Alergias e intolerancias
"¿Algo que debamos evitar?" — buscador + chips de alérgenos (Lactosa, Gluten, Frutos secos, Marisco, Huevo, Soja, Pescado, Sésamo). Único sitio del sistema donde el rojo aparece por selección (exclusión, no error). Banner: las alergias bloquean recetas por completo, las intolerancias solo reducen frecuencia (la UI no distingue cuál es cuál por ítem — ver known gap en `documentation/onboarding.md`). Salida "No tengo ninguna".

## B6 · Ritmo de comidas
"¿Cómo es tu día?" — selector de comidas/día (3/4/5/6) que genera en vivo las filas de horario (Desayuno, Almuerzo, Merienda, Cena para 4; el diseño no especifica 3/5/6, ver known gap).

## B7 · Cocina y presupuesto (último paso)
"¿Cuánto quieres cocinar?" — tres preguntas ligeras en una pantalla: tiempo por comida (15 min o menos/30 min/Sin prisa), nivel en la cocina (Básico/Me defiendo/Avanzado), presupuesto semanal (slider de 4 posiciones con rango orientativo, p. ej. "Ajustado" → "60–80 €"). CTA cambia a "Crear mi plan".

## B8 · Generando tu plan (estado IA) — NO IMPLEMENTADO
Anillo de progreso + checklist de pasos completándose (calculando calorías, filtrando alimentos, eligiendo recetas, organizando lista de compra) + skeleton shimmer. Depende de la generación real de un plan por IA (Épica 5/6, no construida) — implementarlo con contenido inventado sería engañoso, así que se difiere.

## B9 · Tu plan está listo — NO IMPLEMENTADO
Resumen con anillo de kcal, barras de macros (proteína/carbos/grasas), preview de comidas del día, CTA "Empezar mi día". Aquí es donde se entra a A4 (registro) o se sigue como invitado. Mismo motivo de diferimiento que B8.

## Notas de sistema (del propio diseño)

- **Componentes usados**: PrimaryButton, SecondaryButton, TextField, SearchField, SelectableChip, Card de opción, ProgressIndicator lineal, ProgressRing, MealCard, Skeleton, AIStateCard. Cero componentes nuevos respecto a Fase 1; el único propuesto es **StepHeader** (volver + barra + contador), que se repite en las 8 pantallas — implementado en `features/onboarding/presentation/widgets/step_header.dart`.
- **Accesibilidad**: selección = borde 1.5px + check + fondo, nunca solo color. Todo lo tocable ≥ 48px. La barra de progreso anuncia "Paso n de 8" (`Semantics` en `StepHeader`). Con texto al 200%, las cards de opción deberían pasar a una columna y el CTA quedar fijo (no verificado explícitamente todavía).
- **Copy**: preguntas en segunda persona, CTA en primera ("Crear mi plan", "Empezar mi día"). Ningún paso juzga la respuesta. Todo el texto sale de claves de traducción (`app_es.arb`/`app_en.arb`, prefijo `onboarding*`).
