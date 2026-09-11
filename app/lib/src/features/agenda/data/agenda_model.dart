class AgendaModel {
  const AgendaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    this.taskCount = 0,
    this.completedCount = 0,
  });

  final String id;
  final String title;
  final String description;
  final String color;
  final int taskCount;
  final int completedCount;

  factory AgendaModel.fromJson(Map<String, dynamic> json) {
    return AgendaModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      color: (json['color'] ?? '#2563EB') as String,
      taskCount: (json['taskCount'] ?? 0) as int,
      completedCount: (json['completedCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'color': color,
      };

  double get progress => taskCount == 0 ? 0 : completedCount / taskCount;

  AgendaModel copyWith({
    String? title,
    String? description,
    String? color,
    int? taskCount,
    int? completedCount,
  }) {
    return AgendaModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      taskCount: taskCount ?? this.taskCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }
}
