import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/version_compare.dart';
import '../firebase_instances.dart';

/// Claves de Remote Config de la versión mínima obligatoria (Épica 17).
/// Se configuran en Firebase Console → Remote Config; sin publicar nada, los
/// valores por defecto de aquí hacen que el bloqueo nunca se active.
abstract final class AppUpdateConfigKeys {
  static const String minAppVersion = 'min_app_version';
  static const String storeUrlAndroid = 'update_store_url_android';
  static const String storeUrlIos = 'update_store_url_ios';
}

class AppUpdateStatus {
  const AppUpdateStatus({required this.isUpdateRequired, this.storeUrl});

  static const notRequired = AppUpdateStatus(isUpdateRequired: false);

  final bool isUpdateRequired;

  /// `null` si no hay enlace configurado para esta plataforma — la pantalla
  /// de bloqueo entonces solo explica, sin botón.
  final String? storeUrl;
}

/// ¿La versión instalada es menor que `min_app_version`? Lo lee el
/// `redirect` del router para bloquear la app entera.
///
/// **Falla abierto** a propósito: si Remote Config no responde (sin red,
/// primer arranque offline), se usan los últimos valores activados o los
/// por defecto — nunca se bloquea a alguien por no poder consultar. El
/// límite real contra clientes viejos sigue siendo el backend; esto es la
/// capa de UX que les pide actualizar. En web no aplica (siempre se sirve la
/// última versión, no hay tienda).
final appUpdateStatusProvider = FutureProvider<AppUpdateStatus>((ref) async {
  if (kIsWeb) return AppUpdateStatus.notRequired;

  final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
  try {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(fetchTimeout: const Duration(seconds: 10), minimumFetchInterval: const Duration(hours: 1)),
    );
    await remoteConfig.setDefaults(const {
      AppUpdateConfigKeys.minAppVersion: '0.0.0',
      AppUpdateConfigKeys.storeUrlAndroid: '',
      AppUpdateConfigKeys.storeUrlIos: '',
    });
    await remoteConfig.fetchAndActivate();
  } catch (error) {
    debugPrint('Remote Config fetch failed, using cached/default values: $error');
  }

  final installed = (await PackageInfo.fromPlatform()).version;
  final minimum = remoteConfig.getString(AppUpdateConfigKeys.minAppVersion);
  if (compareVersions(installed, minimum) >= 0) return AppUpdateStatus.notRequired;

  final storeUrl = remoteConfig.getString(
    defaultTargetPlatform == TargetPlatform.iOS ? AppUpdateConfigKeys.storeUrlIos : AppUpdateConfigKeys.storeUrlAndroid,
  );
  return AppUpdateStatus(isUpdateRequired: true, storeUrl: storeUrl.isEmpty ? null : storeUrl);
});
