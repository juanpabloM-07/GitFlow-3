import '../../../config/constants.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.agendaId,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.status,
  });

  final String id;
  final String agendaId;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final TaskStatus status;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      agendaId: (json['agenda'] ?? '').toString(),
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      date: DateTime.tryParse((json['date'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      time: (json['time'] ?? '00:00') as String,
      status: TaskStatus.fromValue(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'agenda': agendaId,
        'title': title,
        'description': description,
        // El backend espera una fecha ISO; mandamos solo el dia, sin hora.
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'time': time,
        'status': status.value,
      };

  bool get isOverdue {
    if (status == TaskStatus.completed || status == TaskStatus.cancelled) {
      return false;
    }

    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final due = DateTime(date.year, date.month, date.day, hour, minute);

    return due.isBefore(DateTime.now());
  }

  TaskModel copyWith({
    String? agendaId,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    TaskStatus? status,
  }) {
    return TaskModel(
      id: id,
      agendaId: agendaId ?? this.agendaId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
