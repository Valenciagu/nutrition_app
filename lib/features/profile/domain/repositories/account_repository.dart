abstract class AccountRepository {
  /// Elimina la cuenta del usuario autenticado y todos sus datos
  /// (Instrucciones.md §33-34). Sin parámetros a propósito: el objetivo es
  /// siempre el usuario que llama, nunca un uid que decida el cliente.
  Future<void> deleteAccount();
}
