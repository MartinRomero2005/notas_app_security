class Nota {
  final int? id;
  final int estudianteId;
  final int docenteId;
  final String estudiante;
  final String asignatura;
  final double calificacion;
  final String comentario;
  final DateTime fecha;
  final bool sincronizada;

  Nota({
    this.id,
    required this.estudianteId,
    required this.docenteId,
    required this.estudiante,
    required this.asignatura,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
    this.sincronizada = false,
  });

  Nota copyWith({
    int? id,
    int? estudianteId,
    int? docenteId,
    String? estudiante,
    String? asignatura,
    double? calificacion,
    String? comentario,
    DateTime? fecha,
    bool? sincronizada,
  }) {
    return Nota(
      id: id ?? this.id,
      estudianteId: estudianteId ?? this.estudianteId,
      docenteId: docenteId ?? this.docenteId,
      estudiante: estudiante ?? this.estudiante,
      asignatura: asignatura ?? this.asignatura,
      calificacion: calificacion ?? this.calificacion,
      comentario: comentario ?? this.comentario,
      fecha: fecha ?? this.fecha,
      sincronizada: sincronizada ?? this.sincronizada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estudianteId': estudianteId,
      'docenteId': docenteId,
      'estudiante': estudiante,
      'asignatura': asignatura,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': fecha.toIso8601String(),
      'sincronizada': sincronizada ? 1 : 0,
    };
  }

  factory Nota.fromMap(Map<String, dynamic> map) {
    return Nota(
      id: map['id'] as int?,
      estudianteId: map['estudianteId'] as int,
      docenteId: map['docenteId'] as int,
      estudiante: map['estudiante'] as String,
      asignatura: map['asignatura'] as String,
      calificacion: (map['calificacion'] as num).toDouble(),
      comentario: map['comentario'] as String? ?? '',
      fecha: DateTime.parse(map['fecha'] as String),
      sincronizada: map['sincronizada'] == true || map['sincronizada'] == 1,
    );
  }
}
