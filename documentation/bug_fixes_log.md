# Registro de bugs — encontrados en pruebas manuales

Consolidado de bugs reportados por el usuario (o encontrados durante el desarrollo) vía prueba manual de la app, con su causa raíz y la solución aplicada. Complementa — no reemplaza — el detalle de arquitectura que ya vive en `documentation/<feature>.md`; este archivo es el índice rápido de "qué se rompió y por qué".

Formato por entrada: qué se reportó → causa raíz real → fix → archivos tocados.

---

## Épica 4 — Home

### BUG-H01 — Crash al tocar el botón de cámara (`bottom_navigation.dart`)

- **Reportado**: crash / assertion error al interactuar con el botón central de cámara del shell principal.
- **Causa raíz**: `Container.margin` no acepta valores negativos — el código usaba `margin: const EdgeInsets.only(top: -26)` para lograr el efecto "botón elevado sobre la barra" del diseño, lo cual Flutter rechaza con un assertion error.
- **Fix**: se reemplazó el `margin` negativo por `Transform.translate(offset: const Offset(0, -26), ...)`, logrando el mismo efecto visual sin depender de un valor de margen inválido.
- **Archivo**: `lib/core/widgets/bottom_navigation.dart`.
- **Estado**: corregido y **commiteado** (commit `6cc1680 "epica 5"`, por el usuario).

La "lista de bugs" que el usuario había mencionado en una sesión anterior (antes de empezar la Épica 5) resultó ser esta misma: los 3 bugs de Onboarding (BUG-O01/O02/O03) más este de Home (BUG-H01) — confirmado por el usuario 2026-09-20. No hay una lista adicional de Home pendiente.

---

## Épica 3 — Onboarding

Los 3 bugs siguientes se encontraron el 2026-09-20 probando el flujo B1-B7 manualmente en modo oscuro. Screenshots de referencia: B2 "Cuéntanos de ti" (selector de sexo + rueda de edad/altura/peso), B3 "¿Qué tan activo eres?", y B5 "¿Algo que debemos evitar?" (usado como contraejemplo — ahí NO pasaba el bug).

### BUG-O01 — Texto invisible al seleccionar una opción (B2 sexo, B3 actividad, y otros)

- **Reportado**: al seleccionar "Hombre/Mujer/Otro" (B2) o un nivel de actividad (B3), la opción se pinta de verde pero el texto desaparece por completo. El usuario notó que en B5 (alergias) esto NO pasaba.
- **Causa raíz real**: en `AppColorTokens.dark` (modo oscuro), los tokens `actionPrimaryPressed` y `actionPrimarySurface` tenían **el mismo valor hex** (`#1F6B48`) — un placeholder puesto en la Épica 1, ya marcado con un `// TODO(design-sync)` como "no confirmado contra el canvas", que nadie había disparado hasta ahora porque ningún flujo dibujaba un modo oscuro real en pantalla. Varios widgets seleccionables (`SelectableChip`, `OnboardingOptionCard`, el selector de sexo de B2) pintan el texto con `actionPrimaryPressed` sobre un fondo `actionPrimarySurface` cuando están seleccionados — con ambos siendo el mismo color, el texto quedaba literalmente invisible sobre su propio fondo. B5 (alergias) no mostraba el bug porque usa la variante `negative` de `SelectableChip` (colores `error`/`errorSurface`), un par de tokens distinto que sí difiere en modo oscuro — exactamente el contraejemplo que el usuario señaló.
- **Fix**: en vez de solo cambiar el valor de un color (lo que habría dejado un solo token cubriendo dos significados distintos en conflicto — fondo de botón presionado vs. texto sobre superficie tintada), se **separó el token en dos**:
  - `actionPrimaryPressed` se mantiene con su significado original y correcto (fondo de un botón sólido en su estado presionado — usado solo en `app_button.dart`, donde nunca hubo bug).
  - Se agregó `onActionPrimarySurface`, el color correcto para texto/ícono dibujado sobre `actionPrimarySurface`, modelado sobre la relación ya confirmada en el propio sistema de diseño entre `onAiAction` y `aiActionSurface` (color claro sobre superficie oscura saturada). En modo claro es idéntico al valor anterior de `actionPrimaryPressed` (`#076B40`) — cero cambio visual ahí. En modo oscuro es un mint claro nuevo (`#B8F5D6`), marcado igual que los demás placeholders de dark mode ya pendientes de confirmar contra el canvas de diseño.
- **Archivos**:
  - `lib/core/theme/app_color_tokens.dart` (token nuevo + doc-comment explicando la separación).
  - Los 7 sitios que hacían el mal uso, migrados al token nuevo: `lib/core/widgets/selectable_chip.dart`, `lib/features/onboarding/presentation/widgets/onboarding_option_card.dart` (B1/B3), `lib/features/onboarding/presentation/pages/steps/personal_data_step.dart` (selector de sexo, B2), `lib/features/onboarding/presentation/pages/steps/meal_rhythm_step.dart` (B6), `lib/features/onboarding/presentation/pages/steps/liked_foods_step.dart` (B4), `lib/features/home/presentation/pages/home_page.dart` (avatar con inicial), `lib/features/authentication/presentation/pages/sign_up_page.dart` (banner "tu plan ya está calculado") — estos dos últimos no fueron reportados por el usuario pero tenían exactamente la misma causa raíz, así que se corrigieron a la vez.
  - `documentation/design_system.md` (tabla de tokens actualizada).
- **Estado**: corregido, `flutter analyze` limpio. Pendiente de commit.

### BUG-O02 — Texto invisible en la tarjeta de actividad seleccionada (B3)

Mismo bug que BUG-O01, mismo fix — el usuario lo reportó como un bug aparte ("conecta con el 1") porque lo vio en un componente visualmente distinto (`OnboardingOptionCard`, tarjeta completa con checkmark, no un pill). Técnicamente es el mismo token mal usado en un segundo widget; se documenta con su propio ID porque así lo reportó el usuario, pero el fix fue uno solo (ver BUG-O01).

### BUG-O03 — Botón "Continuar" apagado en B2 con los 3 campos ya "llenos"

- **Reportado**: al entrar a B2, Edad/Altura/Peso ya muestran valores (29 años / 170 cm / 70.0 kg), pero el botón "Continuar" se ve apagado hasta que el usuario abre y confirma cada selector de rueda — se ve mal tener los 3 campos "listos" y el botón deshabilitado igual.
- **Causa raíz**: los valores mostrados (29/170/70) eran un fallback puramente visual (`answers.age ?? 29`, etc.) — el estado real (`answers.age`/`heightCm`/`weightKg` en `OnboardingAnswers`) seguía en `null` hasta que el usuario tocaba cada rueda. La condición `isValid` del botón exigía que los 3 campos NO fueran nulos, así que quedaba deshabilitado aunque la UI mostrara valores.
- **Fix**: `OnboardingAnswers` ahora inicializa `age`, `heightCm`, `weightKg` con esos mismos valores por defecto directamente en el constructor (`age = 29`, `heightCm = 170`, `weightKg = 70`) en vez de dejarlos en `null`. Lo mostrado y lo guardado coinciden desde el primer render — el botón ahora solo espera que se elija el sexo (el único de los 4 campos que correctamente no tiene un valor por defecto, porque no hay uno razonable que adivinar).
- **Nota de compatibilidad**: un borrador de Onboarding guardado localmente por una versión de la app anterior a este fix podría tener `age: null` explícito en su JSON persistido (`shared_preferences`). Es un caso de datos legacy pre-lanzamiento (sin usuarios reales todavía) que se degrada con gracia: el fallback visual `?? 29` lo sigue mostrando bien, solo pediría tocar ese campo una vez más de lo necesario.
- **Archivo**: `lib/features/onboarding/domain/entities/onboarding_answers.dart`.
- **Estado**: corregido, `flutter analyze` limpio. Pendiente de commit.

---

## Resumen

| ID | Épica | Bug | Causa raíz | Estado |
|---|---|---|---|---|
| BUG-H01 | Home | Crash al tocar botón de cámara | `Container.margin` negativo (no permitido por Flutter) | Corregido y commiteado |
| BUG-O01 | Onboarding | Texto invisible al seleccionar (B2, y otros) | `actionPrimaryPressed` == `actionPrimarySurface` en modo oscuro | Corregido, pendiente de commit |
| BUG-O02 | Onboarding | Texto invisible en tarjeta de actividad (B3) | Mismo que BUG-O01 | Corregido, pendiente de commit |
| BUG-O03 | Onboarding | Botón "Continuar" apagado con campos ya llenos (B2) | Estado real en `null` pese al fallback visual | Corregido, pendiente de commit |

**Todos los bugs conocidos están resueltos** (confirmado por el usuario 2026-09-20 — no había una lista de Home separada de los 4 anteriores).
