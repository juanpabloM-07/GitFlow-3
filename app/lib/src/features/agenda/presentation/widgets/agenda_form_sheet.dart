import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../controllers/agenda_controller.dart';
import '../../data/agenda_model.dart';

/// Abre el formulario de agenda. Sin `agenda` crea una nueva; con `agenda`
/// edita la existente. Devuelve true si se guardo.
Future<bool> showAgendaFormSheet(BuildContext context, {AgendaModel? agenda}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AgendaFormSheet(agenda: agenda),
  );

  return result ?? false;
}

class AgendaFormSheet extends StatefulWidget {
  const AgendaFormSheet({super.key, this.agenda});

  final AgendaModel? agenda;

  @override
  State<AgendaFormSheet> createState() => _AgendaFormSheetState();
}

class _AgendaFormSheetState extends State<AgendaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _color;

  bool get _isEditing => widget.agenda != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.agenda?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.agenda?.description ?? '');
    _color = widget.agenda?.color ?? AgendaPalette.colors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AgendaController>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final ok = _isEditing
        ? await controller.update(widget.agenda!.copyWith(
            title: title,
            description: description,
            color: _color,
          ))
        : await controller.create(
            title: title,
            description: description,
            color: _color,
          );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(
        context,
        controller.errorMessage ?? 'No se pudo guardar la agenda',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<AgendaController>().isSaving;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Editar agenda' : 'Nueva agenda',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Agrupa tus tareas por proyecto, materia o area.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _titleController,
                label: 'Titulo',
                hint: 'Ej: Trabajo, Facultad, Casa',
                icon: Icons.title_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El titulo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descriptionController,
                label: 'Descripcion',
                hint: 'Opcional',
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final hex in AgendaPalette.colors)
                    _ColorDot(
                      hex: hex,
                      isSelected: hex == _color,
                      onTap: () => setState(() => _color = hex),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              AppButton(
                label: _isEditing ? 'Guardar cambios' : 'Crear agenda',
                icon: _isEditing ? Icons.save_outlined : Icons.add_rounded,
                color: _isEditing ? AppColors.update : AppColors.create,
                isLoading: isSaving,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AgendaPalette.parse(hex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 4,
        width: 42,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
