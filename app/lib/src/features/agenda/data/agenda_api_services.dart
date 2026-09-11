import '../../../config/constants.dart';
import '../../../shared/services/api_client.dart';
import 'agenda_model.dart';

class AgendaApiServices {
  AgendaApiServices({ApiClient? client}) : _client = client ?? ApiClient.shared;

  final ApiClient _client;

  Future<List<AgendaModel>> fetchAll() async {
    final data = await _client.get(ApiConfig.agendas) as List<dynamic>;

    return data
        .map((item) => AgendaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AgendaModel> create({
    required String title,
    required String description,
    required String color,
  }) async {
    final data = await _client.post(ApiConfig.agendas, {
      'title': title,
      'description': description,
      'color': color,
    });

    return AgendaModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AgendaModel> update(AgendaModel agenda) async {
    final data = await _client.put(
      '${ApiConfig.agendas}/${agenda.id}',
      agenda.toJson(),
    );

    return AgendaModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConfig.agendas}/$id');
  }
}
