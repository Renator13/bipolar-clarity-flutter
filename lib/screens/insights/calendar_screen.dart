import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/mood_entry.dart';
import '../../services/firestore_service.dart';
import 'mood_detail_bottom_sheet.dart';

/// Pantalla de calendario para ver historial de humor
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<MoodEntry>> _moodEntries = {};
  List<MoodEntry> _selectedEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    setState(() => _isLoading = true);
    
    // Cargar entradas de los últimos 3 meses
    final entries = await FirestoreService.getMoodEntries('current_user_id');
    
    // Agrupar por fecha
    final grouped = <DateTime, List<MoodEntry>>{};
    for (final entry in entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      grouped[date] = [...(grouped[date] ?? []), entry];
    }

    setState(() {
      _moodEntries = grouped;
      _isLoading = false;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEntries = _moodEntries[selectedDay] ?? [];
    });
  }

  void _showMoodDetail(MoodEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MoodDetailBottomSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Hoy',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendario
                Card(
                  margin: const EdgeInsets.all(16),
                  child: TableCalendar<MoodEntry>(
                    firstDay: DateTime.now().subtract(Duration(days: 90)),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF20C997),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF004B49),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Color(0xFF004B49),
                        shape: BoxShape.circle,
                      ),
                    ),
                    eventLoader: (day) {
                      return _moodEntries[day] ?? [];
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return const SizedBox();
                        
                        final entry = events.first as MoodEntry;
                        final color = _getMoodColor(entry.moodScore);
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Leyenda de colores
                _buildLegend(),
                const SizedBox(height: 8),

                // Entradas del día seleccionado
                Expanded(
                  child: _selectedDay == null
                      ? Center(
                          child: Text(
                            'Selecciona un día para ver los registros',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : _selectedEntries.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sin registros el ${_formatDate(_selectedDay!)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _selectedEntries.length,
                              itemBuilder: (context, index) {
                                final entry = _selectedEntries[index];
                                return _buildMoodCard(entry);
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.redAccent, 'Depresivo'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.yellow, 'Ligeramente bajo'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.green, 'Estable'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.orange, 'Elevado'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMoodCard(MoodEntry entry) {
    final color = _getMoodColor(entry.moodScore);
    final time = TimeOfDay.fromDateTime(entry.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showMoodDetail(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador de humor
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    entry.moodScore.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMoodLabel(entry.moodScore),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${time.format(context)} - ${_getMoodEmoji(entry.moodScore)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Etiquetas
              Wrap(
                spacing: 4,
                children: [
                  if (entry.sleepHours != null)
                    Chip(
                      label: Text('${entry.sleepHours!.toStringAsFixed(1)}h'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
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

  String _getMoodEmoji(double score) {
    if (score >= 8) return '⚡';
    if (score >= 6) return '😊';
    if (score >= 4) return '😐';
    return '😔';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
