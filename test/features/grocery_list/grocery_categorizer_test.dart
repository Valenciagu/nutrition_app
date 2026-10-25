import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/grocery_list/domain/entities/grocery_item.dart';
import 'package:nutrition_app/features/grocery_list/domain/grocery_categorizer.dart';

void main() {
  test('clasifica ingredientes comunes', () {
    expect(categorizeIngredient('Pechuga de pollo'), GroceryCategory.protein);
    expect(categorizeIngredient('Arroz integral'), GroceryCategory.carbs);
    expect(categorizeIngredient('Manzana verde'), GroceryCategory.fruit);
    expect(categorizeIngredient('Brócoli'), GroceryCategory.vegetable);
    expect(categorizeIngredient('Yogur griego'), GroceryCategory.dairy);
    expect(categorizeIngredient('Aceite de oliva'), GroceryCategory.other);
  });

  test('cubre plurales', () {
    expect(categorizeIngredient('2 huevos'), GroceryCategory.protein);
    expect(categorizeIngredient('Lentejas'), GroceryCategory.protein);
  });

  test('"res" no atrapa palabras que solo la contienen (regresión)', () {
    expect(categorizeIngredient('Fresas'), GroceryCategory.fruit);
    expect(categorizeIngredient('Queso fresco'), GroceryCategory.dairy);
    expect(categorizeIngredient('Carne de res'), GroceryCategory.protein);
  });
}
