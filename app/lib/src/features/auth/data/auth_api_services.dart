import '../../../config/constants.dart';
import '../../../shared/services/api_client.dart';
import 'user_model.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserModel user;
}

class AuthApiServices {
  AuthApiServices({ApiClient? client}) : _client = client ?? ApiClient.shared;

  final ApiClient _client;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _client.post(ApiConfig.register, {
      'name': name,
      'email': email,
      'password': password,
    });

    return _toResult(data);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(ApiConfig.login, {
      'email': email,
      'password': password,
    });

    return _toResult(data);
  }

  /// Valida contra el backend que el token guardado siga siendo valido.
  Future<UserModel> me() async {
    final data = await _client.get(ApiConfig.me);

    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  AuthResult _toResult(dynamic data) {
    return AuthResult(
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
