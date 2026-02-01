import 'package:flutter/material.dart';
import '../../services/digital_phenotype_service.dart';
import '../../services/theme_service.dart';
import '../../models/digital_phenotype.dart';

/// Pantalla de Digital Phenotyping
/// Muestra patrones detectados automáticamente
class DigitalPhenotypeScreen extends StatefulWidget {
  const DigitalPhenotypeScreen({super.key});

  @override
  State<DigitalPhenotypeScreen> createState() => _DigitalPhenotypeScreenState();
}

class _DigitalPhenotypeScreenState extends State<DigitalPhenotypeScreen> {
  final _phenotypeService = DigitalPhenotypeService();
  PhenotypeState _currentState = PhenotypeState.unknown;
  List<PhenotypeDataPoint> _recentData = [];
  WeeklyPhenotypeSummary? _weeklySummary;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _phenotypeService.onStateChange.listen(_handleStateChange);
  }

  @override
  void dispose() {
    _phenotypeService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = _phenotypeService.getHistoricalData(days: 7);
    final summary = WeeklyPhenotypeSummary.fromDataPoints(data);
    final currentState = _phenotypeService.getCurrentState();

    setState(() {
      _recentData = data;
      _weeklySummary = summary;
      _currentState = currentState;
    });
  }

  void _handleStateChange(StateChangeEvent event) {
    if (mounted) {
      _loadData();
      _showStateChangeDialog(event);
    }
  }

  void _showStateChangeDialog(StateChangeEvent event) {
    final color = switch (event.currentState) {
      PhenotypeState.elevated => Colors.orange,
      PhenotypeState.depressive => Colors.blue,
      _ => Colors.grey,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cambio detectado',
          style: TextStyle(color: color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado anterior: ${event.previousState.name}'),
            Text('Estado actual: ${event.currentState.name}'),
            const SizedBox(height: 8),
            Text(
              'Confianza: ${(event.confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (event.indicators.isEmpty) ...[
              const SizedBox(height: 8),
              const Text('Indicadores:'),
              ...event.indicators.map((i) => Text('• $i')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _toggleMonitoring() async {
    if (_isMonitoring) {
      _phenotypeService.stopCollecting();
    } else {
      await _phenotypeService.startCollecting();
    }
    setState(() => _isMonitoring = !_isMonitoring);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrones Automáticos'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _isMonitoring,
            onChanged: (_) => _toggleMonitoring(),
            activeColor: Colors.white,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado actual
            _buildCurrentStateCard(),
            const SizedBox(height: 16),

            // Resumen semanal
            if (_weeklySummary != null) _buildWeeklySummary(),
            const SizedBox(height: 16),

            // Métricas
            _buildMetricsCard(),
            const SizedBox(height: 16),

            // Patrones detectados
            if (_weeklySummary != null && _weeklySummary!.detectedPatterns.isNotEmpty)
              _buildPatternsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStateCard() {
    final stateInfo = _getStateInfo(_currentState);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              stateInfo['icon'],
              size: 48,
              color: stateInfo['color'],
            ),
            const SizedBox(height: 12),
            Text(
              stateInfo['label'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: stateInfo['color'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stateInfo['description'],
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isMonitoring
                    ? const Row(
                        children: [
                          Icon(Icons.monitoring, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Monitoreando', style: TextStyle(color: Colors.green)),
                        ],
                      )
                    : const Text('Monitoreo pausado'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    final summary = _weeklySummary!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta semana',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Sueño', '${summary.avgSleep.toStringAsFixed(1)}h'),
                _buildMetric('Actividad', summary.avgActivity.toStringAsFixed(1)),
                _buildMetric('Pantalla', '${(summary.avgScreenTime / 60).toStringAsFixed(1)}h'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMetricsCard() {
    if (_recentData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sin datos aún. Activa el monitoreo para comenzar.'),
        ),
      );
    }

    final lastPoint = _recentData.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Última lectura',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricTile('💤 Sueño', '${lastPoint.sleepHours.toStringAsFixed(1)}h'),
                _buildMetricTile('🏃 Actividad', lastPoint.activityLevel.toStringAsFixed(1)),
                _buildMetricTile('📱 Pantalla', '${(lastPoint.screenTimeMinutes / 60).toStringAsFixed(1)}h'),
                _buildMetricTile('🔄 Cambios app', lastPoint.appUsagePattern.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPatternsCard() {
    final patterns = _weeklySummary!.detectedPatterns;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber[600]),
                const SizedBox(width: 8),
                const Text(
                  'Patrones detectados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...patterns.map((pattern) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8),
                      const SizedBox(width: 8),
                      Expanded(child: Text(pattern)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStateInfo(PhenotypeState state) {
    switch (state) {
      case PhenotypeState.stable:
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'label': 'Estado Estable',
          'description': 'Tus patrones están dentro de lo normal',
        };
      case PhenotypeState.elevated:
        return {
          'icon': Icons.trending_up,
          'color': Colors.orange,
          'label': 'Estado Elevado',
          'description': 'Detectamos mayor actividad y menos sueño de lo habitual',
        };
      case PhenotypeState.depressive:
        return {
          'icon': Icons.trending_down,
          'color': Colors.blue,
          'label': 'Estado Decreciente',
          'description': 'Detectamos menos actividad y más sueño de lo habitual',
        };
      case PhenotypeState.mixed:
        return {
          'icon': Icons.swap_horiz,
          'color': Colors.purple,
          'label': 'Cambios Mixtos',
          'description': 'Patrones variables detectados',
        };
      case PhenotypeState.unknown:
      default:
        return {
          'icon': Icons.help,
          'color': Colors.grey,
          'label': 'Sin datos suficientes',
          description: 'Activa el monitoreo para comenzar a detectar patrones',
        };
    }
  }
}
