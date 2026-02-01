/// Modelo de Trusted Ally - Contacto de confianza
class TrustedAlly {
  String id;
  String userId;          // Usuario que comparte el estado
  String allyId;          // Contacto que recibe notificaciones
  String? allyName;
  String? allyEmail;
  String? allyPhone;
  TrustLevel trustLevel;
  AllyStatus status;
  NotificationSettings notificationSettings;
  DateTime createdAt;
  DateTime? lastNotifiedAt;

  TrustedAlly({
    required this.id,
    required this.userId,
    required this.allyId,
    this.allyName,
    this.allyEmail,
    this.allyPhone,
    this.trustLevel = TrustLevel.medium,
    this.status = AllyStatus.pending,
    required this.notificationSettings,
    required this.createdAt,
    this.lastNotifiedAt,
  });

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'allyId': allyId,
      'allyName': allyName,
      'allyEmail': allyEmail,
      'allyPhone': allyPhone,
      'trustLevel': trustLevel.index,
      'status': status.index,
      'notificationSettings': notificationSettings.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
    };
  }

  /// Crear desde Map de Firestore
  factory TrustedAlly.fromMap(Map<String, dynamic> map) {
    return TrustedAlly(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      allyId: map['allyId'] ?? '',
      allyName: map['allyName'],
      allyEmail: map['allyEmail'],
      allyPhone: map['allyPhone'],
      trustLevel: TrustLevel.values[map['trustLevel'] ?? 1],
      status: AllyStatus.values[map['status'] ?? 0],
      notificationSettings: map['notificationSettings'] != null
          ? NotificationSettings.fromMap(map['notificationSettings'])
          : NotificationSettings(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastNotifiedAt: map['lastNotifiedAt'] != null
          ? DateTime.parse(map['lastNotifiedAt'])
          : null,
    );
  }

  /// Clonar con modificaciones
  TrustedAlly copyWith({
    String? allyName,
    String? allyEmail,
    String? allyPhone,
    TrustLevel? trustLevel,
    AllyStatus? status,
    NotificationSettings? notificationSettings,
    DateTime? lastNotifiedAt,
  }) {
    return TrustedAlly(
      id: id,
      userId: userId,
      allyId: allyId,
      allyName: allyName ?? this.allyName,
      allyEmail: allyEmail ?? this.allyEmail,
      allyPhone: allyPhone ?? this.allyPhone,
      trustLevel: trustLevel ?? this.trustLevel,
      status: status ?? this.status,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      createdAt: createdAt,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
    );
  }

  /// ¿Está activo para recibir notificaciones?
  bool get isActive => status == AllyStatus.active;
}

/// Nivel de confianza
enum TrustLevel {
  low,      // Solo notificaciones básicas
  medium,   // Notificaciones estándar
  high,     // Notificaciones urgentes + llamada automática
  maximum,  // Acceso completo + emergencia inmediata
}

/// Estado del aliado
enum AllyStatus {
  pending,   // Esperando aceptación
  active,    // Activo
  paused,    // Pausado temporalmente
  blocked,   // Bloqueado
}

/// Configuración de notificaciones por tipo de alerta
class NotificationSettings {
  bool notifyOnStable;      // Estado estable
  bool notifyOnWarning;     // Señales de advertencia
  bool notifyOnElevated;    // Estado elevado (hipomanía)
  bool notifyOnHighRisk;    // Alto riesgo
  bool notifyOnCrisis;      // Crisis activa
  bool allowCall;           // Permitir llamada automática
  int callDelayMinutes;     // Minutos antes de llamar automáticamente (0 =disabled)

  NotificationSettings({
    this.notifyOnStable = false,
    this.notifyOnWarning = true,
    this.notifyOnElevated = true,
    this.notifyOnHighRisk = true,
    this.notifyOnCrisis = true,
    this.allowCall = false,
    this.callDelayMinutes = 0,
  });

  /// ¿Debe notificar para este tipo de alerta?
  bool enabledForType(AlertType type) {
    switch (type) {
      case AlertType.stable: return notifyOnStable;
      case AlertType.warning: return notifyOnWarning;
      case AlertType.elevated: return notifyOnElevated;
      case AlertType.highRisk: return notifyOnHighRisk;
      case AlertType.crisis: return notifyOnCrisis;
    }
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'notifyOnStable': notifyOnStable,
      'notifyOnWarning': notifyOnWarning,
      'notifyOnElevated': notifyOnElevated,
      'notifyOnHighRisk': notifyOnHighRisk,
      'notifyOnCrisis': notifyOnCrisis,
      'allowCall': allowCall,
      'callDelayMinutes': callDelayMinutes,
    };
  }

  /// Crear desde Map
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      notifyOnStable: map['notifyOnStable'] ?? false,
      notifyOnWarning: map['notifyOnWarning'] ?? true,
      notifyOnElevated: map['notifyOnElevated'] ?? true,
      notifyOnHighRisk: map['notifyOnHighRisk'] ?? true,
      notifyOnCrisis: map['notifyOnCrisis'] ?? true,
      allowCall: map['allowCall'] ?? false,
      callDelayMinutes: map['callDelayMinutes'] ?? 0,
    );
  }
}

/// Tipo de alerta
enum AlertType {
  stable,      // Estado estable/normal
  warning,     // Señales de advertencia detectadas
  elevated,    // Estado elevado (hipomanía/manía)
  highRisk,    // Alto riesgo (pensamientos autodañivos)
  crisis,      // Crisis activa (necesita ayuda inmediata)
}

/// Notificación enviada a un aliado
class AllyNotification {
  String id;
  String userId;
  String allyId;
  AlertType alertType;
  double? moodScore;
  DateTime timestamp;
  String? customMessage;
  bool isRead;

  AllyNotification({
    required this.id,
    required this.userId,
    required this.allyId,
    required this.alertType,
    this.moodScore,
    required this.timestamp,
    this.customMessage,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'allyId': allyId,
      'alertType': alertType.index,
      'moodScore': moodScore,
      'timestamp': timestamp.toIso8601String(),
      'customMessage': customMessage,
      'isRead': isRead,
    };
  }

  factory AllyNotification.fromMap(Map<String, dynamic> map) {
    return AllyNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      allyId: map['allyId'] ?? '',
      alertType: AlertType.values[map['alertType'] ?? 0],
      moodScore: map['moodScore'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      customMessage: map['customMessage'],
      isRead: map['isRead'] ?? false,
    );
  }
}
