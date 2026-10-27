import '../entities/extra_meal.dart';

abstract class ExtraMealRepository {
  /// Comidas extra de un día (YYYY-MM-DD), en el orden en que se registraron.
  Future<List<ExtraMeal>> getForDate({required String userId, required String date});

  /// Días (YYYY-MM-DD) entre [fromDate] y [toDate], inclusive, con al menos
  /// una comida extra — para la racha de Home.
  Future<Set<String>> getDatesWithMeals({required String userId, required String fromDate, required String toDate});

  /// "Registrar sin foto" (LOG-105): nombre y macros escritos por el usuario.
  Future<ExtraMeal> logManual({
    required String date,
    required String name,
    required int calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
  });

  /// "Registrar comida" sobre un análisis de foto ya hecho (LOG-102) — las
  /// cifras las toma el servidor del análisis guardado, no el cliente.
  Future<ExtraMeal> logFromPhotoAnalysis({required String date, required String analysisId});

  Future<void> setPortion({required String mealId, required double portion});

  Future<void> delete({required String mealId});
}
