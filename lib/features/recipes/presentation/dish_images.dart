import '../../../core/constants/app_assets.dart';
import '../domain/entities/dish_category.dart';

/// Categorías que YA tienen su foto en `assets/images/dish_<id>.jpg`
/// (RECIPE-101). Las fotos las genera el usuario con los prompts de
/// `documentation/image_generation_prompts.md`; al agregar una, sumar su
/// categoría aquí. Mientras falte, esa categoría muestra el placeholder.
const Set<DishCategory> _dishesWithPhoto = {};

/// Foto ilustrativa del tipo de plato, o `null` (placeholder rayado) si la
/// categoría no se conoce o aún no tiene foto.
String? dishImageAsset(DishCategory? category) {
  if (category == null || !_dishesWithPhoto.contains(category)) return null;
  return AppAssets.dish(category.id);
}
