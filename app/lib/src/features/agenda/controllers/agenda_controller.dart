import 'package:flutter/foundation.dart';

import '../../../shared/services/api_client.dart';
import '../data/agenda_api_services.dart';
import '../data/agenda_model.dart';

// ---------------------------------------------------------------------------
// CONTROLLER DE AGENDAS
// ---------------------------------------------------------------------------
// Guarda la lista de agendas y el estado de la pantalla (cargando, guardando,
// error). Las pantallas leen estos datos con context.watch y llaman a los
// metodos con context.read.
//
// Cada vez que algo cambia se llama a notifyListeners() para que Flutter
// vuelva a dibujar las pantallas que esten escuchando.
// ---------------------------------------------------------------------------
class AgendaController extends ChangeNotifier {
  AgendaController({AgendaApiServices? services})
      : _services = services ?? AgendaApiServices();

  final AgendaApiServices _services;

  // --- Estado interno ------------------------------------------------------

  List<AgendaModel> _agendas = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _query = '';

  // --- Lo que leen las pantallas -------------------------------------------

  /// Lista ya filtrada por el texto del buscador.
  /// El filtrado se hace en memoria: las agendas de un usuario son pocas, no
  /// vale la pena ir al servidor en cada tecla.
  List<AgendaModel> get agendas {
    if (_query.isEmpty) return List.unmodifiable(_agendas);

    final texto = _query.toLowerCase();

    return _agendas
        .where((agenda) =>
            agenda.title.toLowerCase().contains(texto) ||
            agenda.description.toLowerCase().contains(texto))
        .toList();
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get query => _query;

  /// Totales que se muestran en la franja de resumen de la pantalla principal.
  int get totalTasks =>
      _agendas.fold(0, (suma, agenda) => suma + agenda.taskCount);
  int get completedTasks =>
      _agendas.fold(0, (suma, agenda) => suma + agenda.completedCount);

  AgendaModel? findById(String id) {
    for (final agenda in _agendas) {
      if (agenda.id == id) return agenda;
    }

    return null;
  }

  // --- Buscador ------------------------------------------------------------

  void search(String value) {
    _query = value.trim();
    notifyListeners();
  }

  // --- Leer (READ) ---------------------------------------------------------

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _agendas = await _services.fetchAll();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Crear (CREATE) ------------------------------------------------------

  Future<bool> create({
    required String title,
    required String description,
    required String color,
  }) {
    return _mutate(() async {
      final agenda = await _services.create(
        title: title,
        description: description,
        color: color,
      );

      // Se agrega arriba de todo porque el backend ordena por fecha desc.
      _agendas.insert(0, agenda);
    });
  }

  // --- Editar (UPDATE) -----------------------------------------------------

  Future<bool> update(AgendaModel agenda) {
    return _mutate(() async {
      final actualizada = await _services.update(agenda);
      final indice = _agendas.indexWhere((item) => item.id == agenda.id);

      if (indice != -1) {
        // La respuesta del PUT no incluye taskCount ni completedCount, asi que
        // conservamos los que ya teniamos para no perder el progreso en la UI.
        _agendas[indice] = actualizada.copyWith(
          taskCount: _agendas[indice].taskCount,
          completedCount: _agendas[indice].completedCount,
        );
      }
    });
  }

  // --- Borrar (DELETE) -----------------------------------------------------

  Future<bool> delete(String id) {
    return _mutate(() async {
      await _services.delete(id);
      _agendas.removeWhere((agenda) => agenda.id == id);
    });
  }

  // --- Sincronizacion de contadores ----------------------------------------

  /// La pantalla de detalle avisa cuantas tareas quedaron despues de un cambio.
  /// Actualizamos la tarjeta en memoria en vez de volver a pedir toda la lista
  /// al servidor, que seria una peticion de mas.
  void syncCounts({
    required String agendaId,
    required int taskCount,
    required int completedCount,
  }) {
    final indice = _agendas.indexWhere((agenda) => agenda.id == agendaId);
    if (indice == -1) return;

    _agendas[indice] = _agendas[indice].copyWith(
      taskCount: taskCount,
      completedCount: completedCount,
    );

    notifyListeners();
  }

  // --- Helper compartido por create / update / delete ----------------------

  /// Envuelve una operacion que escribe en el servidor: prende el indicador de
  /// guardado, ejecuta, guarda el error si falla y siempre lo apaga al final.
  /// Devuelve true si salio bien, para que la pantalla sepa que mostrar.
  Future<bool> _mutate(Future<void> Function() operacion) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operacion();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
