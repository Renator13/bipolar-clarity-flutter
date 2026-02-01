import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/digital_phenotype.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para recopilar y analizar datos de Digital Phenotyping
/// Los datos se envían a una colección ANÓNIMA separada para investigación
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
  static const int _usageFragmentationThreshold = 50;

  Timer? _collectionTimer;
  bool _isEnabled = false;
  bool _userConsent = false; // Consentimiento del usuario
  String? _anonymousId; // ID pseudo-anónimo único
  List<PhenotypeDataPoint> _dataPoints = [];

  final _stateChangeStream = StreamController<StateChangeEvent>.broadcast();
  Stream<StateChangeEvent> get onStateChange => _stateChangeStream.stream;

  /// Inicializar con consentimiento del usuario
  Future<void> initialize({required bool userConsent}) async {
    _userConsent = userConsent;
    await _loadOrGenerateAnonymousId();
  }

  /// Generar o cargar ID pseudo-anónimo
  Future<void> _loadOrGenerateAnonymousId() async {
    final prefs = await SharedPreferences.getInstance();
    _anonymousId = prefs.getString('phenotype_anonymous_id');
    
    if (_anonymousId == null) {
      // Generar ID aleatorio único
      _anonymousId = 'phenotype_${base64UrlEncode utf8.encode(DateTime.now().millisecondsSinceEpoch.toString())}_${Random.secure().nextInt(1000000)}';
      await prefs.setString('phenotype_anonymous_id', _anonymousId!);
    }
  }

  /// Iniciar recopilación (solo si hay consentimiento)
  Future<void> startCollecting() async {
    if (!_userConsent || _isEnabled) return;
    
    _isEnabled = true;
    _loadHistoricalData();
    
    _collectionTimer = Timer.periodic(
      _collectionInterval,
      (_) => _collectAndUploadData(),
    );
    
    await _collectAndUploadData();
  }

  /// Detener recopilación
  void stopCollecting() {
    _isEnabled = false;
    _collectionTimer?.cancel();
    _collectionTimer = null;
  }

  /// Recopilar datos y subir a colección ANÓNIMA
  Future<void> _collectAndUploadData() async {
    if (!_isEnabled || !_userConsent) return;

    final dataPoint = PhenotypeDataPoint(
      anonymousId: _anonymousId!, // ID pseudo-anónimo
      timestamp: DateTime.now(),
      sleepHours: await _getSleepHours(),
      activityLevel: await _getActivityLevel(),
      screenTimeMinutes: await _getScreenTime(),
      appUsagePattern: await _getAppUsagePattern(),
      locationChanges: await _getLocationChanges(),
      socialInteractionScore: await _getSocialScore(),
    );

    _dataPoints.add(dataPoint);
    _saveHistoricalDataLocal();

    // Subir a Firestore en colección ANÓNIMA
    await _uploadToAnonymizedCollection(dataPoint);

    // Analizar patrones localmente
    await _analyzePatterns(dataPoint);
  }

  /// Subir a colección separada y anonimizada
  Future<void> _uploadToAnonymizedCollection(PhenotypeDataPoint data) async {
    try {
      await FirebaseFirestore.instance
          .collection('anonymized_phenotypes')
          .doc(_anonymousId)
          .collection('data_points')
          .add(data.toAnonymizedJson());
    } catch (e) {
      print('Error uploading anonymized data: $e');
    }
  }

  /// Analizar patrones y detectar cambios
  Future<void> _analyzePatterns(PhenotypeDataPoint currentPoint) async {
    if (_dataPoints.length < 3) return;

    final last24Hours = _dataPoints
        .where((p) => p.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 24))))
        .toList();

    if (last24Hours.length < 10) return;

    final avgSleep = last24Hours.map((p) => p.sleepHours).reduce((a, b) => a + b) / last24Hours.length;
    final avgActivity = last24Hours.map((p) => p.activityLevel).reduce((a, b) => a + b) / last24Hours.length;
    final avgScreenTime = last24Hours.map((p) => p.screenTimeMinutes).reduce((a, b) => a + b) / last24Hours.length;

    StateChangeEvent? event;

    // Estado elevado
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
    // Estado depresivo
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

    if (event != null) {
      _stateChangeStream.add(event);
    }
  }

  double _calculateConfidence(PhenotypeDataPoint current, List<PhenotypeDataPoint> historical) {
    final sleepChange = (current.sleepHours - _getAverage(historical, (p) => p.sleepHours)) /
        _getAverage(historical, (p) => p.sleepHours);
    final activityChange = (current.activityLevel - _getAverage(historical, (p) => p.activityLevel)) /
        _getAverage(historical, (p) => p.activityLevel);

    final baseConfidence = min(0.9, 0.5 + (historical.length / 100));
    final changeBonus = min(0.2, (sleepChange.abs() + activityChange.abs()) * 0.1);

    return (baseConfidence + changeBonus).clamp(0.0, 1.0);
  }

  List<String> _getElevatedIndicators(PhenotypeDataPoint current, List<PhenotypeDataPoint> historical) {
    final indicators = <String>[];
    final avgSleep = _getAverage(historical, (p) => p.sleepHours);
    final avgActivity = _getAverage(historical, (p) => p.activityLevel);
    final avgScreen = _getAverage(historical, (p) => p.screenTimeMinutes);

    if (current.sleepHours < avgSleep * 0.8) {
      indicators.add('Reducción de sueño');
    }
    if (current.activityLevel > avgActivity * 1.3) {
      indicators.add('Aumento de actividad');
    }
    if (current.screenTimeMinutes > avgScreen * 1.5) {
      indicators.add('Mayor tiempo de pantalla');
    }

    return indicators;
  }

  List<String> _getDepressiveIndicators(PhenotypeDataPoint current, List<PhenotypeDataPoint> historical) {
    final indicators = <String>[];
    final avgSleep = _getAverage(historical, (p) => p.sleepHours);
    final avgActivity = _getAverage(historical, (p) => p.activityLevel);
    final avgSocial = _getAverage(historical, (p) => p.socialInteractionScore);

    if (current.sleepHours > avgSleep * 1.2) {
      indicators.add('Aumento de sueño');
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

  // ========== PLACEHOLDERS PARA DATOS ==========
  Future<double> _getSleepHours() async => Random().nextDouble() * 4 + 5;
  Future<double> _getActivityLevel() async => Random().nextDouble() * 5 + 3;
  Future<int> _getScreenTime() async => Random().nextInt(180) + 60;
  Future<int> _getAppUsagePattern() async => Random().nextInt(40) + 20;
  Future<int> _getLocationChanges() async => Random().nextInt(5);
  Future<double> _getSocialScore() async => Random().nextDouble();

  // ========== PERSISTENCIA LOCAL ==========
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

  Future<void> _saveHistoricalDataLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = _dataPoints
        .where((p) => p.timestamp.isAfter(DateTime.now().subtract(Duration(days: 7))))
        .map((p) => p.toJson())
        .toList();
    await prefs.setStringList('phenotype_data', jsonData);
  }

  List<PhenotypeDataPoint> getHistoricalData({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _dataPoints.where((p) => p.timestamp.isAfter(cutoff)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  PhenotypeState getCurrentState() {
    if (_dataPoints.length < 10) return PhenotypeState.unknown;

    final last24Hours = getHistoricalData(days: 1);
    if (last24Hours.isEmpty) return PhenotypeState.unknown;

    final avgSleep = last24Hours.map((p) => p.sleepHours).reduce((a, b) => a + b) / last24Hours.length;
    final avgActivity = last24Hours.map((p) => p.activityLevel).reduce((a, b) => a + b) / last24Hours.length;

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
