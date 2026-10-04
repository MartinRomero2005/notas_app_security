// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notas_app/main.dart';
import 'package:notas_app/models/nota.dart';
import 'package:notas_app/services/api_service.dart';
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

  testWidgets('muestra acceso exclusivo para docentes', (tester) async {
    final session = SessionController(storage: InMemorySessionStorage());
    await session.restore();
    await tester.pumpWidget(NotasApp(sessionController: session));
    await tester.pumpAndSettle();

    expect(find.text('Gestión Académica'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Estudiante'), findsNothing);
  });

  test('persiste y elimina la sesión al iniciar y cerrar sesión', () async {
    final storage = InMemorySessionStorage();
    final session = SessionController(storage: storage);

    await session.restore();
    expect(session.isAuthenticated, isFalse);

    await session.signIn('docente@example.com', 'clave123');
    expect(session.isAuthenticated, isTrue);
    expect(session.userEmail, 'docente@example.com');
    expect(storage.values['session_token'], isNotEmpty);

    final restored = SessionController(storage: storage);
    await restored.restore();
    expect(restored.isAuthenticated, isTrue);
    expect(restored.userEmail, 'docente@example.com');

    await restored.signOut();
    expect(restored.isAuthenticated, isFalse);
    expect(storage.values, isEmpty);
  });

  test('rechaza credenciales incompletas', () async {
    final session = SessionController(storage: InMemorySessionStorage());
    await session.restore();

    await expectLater(
      session.signIn('correo-invalido', '123'),
      throwsFormatException,
    );
    expect(session.isAuthenticated, isFalse);
  });

  test('permite crear, actualizar, eliminar y sincronizar notas', () async {
    final api = ApiService.instance;
    final creada = await api.crearNota(
      Nota(
        estudianteId: 99,
        docenteId: 1,
        estudiante: 'Prueba docente',
        asignatura: 'Evaluación',
        calificacion: 4,
        comentario: '',
        fecha: DateTime(2026, 9, 12),
      ),
    );

    expect(creada.id, isNotNull);
    expect(creada.sincronizada, isFalse);

    final actualizada = await api.actualizarNota(
      creada.copyWith(calificacion: 4.5),
    );
    expect(actualizada.calificacion, 4.5);

    expect(await api.sincronizarConLaNube(), 1);
    expect(
      (await api.obtenerNotas())
          .singleWhere((nota) => nota.id == creada.id)
          .sincronizada,
      isTrue,
    );

    await api.eliminarNota(creada.id!);
    expect(
      (await api.obtenerNotas()).any((nota) => nota.id == creada.id),
      isFalse,
    );
  });
}
