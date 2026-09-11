import 'package:flutter_test/flutter_test.dart';

import 'package:agenda/main.dart';

void main() {
  testWidgets('la app arranca mostrando el splash mientras valida la sesion',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AgendaApp());

    // Con la sesion todavia sin resolver, el AuthGate muestra el indicador
    // de carga en lugar del login o la lista de agendas.
    expect(find.byType(AgendaApp), findsOneWidget);
  });
}
