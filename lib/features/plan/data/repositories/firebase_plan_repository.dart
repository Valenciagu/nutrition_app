import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/firebase_functions_error_mapper.dart';
import '../../domain/entities/meal_alternative.dart';
import '../../domain/entities/nutrition_plan.dart';
import '../../domain/repositories/plan_repository.dart';

/// Implementación de [PlanRepository]. Única frontera del cliente que
/// conoce la colección `nutritionPlans` y los nombres de las Cloud
/// Functions de `functions/src/plan/` — mismo criterio de
/// `FirebaseAiService` (Épica 5): un repositorio concreto, sin una capa de
/// "data source" aparte, porque las operaciones son simples.
class FirebasePlanRepository implements PlanRepository {
  FirebasePlanRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<NutritionPlan?> getPlan({required String userId, required String date}) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('nutritionPlans').doc(date).get();
      if (!doc.exists) return null;
      return NutritionPlan.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: 'El plan guardado tiene una forma inesperada', cause: e);
    }
  }

  @override
  Future<Map<String, NutritionPlan?>> getPlansForDates({required String userId, required List<String> dates}) async {
    final results = await Future.wait(dates.map((date) => getPlan(userId: userId, date: date)));
    return {for (var i = 0; i < dates.length; i++) dates[i]: results[i]};
  }

  @override
  Future<List<NutritionPlan>> getRecentPlans({required String userId, required String untilDate, required int limit}) async {
    try {
      // El id del documento ES la fecha YYYY-MM-DD, que ordena igual
      // lexicográfica que cronológicamente — no hace falta índice compuesto.
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutritionPlans')
          .where(FieldPath.documentId, isLessThanOrEqualTo: untilDate)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => NutritionPlan.fromJson(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: 'El plan guardado tiene una forma inesperada', cause: e);
    }
  }

  @override
  Future<NutritionPlan> generatePlan({required String userId, required String date}) async {
    // `remainingToday` viaja en la respuesta pero todavía no se muestra en
    // ningún lado del cliente — no hay una UI que lo necesite todavía, se
    // deja caer a propósito (ver `documentation/ai_backend.md`).
    final data = await _callAndParse('generateDailyPlan', {'date': date});
    return NutritionPlan.fromJson(data);
  }

  @override
  Future<NutritionPlan> adjustPlan({required String userId, required String date, required String message}) async {
    final data = await _callAndParse('adjustDailyPlan', {'date': date, 'message': message});
    return NutritionPlan.fromJson(data);
  }

  @override
  Future<void> setMealRegistered({
    required String userId,
    required String date,
    required String mealId,
    bool registered = true,
  }) {
    return _callAndParse('registerMeal', {'date': date, 'mealId': mealId, 'registered': registered});
  }

  @override
  Future<List<MealAlternative>> suggestMealAlternatives({
    required String userId,
    required String date,
    required String mealId,
    String? filterHint,
  }) async {
    final data = await _callAndParse('suggestMealAlternatives', {
      'date': date,
      'mealId': mealId,
      'filterHint': ?filterHint,
    });
    final rawAlternatives = data['alternatives'] as List;
    return rawAlternatives.map((raw) => MealAlternative.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
  }

  @override
  Future<void> replaceMeal({
    required String userId,
    required String date,
    required String mealId,
    required int candidateIndex,
  }) {
    return _callAndParse('replaceMeal', {'date': date, 'mealId': mealId, 'candidateIndex': candidateIndex});
  }

  /// Llama una función `onCall` y devuelve su respuesta ya decodificada a
  /// `Map<String, dynamic>` — centraliza el manejo de errores compartido
  /// por las 5 funciones de `functions/src/plan/`.
  Future<Map<String, dynamic>> _callAndParse(String name, Map<String, dynamic> params) async {
    try {
      final callable = _functions.httpsCallable(name);
      final result = await callable.call<Object?>(params);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: '$name devolvió una respuesta con forma inesperada', cause: e);
    }
  }

  Failure _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return PermissionFailure(message: e.message, cause: e);
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkFailure(message: e.message, cause: e);
      default:
        return ServerFailure(message: e.message, cause: e);
    }
  }
}
