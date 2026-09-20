import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Instancias crudas de los SDKs de Firebase, para que cada feature
/// construya su propio repositorio sobre ellas en vez de acceder a
/// `FirebaseAuth.instance`/etc. directamente en varios sitios.
///
/// Requiere que `Firebase.initializeApp()` ya se haya ejecutado en
/// `main.dart` (pendiente de FOUND-009 — ver PROJECT_CONTEXT.md); leer
/// estos providers antes de eso lanza `[core/no-app]`.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// `FirebaseFunctions.instance` ya apunta a la región por defecto
/// (`us-central1`), la misma que declara `askNutritionAssistant` en
/// `functions/src/ai/askNutritionAssistant.ts` — si una función futura usa
/// otra región, pedir esa instancia con `FirebaseFunctions.instanceFor`
/// en vez de cambiar este provider global.
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);
