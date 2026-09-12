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
