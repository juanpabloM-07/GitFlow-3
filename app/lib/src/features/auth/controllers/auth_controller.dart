import 'package:flutter/foundation.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../data/auth_api_services.dart';
import '../data/user_model.dart';

/// Estado de la sesion. El AuthGate del main.dart decide que pantalla mostrar
/// mirando este valor.
enum AuthStatus {
  unknown, // todavia estamos revisando si hay sesion guardada -> splash
  authenticated, // hay sesion valida -> lista de agendas
  unauthenticated, // no hay sesion -> login
}

// ---------------------------------------------------------------------------
// CONTROLLER DE AUTENTICACION
// ---------------------------------------------------------------------------
class AuthController extends ChangeNotifier {
  AuthController({AuthApiServices? services, TokenStorage? storage})
      : _services = services ?? AuthApiServices(),
        _storage = storage ?? TokenStorage();

  final AuthApiServices _services;
  final TokenStorage _storage;

  // --- Estado interno ------------------------------------------------------

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // --- Lo que leen las pantallas -------------------------------------------

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Restaurar sesion al abrir la app ------------------------------------

  /// Se ejecuta una sola vez al arrancar. Si hay un token guardado, le pregunta
  /// al backend si sigue siendo valido.
  Future<void> restoreSession() async {
    final token = await _storage.readToken();

    // Sin token no hay nada que revisar: derecho al login.
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Mostramos primero el usuario guardado en disco para que la app se sienta
    // rapida, y despues confirmamos contra el servidor.
    final guardado = await _storage.readUser();
    if (guardado != null) _user = UserModel.fromJson(guardado);

    try {
      _user = await _services.me();
      _status = AuthStatus.authenticated;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        // El token vencio o es invalido: hay que volver a loguearse.
        await _storage.clear();
        _user = null;
        _status = AuthStatus.unauthenticated;
      } else {
        // Fue un problema de red. Si teniamos datos guardados dejamos entrar
        // igual, asi la app no se vuelve inusable sin internet.
        _status =
            _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      }
    }

    notifyListeners();
  }

  // --- Login y registro ----------------------------------------------------

  Future<bool> login({required String email, required String password}) {
    return _authenticate(() => _services.login(email: email, password: password));
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authenticate(() => _services.register(
          name: name,
          email: email,
          password: password,
        ));
  }

  // --- Cerrar sesion -------------------------------------------------------

  Future<void> logout() async {
    await _storage.clear();

    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Limpia el mensaje de error al cambiar de pantalla, para que no quede
  /// colgado el error del login cuando el usuario va al registro.
  void clearError() {
    if (_errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }

  // --- Helper compartido por login y register ------------------------------

  /// Ejecuta la peticion, guarda el token y el usuario, y marca la sesion como
  /// iniciada. Devuelve true si salio bien.
  Future<bool> _authenticate(Future<AuthResult> Function() operacion) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await operacion();

      await _storage.saveSession(
        token: resultado.token,
        user: resultado.user.toJson(),
      );

      _user = resultado.user;
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
