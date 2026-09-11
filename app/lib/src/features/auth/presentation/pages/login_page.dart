import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    // El AuthGate del main se encarga de navegar cuando el estado cambia.
    await context.read<AuthController>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _goToRegister() {
    context.read<AuthController>().clearError();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return AuthScaffold(
      title: 'Hola de nuevo',
      subtitle: 'Inicia sesion para ver tus agendas y tareas.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No tenes cuenta?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: auth.isLoading ? null : _goToRegister,
            child: const Text(
              'Crear una',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.errorMessage != null)
              AuthErrorBanner(message: auth.errorMessage!),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'nombre@correo.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'Contrasena',
              hint: 'Tu contrasena',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              validator: AuthValidators.password,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Entrar',
              icon: Icons.login_rounded,
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
