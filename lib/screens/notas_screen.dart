import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/nota.dart';
import '../services/api_service.dart';
import '../services/session_controller.dart';
import '../widgets/nota_card.dart';
import 'editar_nota_screen.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> with WidgetsBindingObserver {
  final ApiService api = ApiService.instance;
  final TextEditingController busquedaController = TextEditingController();
  StreamSubscription<Position>? _locationSubscription;
  Completer<Position?>? _locationCompleter;
  int _locationRequestId = 0;
  List<Nota> notas = [];
  bool cargando = true;
  bool consultandoUbicacion = false;
  bool _ubicacionEsUltimaConocida = false;
  String? ubicacion;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    cargarNotas();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.hidden &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }

    _locationRequestId++;
    unawaited(_cancelLocationRequest());
    if (mounted && consultandoUbicacion) {
      setState(() => consultandoUbicacion = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationRequestId++;
    unawaited(_cancelLocationRequest());
    busquedaController.dispose();
    super.dispose();
  }

  Future<void> cargarNotas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultado = await api.obtenerNotas();
      if (mounted) {
        setState(() {
          notas = resultado;
          cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudieron cargar las calificaciones.';
          cargando = false;
        });
      }
    }
  }

  Future<void> agregarNota() async {
    final resultado = await Navigator.push<Nota>(
      context,
      MaterialPageRoute(builder: (context) => const EditarNotaScreen()),
    );

    if (resultado != null) {
      await api.crearNota(resultado);
      await cargarNotas();
      mostrarMensaje('Calificación creada y pendiente de sincronización.');
    }
  }

  Future<void> editarNota(Nota nota) async {
    final resultado = await Navigator.push<Nota>(
      context,
      MaterialPageRoute(builder: (context) => EditarNotaScreen(nota: nota)),
    );

    if (resultado != null) {
      await api.actualizarNota(resultado);
      await cargarNotas();
      mostrarMensaje('Calificación modificada y pendiente de sincronización.');
    }
  }

  Future<void> eliminarNota(Nota nota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar calificación'),
        content: Text('¿Eliminar la calificación de ${nota.estudiante}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || nota.id == null) {
      return;
    }

    await api.eliminarNota(nota.id!);
    await cargarNotas();
    mostrarMensaje('Calificación eliminada.');
  }

  Future<void> sincronizar() async {
    final cantidad = await api.sincronizarConLaNube();
    await cargarNotas();
    mostrarMensaje(
      cantidad == 0
          ? 'La información ya estaba sincronizada.'
          : '$cantidad calificación(es) sincronizada(s) con la nube.',
    );
  }

  Future<void> consultarUbicacion() async {
    if (consultandoUbicacion) return;
    final requestId = ++_locationRequestId;
    setState(() => consultandoUbicacion = true);

    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationRequestActive(requestId)) return;
      if (!servicioActivo) {
        mostrarMensaje('Activa los servicios de ubicación del dispositivo.');
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (!_isLocationRequestActive(requestId)) return;
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (!_isLocationRequestActive(requestId)) return;
      if (permiso == LocationPermission.deniedForever) {
        mostrarMensaje('Habilita el permiso de ubicación en los ajustes.');
        return;
      }
      if (permiso == LocationPermission.denied) {
        mostrarMensaje('Se necesita permiso para consultar la ubicación.');
        return;
      }

      Position? posicionGuardada;
      try {
        posicionGuardada = await Geolocator.getLastKnownPosition();
      } catch (_) {
        // Continue with a fresh request if the platform has no cached position.
      }
      if (!_isLocationRequestActive(requestId)) return;
      if (posicionGuardada != null && _esUbicacionReciente(posicionGuardada)) {
        _mostrarUbicacion(posicionGuardada, ultimaConocida: true);
        return;
      }

      final posicion = await _getFirstLocation();
      if (!_isLocationRequestActive(requestId)) return;
      if (posicion == null) {
        await _mostrarUltimaUbicacionOError(requestId, timedOut: false);
        return;
      }
      _mostrarUbicacion(posicion);
    } on TimeoutException {
      await _mostrarUltimaUbicacionOError(requestId, timedOut: true);
    } on LocationServiceDisabledException {
      if (_isLocationRequestActive(requestId)) {
        mostrarMensaje('Activa los servicios de ubicación del dispositivo.');
      }
    } on PermissionDeniedException {
      if (_isLocationRequestActive(requestId)) {
        mostrarMensaje('No se concedió el permiso de ubicación.');
      }
    } catch (error, stackTrace) {
      debugPrint('Error al consultar ubicación: $error\n$stackTrace');
      if (_isLocationRequestActive(requestId)) {
        await _mostrarUltimaUbicacionOError(requestId, timedOut: false);
      }
    } finally {
      if (_isLocationRequestActive(requestId)) {
        await _cancelLocationRequest();
      }
      if (_isLocationRequestActive(requestId)) {
        setState(() => consultandoUbicacion = false);
      }
    }
  }

  bool _isLocationRequestActive(int requestId) =>
      mounted && requestId == _locationRequestId;

  bool _esUbicacionReciente(Position posicion) {
    final antiguedad = DateTime.now().difference(posicion.timestamp);
    return !antiguedad.isNegative && antiguedad <= const Duration(minutes: 2);
  }

  void _mostrarUbicacion(Position posicion, {bool ultimaConocida = false}) {
    setState(() {
      ubicacion =
          '${posicion.latitude.toStringAsFixed(4)}, '
          '${posicion.longitude.toStringAsFixed(4)}';
      _ubicacionEsUltimaConocida = ultimaConocida;
    });
  }

  Future<void> _mostrarUltimaUbicacionOError(
    int requestId, {
    required bool timedOut,
  }) async {
    Position? posicionGuardada;
    try {
      posicionGuardada = await Geolocator.getLastKnownPosition();
    } catch (_) {
      // The current-location request may still be usable without a cache.
    }
    if (!_isLocationRequestActive(requestId)) return;

    if (posicionGuardada != null) {
      _mostrarUbicacion(posicionGuardada, ultimaConocida: true);
      mostrarMensaje(
        'No llegó una ubicación nueva; se muestra la última conocida.',
      );
      return;
    }

    mostrarMensaje(
      timedOut
          ? 'No se obtuvo una posición en 10 segundos. Comprueba la señal GPS e inténtalo de nuevo.'
          : 'No se encontró una ubicación disponible. Comprueba el GPS e inténtalo de nuevo.',
    );
  }

  Future<Position?> _getFirstLocation() {
    final completer = Completer<Position?>();
    _locationCompleter = completer;
    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 10),
          ),
        ).listen(
          (position) async {
            if (completer.isCompleted) return;
            final subscription = _locationSubscription;
            _locationSubscription = null;
            await subscription?.cancel();
            if (!completer.isCompleted) completer.complete(position);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete(null);
          },
        );
    return completer.future;
  }

  Future<void> _cancelLocationRequest() async {
    final subscription = _locationSubscription;
    _locationSubscription = null;
    final completer = _locationCompleter;
    _locationCompleter = null;

    try {
      await subscription?.cancel();
    } catch (_) {
      // A cancellation failure must not leave the request pending.
    } finally {
      if (completer != null && !completer.isCompleted) {
        completer.complete(null);
      }
    }
  }

  Future<void> cerrarSesion() async {
    _locationRequestId++;
    await _cancelLocationRequest();
    try {
      await context.read<SessionController>().signOut();
    } catch (_) {
      mostrarMensaje('No se pudo cerrar la sesión de forma segura.');
    }
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final correoUsuario = context.watch<SessionController>().userEmail ?? '';
    final textoBusqueda = busquedaController.text.trim().toLowerCase();
    final notasFiltradas = notas.where((nota) {
      return nota.estudiante.toLowerCase().contains(textoBusqueda) ||
          nota.asignatura.toLowerCase().contains(textoBusqueda);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de calificaciones'),
        actions: [
          IconButton(
            onPressed: consultandoUbicacion ? null : consultarUbicacion,
            icon: consultandoUbicacion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.location_searching),
            tooltip: 'Consultar ubicación',
          ),
          IconButton(
            onPressed: sincronizar,
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Sincronizar con la nube',
          ),
          IconButton(
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: cargarNotas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text('Hola, ${correoUsuario.split('@').first}'),
                  subtitle: Text(correoUsuario),
                  dense: true,
                ),
                if (ubicacion != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_ubicacionEsUltimaConocida ? 'Última ubicación conocida' : 'Ubicación actual'}: $ubicacion',
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: busquedaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Buscar estudiante o asignatura',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: textoBusqueda.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                busquedaController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: notasFiltradas.isEmpty
                      ? Center(
                          child: Text(
                            notas.isEmpty
                                ? 'No hay calificaciones registradas.'
                                : 'No hay resultados para la búsqueda.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notasFiltradas.length,
                          itemBuilder: (context, index) {
                            final nota = notasFiltradas[index];
                            return NotaCard(
                              nota: nota,
                              onEdit: () => editarNota(nota),
                              onDelete: () => eliminarNota(nota),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: agregarNota,
        icon: const Icon(Icons.add),
        label: const Text('Agregar nota'),
      ),
    );
  }
}
