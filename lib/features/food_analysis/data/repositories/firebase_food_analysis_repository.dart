import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/firebase_functions_error_mapper.dart';
import '../../../../core/errors/firebase_storage_error_mapper.dart';
import '../../domain/entities/food_analysis_result.dart';
import '../../domain/repositories/food_analysis_repository.dart';

/// Implementación de [FoodAnalysisRepository]. `_firestore` se usa SOLO para
/// generar un id de documento del lado del cliente (`.doc().id`, sin
/// escribir nada) — el mismo id nombra el archivo en Storage y, si el
/// análisis reconoce comida, el documento que escribe `analyzeFoodPhoto` en
/// Firestore, así los tres quedan correlacionados sin un mapeo aparte.
class FirebaseFoodAnalysisRepository implements FoodAnalysisRepository {
  FirebaseFoodAnalysisRepository(this._storage, this._functions, this._firestore);

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<FoodAnalysisResult> analyzePhoto({required String userId, required Uint8List imageBytes}) async {
    final analysisId = _firestore.collection('users').doc(userId).collection('foodAnalyses').doc().id;

    try {
      final ref = _storage.ref('users/$userId/foodAnalyses/$analysisId.jpg');
      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
    } on FirebaseException catch (e) {
      throw mapFirebaseStorageException(e);
    }

    try {
      final callable = _functions.httpsCallable('analyzeFoodPhoto');
      final result = await callable.call<Object?>({'analysisId': analysisId});
      return FoodAnalysisResult.fromJson(Map<String, dynamic>.from(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: 'analyzeFoodPhoto devolvió una respuesta con forma inesperada', cause: e);
    }
  }
}
