/// Modelo de datos para Digital Phenotyping
/// Representa un punto de datos anonimizado para investigación
class PhenotypeDataPoint {
  final String id;
  final String anonymousId; // ID pseudo-anónimo (NO datos personales)
  final DateTime timestamp;
  final double sleepHours;
  final double activityLevel;
  final int screenTimeMinutes;
  final int appUsagePattern;
  final int locationChanges;
  final double socialInteractionScore;

  PhenotypeDataPoint({
    String? id,
    required this.anonymousId,
    required this.timestamp,
    required this.sleepHours,
    required this.activityLevel,
    required this.screenTimeMinutes,
    required this.appUsagePattern,
    required this.locationChanges,
    required this.socialInteractionScore,
  }) : id = id ?? '${timestamp.millisecondsSinceEpoch}_${DateTime.now().hashCode}';

  /// Convertir a JSON para almacenamiento local (con anonymousId)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anonymousId': anonymousId,
      'timestamp': timestamp.toIso8601String(),
      'sleepHours': sleepHours,
      'activityLevel': activityLevel,
      'screenTimeMinutes': screenTimeMinutes,
      'appUsagePattern': appUsagePattern,
      'locationChanges': locationChanges,
      'socialInteractionScore': socialInteractionScore,
    };
  }

  /// Convertir a JSON ANONIMIZADO para Firestore (sin datos personales)
  Map<String, dynamic> toAnonymizedJson() {
    return {
      'anonymousId': anonymousId, // ID pseudo-anónimo solo
      'timestamp': timestamp.toIso8601String(),
      'sleepHours': sleepHours,
      'activityLevel': activityLevel,
      'screenTimeMinutes': screenTimeMinutes,
      'appUsagePattern': appUsagePattern,
      'locationChanges': locationChanges,
      'socialInteractionScore': socialInteractionScore,
      // SIN: email, nombre, teléfono, o cualquier dato personal
    };
  }

  /// Crear desde JSON local
  factory PhenotypeDataPoint.fromJson(String jsonStr) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(jsonStr));
    return PhenotypeDataPoint(
      id: map['id'],
      anonymousId: map['anonymousId'],
      timestamp: DateTime.parse(map['timestamp']),
      sleepHours: map['sleepHours'].toDouble(),
      activityLevel: map['activityLevel'].toDouble(),
      screenTimeMinutes: map['screenTimeMinutes'],
      appUsagePattern: map['appUsagePattern'],
      locationChanges: map['locationChanges'],
      socialInteractionScore: map['socialInteractionScore'].toDouble(),
    );
  }

  /// Clonar con modificaciones
  PhenotypeDataPoint copyWith({
    String? id,
    String? anonymousId,
    DateTime? timestamp,
    double? sleepHours,
    double? activityLevel,
    int? screenTimeMinutes,
    int? appUsagePattern,
    int? locationChanges,
    double? socialInteractionScore,
  }) {
    return PhenotypeDataPoint(
      id: id ?? this.id,
      anonymousId: anonymousId ?? this.anonymousId,
      timestamp: timestamp ?? this.timestamp,
      sleepHours: sleepHours ?? this.sleepHours,
      activityLevel: activityLevel ?? this.activityLevel,
      screenTimeMinutes: screenTimeMinutes ?? this.screenTimeMinutes,
      appUsagePattern: appUsagePattern ?? this.appUsagePattern,
      locationChanges: locationChanges ?? this.locationChanges,
      socialInteractionScore: socialInteractionScore ?? this.socialInteractionScore,
    );
  }
}

/// Resumen semanal de fenotipo para mostrar en UI
class WeeklyPhenotypeSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double avgSleep;
  final double avgActivity;
  final int avgScreenTime;
  final List<String> detectedPatterns;
  final PhenotypeState dominantState;
  final List<StateChangeEvent> stateChanges;

  WeeklyPhenotypeSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.avgSleep,
    required this.avgActivity,
    required this.avgScreenTime,
    required this.detectedPatterns,
    required this.dominantState,
    required this.stateChanges,
  });

  factory WeeklyPhenotypeSummary.fromDataPoints(List<PhenotypeDataPoint> dataPoints) {
    if (dataPoints.isEmpty) {
      return WeeklyPhenotypeSummary(
        weekStart: DateTime.now(),
        weekEnd: DateTime.now(),
        avgSleep: 0,
        avgActivity: 0,
        avgScreenTime: 0,
        detectedPatterns: [],
        dominantState: PhenotypeState.unknown,
        stateChanges: [],
      );
    }

    dataPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final weekStart = dataPoints.first.timestamp;
    final weekEnd = dataPoints.last.timestamp;

    final avgSleep = dataPoints.map((p) => p.sleepHours).reduce((a, b) => a + b) / dataPoints.length;
    final avgActivity = dataPoints.map((p) => p.activityLevel).reduce((a, b) => a + b) / dataPoints.length;
    final avgScreenTime = (dataPoints.map((p) => p.screenTimeMinutes).reduce((a, b) => a + b) / dataPoints.length).round();

    // Determinar estado dominante
    final elevatedCount = dataPoints.where((p) => p.activityLevel > 7 && p.sleepHours < 6).length;
    final depressiveCount = dataPoints.where((p) => p.activityLevel < 4 && p.sleepHours > 8).length;

    PhenotypeState dominantState;
    if (elevatedCount > dataPoints.length * 0.3) {
      dominantState = PhenotypeState.elevated;
    } else if (depressiveCount > dataPoints.length * 0.3) {
      dominantState = PhenotypeState.depressive;
    } else {
      dominantState = PhenotypeState.stable;
    }

    // Patrones detectados
    final patterns = <String>[];
    if (avgSleep < 6) patterns.add('Patrón de sueño reducido');
    if (avgSleep > 9) patterns.add('Posible hipersomnia');
    if (avgActivity > 7) patterns.add('Nivel de actividad elevado');
    if (avgActivity < 4) patterns.add('Reducción de actividad');
    if (avgScreenTime > 240) patterns.add('Alto tiempo de pantalla');

    return WeeklyPhenotypeSummary(
      weekStart: weekStart,
      weekEnd: weekEnd,
      avgSleep: avgSleep,
      avgActivity: avgActivity,
      avgScreenTime: avgScreenTime,
      detectedPatterns: patterns,
      dominantState: dominantState,
      stateChanges: [],
    );
  }
}
