# Fase 4 · Plan y recetas — diseño (transcrito del canvas)

Fuente: `desing.md` → Claude Design canvas, proyecto `d3c0cd06-9d89-4ceb-b4b7-0f3f858d37c1`, archivo `Fase 4 - Plan y Recetas.dc.html`, leído 2026-09-20 (al iniciar la Épica 6). 5 pantallas (D1-D5). Reusa los tokens de `documentation/design_system.md` — aquí solo se documenta lo específico de esta fase.

## Dirección

"El plan es una lista de comidas con estado, no una tabla nutricional. La receta es una foto grande con instrucciones debajo. Cambiar una comida es una acción de dos toques, no un formulario."

## D1 · Plan del día

- Header: "Tu plan" + toggle "Semana"/"Día" (pill).
- `DayStrip`: 5 días (lun-vie) en pills; el día activo tiene fondo verde sólido (`actionPrimary`) y texto blanco; los demás blancos con borde.
- Barra resumen: "2 de 4 comidas registradas" + "1.420 kcal" (verde, tabular).
- Lista de `MealCard` (una fila por comida), 3 estados visuales:
  - **Registrada**: foto atenuada (opacity .6), label "Desayuno · registrado" en verde, título con `line-through`, check verde sólido a la derecha.
  - **En curso / próxima con hora ya pasada pero sin registrar**: se eleva con sombra (e2), foto sin atenuar, label con la hora ("Merienda · 17:30"), círculo vacío (borde, sin check) a la derecha.
  - **Futura**: igual que "en curso" pero sin la elevación/sombra.
- Fila "Generar lista de compra" (icono + texto + chevron) — mismo patrón visual que `QuickActionTile` de Home.
- Nota de interacción: swipe izquierda sobre cualquier fila → reemplazar · registrar · preguntar a la IA (3 acciones).
- Bottom nav con tab "Plan" activo (mismo `BottomNavigation` de Home).

## D2 · Plan semanal

- Header: rango de fechas ("8 – 14 sep") + toggle a "Día" (pill verde sólido, invertido respecto a D1).
- Por cada día: label (hoy en negrita + "Hoy · lunes"; otros días en gris) + kcal total, y una fila de 4 miniaturas (Desayuno/Almuerzo/Merienda/Cena) — placeholder rayado con el nombre de la comida superpuesto (scrim oscuro abajo), sin foto real en el mock.
- Tarjeta de sugerencia IA (fondo `aiActionSurface`/indigo claro, borde a juego): "El jueves repites tres comidas de esta semana. ¿Quieres variar?" + botón sólido indigo "Renovar el jueves".

## D3 · Detalle de receta

- Foto 4:5 a sangre arriba (300px alto), con botón "←" (volver) y "♡" (favorito) flotantes sobre la foto, label pequeño "foto 4:5 · plato terminado" en el mock (referencia de spec, no UI real).
- Hoja blanca con esquinas superiores redondeadas (28px) montada sobre la foto (`margin-top:-28px` en el mock — en Flutter usar `Transform.translate`, NO `margin` negativo, ver `documentation/bug_fixes_log.md` BUG-H01).
- Título (h2, 25px) + 3 chips: tiempo ("25 min"), dificultad ("Fácil"), y un chip verde tipo "insight" ("Alta en proteína").
- **`MacroStatTile`** (componente nuevo, 05/10 de esta fase): 4 tiles iguales en fila (kcal, proteína g, carbos g, grasas g) — número grande (19px/800) + label pequeño debajo.
- Sección "Ingredientes · 1 ración" + link "Sustituir" a la derecha del título de sección → abre D4.
- Lista de ingredientes: nombre + cantidad alineada a la derecha, sin viñetas ni iconos.
- Footer fijo: botón sólido "Empezar a cocinar" (lleva a D5) + botón outline "Registrar" (marca la comida como comida sin pasar por modo cocina).

## D4 · Reemplazar comida (bottom sheet)

- Se abre sobre D1 con el fondo desenfocado/oscurecido (blur + scrim `rgba(16,21,18,.42)`), patrón ya usado por `showAppBottomSheet`.
- Título "Otra cena para hoy" + subtítulo "Mismos macros, con lo que ya tienes en casa."
- 3 tarjetas de alternativas (mismo `MealCard`, variante "opción seleccionable"): la primera viene pre-seleccionada (borde+fondo verde, check), las otras 2 sin selección.
- Fila de chips de filtro: "Más rápido", "Más ligera" (neutros) + "Pedir otra a la IA" (chip indigo, `aiActionSurface`).
- Botón sólido "Cambiar mi cena" al fondo.
- Nota de diseño: "Tres alternativas cerradas antes que un buscador abierto: decidir es más rápido que buscar."

## D5 · Modo cocina — paso a paso

- **Marcado explícitamente por el propio diseño como "Pendiente de tu OK"**: "El modo cocina (D5) no estaba en el inventario del brief. Lo propongo como mejora, no lo doy por aprobado: sin él, la receta es sólo lectura y el plan se queda a medio camino." — **decisión de producto que le corresponde al usuario, no asumir que está aprobada.**
- Header: "✕" (cerrar) + barra de progreso (50% en el mock) + contador "2/4".
- Foto del paso (placeholder rayado, sin foto real).
- "Paso N" (label verde) + instrucción en texto grande (26px/700) — pensado para leerse a un metro de distancia.
- Widget de temporizador: cifra grande "04:00" + botón "Iniciar" — implica manejo de estado de un timer real corriendo en la pantalla.
- Footer: "Anterior" (outline) + "Siguiente paso" (sólido, ocupa el resto del ancho).
- Al terminar el último paso: según la nota de "Estados" más abajo, lleva a registrar la comida directamente.

## Componentes nuevos de esta fase (`Fichas de componentes` no los cubre — son propuestos aquí)

- **`DayStrip`** — selector de días (D1/D2), pills en fila.
- **`MacroStatTile`** — las 4 cifras de macro de una receta (D3).
- **`StepScreen`** — la pantalla completa de un paso de modo cocina (D5) — condicionado a que se apruebe D5.
- `MealCard` reaparece en 3 variantes visuales (registrada/en curso/futura en D1; miniatura en D2; opción seleccionable en D4) — **sin forks**, según la nota del propio diseño: es un solo componente parametrizado, no 3 componentes distintos.

## Estados (nota del diseño)

- **Plan vacío**: "Aún no tienes plan para este día" + acción para generar.
- **Receta sin foto**: placeholder rayado con el nombre — nunca un ícono genérico.
- **Sin conexión**: el plan del día y las recetas ya vistas quedan en caché (implica una estrategia de cache/offline no trivial — Instrucciones.md §66 Offline/Connectivity).

## Decisiones del usuario (2026-09-20)

1. **Modo cocina (D5): aprobado.** Se construye completo (temporizador real, navegación paso a paso, registro automático al terminar) cuando la Épica 7 (Recetas) llegue de verdad — D3 sí debe incluir "Empezar a cocinar", no solo "Registrar".
2. **Alcance de la primera tarea de la Épica 6**: empezar por el modelo de datos (entidades de dominio + forma del esquema de Firestore), sin IA ni pantallas todavía — ver `TASKS.md` Épica 6, tarea 6.1. La generación real por IA (Cloud Function nueva, del mismo tamaño que toda la Épica 5) queda para una tarea posterior, con su propio diseño de prompt/schema.
