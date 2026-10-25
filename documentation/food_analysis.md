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

- **El resultado no se vincula al plan/registro de comidas** — Épica 6 (`PlannedMeal`) exige un `slotLabelKey`/horario predefinido por el plan; una foto analizada es, por definición, algo no planeado. Vincular esto necesita un concepto de "comida ad-hoc" que no existe en ningún epic del backlog todavía (ni siquiera "Registrar sin foto" del propio menú de cámara lo tiene). El análisis queda guardado en `foodAnalyses` como historial, sin acción de "agregar a mi día" todavía.
- **Retención de fotos (resuelto 2026-10-19)**: `analyzeFoodPhoto` borra la foto de Storage al terminar, con éxito o error (`finally` → `deletePhotoQuietly`, que nunca hace fallar el análisis). El documento de Firestore ya no guarda `imagePath` (apuntaría a un archivo borrado). Red de seguridad: `storage-lifecycle.json` (raíz del repo) — regla del bucket que borra todo lo que esté bajo `users/` con más de 1 día. **Ojo**: cualquier archivo futuro que sí deba persistir (p. ej. foto de perfil) tiene que vivir fuera de `users/` o ajustar esa regla. Se aplica una sola vez con `gcloud storage buckets update gs://nutritionapp-eee08.firebasestorage.app --lifecycle-file=storage-lifecycle.json` (el nombre exacto del bucket está en Firebase Console → Storage); la función necesita `firebase deploy --only functions:analyzeFoodPhoto`.
- **Solo "Analizar mi comida" quedó conectado** de las 3 opciones del menú de cámara — "Tengo ingredientes" (Épica 9, premium) y "Registrar sin foto" (sin épica dueña) siguen mostrando "muy pronto".

`flutter analyze` y `flutter build web --debug` limpios; `tsc`/`npm run build` limpios en `functions/` (8 Cloud Functions en total ahora).
