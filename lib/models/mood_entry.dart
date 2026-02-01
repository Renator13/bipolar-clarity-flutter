import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Mood level enumeration representing the bipolar spectrum
/// Ranges from severe depression (1) to severe mania (10)
enum MoodLevel {
  severeDepression(1, 'Severe Depression'),
  moderateDepression(2, 'Moderate Depression'),
  mildDepression(3, 'Mild Depression'),
  lowMood(4, 'Low Mood'),
  neutral(5, 'Neutral'),
  elevated(6, 'Elevated'),
  good(7, 'Good'),
  high(8, 'High'),
  manic(9, 'Manic'),
  severeMania(10, 'Severe Mania');

  final int value;
  final String label;

  const MoodLevel(this.value, this.label);

  /// Creates a MoodLevel from an integer value (1-10)
  factory MoodLevel.fromValue(int value) {
    return MoodLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => MoodLevel.neutral,
    );
  }

  /// Returns the category of mood for analytics
  MoodCategory get category {
    if (value <= 3) return MoodCategory.depression;
    if (value <= 6) return MoodCategory.stable;
    return MoodCategory.mania;
  }

  /// Returns a color associated with this mood level
  /// Used for visualizations and status indicators
  int get colorValue {
    switch (this) {
      case MoodLevel.severeDepression:
        return 0xFFB71C1C;
      case MoodLevel.moderateDepression:
        return 0xFFD32F2F;
      case MoodLevel.mildDepression:
        return 0xFFE57373;
      case MoodLevel.lowMood:
        return 0xFFFFB74D;
      case MoodLevel.neutral:
        return 0xFF4CAF50;
      case MoodLevel.elevated:
        return 0xFF81C784;
      case MoodLevel.good:
        return 0xFF64B5F6;
      case MoodLevel.high:
        return 0xFF2196F3;
      case MoodLevel.manic:
        return 0xFF3F51B5;
      case MoodLevel.severeMania:
        return 0xFF1A237E;
    }
  }
}

/// Mood category for high-level analytics
enum MoodCategory {
  depression,
  stable,
  mania,
}

/// Represents a single mood check-in entry
/// Contains mood level, associated symptoms, and contextual data
class MoodEntry {
  // Unique identifier for this entry
  final String id;
  
  // Reference to the user who created this entry
  final String userId;
  
  // The recorded mood level
  final MoodLevel moodLevel;
  
  // Optional note from the user
  final String? note;
  
  // Sleep duration in hours
  final double sleepHours;
  
  // Sleep quality rating (1-5)
  final int sleepQuality;
  
  // Medications taken today (list of medication names)
  final List<String> medications;
  
  // Activities completed today
  final List<String> activities;
  
  // Triggers or factors that may have influenced mood
  final List<String> triggers;
  
  // Energy level (1-10)
  final int energyLevel;
  
  // Anxiety level (1-10)
  final int anxietyLevel;
  
  // Irritability level (1-10)
  final int irritabilityLevel;
  
  // Whether this is a rapid check-in (5-second mode)
  final bool isQuickCheckIn;
  
  // Timestamp when this entry was created
  final DateTime timestamp;
  
  // Optional location data for the entry
  final LocationData? location;

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.moodLevel,
    this.note,
    required this.sleepHours,
    required this.sleepQuality,
    this.medications = const [],
    this.activities = const [],
    this.triggers = const [],
    required this.energyLevel,
    required this.anxietyLevel,
    required this.irritabilityLevel,
    this.isQuickCheckIn = false,
    required this.timestamp,
    this.location,
  });

  /// Creates a MoodEntry from a Firestore document
  factory MoodEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return MoodEntry(
      id: id,
      userId: data['userId'] ?? '',
      moodLevel: MoodLevel.fromValue(data['moodLevel'] ?? 5),
      note: data['note'],
      sleepHours: (data['sleepHours'] ?? 7.0).toDouble(),
      sleepQuality: data['sleepQuality'] ?? 3,
      medications: List<String>.from(data['medications'] ?? []),
      activities: List<String>.from(data['activities'] ?? []),
      triggers: List<String>.from(data['triggers'] ?? []),
      energyLevel: data['energyLevel'] ?? 5,
      anxietyLevel: data['anxietyLevel'] ?? 3,
      irritabilityLevel: data['irritabilityLevel'] ?? 3,
      isQuickCheckIn: data['isQuickCheckIn'] ?? false,
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      location: data['location'] != null
          ? LocationData.fromMap(data['location'])
          : null,
    );
  }

  /// Converts a MoodEntry to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'moodLevel': moodLevel.value,
      'note': note,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'medications': medications,
      'activities': activities,
      'triggers': triggers,
      'energyLevel': energyLevel,
      'anxietyLevel': anxietyLevel,
      'irritabilityLevel': irritabilityLevel,
      'isQuickCheckIn': isQuickCheckIn,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toMap(),
    };
  }

  /// Creates a copy of this MoodEntry with modified fields
  MoodEntry copyWith({
    String? id,
    String? userId,
    MoodLevel? moodLevel,
    String? note,
    double? sleepHours,
    int? sleepQuality,
    List<String>? medications,
    List<String>? activities,
    List<String>? triggers,
    int? energyLevel,
    int? anxietyLevel,
    int? irritabilityLevel,
    bool? isQuickCheckIn,
    DateTime? timestamp,
    LocationData? location,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodLevel: moodLevel ?? this.moodLevel,
      note: note ?? this.note,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      medications: medications ?? this.medications,
      activities: activities ?? this.activities,
      triggers: triggers ?? this.triggers,
      energyLevel: energyLevel ?? this.energyLevel,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      irritabilityLevel: irritabilityLevel ?? this.irritabilityLevel,
      isQuickCheckIn: isQuickCheckIn ?? this.isQuickCheckIn,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }

  /// Returns a formatted date string for display
  String get formattedDate {
    return DateFormat('EEEE, MMMM d, yyyy').format(timestamp);
  }

  /// Returns a formatted time string for display
  String get formattedTime {
    return DateFormat('h:mm a').format(timestamp);
  }

  /// Returns a short summary of the mood entry
  String get summary {
    return '${moodLevel.label} - Sleep: ${sleepHours}h';
  }
}

/// Optional location data for mood entries
/// Can help identify environmental factors affecting mood
class LocationData {
  // Latitude coordinate
  final double latitude;
  
  // Longitude coordinate
  final double longitude;
  
  // Optional location name or address
  final String? placeName;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.placeName,
  });

  /// Creates LocationData from a map
  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      placeName: map['placeName'],
    );
  }

  /// Converts LocationData to a map
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
    };
  }
}
