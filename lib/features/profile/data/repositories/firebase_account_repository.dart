import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/errors/firebase_functions_error_mapper.dart';
import '../../domain/repositories/account_repository.dart';

class FirebaseAccountRepository implements AccountRepository {
  FirebaseAccountRepository(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> deleteAccount() async {
    try {
      final callable = _functions.httpsCallable('deleteAccount');
      await callable.call<Object?>();
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    }
  }
}
