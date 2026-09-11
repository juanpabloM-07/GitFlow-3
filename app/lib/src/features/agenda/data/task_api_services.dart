import '../../../config/constants.dart';
import '../../../shared/services/api_client.dart';
import 'task_model.dart';

class TaskApiServices {
  TaskApiServices({ApiClient? client}) : _client = client ?? ApiClient.shared;

  final ApiClient _client;

  /// Sin `agendaId` trae todas las tareas del usuario (vista "Hoy"/"Todas").
  Future<List<TaskModel>> fetchAll({String? agendaId, String? status}) async {
    final data = await _client.get(ApiConfig.tasks, query: {
      'agenda': ?agendaId,
      'status': ?status,
    }) as List<dynamic>;

    return data
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TaskModel> create(TaskModel task) async {
    final data = await _client.post(ApiConfig.tasks, task.toJson());

    return TaskModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TaskModel> update(TaskModel task) async {
    final data = await _client.put('${ApiConfig.tasks}/${task.id}', task.toJson());

    return TaskModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConfig.tasks}/$id');
  }
}
