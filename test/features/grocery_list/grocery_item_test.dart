import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/grocery_list/domain/entities/grocery_item.dart';

GroceryItem _item({List<GroceryItemSource> sources = const [], List<String> manualNames = const []}) {
  return GroceryItem(
    key: 'arroz',
    name: 'Arroz',
    category: GroceryCategory.carbs,
    sources: sources,
    checked: false,
    manualNames: manualNames,
  );
}

void main() {
  final planSource = GroceryItemSource(quantity: '200 g', slotLabelKey: 'lunch', date: DateTime(2026, 10, 26));

  test('a manually added item with no recipe source can be removed', () {
    expect(_item(manualNames: ['Arroz', 'arroz']).isRemovable, isTrue);
  });

  test('an item a plan recipe needs cannot be removed, even if also added by hand', () {
    expect(_item(sources: [planSource], manualNames: ['Arroz']).isRemovable, isFalse);
  });

  test('a recipe-only item cannot be removed', () {
    expect(_item(sources: [planSource]).isRemovable, isFalse);
  });

  test('copyWith keeps manualNames', () {
    expect(_item(manualNames: ['Arroz']).copyWith(checked: true).manualNames, ['Arroz']);
  });
}
