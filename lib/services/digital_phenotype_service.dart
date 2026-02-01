import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/digital_phenotype.dart';

/// Servicio para recopilar y analizar datos de Digital Phenotyping
/// Detecta cambios de estado usando patrones pasivos del usuario
class DigitalPhenotypeService {
  static final DigitalPhenotypeService _instance = DigitalPhenotypeService._internal();
  factory DigitalPhenotypeService() => _instance;
  DigitalPhenotypeService._internal();

  // Intervalo de recopilación (cada 15 minutos)
  static const Duration _collectionInterval = Duration(minutes: 15);

  // Umbrales para detección de estados
  static const double _sleepThreshold = 5.0; // horas
  static const double _activityLowThreshold = 3.0;
  static const double _activityHighThreshold = 8.0;
  static const int _usageFragmentationThreshold = 50; // cambios de app por hora

  Timer? _collectionTimer;
  bool _isEnabled = false;
  List<PhenotypeDataPoint> _dataPoints = [];

  // Stream para notificar cambios de estado detectados
  final _stateChangeStream = StreamController<StateChangeEvent>.broadcast();
  Stream<StateChangeEvent> get onStateChange => _stateChangeStream.stream;

  /// Iniciar recopilación de datos
  Future<void> startCollecting() async {
    if (_isEnabled) return;
    
    _isEnabled = true;
    _loadHistoricalData();
    
    // Iniciar timer de recopilación periódica
    _collectionTimer = Timer.periodic(
      _collectionInterval,
      (_) => _collectDataPoint(),
    );
    
    // Recopilar dato inicial
    await _collectDataPoint();
  }

  /// Detener recopilación
  void stopCollecting() {
    _isEnabled = false;
    _collectionTimer?.cancel();
    _collectionTimer = null;
  }

  /// Recopilar un punto de datos
  Future<void> _collectDataPoint() async {
    if (!_isEnabled) return;

    final dataPoint = PhenotypeDataPoint(
      timestamp: DateTime.now(),
      sleepHours: await _getSleepHours(),
      activityLevel: await _getActivityLevel(),
      screenTimeMinutes: await _getScreenTime(),
      appUsagePattern: await _getAppUsagePattern(),
      locationChanges: await _getLocationChanges(),
      socialInteractionScore: await _getSocialScore(),
    );

    _dataPoints.add(dataPoint);
    _saveHistoricalData();

    // Analizar patrones y detectar cambios
    await _analyzePatterns(dataPoint);
  }

  /// Analizar patrones y detectar cambios de estado
  Future<void> _analyzePatterns(PhenotypeDataPoint currentPoint) async {
    if (_dataPoints.length < 3) return;

    // Obtener promedio de las últimas 24 horas (96 puntos de 15 min)
    final last24Hours = _dataPoints
        .where((p) => p.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 24))))
        .toList();

    if (last24Hours.length < 10) return;

    final avgSleep = last24Hours.map((p) => p.sleepHours).reduce((a, b) => a + b) / last24Hours.length;
    final avgActivity = last24Hours.map((p) => p.activityLevel).reduce((a, b) => a + b) / last24Hours.length;
    final avgScreenTime = last24Hours.map((p) => p.screenTimeMinutes).reduce((a, b) => a + b) / last24Hours.length;

    // Detectar cambios significativos
    StateChangeEvent? event;

    // Hipomanía/estado elevado: menos sueño + más actividad + más tiempo de pantalla
    if (currentPoint.sleepHours < avgSleep * 0.8 &&
        currentPoint.activityLevel > avgActivity * 1.3 &&
        currentPoint.screenTimeMinutes > avgScreenTime * 1.5) {
      event = StateChangeEvent(
        timestamp: DateTime.now(),
        previousState: PhenotypeState.stable,
        currentState: PhenotypeState.elevated,
        confidence: _calculateConfidence(currentPoint, last24Hours),
        indicators: _getElevatedIndicators(currentPoint, last24Hours),
      );
    }
    // Depresión: más sueño + menos actividad + menos interacción social
    else if (currentPoint.sleepHours > avgSleep * 1.2 &&
        currentPoint.activityLevel < avgActivity * 0.7 &&
        currentPoint.socialInteractionScore < 0.4) {
      event = StateChangeEvent(
        timestamp: DateTime.now(),
        previousState: PhenotypeState.stable,
        currentState: PhenotypeState.depressive,
        confidence: _calculateConfidence(currentPoint, last24Hours),
        indicators: _getDepressiveIndicators(currentPoint, last24Hours),
      );
    }

    // Notificar cambio si se detectó
    if (event != null) {
      _stateChangeStream.add(event);
    }
  }

  /// Calcular confianza de la detección
  double _calculateConfidence(
    PhenotypeDataPoint current,
    List<PhenotypeDataPoint> historical,
  ) {
    // Entre más datos históricos y más extremo el cambio, mayor confianza
    final sleepChange = (current.sleepHours - _getAverage(historical, (p) => p.sleepHours)) /
        _getAverage(historical, (p) => p.sleepHours);
    final activityChange = (current.activityLevel - _getAverage(historical, (p) => p.activityLevel)) /
        _getAverage(historical, (p) => p.activityLevel);

    final baseConfidence = min(0.9, 0.5 + (historical.length / 100));
    final changeBonus = min(0.2, (sleepChange.abs() + activityChange.abs()) * 0.1);

    return (baseConfidence + changeBonus).clamp(0.0, 1.0);
  }

  /// Obtener indicadores de estado elevado
  List<String> _getElevatedIndicators(
    PhenotypeDataPoint current,
    List<PhenotypeDataPoint> historical,
  ) {
    final indicators = <String>[];
    final avgSleep = _getAverage(historical, (p) => p.sleepHours);
    final avgActivity = _getAverage(historical, (p) => p.activityLevel);
    final avgScreen = _getAverage(historical, (p) => p.screenTimeMinutes);

    if (current.sleepHours < avgSleep * 0.8) {
      indicators.add('Reducción de sueño (${(avgSleep - current.sleepHours).toStringAsFixed(1)}h menos)');
    }
    if (current.activityLevel > avgActivity * 1.3) {
      indicators.add('Aumento de actividad (${((current.activityLevel / avgActivity - 1) * 100).toStringAsFixed(0)}% más)');
    }
    if (current.screenTimeMinutes > avgScreen * 1.5) {
      indicators.add('Mayor tiempo de pantalla');
    }

    return indicators;
  }

  /// Obtener indicadores de estado depresivo
  List<String> _getDepressiveIndicators(
    PhenotypeDataPoint current,
    List<PhenotypeDataPoint> historical,
  ) {
    final indicators = <String>[];
    final avgSleep = _getAverage(historical, (p) => p.sleepHours);
    final avgActivity = _getAverage(historical, (p) => p.activityLevel);
    final avgSocial = _getAverage(historical, (p) => p.socialInteractionScore);

    if (current.sleepHours > avgSleep * 1.2) {
      indicators.add('Aumento de sueño (${(current.sleepHours - avgSleep).toStringAsFixed(1)}h más)');
    }
    if (current.activityLevel < avgActivity * 0.7) {
      indicators.add('Reducción de actividad');
    }
    if (current.socialInteractionScore < avgSocial * 0.6) {
      indicators.add('Menos interacción social');
    }

    return indicators;
  }

  double _getAverage(List<PhenotypeDataPoint> data, double Function(PhenotypeDataPoint) extractor) {
    if (data.isEmpty) return 0;
    return data.map(extractor).reduce((a, b) => a + b) / data.length;
  }

  // ========== MÉTODOS DE RECOPILACIÓN DE DATOS ==========
  // Estos son placeholders - en producción necesitarían integración real

  Future<double> _getSleepHours() async {
    // En producción: obtener de HealthKit / Google Fit
    return Random().nextDouble() * 4 + 5; // 5-9 horas aleatorio
  }

  Future<double> _getActivityLevel() async {
    // En producción: obtener de accelerómetro / pasos
    return Random().nextDouble() * 5 + 3; // 3-8 nivel aleatorio
  }

  Future<int> _getScreenTime() async {
    // En producción: obtener de UsageStatsManager
    return Random().nextInt(180) + 60; // 1-4 horas
  }

  Future<int> _getAppUsagePattern() async {
    // Número de cambios de app por hora
    return Random().nextInt(40) + 20;
  }

  Future<int> _getLocationChanges() async {
    // Cambios de ubicación significativos
    return Random().nextInt(5);
  }

  Future<double> _getSocialScore() async {
    // Puntuación de interacción social (llamadas, mensajes, etc.)
    return Random().nextDouble();
  }

  // ========== PERSISTENCIA ==========

  Future<void> _loadHistoricalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('phenotype_data');
    if (data != null) {
      _dataPoints = data
          .map((e) => PhenotypeDataPoint.fromJson(e))
          .where((p) => p.timestamp.isAfter(DateTime.now().subtract(Duration(days: 7))))
          .toList();
    }
  }

  Future<void> _saveHistoricalData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = _dataPoints
        .where((p) => p.timestamp.isAfter(DateTime.now().subtract(Duration(days: 7))))
        .map((p) => p.toJson())
        .toList();
    await prefs.setStringList('phenotype_data', jsonData);
  }

  /// Obtener datos históricos para análisis
  List<PhenotypeDataPoint> getHistoricalData({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _dataPoints.where((p) => p.timestamp.isAfter(cutoff)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Obtener estado actual estimado
  PhenotypeState getCurrentState() {
    if (_dataPoints.length < 10) return PhenotypeState.unknown;

    final last24Hours = getHistoricalData(days: 1);
    if (last24Hours.isEmpty) return PhenotypeState.unknown;

    final avgSleep = last24Hours.map((p) => p.sleepHours).reduce((a, b) => a + b) / last24Hours.length;
    final avgActivity = last24Hours.map((p) => p.activityLevel).reduce((a, b) => a + b) / last24Hours.length;

    // Estado baseline del usuario (promedio histórico)
    final baseline = getHistoricalData(days: 7);
    final baselineSleep = baseline.map((p) => p.sleepHours).reduce((a, b) => a + b) / baseline.length;
    final baselineActivity = baseline.map((p) => p.activityLevel).reduce((a, b) => a + b) / baseline.length;

    if (avgSleep < baselineSleep * 0.8 && avgActivity > baselineActivity * 1.3) {
      return PhenotypeState.elevated;
    } else if (avgSleep > baselineSleep * 1.2 && avgActivity < baselineActivity * 0.7) {
      return PhenotypeState.depressive;
    }

    return PhenotypeState.stable;
  }

  /// Dispose
  void dispose() {
    stopCollecting();
    _stateChangeStream.close();
  }
}

/// Evento de cambio de estado detectado
class StateChangeEvent {
  final DateTime timestamp;
  final PhenotypeState previousState;
  final PhenotypeState currentState;
  final double confidence;
  final List<String> indicators;

  StateChangeEvent({
    required this.timestamp,
    required this.previousState,
    required this.currentState,
    required this.confidence,
    required this.indicators,
  });
}

/// Estados posibles del fenotipo
enum PhenotypeState {
  stable,
  elevated,    // Hipomanía/manía
  depressive,  // Depresión
  mixed,
  unknown,
}
