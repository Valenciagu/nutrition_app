import 'package:flutter/material.dart';

/// Pantalla que se muestra en vez de la app real cuando
/// `Firebase.initializeApp()` falla (típicamente: no se ha corrido
/// `flutterfire configure` todavía, ver TASKS.md > FOUND-009). Es un
/// mensaje para desarrolladores, no para usuarios finales — nunca debería
/// verse en producción una vez Firebase esté configurado, así que no pasa
/// por el sistema de localización ni el design system del producto.
class FirebaseSetupRequiredPage extends StatelessWidget {
  const FirebaseSetupRequiredPage({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF101512),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Firebase no está configurado',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esta app necesita un proyecto de Firebase conectado (FOUND-009 en TASKS.md). '
                    'Corre `flutterfire configure` desde una terminal interactiva y vuelve a compilar.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Detalle: $error',
                    style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
