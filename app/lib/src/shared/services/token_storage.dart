import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

// ---------------------------------------------------------------------------
// GUARDADO DE LA SESION
// ---------------------------------------------------------------------------
// Guarda el token y los datos del usuario en el disco del telefono para que la
// sesion siga viva despues de cerrar la app.
//
// Ademas mantiene el token en memoria (`_cachedToken`). Asi el ApiClient no
// tiene que leer del disco en cada peticion, que era trabajo repetido y al
// pedo en pantallas que hacen varias llamadas seguidas.
// ---------------------------------------------------------------------------
class TokenStorage {
  static String? _cachedToken;

  // --- Guardar -------------------------------------------------------------

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _cachedToken = token;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.token, token);
    await prefs.setString(StorageKeys.user, jsonEncode(user));
  }

  // --- Leer ----------------------------------------------------------------

  /// Devuelve el token. La primera vez lo busca en disco; despues usa la copia
  /// en memoria.
  Future<String?> readToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(StorageKeys.token);

    return _cachedToken;
  }

  Future<Map<String, dynamic>?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.user);
    if (raw == null) return null;

    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // --- Borrar --------------------------------------------------------------

  Future<void> clear() async {
    _cachedToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.token);
    await prefs.remove(StorageKeys.user);
  }
}
