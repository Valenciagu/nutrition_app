# Épica 8 — Análisis de foto de comida

Estado: **completa** (2026-09-20).

## Qué hace

Desde el botón de cámara central (`MainShell`), "Analizar mi comida" deja tomar o elegir una foto (Instrucciones.md §6: "take or upload a photo"), la sube, y devuelve una estimación de calorías/macros con incertidumbre explícita — nunca presentada como una medición exacta.

## Flujo completo

```
Flutter → elegir fuente (cámara/galería) → comprimir (image_picker) →
subir a Storage (users/{uid}/foodAnalyses/{analysisId}.jpg) →
Cloud Function `analyzeFoodPhoto` (auth → cuota → descarga la foto vía
Admin SDK → OpenAI vision → validación estructurada/seguridad → Firestore) →
Flutter (FoodAnalysisResultCard)
```

## Backend (`functions/src/foodAnalysis/`)

- **`analyzeFoodPhoto.ts`** — Cloud Function `onCall`. La ruta de Storage se arma SIEMPRE server-side a partir de `request.auth.uid` + el `analysisId` que manda el cliente (nunca se confía en una ruta arbitraria, Instrucciones.md §70). Descarga la foto con el Admin SDK (bypassa `storage.rules`, funciona sobre un archivo privado) y la manda a OpenAI como `data:` URI en base64 — **nunca se genera una URL firmada/pública** (Instrucciones.md §68: "avoid exposing public URLs unnecessarily").
- **`schema.ts`** — `FoodAnalysisSchema`. Primer chequeo: `isFoodPhoto` — si la foto no muestra comida reconocible, TODOS los campos de comida quedan en `null`, nunca una estimación inventada de algo que no es comida.
- **`safety.ts`** — a diferencia de `plan/safety.ts`/`recipes/safety.ts` (que rechazan y dejan que el modelo regenere), aquí **no hay nada que regenerar**: el plato ya existe frente al usuario. Un alérgeno detectado (autorreporte + escaneo de `ALLERGEN_KEYWORDS` sobre el nombre del alimento) se devuelve como **advertencia** (`allergenWarning: true`), no como rechazo — la estimación se muestra igual.
- **`prompts/foodAnalysisV1.ts`** — `uncertaintyNote` es un campo obligatorio del esquema siempre que `isFoodPhoto` sea `true`, no solo una instrucción del prompt — fuerza esa comunicación en cada respuesta (Instrucciones.md §6).
- No se rechaza NUNCA una respuesta completa (a diferencia de `askNutritionAssistant`/`generateDailyPlan`) — ni por alérgeno (advertencia) ni por "no es comida" (se devuelve con `isFoodPhoto: false`, sin lanzar `HttpsError`, mismo patrón de "respuesta de seguridad" que el *fallback* de `askNutritionAssistant`). Solo un fallo real de OpenAI reembolsa la cuota.
- Solo se persiste en Firestore (`users/{uid}/foodAnalyses/{analysisId}`) un análisis que sí reconoció comida.
- `AI_MODELS.foodPhotoAnalysis` reusa el mismo modelo que `nutritionQa`/`recipeGeneration` (`gpt-5.6-luna`, ya nativamente multimodal) con una clave propia para poder enrutar a otro modelo en el futuro sin tocar la función.
- Nueva cuota `foodAnalysis` (5/día free · 20/día premium, igual criterio que `planGeneration`).

## Storage (primer uso real)

- `storage.rules` (nuevo archivo, agregado a `firebase.json`) — `users/{userId}/foodAnalyses/{fileName}`: el cliente puede leer/subir SOLO lo suyo, con tope de 10 MB y `contentType` que empiece con `image/` (debe coincidir con `MAX_IMAGE_BYTES` en `analyzeFoodPhoto.ts`). No desplegado todavía (mismo estado que `firestore.rules` — ver "Open questions" en `TASKS.md`).
- `firebaseStorageProvider` nuevo en `core/services/firebase_instances.dart`.

## Flutter (`lib/features/food_analysis/`)

- Dominio: `FoodAnalysisResult` (+ `FoodAnalysisConfidence`), `FoodAnalysisRepository` — recibe `Uint8List`, no un `XFile` de `image_picker`: el dominio no depende de un paquete de terceros específico de la fuente de la imagen.
- Datos: `FirebaseFoodAnalysisRepository` — sube a Storage y llama al callable; usa `firestore.collection(...).doc().id` solo para generar un id del lado del cliente (sin escribir nada), que nombra el archivo Y, si el análisis reconoce comida, el documento que escribe la función — los tres quedan correlacionados sin un mapeo aparte.
- Presentación: `foodAnalysisControllerProvider` (mismo patrón `AsyncNotifier<FoodAnalysisResult?>` que `MealAlternativesController`, Épica 6), `FoodAnalysisPage` (ruta de nivel superior `/food-analysis`, no anidada bajo ningún tab — el botón de cámara vive en `MainShell`, fuera de las pilas de navegación de las tabs), `FoodAnalysisResultCard`.
- `camera_action_sheet.dart` reescrito: "Analizar mi comida" ahora revisa sesión ANTES de abrir la cámara/galería (sin camino de invitado, mismo criterio que Plan — pedirle una foto a un invitado para recién ahí decirle que necesita cuenta sería peor UX), luego pregunta cámara/galería en una segunda hoja, comprime con `image_picker` (`imageQuality: 70`, `maxWidth: 1600`), y navega a `FoodAnalysisPage` con los bytes ya en mano vía `extra` de GoRouter.
- Nuevos componentes compartidos (`core/widgets/`) extraídos en su SEGUNDO consumidor real: `MacroStatTile` (antes privado de D3) y `RoundIconButton` (antes privado de D3) — ahora los usan D3 y esta pantalla.

## Decisiones de alcance, documentadas no adivinadas

- ~~**El resultado no se vincula al plan/registro de comidas**~~ — **resuelto 2026-10-26 (LOG-102, Épica 19)**: el botón "Registrar comida" bajo el resultado lo suma a hoy como comida extra (`logExtraMeal` con `source: photo`, cifras tomadas del documento `foodAnalyses` en el servidor, idempotente). Ver `documentation/meal_log.md`.
- **Retención de fotos (resuelto 2026-10-19)**: `analyzeFoodPhoto` borra la foto de Storage al terminar, con éxito o error (`finally` → `deletePhotoQuietly`, que nunca hace fallar el análisis). El documento de Firestore ya no guarda `imagePath` (apuntaría a un archivo borrado). Red de seguridad: `storage-lifecycle.json` (raíz del repo) — regla del bucket que borra todo lo que esté bajo `users/` con más de 1 día. **Ojo**: cualquier archivo futuro que sí deba persistir (p. ej. foto de perfil) tiene que vivir fuera de `users/` o ajustar esa regla. Se aplica una sola vez con `gcloud storage buckets update gs://nutritionapp-eee08.firebasestorage.app --lifecycle-file=storage-lifecycle.json` (el nombre exacto del bucket está en Firebase Console → Storage); la función necesita `firebase deploy --only functions:analyzeFoodPhoto`.
- Las 3 opciones del menú de cámara ya están conectadas: "Tengo ingredientes" (Épica 9, 2026-10-25) y "Registrar sin foto" (LOG-105, 2026-10-26).

`flutter analyze` y `flutter build web --debug` limpios; `tsc`/`npm run build` limpios en `functions/` (8 Cloud Functions en total ahora).

## Canvas · Fase 5 (Análisis de comida), leído 2026-10-26

Bloque de `Fases 5-12 - Entrega final.dc.html`: "Cámara → análisis → resultado editable → registro". La palabra "estimación" y el símbolo ~ van siempre junto a la cifra.

- **E1 · Cámara analizando**: cámara siempre en oscuro, "Identificando tu plato…", "Mantén el plato completo dentro del marco"; barrido verde por el marco cada 1,4 s.
- **E2 · Detección con overlays**: un overlay por alimento con sus kcal (Pollo 330, Brócoli 42…), "Estimación ~576 kcal · 4 alimentos", proteína/carbos/grasas, "Valores aproximados. Toca cualquier alimento para ajustar la cantidad." Acciones **"Corregir"** (tan visible como registrar: la IA puede equivocarse) y **"Registrar comida"**. Overlays escalonados (60 ms, scale .92→1), fuera del centro del plato.
- **E3 · Error de análisis**: "No pudimos reconocer el plato" + consejo de luz/ángulo; dos salidas, **"Repetir la foto"** y **"Escribir qué comí"**; nunca códigos de error; sin red → "Sin conexión" y la foto se guarda para después.

Estado frente al canvas: la app hoy no hace E1 (usa la cámara del sistema) ni overlays por alimento (el modelo devuelve un plato, no alimentos con posición). "Registrar comida" está hecho (LOG-102). "Corregir" se cubre con el ajuste de porción de la comida extra en D1. E3 no está construido como pantalla propia.

