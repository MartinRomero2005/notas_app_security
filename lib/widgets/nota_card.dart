import 'package:flutter/material.dart';

import '../models/nota.dart';

class NotaCard extends StatelessWidget {
  final Nota nota;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NotaCard({
    super.key,
    required this.nota,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nota.estudiante,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  nota.calificacion.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: nota.calificacion >= 3 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Asignatura: ${nota.asignatura}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 6),

            if (nota.comentario.isNotEmpty)
              Text(
                'Comentario: ${nota.comentario}',
                style: const TextStyle(fontSize: 14),
              ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fecha: ${nota.fecha.day}/${nota.fecha.month}/${nota.fecha.year}',
                  style: const TextStyle(color: Colors.grey),
                ),

                Row(
                  children: [
                    Icon(
                      nota.sincronizada ? Icons.cloud_done : Icons.cloud_off,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modificar calificación',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
