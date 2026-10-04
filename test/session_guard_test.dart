import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notas_app/main.dart';
import 'package:notas_app/services/session_controller.dart';

class InMemorySessionStorage implements SessionStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('protege notas y muestra al usuario autenticado', (tester) async {
    final session = SessionController(storage: InMemorySessionStorage());
    await session.restore();
    await session.signIn('docente@example.com', 'clave123');

    await tester.pumpWidget(NotasApp(sessionController: session));
    await tester.pumpAndSettle();

    expect(find.text('Gestión de calificaciones'), findsOneWidget);
    expect(find.text('Hola, docente'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsNothing);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(session.isAuthenticated, isFalse);
  });
}
