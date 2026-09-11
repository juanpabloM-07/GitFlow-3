import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// CONFIGURACION DE RED
// ---------------------------------------------------------------------------
// El host del backend cambia segun donde corre la app:
//
//   - Emulador de Android -> 10.0.2.2 (asi ve el emulador al localhost de la PC)
//   - Chrome / Edge / Windows -> localhost
//   - Celular fisico -> la IP de la PC en la red wifi (ej: 192.168.0.10)
//
// Por eso no se puede dejar una sola direccion fija: si la app corre en el
// escritorio apuntando a 10.0.2.2, la peticion se cuelga hasta el timeout.
// ---------------------------------------------------------------------------
class ApiConfig {
  ApiConfig._();

  static const int port = 3000;

  /// Para probar en un celular fisico, poner aca la IP de la PC.
  /// Ejemplo: static const String? manualHost = '192.168.0.10';
  static const String? manualHost = null;

  /// Host elegido automaticamente segun la plataforma.
  static String get host {
    if (manualHost != null) return manualHost!;
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';

    return 'localhost';
  }

  static String get baseUrl => 'http://$host:$port/api';

  /// Si el servidor no contesta en este tiempo, cortamos y avisamos al usuario.
  static const Duration timeout = Duration(seconds: 10);

  // Rutas del backend.
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String agendas = '/agendas';
  static const String tasks = '/tasks';
}

// ---------------------------------------------------------------------------
// CLAVES DEL ALMACENAMIENTO LOCAL
// ---------------------------------------------------------------------------
class StorageKeys {
  StorageKeys._();

  static const String token = 'auth_token';
  static const String user = 'auth_user';
}

// ---------------------------------------------------------------------------
// ESTADOS DE UNA TAREA
// ---------------------------------------------------------------------------
// Los `value` tienen que coincidir exactamente con el enum del modelo de
// Mongoose (backend/src/models/task.model.js).
// ---------------------------------------------------------------------------
enum TaskStatus {
  pending('pending', 'Pendiente', Icons.schedule_outlined),
  inProgress('in_progress', 'En progreso', Icons.autorenew_rounded),
  completed('completed', 'Completada', Icons.check_circle_outline_rounded),
  cancelled('cancelled', 'Cancelada', Icons.cancel_outlined);

  const TaskStatus(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  /// Convierte el texto que llega del backend al enum de Dart.
  /// Si llega algo desconocido, cae en `pending` para no romper la pantalla.
  static TaskStatus fromValue(String? value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

// ---------------------------------------------------------------------------
// PALETA DE COLORES PARA LAS AGENDAS
// ---------------------------------------------------------------------------
class AgendaPalette {
  AgendaPalette._();

  static const List<String> colors = [
    '#2563EB',
    '#0EA5E9',
    '#14B8A6',
    '#16A34A',
    '#F59E0B',
    '#EF4444',
    '#8B5CF6',
    '#64748B',
  ];

  /// Pasa un color guardado como '#2563EB' a un Color de Flutter.
  static Color parse(String? hex) {
    final value = (hex ?? '').replaceAll('#', '');
    if (value.length != 6) return const Color(0xFF2563EB);

    return Color(int.parse('FF$value', radix: 16));
  }
}
