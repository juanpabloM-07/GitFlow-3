import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthController>().register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    // Esta pantalla se abrio con push por encima del login, asi que hay que
    // sacarla del stack. Si no, el AuthGate cambia a la lista de agendas pero
    // el formulario de registro queda tapandola.
    if (ok && mounted) Navigator.of(context).pop();
  }

  void _goBack() {
    context.read<AuthController>().clearError();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return AuthScaffold(
      title: 'Crear cuenta',
      subtitle: 'Organiza tus agendas y tareas en un solo lugar.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ya tenes cuenta?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: auth.isLoading ? null : _goBack,
            child: const Text(
              'Iniciar sesion',
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
              controller: _nameController,
              label: 'Nombre',
              hint: 'Como te llamas',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.name,
            ),
            const SizedBox(height: 16),
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
              hint: 'Minimo 6 caracteres',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmController,
              label: 'Repetir contrasena',
              hint: 'Volve a escribirla',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contrasenas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Crear cuenta',
              icon: Icons.person_add_alt_rounded,
              color: AppColors.create,
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
