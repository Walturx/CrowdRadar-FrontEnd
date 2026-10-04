/// Why a session ended.
enum MotivoCierre {
  /// The user chose to sign out (the device is unregistered first).
  usuario,

  /// The server rejected the token (401) outside `/api/auth/`.
  sesionExpirada,

  /// The server answered `CUENTA_SUSPENDIDA`.
  cuentaSuspendida,

  /// The user changed the password: the old token is stale on the server.
  passwordCambiada,
}
