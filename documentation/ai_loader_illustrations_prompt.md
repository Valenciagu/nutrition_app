# Prompt para Claude Design — Ilustraciones del loader de IA (MOTION-102)

> Cómo usarlo: abre el proyecto del canvas (ver `desing.md`), pega todo lo que está bajo la línea `--- PROMPT ---` en Claude Design y pide que entregue **cada ilustración como un SVG separado** con el nombre exacto de la tabla. Después se traen con el MCP `claude_design` (o se pasan a mano) a `assets/illustrations/loader/`, se registran en `documentation/design_system.md` → "Animation sources" y se conectan al widget `AiLoader` (TASKS.md, Épica 20, MOTION-102 — camino "A" aprobado por el usuario el 2026-10-25).

--- PROMPT ---

Eres el ilustrador de producto de una app móvil de nutrición con IA (Flutter, iOS + Android, español primero). El canvas ya tiene el sistema de diseño (`Fase 1 - Fundamentos`, `Fichas de componentes`, `Marca e iconos`, `Fase 2` a `Fases 5-12`). **Léelo primero y respétalo**: estas ilustraciones tienen que verse como si siempre hubieran sido parte de la marca, hermanas del isotipo "Plato en proporción" y de los 18 íconos propios.

## Para qué son

Un **loader de marca** que se muestra solo mientras la IA trabaja: generar el plan del día, analizar una foto de comida, leer ingredientes, generar una receta, ajustar el plan. La app muestra **una ilustración a la vez** en el centro, a unos **72-96 px**, y las va alternando cada ~1,2 s (entra con un pequeño aumento de escala y un fundido, sale con un fundido). Junto a ella va el punto de estado índigo de la IA y el texto que ya tiene cada pantalla. La animación la hace la app en código; **tú entregas dibujos estáticos**.

Referencia de sensación: el loader de Fitia, que va pasando por una piña, un muslo de pollo, etc. **No copies su estilo**: el nuestro sale del sistema de este canvas.

## Las 8 ilustraciones

| Archivo | Alimento |
|---|---|
| `loader/food_pineapple.svg` | Piña (con su corona de hojas) |
| `loader/food_drumstick.svg` | Muslo de pollo cocido |
| `loader/food_avocado.svg` | Medio aguacate con su semilla |
| `loader/food_arepa.svg` | Arepa |
| `loader/food_egg.svg` | Huevo frito |
| `loader/food_banana.svg` | Banano |
| `loader/food_broccoli.svg` | Brócoli |
| `loader/food_rice_bowl.svg` | Tazón de arroz blanco |

## Estilo (obligatorio)

- **Geométrico, plano y redondeado**, con la misma lógica que el isotipo: formas simples, esquinas generosas, siluetas que se reconocen al instante a 72 px. Nada de realismo, texturas ni detalles finos que desaparecen a ese tamaño.
- **Sin degradados, sombras, brillos, contornos negros ni efectos.** Formas de color sólido; como máximo un tono más oscuro del mismo color para dar volumen.
- **Color:** que la comida lleve su color natural, pero **limitado a 2-3 colores por ilustración** y armonizado con la paleta del canvas: verdes cerca de `#0B8F55` / `#17A86A` / `#3ED98C`, dorados cerca de `#C98A17`, cremas y blancos rotos. Nada de morados ni azules (el índigo es exclusivo de la IA y lo pone la app con el punto de estado). Nunca un fondo detrás del alimento.
- **Las 8 deben verse como una serie**: mismo peso visual, mismo nivel de detalle, mismo tamaño óptico dentro del lienzo y la misma "luz" (si una lleva el tono más oscuro abajo a la derecha, todas igual).
- **Funcionan en claro y en oscuro**: se ven sobre `#FFFFFF` y sobre `#141A17`. Evita que el borde de la silueta sea blanco o casi negro, porque desaparecería en uno de los dos.

## Requisitos técnicos (si no se cumplen, el archivo no sirve)

- SVG con `viewBox="0 0 96 96"`, la ilustración centrada con ~8 px de margen y sin `width`/`height` fijos.
- Solo `path`, `circle`, `ellipse`, `rect` y `g` con rellenos sólidos (`fill` en hex). **Sin** `foreignObject`, `filter`, `mask`, `clipPath`, imágenes embebidas, degradados, texto ni CSS (`<style>`): el renderizador de Flutter (`flutter_svg`) no los dibuja bien.
- Agrupa cada parte con un `id` descriptivo (`<g id="leaves">`, `<g id="body">`, `<g id="seed">`). Hoy no se usa, pero permite convertirlas a Rive más adelante para la transformación de una en otra, sin redibujarlas.
- Liviano: cada archivo de menos de 6 KB, con los trazos convertidos a formas y sin metadatos de editor.

## Entrega

1. Una lámina con las 8 juntas en claro y en oscuro, a 72 px y a 96 px, para comparar la serie.
2. Los 8 SVG separados, con los nombres de la tabla.
3. Si alguna no queda bien a 72 px, simplifícala; no la entregues más detallada.

Son obra original para este proyecto (sin bancos de ilustraciones ni íconos de terceros), para poder usarlas comercialmente sin restricciones.
