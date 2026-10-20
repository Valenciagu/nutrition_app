# Prompt para Claude Design — Identidad de marca, iconos e imágenes

> Cómo usarlo: abre el proyecto del canvas (ver `desing.md`), pega todo lo que está bajo la línea `--- PROMPT ---` en Claude Design y pide que entregue **cada asset como archivo separado** (SVG/PNG con el nombre exacto de la tabla). Luego se comparten con Claude Code vía el MCP `claude_design` y se colocan en `assets/` (ver TASKS.md, Epic 18, ASSET-102 a ASSET-106).

--- PROMPT ---

Eres el diseñador de marca y de producto de una app móvil de nutrición con IA (Flutter, iOS + Android, español primero, inglés después). Ya existe un sistema de diseño en este canvas (`Fase 1 - Fundamentos`, `Fichas de componentes`, `Fase 2` a `Fases 5-12`). **Léelo primero y respétalo. No inventes una estética nueva**: lo que pido abajo debe verse como si siempre hubiera pertenecido a estas pantallas.

## 1. Contexto de producto

- Nombre provisional: **NutritionApp** (el nombre final aún no existe; si propones uno mejor, preséntalo como alternativa aparte, sin reemplazar el provisional en los entregables).
- Tagline actual: "Tu nutricionista de bolsillo". Promesa: "Come mejor sin contar cada gramo".
- Usuario: adulto que quiere comer mejor sin obsesión ni culpa. Plan diario, recetas, análisis de comida por foto, lista de compra y un asistente de IA.
- Dirección de diseño del canvas: **"Cocina luminosa, no laboratorio"**. Base blanca amplia, tipografía fuerte, fotografía de comida a sangre, verde usado con sobriedad. Lo premium sale del espacio y la jerarquía, no de degradados ni cromados.

## 2. Reglas del sistema que NO se pueden romper

1. **El verde es un semáforo**: solo CTA principal, progreso, logro y estado saludable. Nunca fondo decorativo grande.
2. **La IA tiene voz, no control**: todo lo generado por IA se marca con índigo (`#4740C4` / superficie `#EEEDFB`, texto `#332D93`) y un punto de estado.
3. **La comida lidera**: la foto es el elemento más grande de la pantalla.
4. **Progreso, nunca culpa**: nada de rojo para "te pasaste". El rojo es solo error del sistema.

Paleta (light / dark):
- Primario `#0B8F55` (texto blanco encima) · primario fuerte `#17A86A` (rellenos sin texto, iconos) · hover/pressed `#076B40` · superficie `#E9F7F0` / dark `#1F6B48`
- Fondo `#F7F8F7` / `#0C110F` · superficie `#FFFFFF` / `#141A17` · borde `#E4E7E5` / `#2A332E`
- Texto `#101512` / `#F2F5F3` · secundario `#5B635E` / `#A3ADA7`
- Macros: proteína `#0B8F55`, carbos `#C98A17`, grasa `#4740C4`, agua `#1A6FB8`
- Tipografía: **Plus Jakarta Sans** (6 pesos, cifras tabulares para números nutricionales). Es la única familia permitida, también dentro del logotipo.
- Radios: 4/8/12/16/20/28 y `full`. Botones y chips siempre `full`; imágenes dentro de tarjeta 12.
- Iconos: **Phosphor** (ya elegido). Tamaños 16/20/24/28/32, trazo 1.75 (1.5 a tamaño 20).

## 3. Entregables

### A. Marca (prioridad máxima)

Explora **3 direcciones** de isotipo + wordmark en una sola lámina comparativa (cada una con su razonamiento en 2 líneas), recomienda una y entrega **solo la elegida** en los archivos finales. Criterios:
- Isotipo geométrico, simple, reconocible a 16 px, que funcione en **un solo color**. Evoca comida/hoja/plato/equilibrio **sin caer en el cliché** de hoja genérica + tenedor + cuchara, ni en manzanas ni en corazones.
- Esquinas redondeadas coherentes con el sistema (radios generosos). Sin degradados, sombras ni efectos.
- El wordmark usa Plus Jakarta Sans (peso 700–800) con ajuste óptico de kerning.
- Debe leerse bien (1) en blanco sobre el verde `#17A86A` del Splash y (2) en verde `#0B8F55` sobre `#F7F8F7`.

| Archivo | Descripción | Formato |
|---|---|---|
| `brand/isotype_color.svg` | Isotipo a color sobre transparente | SVG, viewBox cuadrado |
| `brand/isotype_white.svg` | Isotipo en blanco (para fondo verde, Splash) | SVG |
| `brand/isotype_mono.svg` | Silueta de un solo color, sin detalles internos finos | SVG |
| `brand/wordmark_color.svg` / `brand/wordmark_white.svg` | Wordmark solo, a color y en blanco | SVG, texto convertido a trazos |
| `brand/logo_horizontal_color.svg` / `_white.svg` | Isotipo + wordmark en horizontal | SVG |
| `brand/app_icon_1024.png` | Ícono de la app: isotipo sobre fondo verde sólido `#17A86A`, **sin transparencia, sin esquinas redondeadas** (el sistema las aplica), sin texto | PNG 1024×1024 |
| `brand/app_icon_foreground.png` | Solo el isotipo, centrado dentro de la **zona segura de Android adaptativo** (círculo de ⅔ del lienzo), fondo transparente | PNG 1024×1024 |
| `brand/app_icon_background.png` | Fondo verde sólido para el ícono adaptativo | PNG 1024×1024 |
| `brand/app_icon_dark_1024.png` | Variante oscura/tintada para iOS (isotipo verde claro `#3ED98C` sobre `#0C110F`) | PNG 1024×1024 |
| `brand/notification_icon.svg` | Silueta **blanca monocromática** del isotipo para la barra de estado de Android (sin color, sin rellenos parciales), legible a 24×24 dp | SVG + PNG 96×96 |
| `brand/splash_logo.svg` | Isotipo blanco para el splash nativo (fondo real: `#0B8F55`, ver design_system.md) | SVG (y PNG 1152×1152 transparente) |

Entrega además una lámina de uso: área de respeto, tamaño mínimo, y 3 usos incorrectos.

### B. Iconos propios (complementan Phosphor, mismo trazo 1.75, esquinas redondeadas, cuadrícula 24×24)

Phosphor ya cubre lo genérico. Dibuja **solo** estos, diseñados para que **parezcan hermanos de Phosphor** (misma cuadrícula, terminales redondeadas, mismo peso visual). Cada uno en versión `regular` (contorno) y `fill` (relleno), SVG con `currentColor`:

| Archivo | Concepto |
|---|---|
| `icons/food_scanner` | Plato visto desde arriba dentro de marcos de escaneo en las esquinas |
| `icons/ingredients_photo` | Cámara/marco con una zanahoria y una hoja asomando |
| `icons/recalculate_day` | Sol/día con flecha circular |
| `icons/streak` | Llama estilizada (racha); el `fill` se usará con el badge de racha |
| `icons/ai_sparkle` | Destello propio de la IA (más sobrio que el genérico; se pinta en índigo) |
| `icons/macro_protein`, `macro_carbs`, `macro_fat`, `macro_water` | 4 glifos pequeños para las barras de macros (16–20 px), distinguibles también sin color (forma distinta cada uno) |

### C. Fotografía (guía de dirección + imágenes)

Receta fija de fotografía (del sistema): **luz natural lateral, fondo neutro mate, ángulo 90° o 45°, plato limpio y simple, porción realista, sin manos ni cubiertos**. Sin filtros saturados; el verde de la UI es el único color intenso, así que la comida debe verse natural.

| Archivo | Uso | Formato |
|---|---|---|
| `images/welcome_hero.jpg` | Pantalla de bienvenida: foto de comida **a sangre** en la mitad superior. Debe prometer comida, no software. Dejar el tercio inferior visualmente tranquilo (se superpone un fade a blanco). Un plato colorido, de aspecto casero | 4:5, 1600×2000, JPG calidad 85 |
| `images/goal_lose_fat.jpg` | Tarjeta "Perder grasa" — plato ligero, mucha verdura, proteína magra | 1:1, 800×800 |
| `images/goal_gain_muscle.jpg` | "Ganar músculo" — plato abundante con proteína visible | 1:1, 800×800 |
| `images/goal_maintain.jpg` | "Mantener peso" — plato equilibrado, proporciones clásicas | 1:1, 800×800 |
| `images/goal_eat_healthier.jpg` | "Comer más saludable" — bowl fresco, variedad de ingredientes | 1:1, 800×800 |

Las 4 imágenes de objetivos deben formar una **serie coherente** (mismo fondo, luz y ángulo) y verse bien recortadas a 64×64 px dentro de una tarjeta con radio 12. Si no puedes generar fotografía realista, entrega en su lugar **briefs fotográficos detallados** (encuadre, props, luz, plato, paleta) para que un fotógrafo/banco de imágenes los produzca, y márcalo claramente.

### D. Elementos de terceros (NO los dibujes)

El logo de **Google "G"** y el de **Apple** deben usarse **tal cual los publica cada marca** (Google Sign-In branding guidelines / Apple HIG). No los redibujes ni los "adaptes al estilo": indícame únicamente el tamaño, el padding y el fondo que debe tener el botón en nuestro sistema para cumplir sus guías.

## 4. Reglas de formato y calidad

- SVG limpios: sin metadatos de editor, sin `<style>` global, sin fuentes embebidas (texto a trazos), sin IDs duplicados, colores como `fill`/`stroke` simples; los iconos con `currentColor`.
- Nombres de archivo exactos como en las tablas, en `snake_case`, sin espacios ni acentos.
- Verifica cada asset en **claro y oscuro** y a **16, 24 y 48 px**.
- Contraste: texto/iconos sobre el verde cumplen WCAG AA (el único verde con texto blanco encima es `#0B8F55`; `#17A86A` es solo para rellenos e iconos).
- Todo lo que dependa de un texto (wordmark) debe indicar la fuente y el peso exactos usados.
- Al final, entrega una **tabla resumen** con: archivo, qué es, dónde se usa en la app, dimensiones, y cualquier decisión de diseño que yo deba confirmar.

## 5. Antes de empezar

Si algo de esto contradice el canvas existente, **gana el canvas**: dímelo en vez de resolverlo en silencio. Si te falta información (por ejemplo el nombre final de la marca), propón un supuesto explícito y continúa.

--- FIN DEL PROMPT ---

## Mapa de destino en el repo (para Claude Code, no para Claude Design)

| Entregable | Destino | Tarea |
|---|---|---|
| `brand/isotype_*.svg`, `wordmark_*`, `logo_horizontal_*` | `assets/brand/` (reemplaza `isotype.svg` placeholder; `AppAssets`) | ASSET-102 |
| `app_icon_*`, `splash_logo`, `notification_icon` | fuente de `flutter_launcher_icons` / `flutter_native_splash` + `android/.../res/drawable` | ASSET-103 |
| Google "G" oficial | `assets/images/third_party/` + botón en Login/SignUp | ASSET-104 |
| `images/*.jpg` | `assets/images/` + `OnboardingOptionCard` (reemplaza `showImagePlaceholder`) y `welcome_page.dart` (reemplaza `HatchedPlaceholder`) | ASSET-105 |
| `icons/*` propios | `assets/icons/` + entradas en `AppIcons` (envolviendo `SvgPicture`) | ASSET-106 |
