import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/core/errors/failure.dart';
import 'package:nutrition_app/core/errors/firebase_functions_error_mapper.dart';

FirebaseFunctionsException _exception(String code) => FirebaseFunctionsException(message: 'm', code: code);

void main() {
  test('mapea cada código de HttpsError a su Failure', () {
    expect(mapFirebaseFunctionsException(_exception('unauthenticated')), isA<AuthFailure>());
    expect(mapFirebaseFunctionsException(_exception('invalid-argument')), isA<ValidationFailure>());
    expect(mapFirebaseFunctionsException(_exception('failed-precondition')), isA<ValidationFailure>());
    expect(mapFirebaseFunctionsException(_exception('resource-exhausted')), isA<AiQuotaExceededFailure>());
    expect(mapFirebaseFunctionsException(_exception('unavailable')), isA<NetworkFailure>());
    expect(mapFirebaseFunctionsException(_exception('deadline-exceeded')), isA<NetworkFailure>());
  });

  test('cualquier otro código cae en ServerFailure', () {
    expect(mapFirebaseFunctionsException(_exception('internal')), isA<ServerFailure>());
    expect(mapFirebaseFunctionsException(_exception('not-found')), isA<ServerFailure>());
  });
}
