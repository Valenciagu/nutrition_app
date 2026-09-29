enum ChatMessageRole { user, assistant }

/// Un mensaje del chat de IA (G1). Vive solo en memoria — sin historial
/// persistido en v1 (ninguna colección de Firestore lo guarda, se pierde al
/// cerrar la app), ver `documentation/ai_assistant.md`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isPending = false,
    this.isError = false,
    this.isQuotaExceeded = false,
    this.recommendsProfessionalConsult = false,
    this.safetyFallbackApplied = false,
  });

  final String id;
  final ChatMessageRole role;

  /// La respuesta real del asistente cuando todo salió bien. Vacío/no usado
  /// mientras [isPending] o [isError] — la UI resuelve qué mostrar en esos
  /// casos vía la localización (nunca texto de error hardcodeado aquí, ver
  /// `nutrition-app-architecture`).
  final String text;

  /// true mientras se espera la respuesta del asistente a este mensaje del
  /// usuario — la UI pinta el indicador de "escribiendo" en su lugar.
  final bool isPending;

  /// true si la llamada falló (cuota agotada, red, validación, etc.).
  final bool isError;

  /// Distingue el caso específico de cupo diario agotado dentro de
  /// [isError] — la UI le muestra un mensaje distinto (Instrucciones.md
  /// §28: el cliente puede comunicar el cupo, nunca controlarlo).
  final bool isQuotaExceeded;

  final bool recommendsProfessionalConsult;
  final bool safetyFallbackApplied;

  ChatMessage copyWith({
    String? text,
    bool? isPending,
    bool? isError,
    bool? isQuotaExceeded,
    bool? recommendsProfessionalConsult,
    bool? safetyFallbackApplied,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      isPending: isPending ?? this.isPending,
      isError: isError ?? this.isError,
      isQuotaExceeded: isQuotaExceeded ?? this.isQuotaExceeded,
      recommendsProfessionalConsult: recommendsProfessionalConsult ?? this.recommendsProfessionalConsult,
      safetyFallbackApplied: safetyFallbackApplied ?? this.safetyFallbackApplied,
    );
  }
}
