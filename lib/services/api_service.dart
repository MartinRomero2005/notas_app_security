import 'dart:convert';

import '../models/nota.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService instance = ApiService._();

  ApiService._();

  static const _notasKey = 'notas_persistidas';
  final List<Nota> _notas = [
    Nota(
      id: 1,
      estudianteId: 1,
      docenteId: 1,
      estudiante: 'Juan Pérez',
      asignatura: 'Programación',
      calificacion: 4.5,
      comentario: 'Excelente trabajo.',
      fecha: DateTime(2026, 9, 1),
      sincronizada: true,
    ),
    Nota(
      id: 2,
      estudianteId: 2,
      docenteId: 1,
      estudiante: 'María Gómez',
      asignatura: 'Bases de Datos',
      calificacion: 3.8,
      comentario: 'Buen desempeño.',
      fecha: DateTime(2026, 9, 2),
      sincronizada: true,
    ),
  ];

  int _nextId = 3;
  late final Future<void> _inicializacion = _cargarPersistencia();

  Future<List<Nota>> obtenerNotas() async {
    await _inicializacion;
    await _simularRespuestaRest();
    return List.unmodifiable(_notas);
  }

  Future<Nota> crearNota(Nota nota) async {
    await _inicializacion;
    await _simularRespuestaRest();
    final creada = nota.copyWith(id: _nextId++, sincronizada: false);
    _notas.add(creada);
    await _guardarPersistencia();
    return creada;
  }

  Future<Nota> actualizarNota(Nota nota) async {
    await _inicializacion;
    await _simularRespuestaRest();
    final indice = _notas.indexWhere((item) => item.id == nota.id);
    if (indice == -1) {
      throw StateError('La calificación no existe.');
    }

    final actualizada = nota.copyWith(sincronizada: false);
    _notas[indice] = actualizada;
    await _guardarPersistencia();
    return actualizada;
  }

  Future<void> eliminarNota(int id) async {
    await _inicializacion;
    await _simularRespuestaRest();
    _notas.removeWhere((nota) => nota.id == id);
    await _guardarPersistencia();
  }

  Future<int> sincronizarConLaNube() async {
    await _inicializacion;
    await _simularRespuestaRest();
    var sincronizadas = 0;
    for (var indice = 0; indice < _notas.length; indice++) {
      if (!_notas[indice].sincronizada) {
        _notas[indice] = _notas[indice].copyWith(sincronizada: true);
        sincronizadas++;
      }
    }
    if (sincronizadas > 0) {
      await _guardarPersistencia();
    }
    return sincronizadas;
  }

  Future<void> _cargarPersistencia() async {
    final preferencias = await SharedPreferences.getInstance();
    final datos = preferencias.getString(_notasKey);
    if (datos == null) {
      await _guardarPersistencia(preferencias);
      return;
    }

    final lista = jsonDecode(datos) as List<dynamic>;
    _notas
      ..clear()
      ..addAll(
        lista.map(
          (item) => Nota.fromMap(Map<String, dynamic>.from(item as Map)),
        ),
      );
    final ids = _notas.map((nota) => nota.id ?? 0);
    _nextId = ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _guardarPersistencia([SharedPreferences? preferencias]) async {
    final almacenamiento =
        preferencias ?? await SharedPreferences.getInstance();
    final datos = _notas.map((nota) => nota.toMap()).toList();
    await almacenamiento.setString(_notasKey, jsonEncode(datos));
  }

  Future<void> _simularRespuestaRest() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
