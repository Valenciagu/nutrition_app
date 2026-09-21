import 'dart:typed_data';

import '../entities/food_analysis_result.dart';

abstract class FoodAnalysisRepository {
  /// Sube los bytes de la foto a Storage y pide el análisis a
  /// `analyzeFoodPhoto`. Dos pasos de red distintos (subida + callable)
  /// detrás de un solo método — quien lo llama no necesita saber que
  /// existen dos viajes. Recibe bytes crudos, no un `XFile` de
  /// `image_picker` — el dominio no depende de paquetes de terceros
  /// específicos de una fuente de imagen (mismo criterio que el resto de
  /// `domain/` en este proyecto).
  Future<FoodAnalysisResult> analyzePhoto({required String userId, required Uint8List imageBytes});
}
