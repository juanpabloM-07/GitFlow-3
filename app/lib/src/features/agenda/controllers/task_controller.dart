import 'package:flutter/foundation.dart';

import '../../../config/constants.dart';
import '../../../shared/services/api_client.dart';
import '../data/task_api_services.dart';
import '../data/task_model.dart';

// ---------------------------------------------------------------------------
// CONTROLLER DE TAREAS
// ---------------------------------------------------------------------------
// Maneja las tareas de UNA agenda por vez: la pantalla de detalle llama a
// reset() y despues a load(agendaId) cada vez que se abre.
// ---------------------------------------------------------------------------
class TaskController extends ChangeNotifier {
  TaskController({TaskApiServices? services})
      : _services = services ?? TaskApiServices();

  final TaskApiServices _services;

  // --- Estado interno ------------------------------------------------------

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  TaskStatus? _filter;

  // --- Lo que leen las pantallas -------------------------------------------

  /// Tareas ya filtradas por estado y ordenadas por fecha y hora.
  /// Se filtra y ordena en memoria para que tocar un filtro sea instantaneo,
  /// sin pedirle nada al servidor.
  List<TaskModel> get tasks {
    final lista = _filter == null
        ? List<TaskModel>.from(_tasks)
        : _tasks.where((task) => task.status == _filter).toList();

    lista.sort((a, b) {
      final porFecha = a.date.compareTo(b.date);

      return porFecha != 0 ? porFecha : a.time.compareTo(b.time);
    });

    return List.unmodifiable(lista);
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  TaskStatus? get filter => _filter;

  /// Totales sobre TODAS las tareas, sin importar el filtro activo.
  int get total => _tasks.length;
  int get completed =>
      _tasks.where((task) => task.status == TaskStatus.completed).length;

  int countByStatus(TaskStatus status) =>
      _tasks.where((task) => task.status == status).length;

  // --- Filtro por estado ---------------------------------------------------

  void setFilter(TaskStatus? status) {
    _filter = status;
    notifyListeners();
  }

  // --- Leer (READ) ---------------------------------------------------------

  Future<void> load(String agendaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _services.fetchAll(agendaId: agendaId);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Crear (CREATE) ------------------------------------------------------

  Future<bool> create(TaskModel task) {
    return _mutate(() async {
      _tasks.add(await _services.create(task));
    });
  }

  // --- Editar (UPDATE) -----------------------------------------------------

  Future<bool> update(TaskModel task) {
    return _mutate(() async {
      final actualizada = await _services.update(task);
      final indice = _tasks.indexWhere((item) => item.id == task.id);

      if (indice != -1) _tasks[indice] = actualizada;
    });
  }

  /// Atajo del circulito de la lista: pasa de completada a pendiente y viceversa.
  Future<bool> toggleCompleted(TaskModel task) {
    final nuevoEstado = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;

    return update(task.copyWith(status: nuevoEstado));
  }

  // --- Borrar (DELETE) -----------------------------------------------------

  Future<bool> delete(String id) {
    return _mutate(() async {
      await _services.delete(id);
      _tasks.removeWhere((task) => task.id == id);
    });
  }

  // --- Limpieza ------------------------------------------------------------

  /// Vacia la lista antes de abrir otra agenda, asi no se ven por un instante
  /// las tareas de la agenda anterior.
  void reset() {
    _tasks = [];
    _filter = null;
    _errorMessage = null;
  }

  // --- Helper compartido por create / update / delete ----------------------

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
