import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single [Dio] instance for all outbound HTTP calls to our own secure
/// backend (Cloud Functions HTTPS endpoints, etc). Do not instantiate `Dio()`
/// anywhere else — add a data source that consumes this provider instead.
///
/// This client talks only to *our* backend, never directly to OpenAI or any
/// other third-party API (see `nutrition-app-security` skill) — the base URL
/// is provided at build time via `--dart-define=API_BASE_URL=...`, never
/// hardcoded, so it can differ per environment (dev/staging/prod).
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // The Firebase Auth ID token is attached here once
        // `features/authentication` exists (Epic 2) — never send raw
        // credentials or long-lived secrets from the client.
        handler.next(options);
      },
      onError: (DioException error, handler) {
        if (kDebugMode) {
          // Never log headers/body here — they may carry auth tokens or PII.
          debugPrint(
            '[dio] ${error.requestOptions.method} '
            '${error.requestOptions.path} -> ${error.response?.statusCode}',
          );
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
