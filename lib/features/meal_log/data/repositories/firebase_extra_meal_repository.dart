import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/firebase_functions_error_mapper.dart';
import '../../domain/entities/extra_meal.dart';
import '../../domain/repositories/extra_meal_repository.dart';

/// Lee `users/{uid}/extraMeals` directo (las reglas lo permiten solo al
/// dueño) y escribe únicamente vía `logExtraMeal`/`editExtraMeal` — mismo
/// reparto que `FirebasePlanRepository` con `nutritionPlans`/`registerMeal`.
class FirebaseExtraMealRepository implements ExtraMealRepository {
  FirebaseExtraMealRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<List<ExtraMeal>> getForDate({required String userId, required String date}) async {
    try {
      // Solo igualdad sobre `date`: sin `orderBy` no hace falta índice
      // compuesto; se ordena aquí (un día tiene pocas entradas).
      final snapshot =
          await _firestore.collection('users').doc(userId).collection('extraMeals').where('date', isEqualTo: date).get();
      final meals = snapshot.docs.map((doc) => ExtraMeal.fromJson(doc.data())).toList();
      meals.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      return meals;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: 'Una comida extra guardada tiene una forma inesperada', cause: e);
    }
  }

  /// Rango sobre un solo campo (`date`): lo cubre el índice automático, sin
  /// índice compuesto. El tope evita leer de más en el peor caso (30 por día).
  @override
  Future<Set<String>> getDatesWithMeals({required String userId, required String fromDate, required String toDate}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('extraMeals')
          .where('date', isGreaterThanOrEqualTo: fromDate)
          .where('date', isLessThanOrEqualTo: toDate)
          .limit(500)
          .get();
      return {for (final doc in snapshot.docs) doc.data()['date'] as String};
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<ExtraMeal> logManual({
    required String date,
    required String name,
    required int calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
  }) async {
    final data = await _call('logExtraMeal', {
      'date': date,
      'source': 'manual',
      'name': name,
      'calories': calories,
      'proteinGrams': ?proteinGrams,
      'carbsGrams': ?carbsGrams,
      'fatGrams': ?fatGrams,
    });
    return ExtraMeal.fromJson(data);
  }

  @override
  Future<ExtraMeal> logFromPhotoAnalysis({required String date, required String analysisId}) async {
    final data = await _call('logExtraMeal', {'date': date, 'source': 'photo', 'analysisId': analysisId});
    return ExtraMeal.fromJson(data);
  }

  @override
  Future<void> setPortion({required String mealId, required double portion}) {
    return _call('editExtraMeal', {'mealId': mealId, 'portion': portion});
  }

  @override
  Future<void> delete({required String mealId}) {
    return _call('editExtraMeal', {'mealId': mealId, 'delete': true});
  }

  Failure _mapFirestoreException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => PermissionFailure(message: e.message, cause: e),
      'unavailable' || 'deadline-exceeded' => NetworkFailure(message: e.message, cause: e),
      _ => ServerFailure(message: e.message, cause: e),
    };
  }

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> params) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(params);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: '$name devolvió una respuesta con forma inesperada', cause: e);
    }
  }
}
