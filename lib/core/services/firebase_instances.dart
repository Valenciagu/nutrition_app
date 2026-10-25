import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) => FirebaseAnalytics.instance);

final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) => FirebaseRemoteConfig.instance);

/// No es un SDK de Firebase en sí, pero se instancia una sola vez aquí por
/// la misma razón que todo lo demás en este archivo: es el único punto que
/// crea un `GoogleSignIn()`, para que `FirebaseAuthDataSource` no tenga que
/// preocuparse de mantener viva una única instancia (necesario para que
/// `signOut()` de verdad cierre la sesión de la MISMA cuenta que inició
/// sesión, no una instancia nueva).
///
/// En Web, a diferencia de Android/iOS, el plugin no puede leer el client
/// ID de ningún archivo nativo — hay que pasarlo explícito o el paquete
/// lanza un `AssertionError` apenas se construye (crashea la app entera al
/// arrancar, porque este provider se lee temprano vía `authRepositoryProvider`
/// para el router). Este ID de cliente OAuth "Web" es público por diseño
/// (Google lo expone en JS del lado del cliente) — no es un secreto, mismo
/// valor que aparece en `android/app/google-services.json` bajo
/// `oauth_client` → `client_type: 3`.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    clientId: kIsWeb ? '231974163983-5flbf4hkt2gujmb73v4f3gada9klrjr8.apps.googleusercontent.com' : null,
  );
});
