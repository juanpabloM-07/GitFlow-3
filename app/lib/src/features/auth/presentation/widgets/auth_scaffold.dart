import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

/// Estructura compartida por login y registro: encabezado con el logo y una
/// tarjeta blanca con el formulario.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // El Align evita que el stretch de la Column estire el logo
                  // a lo ancho de toda la tarjeta.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 64,
                      width: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: child,
                  ),
                  const SizedBox(height: 18),
                  footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banda roja que muestra el error devuelto por el backend.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.delete.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.delete.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.delete, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.delete, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Validadores reutilizados por los dos formularios de auth.
class AuthValidators {
  AuthValidators._();

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    if (value.trim().length < 3) return 'Debe tener al menos 3 caracteres';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu email';
    final pattern = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!pattern.hasMatch(value.trim())) return 'Ingresa un email valido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contrasena';
    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }
}
