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
- **Estado**: corregido y **commiteado** (`676af41 "epica 10"`).

### BUG-O02 — Texto invisible en la tarjeta de actividad seleccionada (B3)

Mismo bug que BUG-O01, mismo fix — el usuario lo reportó como un bug aparte ("conecta con el 1") porque lo vio en un componente visualmente distinto (`OnboardingOptionCard`, tarjeta completa con checkmark, no un pill). Técnicamente es el mismo token mal usado en un segundo widget; se documenta con su propio ID porque así lo reportó el usuario, pero el fix fue uno solo (ver BUG-O01).

### BUG-O03 — Botón "Continuar" apagado en B2 con los 3 campos ya "llenos"

- **Reportado**: al entrar a B2, Edad/Altura/Peso ya muestran valores (29 años / 170 cm / 70.0 kg), pero el botón "Continuar" se ve apagado hasta que el usuario abre y confirma cada selector de rueda — se ve mal tener los 3 campos "listos" y el botón deshabilitado igual.
- **Causa raíz**: los valores mostrados (29/170/70) eran un fallback puramente visual (`answers.age ?? 29`, etc.) — el estado real (`answers.age`/`heightCm`/`weightKg` en `OnboardingAnswers`) seguía en `null` hasta que el usuario tocaba cada rueda. La condición `isValid` del botón exigía que los 3 campos NO fueran nulos, así que quedaba deshabilitado aunque la UI mostrara valores.
- **Fix**: `OnboardingAnswers` ahora inicializa `age`, `heightCm`, `weightKg` con esos mismos valores por defecto directamente en el constructor (`age = 29`, `heightCm = 170`, `weightKg = 70`) en vez de dejarlos en `null`. Lo mostrado y lo guardado coinciden desde el primer render — el botón ahora solo espera que se elija el sexo (el único de los 4 campos que correctamente no tiene un valor por defecto, porque no hay uno razonable que adivinar).
- **Nota de compatibilidad**: un borrador de Onboarding guardado localmente por una versión de la app anterior a este fix podría tener `age: null` explícito en su JSON persistido (`shared_preferences`). Es un caso de datos legacy pre-lanzamiento (sin usuarios reales todavía) que se degrada con gracia: el fallback visual `?? 29` lo sigue mostrando bien, solo pediría tocar ese campo una vez más de lo necesario.
- **Archivo**: `lib/features/onboarding/domain/entities/onboarding_answers.dart`.
- **Estado**: corregido y **commiteado** (`676af41 "epica 10"`).

### BUG-O04 — Overflow (rayas amarillas/negras) en B3, contenido cortado

- **Reportado**: en el paso de nivel de actividad (B3), aparecen rayas amarillas y negras (indicador de overflow de Flutter) y no se ve nada útil debajo — probado en un dispositivo Android real (Samsung SM-A546E), 2026-09-29.
- **Causa raíz**: `activity_level_step.dart` envolvía título + subtítulo + 5 tarjetas de opción + la caja de estimación de calorías (aparece dinámicamente al seleccionar una opción) en un `Padding` + `Column` sin ningún widget de scroll — a diferencia de otros pasos compuestos (`meal_rhythm_step.dart`, `liked_foods_step.dart`, `cooking_budget_step.dart`) que sí usan `SingleChildScrollView`. El contenido total supera el alto disponible en una pantalla real.
- **Fix**: se envolvió el contenido en `SingleChildScrollView`, mismo patrón que los pasos hermanos.
- **Archivo**: `lib/features/onboarding/presentation/pages/steps/activity_level_step.dart`.
- **Estado**: corregido y **commiteado** (`ccb7306 "fix(ui): fix 4 bugs found in real-device testing"`).

### BUG-O05 — Crash (`RangeError`) al tocar el horario de una comida en B6 sin haber elegido "comidas por día"

- **Reportado**: en el paso de ritmo de comidas (B6), seleccionar cuántas comidas al día funciona bien, pero al abrir el selector de hora de una comida la app se cierra con `RangeError (RangeError (length): Invalid value: Valid value range is empty: 0)` — mismo dispositivo, 2026-09-29.
- **Causa raíz real**: `meal_rhythm_step.dart` muestra 4 filas de horario por defecto (`defaultMealSlotsFor(4)`) como valor SOLO de pantalla mientras `answers.mealSlots` sigue vacío — nada obligaba al usuario a tocar antes uno de los chips 3/4/5/6, así que era posible abrir directamente el selector de hora de una de esas 4 filas "fantasma". `setMealSlotTime` indexaba sobre `state.mealSlots`, que seguía en `[]` porque ese valor por defecto nunca se había guardado — mismo tipo de bug que BUG-O03 (lo mostrado y lo guardado divergen), pero no se había extendido a B6 en su momento. A diferencia de BUG-O03, aquí no se pudo resolver con un valor por defecto en el constructor de `OnboardingAnswers`, porque `defaultMealSlotsFor` es una lista computada, no una constante de compilación.
- **Fix**: `setMealSlotTime` ahora es defensivo — si `state.mealSlots` está vacío al momento de aplicar el cambio, se siembra primero con el mismo `defaultMealSlotsFor(4)` que la pantalla ya usaba para mostrar esas 4 filas, y recién ahí aplica el horario elegido. Corrige tanto sesiones nuevas como un borrador ya guardado en el dispositivo del usuario con `mealSlots: []`.
- **Archivo**: `lib/features/onboarding/presentation/providers/onboarding_providers.dart`.
- **Estado**: corregido y **commiteado** (`ccb7306 "fix(ui): fix 4 bugs found in real-device testing"`).

### BUG-O06 — Overflow en la hoja "Analizar mi comida" en un dispositivo con más barra de sistema

- **Reportado**: al abrir "Analizar mi comida" (hoja de cámara, Home), aparece el indicador de overflow de Flutter en la parte inferior — `RenderFlex overflowed by 8.3 pixels on the bottom` en `app_bottom_sheet.dart:44`. Mismo dispositivo Android real, 2026-09-29.
- **Causa raíz**: `showAppBottomSheet` (altura `.auto`, no scrollable) ya reservaba `mediaQuery.padding.bottom` como padding extra para no invadir la zona de gestos/barra de sistema — pero ese padding varía por dispositivo (una barra de navegación de 3 botones reserva más espacio que la de gestos). Contenido que cabía justo en otros dispositivos podía superar por unos pocos píxeles el alto máximo que el modal permite en este, porque el padding reservado creció pero el contenido (título + 3 opciones + botón "Cancelar") no se achicó ni se volvió scrollable.
- **Fix**: se cambió el `Padding` de `showAppBottomSheet` por un `SingleChildScrollView` con el mismo `padding` — corrige la causa de raíz para TODAS las hojas del sistema (no solo la de cámara), de una sola vez, en el componente compartido en vez de parchar cada hoja por separado.
- **Archivo**: `lib/core/widgets/app_bottom_sheet.dart`.
- **Estado**: corregido y **commiteado** (`ccb7306 "fix(ui): fix 4 bugs found in real-device testing"`).

### BUG-O07 — Los botones de navegación del sistema (atrás/inicio) se superponen a la barra de tabs de la app

- **Reportado**: en un dispositivo con navegación de 3 botones (no gestos), los botones "atrás"/"inicio" del sistema aparecen encima de los botones inferiores de la app. Mismo dispositivo, 2026-09-29.
- **Causa raíz**: `BottomNavigation` (la barra de tabs de 4 ítems + botón de cámara) es un `Container` con altura fija (`84`) sin ningún `SafeArea` — a diferencia de un `BottomNavigationBar`/`NavigationBar` de Material (que sí reservan el inset del sistema automáticamente), un `Container` a medida no lo hace solo. `Scaffold.bottomNavigationBar` tampoco lo agrega por sí mismo para un widget custom.
- **Fix**: se envolvió en `SafeArea(top: false, child: ...)` — reserva el alto exacto que el sistema necesita en cada dispositivo (0 en gestos, ~48dp en navegación de 3 botones) sin tocar el resto del diseño.
- **Archivo**: `lib/core/widgets/bottom_navigation.dart`.
- **Estado**: corregido y **commiteado** (`ccb7306 "fix(ui): fix 4 bugs found in real-device testing"`).

---

## Épica 15 / Deployment — Backend

### BUG-D01 — Todas las Cloud Functions devolvían 403 al cliente real pese a un deploy "exitoso"

- **Reportado**: después de desplegar por primera vez a producción (2026-09-29), "Analizar mi comida" fallaba con "Algo salió mal" en el dispositivo real. `firebase functions:log` mostró `The request was not authorized to invoke this service. The access token could not be verified.` — un rechazo de plataforma (Cloud Run), no un error de la función.
- **Causa raíz real**: leyendo el propio código fuente de `firebase-tools` (`lib/deploy/functions/release/fabricator.js`), se confirmó que la herramienta solo otorga el permiso público de invocación (`roles/run.invoker` a `allUsers`) cuando una función callable (`onCall`) se **crea** por primera vez — `updateV2Function` no tiene ninguna rama para triggers callable (sí para HTTP, tareas programadas, etc.), así que un redeploy de una función que ya existe NUNCA vuelve a tocar ese permiso, sin importar cuántas veces se redespliegue. Como contribuyente adicional (no la causa raíz, pero sí bloqueó el diagnóstico): `compute.googleapis.com` nunca había sido habilitada en el proyecto, lo que hacía fallar silenciosamente un paso no relacionado del deploy (búsqueda de la cuenta de servicio por defecto) con `SERVICE_DISABLED`.
- **Fix real**: se agregó `invoker: "public"` explícito a las 9 funciones `onCall(...)` (defensivo, documentado en `firebase-functions`, pero confirmado por curl que esto solo no alcanza para una función que ya existe) y se borró + redesplegó cada una de las 9 funciones para forzar a `firebase-tools` a pasar por su rama de creación (`isCallableTriggered`), que sí otorga el permiso público. Verificado con curl: las 9 pasaron de un bloqueo 403 de plataforma (página HTML de Google Frontend) a un `401 unauthenticated` correcto (rechazo real de la función, por falta de token de Firebase Auth en la prueba).
- **Archivos**: los 9 archivos bajo `functions/src/**/*.ts` con `onCall(...)`.
- **Estado**: corregido y **commiteado** (`d0ac80e "fix(functions): grant public invoker to all callable functions"`). Confirmado funcionando en producción por el usuario 2026-09-30.

---

## Épica 14 — Analytics

### BUG-A01 — Crash al analizar una foto de comida (`_AssertionError` en `firebase_analytics`)

- **Reportado**: después de resolver BUG-D01 (arriba) y recargar crédito de OpenAI, analizar una foto sí funcionaba pero la app crasheaba justo después, con `_AssertionError`: `'value is String || value is num': 'string' OR 'number' must be set as the value of the parameter: is_food_photo. true found instead`.
- **Causa raíz**: `FirebaseAnalyticsService.logFoodPhotoAnalyzed` pasaba el parámetro `isFoodPhoto` (un `bool` de Dart) directo como valor de un parámetro de evento — el plugin `firebase_analytics` solo acepta `String` o `num` como tipo de valor, nunca `bool`, y lo valida con un `assert` que revienta en tiempo de ejecución.
- **Fix**: se codificó como `1`/`0` (`isFoodPhoto ? 1 : 0`), la misma convención GA4 ya usada implícitamente en otros parámetros booleanos del proyecto.
- **Archivo**: `lib/core/services/analytics/firebase_analytics_service.dart`.
- **Estado**: corregido y **commiteado** (`335ac7a "fix(analytics): stop crashing on food_photo_analyzed event"`).

---

## Resumen

| ID | Épica | Bug | Causa raíz | Estado |
|---|---|---|---|---|
| BUG-H01 | Home | Crash al tocar botón de cámara | `Container.margin` negativo (no permitido por Flutter) | Corregido y commiteado |
| BUG-O01 | Onboarding | Texto invisible al seleccionar (B2, y otros) | `actionPrimaryPressed` == `actionPrimarySurface` en modo oscuro | Corregido y commiteado |
| BUG-O02 | Onboarding | Texto invisible en tarjeta de actividad (B3) | Mismo que BUG-O01 | Corregido y commiteado |
| BUG-O03 | Onboarding | Botón "Continuar" apagado con campos ya llenos (B2) | Estado real en `null` pese al fallback visual | Corregido y commiteado |
| BUG-O04 | Onboarding | Overflow visual en B3 (nivel de actividad) | Sin `SingleChildScrollView`, a diferencia de pasos hermanos | Corregido y commiteado |
| BUG-O05 | Onboarding | Crash `RangeError` al elegir hora en B6 sin elegir conteo antes | Estado real (`mealSlots: []`) diverge del fallback visual de 4 filas | Corregido y commiteado |
| BUG-O06 | Home (hoja de cámara) | Overflow en "Analizar mi comida" | `showAppBottomSheet` sin scroll, padding de safe-area varía por dispositivo | Corregido y commiteado |
| BUG-O07 | Shell principal | Botones del sistema se superponen a la barra de tabs | `BottomNavigation` sin `SafeArea` | Corregido y commiteado |
| BUG-D01 | Backend/Deployment | Todas las funciones devolvían 403 pese a deploy exitoso | `firebase-tools` nunca re-aplica el invoker público en un `update`, solo en `create` | Corregido y commiteado, confirmado en producción |
| BUG-A01 | Analytics | Crash tras analizar foto (`_AssertionError`) | `bool` pasado como valor de parámetro de evento (solo acepta `String`/`num`) | Corregido y commiteado |

**Bugs BUG-H01/O01-O07 confirmados resueltos por el usuario y todos commiteados.** BUG-D01/A01 encontrados y corregidos 2026-09-30 durante el primer ciclo de pruebas end-to-end en producción — ambos confirmados funcionando por el usuario.
