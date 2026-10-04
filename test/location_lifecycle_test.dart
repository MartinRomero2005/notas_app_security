import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notas_app/screens/notas_screen.dart';
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

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  int cancellations = 0;
  Position? lastKnownPosition;
  Object? streamError;

  late final StreamController<Position> positions = StreamController<Position>(
    onCancel: () => cancellations++,
  );

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnownPosition;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      streamError == null ? positions.stream : Stream.error(streamError!);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('cancela la ubicación al pasar a segundo plano', (tester) async {
    final previousPlatform = GeolocatorPlatform.instance;
    final platform = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = platform;
    addTearDown(() async {
      GeolocatorPlatform.instance = previousPlatform;
      await platform.positions.close();
    });

    final session = SessionController(storage: InMemorySessionStorage());
    await session.restore();
    await session.signIn('docente@example.com', 'clave123');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(home: NotasScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Consultar ubicación'));
    await tester.pump();
    expect(platform.cancellations, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(platform.cancellations, 1);
    expect(find.text('Ubicación actual: 1.0000, 2.0000'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('muestra la última ubicación conocida tras un timeout', (
    tester,
  ) async {
    final previousPlatform = GeolocatorPlatform.instance;
    final platform = FakeGeolocatorPlatform()
      ..streamError = TimeoutException('No llegó una ubicación nueva')
      ..lastKnownPosition = Position(
        longitude: -122.084,
        latitude: 37.422,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    GeolocatorPlatform.instance = platform;
    addTearDown(() async {
      GeolocatorPlatform.instance = previousPlatform;
      await platform.positions.close();
    });

    final session = SessionController(storage: InMemorySessionStorage());
    await session.restore();
    await session.signIn('docente@example.com', 'clave123');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(home: NotasScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Consultar ubicación'));
    await tester.pumpAndSettle();

    expect(
      find.text('Última ubicación conocida: 37.4220, -122.0840'),
      findsOneWidget,
    );
    expect(
      find.text('No llegó una ubicación nueva; se muestra la última conocida.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
