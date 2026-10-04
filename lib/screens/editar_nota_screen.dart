import 'package:flutter/material.dart';

import '../models/nota.dart';

class EditarNotaScreen extends StatefulWidget {
  final Nota? nota;

  const EditarNotaScreen({super.key, this.nota});

  @override
  State<EditarNotaScreen> createState() => _EditarNotaScreenState();
}

class _EditarNotaScreenState extends State<EditarNotaScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController estudianteController = TextEditingController();

  final TextEditingController asignaturaController = TextEditingController();

  final TextEditingController calificacionController = TextEditingController();

  final TextEditingController comentarioController = TextEditingController();

  bool get editando => widget.nota != null;

  @override
  void initState() {
    super.initState();
    final nota = widget.nota;
    if (nota != null) {
      estudianteController.text = nota.estudiante;
      asignaturaController.text = nota.asignatura;
      calificacionController.text = nota.calificacion.toString();
      comentarioController.text = nota.comentario;
    }
  }

  @override
  void dispose() {
    estudianteController.dispose();
    asignaturaController.dispose();
    calificacionController.dispose();
    comentarioController.dispose();
    super.dispose();
  }

  void guardarNota() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double calificacion = double.parse(calificacionController.text);

    final nota = Nota(
      id: widget.nota?.id,
      estudianteId: 1,
      docenteId: 1,
      estudiante: estudianteController.text,
      asignatura: asignaturaController.text,
      calificacion: calificacion,
      comentario: comentarioController.text,
      fecha: DateTime.now(),
      sincronizada: widget.nota?.sincronizada ?? false,
    );

    Navigator.pop(context, nota);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editando ? 'Modificar calificación' : 'Registrar calificación',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: estudianteController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del estudiante',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre del estudiante';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: asignaturaController,
                decoration: const InputDecoration(
                  labelText: 'Asignatura',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la asignatura';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: calificacionController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Calificación',
                  hintText: 'Ejemplo: 4.5',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese una calificación';
                  }

                  final nota = double.tryParse(value);

                  if (nota == null) {
                    return 'Ingrese un número válido';
                  }

                  if (nota < 0 || nota > 5) {
                    return 'La calificación debe estar entre 0 y 5';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: comentarioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                  hintText: 'Observación sobre la calificación',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: guardarNota,
                icon: const Icon(Icons.save),
                label: Text(
                  editando ? 'Guardar cambios' : 'Guardar calificación',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
