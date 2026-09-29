import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/failure.dart';
import '../../errors/firebase_functions_error_mapper.dart';
import '../firebase_instances.dart';
import 'ai_service.dart';
import 'nutrition_assistant_answer.dart';

/// Implementación de [AIService] sobre `cloud_functions`. Única frontera del
/// cliente que conoce el nombre de la función y la forma cruda de su
/// respuesta — ver `functions/src/ai/askNutritionAssistant.ts` (el mismo
/// contrato del lado del backend).
class FirebaseAiService implements AIService {
  FirebaseAiService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<NutritionAssistantAnswer> askNutritionQuestion(String question, {List<ChatTurn> history = const []}) async {
    try {
      final callable = _functions.httpsCallable('askNutritionAssistant');
      final result = await callable.call<Object?>({
        'question': question,
        if (history.isNotEmpty)
          'history': [
            for (final turn in history) {'question': turn.question, 'answer': turn.answer},
          ],
      });
      final data = Map<String, dynamic>.from(result.data as Map);

      return NutritionAssistantAnswer(
        answer: data['answer'] as String,
        recommendsProfessionalConsult: data['recommendsProfessionalConsult'] as bool,
        safetyFallbackApplied: data['safetyFallbackApplied'] as bool,
        remainingToday: data['remainingToday'] as int,
      );
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    } on TypeError catch (e) {
      // La respuesta no tenía la forma esperada — nunca confiar en la salida
      // cruda de la función (Instrucciones.md §37-38), aunque ya venga
      // validada del lado del servidor.
      throw AiValidationFailure(message: 'askNutritionAssistant devolvió una respuesta con forma inesperada', cause: e);
    }
  }
}

final aiServiceProvider = Provider<AIService>((ref) {
  return FirebaseAiService(ref.watch(firebaseFunctionsProvider));
});
