# Prompts para generar las fotos de la app (ASSET-105)

Escritos en inglés porque los generadores de imágenes responden mejor así. Para cada foto, pega el **bloque de estilo** completo y debajo el **prompt de esa foto**. Si la herramienta tiene un campo de "negative prompt", pon ahí la lista de "Avoid".

---

## Bloque de estilo (pegar siempre)

```
STYLE — apply to every image in this set (they must look like one series):

Realistic editorial food photography for a Latin American nutrition app whose motto is "a luminous kitchen, not a lab". Looks like a real photo taken at home, not a 3D render or stock image.

Light: natural morning window light coming from the LEFT side of the frame. Soft but defined shadows falling to the right. No studio lighting, no glow, no backlight halo.

Background and surfaces: matte, light, neutral. A soft off-white surface close to #F7F8F7 (pale warm grey-white), or a very light matte plaster or linen-free tabletop. Plain plates and bowls in white or light grey ceramic, slightly irregular and handmade-looking. No marble, no dark wood, no slate.

Color palette: let the food bring the color. The overall image stays bright and airy with lots of off-white. Natural greens from vegetables and herbs are welcome (they echo the brand green #0B8F55), plus warm golden tones (rice, grains, plantain, around #C98A17). Never add green props, green backgrounds or green tablecloths. No purple or blue props.

Food: realistic, honest home-cooked portions for one person, a little imperfect (a crumb, an uneven slice, a sauce drip). Real textures. Ingredients common in Latin America.

Composition: one clear main subject, generous empty space around it, slightly off-center. Camera either directly overhead (90°) or at 45°, as indicated in each prompt.

Avoid: hands, people, cutlery in use, text, logos, labels, brand packaging, marble, rosemary sprigs, eucalyptus, wrinkled beige linen, perfect symmetrical "rainbow" bowls, oversaturated colors, glossy varnished-looking avocado, fake steam, flying or falling ingredients, water droplets, round bokeh, dark vignette, cinematic look, confetti garnish (sesame seeds, microgreens and edible flowers scattered everywhere).
```

---

## 1. Pantalla de bienvenida (hero)

Formato: **vertical 4:5, 1600 × 2000 px**. Ocupa la mitad superior de la pantalla, y la parte de abajo queda tapada por una tarjeta blanca de esquinas redondeadas.

```
IMAGE: Overhead (90°) view of a breakfast table for one, as if someone is about to sit down: a white plate with a grilled corn arepa topped with sliced avocado and a fried egg, a small bowl of fresh papaya and pineapple cubes, a glass of water, half a lime. Keep the main elements in the upper two thirds of the frame; the bottom 20% must be calm, mostly empty off-white surface (an interface card will cover it). Vertical 4:5.
```

## 2. Objetivo "Perder grasa"

Formato: **cuadrado 1:1, 1200 × 1200 px**. Se ve chico, como miniatura en una tarjeta.

```
IMAGE: 45° view of a single wide white bowl with a fresh salad: sliced grilled chicken breast, avocado, cherry tomatoes, cucumber, red onion, a lime wedge. One dish only, centered with margin around it so it reads clearly at a small thumbnail size. Square 1:1.
```

## 3. Objetivo "Ganar músculo"

```
IMAGE: 45° view of a single white plate with a generous but realistic portion: white rice, black beans, grilled steak slices, a fried egg and a few slices of golden sweet plantain. One dish only, centered with margin around it so it reads clearly at a small thumbnail size. Square 1:1.
```

## 4. Objetivo "Mantener peso"

```
IMAGE: 45° view of a single white plate with a balanced meal: a grilled white fish fillet, a portion of quinoa, roasted zucchini, carrots and peppers, a lemon wedge. One dish only, centered with margin around it so it reads clearly at a small thumbnail size. Square 1:1.
```

## 5. Objetivo "Comer más saludable"

```
IMAGE: Overhead (90°) view of a single light grey ceramic bowl with natural yogurt, rolled oats, sliced banana, papaya cubes and a few blackberries, a small spoon resting beside the bowl (not in use). One dish only, centered with margin around it so it reads clearly at a small thumbnail size. Square 1:1.
```

---

## Opcional: los 9 alimentos de "¿Qué te gusta comer?"

Formato: **cuadrado 1:1, 800 × 800 px**. Usa el mismo bloque de estilo y cambia solo `[ALIMENTO]`:

```
IMAGE: Overhead (90°) view of [ALIMENTO], raw or simply prepared, on a small plain white plate, centered with generous margin. Very simple, readable at a tiny size. Square 1:1.
```

Valores de `[ALIMENTO]`, en orden:
1. `a raw chicken breast fillet`
2. `a raw beef steak`
3. `a raw white fish fillet with a lemon wedge`
4. `three brown eggs`
5. `a halved avocado`
6. `a small mound of cooked white rice`
7. `cooked black beans and lentils in two small piles`
8. `uncooked dry pasta`
9. `cubes of firm tofu`

---

## Al recibirlas

- Revisa que las 5 parezcan **la misma serie**: misma luz desde la izquierda y mismo fondo claro. Si una desentona, regenérala.
- Guárdalas en JPG o PNG y pásamelas. Yo las comprimo y las conecto en la app.
- Verifica que la herramienta te permita usarlas comercialmente.

---

## Fotos por tipo de plato (RECIPE-101)

Una foto por categoría, no por receta. La IA elige la categoría de cada comida o receta de una lista cerrada, y la app muestra esta foto como **imagen ilustrativa** en Plan (D1), Home, el detalle de receta (D3) y las recetas de "Tengo ingredientes". Son 16 fotos y no crecen con las combinaciones de ingredientes.

Formato: **horizontal 4:3, 1600 × 1200 px**. Se muestra grande (D3, ~300 px de alto, recortada a lo ancho) y como miniatura cuadrada de 62 px (recorte del centro). Por eso **el plato va centrado y con margen alrededor**: así sobrevive a los dos recortes.

Usa el **bloque de estilo** de arriba y debajo esta plantilla, cambiando solo `[PLATO]`:

```
IMAGE: 45° view of [PLATO], a single serving for one person, centered with generous empty margin on every side so it still reads when cropped to a small square. One dish only, no other plates. Horizontal 4:3.
```

Guarda cada foto con el nombre de la columna "Archivo" y pásamela; yo la optimizo y la activo.

| # | Archivo | `[PLATO]` |
|---|---|---|
| 1 | `dish_salad.jpg` | `a wide white bowl of fresh green salad with lettuce, cherry tomatoes, cucumber, avocado and a few pieces of grilled chicken` |
| 2 | `dish_bowl.jpg` | `a light grey ceramic bowl with rice, black beans, sliced avocado, pico de gallo and shredded chicken arranged in sections` |
| 3 | `dish_soup.jpg` | `a white ceramic bowl of creamy pumpkin soup with a small swirl of cream and a few cilantro leaves` |
| 4 | `dish_pasta.jpg` | `a white plate of spaghetti with homemade tomato sauce and a little grated cheese` |
| 5 | `dish_rice.jpg` | `a white plate of golden rice with chicken, peas, carrots and red pepper (arroz con pollo style)` |
| 6 | `dish_protein_plate.jpg` | `a white plate with a grilled chicken breast, a small portion of white rice and a side of steamed broccoli and carrots` |
| 7 | `dish_fish.jpg` | `a white plate with a grilled white fish fillet, a lemon wedge, a small potato salad and green beans` |
| 8 | `dish_eggs.jpg` | `a white plate with a vegetable omelette (tomato, onion, spinach) folded in half` |
| 9 | `dish_wrap_sandwich.jpg` | `a whole-wheat wrap filled with chicken, lettuce and tomato, cut in half to show the filling, on a white plate` |
| 10 | `dish_tacos_arepa.jpg` | `two corn arepas filled with shredded beef and white cheese on a white plate` |
| 11 | `dish_oats_yogurt.jpg` | `a white bowl of oatmeal topped with sliced banana, a few strawberries and a drizzle of honey` |
| 12 | `dish_smoothie.jpg` | `a tall clear glass of a pink fruit smoothie (strawberry and banana), next to a halved strawberry` |
| 13 | `dish_toast.jpg` | `two slices of whole-grain toast topped with mashed avocado and a sliced boiled egg, on a white plate` |
| 14 | `dish_snack_fruit.jpg` | `a small white bowl of mixed fresh fruit (mango, papaya, pineapple, blackberries) next to a few almonds` |
| 15 | `dish_dessert.jpg` | `a small glass cup of natural yogurt layered with mango puree and a little granola` |
| 16 | `dish_stir_fry.jpg` | `a white plate of sautéed vegetables (broccoli, red pepper, carrot, snow peas) with strips of beef, wok style` |

Para activar una foto: se copia a `assets/images/` y su categoría se suma a `_dishesWithPhoto` en `lib/features/recipes/presentation/dish_images.dart`. Las que falten siguen con el placeholder rayado.
