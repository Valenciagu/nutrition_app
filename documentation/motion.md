# Movimiento e interactividad (Épica 20)

Estado: **en progreso** (2026-10-26). Hechos: MOTION-101 y MOTION-104; MOTION-103 y MOTION-105 casi completos. Pendientes: MOTION-102 (faltan los SVG de comida), MOTION-106 (requiere aprobación del usuario por momento), MOTION-107 (requiere dispositivo real).

## Qué es

El usuario pidió (2026-10-25, referencia: Fitia) que la app se sienta muy interactiva y animada, sin perder rendimiento. Dio una aprobación general para agregar movimiento que no está dibujado en el canvas, **siempre que el canvas siga siendo obligatorio**: el movimiento es una capa encima, y el último cuadro de cada animación es exactamente la pantalla del canvas. Las reglas y el catálogo de patrones (M01-M13) viven en `documentation/design_system.md` → "Motion patterns"; este archivo describe la implementación.

## Implementaciones compartidas

Cada patrón del catálogo tiene **una** implementación; las pantallas la usan, no la reescriben.

| Patrón | Dónde vive | Cómo se usa |
|---|---|---|
| Tokens | `core/theme/app_motion.dart` | `AppMotion.pressScale`, `.listStagger`, `.reduced(context)`, etc. — sin literales sueltos |
| M01 presión | `core/widgets/motion/app_pressable.dart` | `AppPressable(child: ...)` — usa `Listener`, no compite con el `InkWell`/`GestureDetector` del hijo |
| M02/M11 pop-in | `core/widgets/motion/app_entrance.dart` | `icon.appPopIn(context)` (selección) / `appPopIn(context, duration: AppMotion.base)` (éxito) |
| M03 cambio de contenido | `core/widgets/motion/app_content_switcher.dart` | `AppContentSwitcher(child: KeyedSubtree(key: ..., child: ...))` |
| M04 entrada de listas | `core/widgets/motion/app_entrance.dart` | `item.appListEntrance(index)`; en listas perezosas (`ListView`) envolver la lista en `AppEntranceScope` |
| M05 transiciones | `core/theme/app_page_transitions.dart` + `_flowPage` en `app_router.dart` | Automático vía `pageTransitionsTheme`; flujo de pantalla completa → `pageBuilder: (c, s) => _flowPage(c, s, Page())` |
| M06 hojas | `core/widgets/app_bottom_sheet.dart` | Automático (`sheetAnimationStyle`) |
| M05 cambio de tab | `core/widgets/motion/app_tab_transition.dart` | Automático en `MainShell` |
| M13 error | `core/widgets/motion/app_shake.dart` | Automático en `AppTextField`; en otro componente: `AppShake(hasError: ..., child: ...)` |
| M08 progreso | `core/widgets/progress_ring.dart`, `core/widgets/motion/app_count_up_text.dart` | `ProgressRing(centerNumber: n)`; `AppCountUpText(value: n)`; `MacroStatTile` ya cuenta solo |

## Dónde se aplicó

- **Toda la app (por componentes compartidos):** `AppButton`, `AppCard` (si es tocable), `QuickActionTile`, `MealCard`, `SelectableChip`, `RoundIconButton`, `BottomNavigation` (tabs + cámara), `showAppBottomSheet`, `ProgressRing`, `MacroStatTile`, transiciones de pantalla.
- **Onboarding:** cambio de paso (M03), tarjetas de opción B1/B3 (M01+M02+M04), mosaicos de alimentos B4 (M01+M02 — antes tenían un `AnimatedScale` fijo en 1 que no hacía nada), vista previa de B9 (M04).
- **Plan (D1):** comidas entran escalonadas (M04); registrar una comida rellena el círculo y hace aparecer el check (M11).
- **Lista de compra / recetas por ingredientes:** entrada escalonada con `AppEntranceScope` (no se repite al hacer scroll).
- **Chat de IA:** la burbuja nueva entra (M04, solo la recién llegada — `appListEntrance(0, play: isNew)`); al llegar la respuesta, los puntos de "escribiendo" dan paso al texto (M03) y la burbuja crece con `AnimatedSize`. Scroll y puntos pasan a tokens.
- **Formularios (todos, vía `AppTextField`):** el borde/fondo cruzan al enfocar o marcar error; al aparecer un error el campo se sacude y vibra (M13).
- **Tabs:** la tab entrante aparece con fade + escala leve (M05).

## Decisiones

- **Librerías:** `flutter_animate` (efectos declarativos: entrada de listas, pop-in) y `animations` (Material motion oficial: shared axis). **Rive no se agregó todavía**: no hay ningún archivo `.riv`; entra cuando MOTION-102 lo necesite.
- **iOS conserva su transición nativa** al hacer push: el shared axis no tiene el gesto de deslizar desde el borde para volver, y perderlo sería peor que la ganancia visual. Excepción de plataforma documentada en el catálogo. Los flujos de pantalla completa sí usan el shared axis vertical en ambas plataformas (tienen botón de cerrar, no dependen del gesto).
- **`ProgressRing` cambió de API:** `centerValue` (texto) pasó a ser opcional y se agregó `centerNumber` (cuenta animada) + `animate` (`false` en B8, cuya coreografía ya mueve el progreso cuadro a cuadro). Exactamente uno de `centerValue`/`centerNumber`.
- **Entradas que no se repiten:** `Animate` reinicia si sus parámetros cambian entre reconstrucciones, así que `appListEntrance` decide una sola vez por elemento si anima; en listas perezosas, `AppEntranceScope` hace que los ítems creados después de la ventana inicial (por scroll) aparezcan ya en su estado final.
- **Reducir movimiento:** cada patrón cae a un fade de `fast` o a un cambio instantáneo (progreso); `AppPressable` no escala pero el color/tinta del componente siguen respondiendo.
- **Rendimiento:** solo animaciones implícitas o de `flutter_animate` (sin controladores sueltos nuevos); el arco del anillo va dentro de un `RepaintBoundary`.
- **No se usó `dart format`:** el proyecto no lo aplica (archivos sin tocar salen "cambiados"), así que se respetó el estilo a mano para no reformatear código ajeno.

## Pendiente

- MOTION-102: loader de marca (camino "A" aprobado) — espera los SVG de comida del canvas.
- MOTION-102: prompt listo para pedir las ilustraciones al canvas — `documentation/ai_loader_illustrations_prompt.md`.
- MOTION-103: estado de éxito de `AppButton` (sus consumidores principales cierran la pantalla al guardar, así que hoy no hay momento para mostrarlo).
- MOTION-105: `Hero` D1→D3 (M07) **bloqueado** — D3 muestra primero un skeleton de carga, así que el destino del Hero no existe cuando arranca el push; hacerlo volar cambiaría el layout de carga de D3.
- MOTION-106: celebraciones — preguntar al usuario por cada momento.
- MOTION-107: prueba de rendimiento en un dispositivo real (modo profile, DevTools) antes de cerrar la épica.
- **Qué probar cuando se retome el testing (Épica 16):** que `AppEntranceScope` no replaya al hacer scroll; que con "reducir movimiento" no hay desplazamientos; que `ProgressRing` con `animate: false` sigue el valor exacto; que las rutas `_flowPage` conservan su `name` para Analytics.

## Validación

`flutter analyze` sin problemas en todo el proyecto y `flutter build web --debug` exitoso (2026-10-26, junto con el trabajo de la Épica 19 que otro agente hacía en paralelo en el mismo árbol). No probado todavía en un dispositivo.
