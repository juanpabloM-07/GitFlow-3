import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../data/task_model.dart';
import 'status_chip.dart';

/// Fila de la lista de tareas: check para completar, datos y acciones CRUD.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    final statusColor = AppColors.statusColor(task.status);
    final dateLabel = DateFormat("d 'de' MMMM", 'es').format(task.date);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Atajo para marcar la tarea como completada sin abrir el form.
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
                onPressed: onToggle,
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isCompleted ? AppColors.create : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(status: task.status, compact: true),
                        _MetaLabel(
                          icon: Icons.calendar_today_rounded,
                          text: dateLabel,
                          color: task.isOverdue
                              ? AppColors.delete
                              : AppColors.textMuted,
                        ),
                        _MetaLabel(
                          icon: Icons.access_time_rounded,
                          text: task.time,
                          color: task.isOverdue
                              ? AppColors.delete
                              : AppColors.textMuted,
                        ),
                        if (task.isOverdue)
                          const _MetaLabel(
                            icon: Icons.warning_amber_rounded,
                            text: 'Vencida',
                            color: AppColors.delete,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: onEdit,
                    iconSize: 19,
                    constraints:
                        const BoxConstraints(minHeight: 34, minWidth: 34),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.update),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: onDelete,
                    iconSize: 19,
                    constraints:
                        const BoxConstraints(minHeight: 34, minWidth: 34),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.delete),
                  ),
                ],
              ),
              Container(width: 3, height: 56, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
