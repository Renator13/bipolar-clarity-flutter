import 'package:flutter/material.dart';
import '../../models/mood_entry.dart';

/// Bottom sheet para ver detalle de una entrada de humor
class MoodDetailBottomSheet extends StatelessWidget {
  final MoodEntry entry;

  const MoodDetailBottomSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = entry.date;
    final color = _getMoodColor(entry.moodScore);
    final time = TimeOfDay.fromDateTime(date);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con puntuación
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      entry.moodScore.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMoodLabel(entry.moodScore),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatDate(date)} a las ${time.format(context)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Indicador visual
            _buildMoodIndicator(entry.moodScore),
            const SizedBox(height: 24),

            // Notas
            if (entry.notes.isNotEmpty) ...[
              const Text(
                'Notas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(entry.notes),
              ),
              const SizedBox(height: 24),
            ],

            // Métricas adicionales
            const Text(
              'Métricas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricTile('💤 Sueño', '${entry.sleepHours?.toStringAsFixed(1) ?? '-'}h'),
                _buildMetricTile('🏃 Actividad', entry.activityLevel?.toString() ?? '-'),
                _buildMetricTile('💊 Medicación', entry.medicationTaken ? 'Sí' : 'No'),
                _buildMetricTile('📝 tags', entry.tags.length.toString()),
              ],
            ),
            const SizedBox(height: 24),

            // Tags
            if (entry.tags.isNotEmpty) ...[
              const Text(
                'Tags',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: const Color(0xFF004B49).withOpacity(0.1),
                    labelStyle: const TextStyle(color: Color(0xFF004B49)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIndicator(double score) {
    final color = _getMoodColor(score);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIndicatorLabel('😔', '1'),
            _buildIndicatorLabel('😐', '4'),
            _buildIndicatorLabel('😊', '6'),
            _buildIndicatorLabel('⚡', '8'),
            _buildIndicatorLabel('🔥', '10'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 10,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorLabel(String emoji, String score) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(score, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildMetricTile(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                emoji == '💤 Sueño' ? 'Sueño' :
                emoji == '🏃 Actividad' ? 'Actividad' :
                emoji == '💊 Medicación' ? 'Medicación' : 'Tags',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(double score) {
    if (score >= 8) return Colors.orange;
    if (score >= 6) return Colors.green;
    if (score >= 4) return Colors.yellow;
    return Colors.redAccent;
  }

  String _getMoodLabel(double score) {
    if (score >= 8) return 'Estado Elevado';
    if (score >= 6) return 'Estado Estable';
    if (score >= 4) return 'Ligeramente Bajo';
    return 'Estado Depresivo';
  }

  String _formatDate(DateTime date) {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}
