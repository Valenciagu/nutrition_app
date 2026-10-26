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
