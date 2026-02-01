/// Modelo del Plan de Crisis / Safety Plan
class CrisisPlan {
  String id;
  String userId;
  List<CrisisContact> emergencyContacts;
  List<String> warningSigns;
  List<String> copingStrategies;
  List<String> environmentalChanges;
  List<String> socialContacts;
  List<String> professionalResources;
  String? preferredEmergencyService;
  DateTime createdAt;
  DateTime updatedAt;

  CrisisPlan({
    required this.id,
    required this.userId,
    required this.emergencyContacts,
    required this.warningSigns,
    required this.copingStrategies,
    required this.environmentalChanges,
    required this.socialContacts,
    required this.professionalResources,
    this.preferredEmergencyService,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear un plan vacío para nuevo usuario
  factory CrisisPlan.empty(String userId) {
    final now = DateTime.now();
    return CrisisPlan(
      id: '',
      userId: userId,
      emergencyContacts: [],
      warningSigns: [],
      copingStrategies: [],
      environmentalChanges: [],
      socialContacts: [],
      professionalResources: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
      'warningSigns': warningSigns,
      'copingStrategies': copingStrategies,
      'environmentalChanges': environmentalChanges,
      'socialContacts': socialContacts,
      'professionalResources': professionalResources,
      'preferredEmergencyService': preferredEmergencyService,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crear desde Map de Firestore
  factory CrisisPlan.fromMap(Map<String, dynamic> map) {
    return CrisisPlan(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      emergencyContacts: (map['emergencyContacts'] as List?)
              ?.map((e) => CrisisContact.fromMap(e))
              .toList() ??
          [],
      warningSigns: List<String>.from(map['warningSigns'] ?? []),
      copingStrategies: List<String>.from(map['copingStrategies'] ?? []),
      environmentalChanges: List<String>.from(map['environmentalChanges'] ?? []),
      socialContacts: List<String>.from(map['socialContacts'] ?? []),
      professionalResources: List<String>.from(map['professionalResources'] ?? []),
      preferredEmergencyService: map['preferredEmergencyService'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Clonar con modificaciones
  CrisisPlan copyWith({
    List<CrisisContact>? emergencyContacts,
    List<String>? warningSigns,
    List<String>? copingStrategies,
    List<String>? environmentalChanges,
    List<String>? socialContacts,
    List<String>? professionalResources,
    String? preferredEmergencyService,
  }) {
    return CrisisPlan(
      id: id,
      userId: userId,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      warningSigns: warningSigns ?? this.warningSigns,
      copingStrategies: copingStrategies ?? this.copingStrategies,
      environmentalChanges: environmentalChanges ?? this.environmentalChanges,
      socialContacts: socialContacts ?? this.socialContacts,
      professionalResources: professionalResources ?? this.professionalResources,
      preferredEmergencyService: preferredEmergencyService ?? this.preferredEmergencyService,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Contacto de emergencia
class CrisisContact {
  String id;
  String name;
  String relationship;
  String phone;
  String? email;
  bool isPrimary;
  bool isHealthcareProfessional;
  String? notes;
  int order;

  CrisisContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
    this.isPrimary = false,
    this.isHealthcareProfessional = false,
    this.notes,
    this.order = 0,
  });

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
      'isPrimary': isPrimary,
      'isHealthcareProfessional': isHealthcareProfessional,
      'notes': notes,
      'order': order,
    };
  }

  /// Crear desde Map
  factory CrisisContact.fromMap(Map<String, dynamic> map) {
    return CrisisContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      isPrimary: map['isPrimary'] ?? false,
      isHealthcareProfessional: map['isHealthcareProfessional'] ?? false,
      notes: map['notes'],
      order: map['order'] ?? 0,
    );
  }
}

/// Tipos de recursos profesionales
enum ProfessionalResourceType {
  psychiatrist('Psiquiatra'),
  psychologist('Psicólogo'),
  therapist('Terapeuta'),
  primaryCare('Médico de atención primaria'),
  crisisLine('Línea de crisis'),
  hospital('Hospital'),
  emergency('Emergencias 112/911');

  final String label;
  const ProfessionalResourceType(this.label);
}
