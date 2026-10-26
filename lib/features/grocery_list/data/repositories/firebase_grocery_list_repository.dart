import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../recipes/domain/entities/recipe.dart';
import '../../domain/repositories/grocery_list_repository.dart';

/// Sin Cloud Function: a diferencia de `nutritionPlans`/`recipes`, esta
/// feature no genera contenido de IA — solo lee recetas ya generadas
/// (`firestore.rules` ya deja al cliente leerlas directo, Épica 7) y
/// persiste una preferencia propia del usuario ("qué ya tengo/compré").
/// Ambas cosas son lecturas/escrituras directas de Firestore.
class FirebaseGroceryListRepository implements GroceryListRepository {
  FirebaseGroceryListRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Recipe>> getRecipesByIds({required String userId, required List<String> recipeIds}) async {
    final docs = await Future.wait(
      recipeIds.map((id) => _firestore.collection('users').doc(userId).collection('recipes').doc(id).get()),
    );
    return docs.where((doc) => doc.exists).map((doc) => Recipe.fromJson(doc.data()!)).toList();
  }

  @override
  Future<Set<String>> getCheckedItemKeys({required String userId, required String weekKey}) async {
    final doc = await _shoppingListRef(userId, weekKey).get();
    final raw = doc.data()?['checkedItems'] as List?;
    return (raw ?? const []).map((e) => e as String).toSet();
  }

  @override
  Future<void> setItemChecked({
    required String userId,
    required String weekKey,
    required String itemKey,
    required bool checked,
  }) {
    return _shoppingListRef(userId, weekKey).set({
      'checkedItems': checked ? FieldValue.arrayUnion([itemKey]) : FieldValue.arrayRemove([itemKey]),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<String>> getExtraItems({required String userId, required String weekKey}) async {
    final doc = await _shoppingListRef(userId, weekKey).get();
    return ((doc.data()?['extraItems'] as List?) ?? const []).map((e) => e as String).toList();
  }

  /// `arrayUnion`: añadir dos veces lo mismo no lo duplica. `firestore.rules`
  /// acota `extraItems` a 100 elementos.
  @override
  Future<void> addExtraItems({required String userId, required String weekKey, required List<String> names}) {
    return _shoppingListRef(userId, weekKey).set({'extraItems': FieldValue.arrayUnion(names)}, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _shoppingListRef(String userId, String weekKey) {
    return _firestore.collection('users').doc(userId).collection('shoppingLists').doc(weekKey);
  }
}
