import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../controllers/agenda_controller.dart';
import '../../controllers/task_controller.dart';
import '../../data/agenda_model.dart';
import '../../data/task_model.dart';
import '../widgets/agenda_form_sheet.dart';
import '../widgets/status_chip.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_tile.dart';

/// Detalle de una agenda con el CRUD completo de sus tareas.
class AgendaDetailPage extends StatefulWidget {
  const AgendaDetailPage({super.key, required this.agenda});

  final AgendaModel agenda;

  @override
  State<AgendaDetailPage> createState() => _AgendaDetailPageState();
}

class _AgendaDetailPageState extends State<AgendaDetailPage> {
  late AgendaModel _agenda;

  @override
  void initState() {
    super.initState();
    _agenda = widget.agenda;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tasks = context.read<TaskController>();
      tasks.reset();
      await tasks.load(_agenda.id);
      _syncCounts();
    });
  }

  /// Devuelve a la lista de agendas los contadores actualizados para que la
  /// tarjeta muestre el progreso correcto al volver.
  void _syncCounts() {
    if (!mounted) return;

    final tasks = context.read<TaskController>();
    context.read<AgendaController>().syncCounts(
          agendaId: _agenda.id,
          taskCount: tasks.total,
          completedCount: tasks.completed,
        );
  }

  Future<void> _createTask() async {
    final created = await showTaskFormSheet(context, agendaId: _agenda.id);
    if (!created || !mounted) return;

    _syncCounts();
    showAppSnackBar(context, 'Tarea creada');
  }

  Future<void> _editTask(TaskModel task) async {
    final updated = await showTaskFormSheet(
      context,
      agendaId: _agenda.id,
      task: task,
    );
    if (!updated || !mounted) return;

    _syncCounts();
    showAppSnackBar(context, 'Tarea actualizada');
  }

  Future<void> _toggleTask(TaskModel task) async {
    final controller = context.read<TaskController>();
    final ok = await controller.toggleCompleted(task);

    if (!mounted) return;

    if (ok) {
      _syncCounts();
    } else {
      showAppSnackBar(
        context,
        controller.errorMessage ?? 'No se pudo actualizar la tarea',
        isError: true,
      );
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar tarea',
      message: 'Se eliminara "${task.title}". Esta accion no se puede deshacer.',
    );

    if (!confirmed || !mounted) return;

    final controller = context.read<TaskController>();
    final ok = await controller.delete(task.id);

    if (!mounted) return;

    if (ok) _syncCounts();

    showAppSnackBar(
      context,
      ok ? 'Tarea eliminada' : controller.errorMessage ?? 'No se pudo eliminar',
      isError: !ok,
    );
  }

  Future<void> _editAgenda() async {
    final updated = await showAgendaFormSheet(context, agenda: _agenda);
    if (!updated || !mounted) return;

    final refreshed = context.read<AgendaController>().findById(_agenda.id);
    if (refreshed != null) setState(() => _agenda = refreshed);

    showAppSnackBar(context, 'Agenda actualizada');
  }

  Future<void> _deleteAgenda() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar agenda',
      message:
          'Se eliminara "${_agenda.title}" y todas sus tareas. Esta accion no se puede deshacer.',
    );

    if (!confirmed || !mounted) return;

    final controller = context.read<AgendaController>();
    final ok = await controller.delete(_agenda.id);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      return;
    }

    showAppSnackBar(
      context,
      controller.errorMessage ?? 'No se pudo eliminar',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final color = AgendaPalette.parse(_agenda.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_agenda.title),
        actions: [
          IconButton(
            tooltip: 'Editar agenda',
            onPressed: _editAgenda,
            icon: const Icon(Icons.edit_outlined, color: AppColors.update),
          ),
          IconButton(
            tooltip: 'Eliminar agenda',
            onPressed: _deleteAgenda,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.delete),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva tarea'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.load(_agenda.id);
          _syncCounts();
        },
        child: Column(
          children: [
            _AgendaHeader(
              agenda: _agenda,
              color: color,
              total: controller.total,
              completed: controller.completed,
            ),
            StatusFilterBar(
              selected: controller.filter,
              onChanged: controller.setFilter,
              totalCount: controller.total,
              countFor: controller.countByStatus,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TaskController controller) {
    if (controller.isLoading && controller.tasks.isEmpty) {
      return const LoadingView();
    }

    if (controller.errorMessage != null && controller.tasks.isEmpty) {
      return ErrorView(
        message: controller.errorMessage!,
        onRetry: () => controller.load(_agenda.id),
      );
    }

    if (controller.tasks.isEmpty) {
      final isFiltered = controller.filter != null;

      return EmptyView(
        icon: isFiltered ? Icons.filter_alt_off_rounded : Icons.checklist_rounded,
        title: isFiltered ? 'Sin tareas en este estado' : 'Agenda vacia',
        message: isFiltered
            ? 'Proba con otro filtro o crea una tarea nueva.'
            : 'Agrega la primera tarea de esta agenda.',
        actionLabel: isFiltered ? null : 'Crear tarea',
        onAction: isFiltered ? null : _createTask,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: controller.tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = controller.tasks[index];

        return TaskTile(
          task: task,
          onToggle: () => _toggleTask(task),
          onEdit: () => _editTask(task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }
}

/// Encabezado con la descripcion de la agenda y su progreso.
class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({
    required this.agenda,
    required this.color,
    required this.total,
    required this.completed,
  });

  final AgendaModel agenda;
  final Color color;
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  agenda.description.isEmpty
                      ? 'Sin descripcion'
                      : agenda.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$completed de $total',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
