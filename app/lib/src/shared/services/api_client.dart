import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import 'token_storage.dart';

// ---------------------------------------------------------------------------
// ERROR DE API
// ---------------------------------------------------------------------------
// Un unico tipo de error para toda la app. Los servicios lanzan esto y los
// controllers solo tienen que mostrar `message` en pantalla.
// ---------------------------------------------------------------------------
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// True cuando el token vencio o es invalido: hay que volver al login.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// CLIENTE HTTP
// ---------------------------------------------------------------------------
// Centraliza todo lo repetitivo de hablar con el backend:
//   - arma la URL completa a partir de ApiConfig.baseUrl
//   - agrega el header Authorization con el token
//   - corta la espera si el servidor no responde
//   - convierte cualquier falla en un ApiException con mensaje en castellano
//
// Se usa una sola instancia compartida (`ApiClient.shared`) para reaprovechar
// la conexion TCP entre peticiones en vez de abrir una nueva cada vez.
// ---------------------------------------------------------------------------
class ApiClient {
  ApiClient({http.Client? client, TokenStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? TokenStorage();

  /// Instancia que usan todos los servicios por defecto.
  static final ApiClient shared = ApiClient();

  final http.Client _client;
  final TokenStorage _storage;

  // --- Metodos publicos ----------------------------------------------------

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send(() async {
      return _client.get(_uri(path, query), headers: await _headers());
    });
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) {
    return _send(() async {
      return _client.post(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      );
    });
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) {
    return _send(() async {
      return _client.put(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      );
    });
  }

  Future<dynamic> delete(String path) {
    return _send(() async {
      return _client.delete(_uri(path), headers: await _headers());
    });
  }

  // --- Armado de la peticion -----------------------------------------------

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return uri;

    return uri.replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.readToken();

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Envio y manejo de errores -------------------------------------------

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(ApiConfig.timeout);

      return _parse(response);
    } on ApiException {
      // Error de negocio (400, 401, 404...). Ya tiene su mensaje, lo dejamos
      // pasar tal cual en vez de taparlo con el catch generico de abajo.
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'El servidor no respondio a tiempo.\n'
        'Revisa que el backend este corriendo en ${ApiConfig.baseUrl}',
      );
    } on FormatException {
      throw ApiException('El servidor devolvio una respuesta invalida.');
    } catch (error) {
      // Cae aca cuando no hay red o el host no existe. En web el paquete http
      // lanza ClientException y en escritorio/movil SocketException, asi que
      // los tomamos juntos para no depender de dart:io (que no compila en web).
      throw ApiException(
        'No se pudo conectar con el servidor.\n'
        'Verifica que este levantado en ${ApiConfig.baseUrl}',
      );
    }
  }

  /// Si el codigo es 2xx devuelve el cuerpo ya decodificado.
  /// Si no, lanza un ApiException con el mensaje que mando el backend.
  dynamic _parse(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map<String, dynamic> && body['message'] is String
        ? body['message'] as String
        : 'Ocurrio un error (${response.statusCode})';

    throw ApiException(message, statusCode: response.statusCode);
  }
}
