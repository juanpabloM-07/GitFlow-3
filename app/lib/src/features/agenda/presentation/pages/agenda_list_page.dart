import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/agenda_controller.dart';
import '../../data/agenda_model.dart';
import '../widgets/agenda_card.dart';
import '../widgets/agenda_form_sheet.dart';
import 'agenda_detail_page.dart';

/// Pantalla principal: lista de agendas del usuario con buscador y resumen.
class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // La primera carga se dispara despues del primer frame para poder usar
    // el context del Provider sin problemas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgendaController>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await showAgendaFormSheet(context);
    if (created && mounted) {
      showAppSnackBar(context, 'Agenda creada');
    }
  }

  Future<void> _edit(AgendaModel agenda) async {
    final updated = await showAgendaFormSheet(context, agenda: agenda);
    if (updated && mounted) {
      showAppSnackBar(context, 'Agenda actualizada');
    }
  }

  Future<void> _delete(AgendaModel agenda) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar agenda',
      message:
          'Se eliminara "${agenda.title}" y todas sus tareas. Esta accion no se puede deshacer.',
    );

    if (!confirmed || !mounted) return;

    final controller = context.read<AgendaController>();
    final ok = await controller.delete(agenda.id);

    if (!mounted) return;

    showAppSnackBar(
      context,
      ok ? 'Agenda eliminada' : controller.errorMessage ?? 'No se pudo eliminar',
      isError: !ok,
    );
  }

  Future<void> _openDetail(AgendaModel agenda) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AgendaDetailPage(agenda: agenda)),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cerrar sesion',
      message: 'Vas a volver a la pantalla de inicio de sesion.',
      confirmLabel: 'Cerrar sesion',
      confirmColor: AppColors.primary,
    );

    if (!confirmed || !mounted) return;

    await context.read<AuthController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AgendaController>();
    final user = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${user?.name.split(' ').first ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Estas son tus agendas',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva agenda'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Column(
          children: [
            _SummaryBar(
              agendas: controller.agendas.length,
              tasks: controller.totalTasks,
              completed: controller.completedTasks,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: controller.search,
                decoration: InputDecoration(
                  hintText: 'Buscar agenda',
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textMuted),
                  suffixIcon: controller.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.textMuted,
                          onPressed: () {
                            _searchController.clear();
                            controller.search('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(child: _buildBody(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AgendaController controller) {
    if (controller.isLoading && controller.agendas.isEmpty) {
      return const LoadingView();
    }

    if (controller.errorMessage != null && controller.agendas.isEmpty) {
      return ErrorView(
        message: controller.errorMessage!,
        onRetry: controller.load,
      );
    }

    if (controller.agendas.isEmpty) {
      final isSearching = controller.query.isNotEmpty;

      return EmptyView(
        icon: isSearching ? Icons.search_off_rounded : Icons.folder_open_rounded,
        title: isSearching ? 'Sin resultados' : 'Todavia no hay agendas',
        message: isSearching
            ? 'No encontramos agendas que coincidan con "${controller.query}".'
            : 'Crea tu primera agenda para empezar a cargar tareas.',
        actionLabel: isSearching ? null : 'Crear agenda',
        onAction: isSearching ? null : _create,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: controller.agendas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final agenda = controller.agendas[index];

        return AgendaCard(
          agenda: agenda,
          onTap: () => _openDetail(agenda),
          onEdit: () => _edit(agenda),
          onDelete: () => _delete(agenda),
        );
      },
    );
  }
}

/// Franja con los totales generales del usuario.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.agendas,
    required this.tasks,
    required this.completed,
  });

  final int agendas;
  final int tasks;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _SummaryItem(value: agendas, label: 'Agendas', color: AppColors.primary),
          const _SummaryDivider(),
          _SummaryItem(value: tasks, label: 'Tareas', color: AppColors.read),
          const _SummaryDivider(),
          _SummaryItem(
            value: completed,
            label: 'Completadas',
            color: AppColors.create,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.primary.withValues(alpha: 0.15),
    );
  }
}
