/// Un ingrediente dentro de una [Recipe]. La cantidad se guarda como texto
/// libre (`"200 g"`, `"2 unidades"`) en vez de `amount`/`unit` separados —
/// evita construir un sistema de conversión de unidades que ninguna
/// pantalla necesita todavía; revisar si la Épica 10 (lista de compra)
/// termina necesitando agregar cantidades entre recetas.
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.quantity,
    this.substitutes = const [],
  });

  final String name;
  final String quantity;

  /// Sustituciones posibles (Instrucciones.md §8) — p. ej. "yogur griego"
  /// para "yogur natural". Lista vacía si la IA no propuso ninguna.
  final List<String> substitutes;

  RecipeIngredient copyWith({
    String? name,
    String? quantity,
    List<String>? substitutes,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      substitutes: substitutes ?? this.substitutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'substitutes': substitutes,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      substitutes: (json['substitutes'] as List? ?? const []).map((s) => s as String).toList(),
    );
  }
}
