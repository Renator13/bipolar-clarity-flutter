import 'package:flutter/foundation.dart';
import 'mood_entry.dart';

/// Aggregated daily metrics for tracking patterns over time
/// Provides a summary of each day's mood, sleep, and other key metrics
class DailyMetrics {
  // Reference date for these metrics
  final DateTime date;
  
  // User ID these metrics belong to
  final String userId;
  
  // Average mood level for the day (0-10)
  final double averageMood;
  
  // Mood level at the end of the day
  final MoodLevel eveningMood;
  
  // Mood level at the start of the day
  final MoodLevel morningMood;
  
  // Total sleep duration in hours
  final double totalSleepHours;
  
  // Sleep quality rating (1-5)
  final int sleepQuality;
  
  // Time user went to bed
  final DateTime? bedTime;
  
  // Time user woke up
  final DateTime? wakeTime;
  
  // Energy level average (1-10)
  final double averageEnergy;
  
  // Anxiety level average (1-10)
  final double averageAnxiety;
  
  // Irritability level average (1-10)
  final double averageIrritability;
  
  // Number of mood entries for the day
  final int entryCount;
  
  // List of medications taken
  final List<String> medications;
  
  // List of activities completed
  final List<String> activities;
  
  // Notable triggers or factors
  final List<String> triggers;
  
  // Overall stability rating (0-100)
  /// Higher scores indicate more stable mood patterns
  final int stabilityScore;
  
  // Risk level assessment for the day
  final RiskLevel riskLevel;

  const DailyMetrics({
    required this.date,
    required this.userId,
    required this.averageMood,
    required this.eveningMood,
    required this.morningMood,
    required this.totalSleepHours,
    required this.sleepQuality,
    this.bedTime,
    this.wakeTime,
    required this.averageEnergy,
    required this.averageAnxiety,
    required this.averageIrritability,
    required this.entryCount,
    required this.medications,
    required this.activities,
    required this.triggers,
    required this.stabilityScore,
    required this.riskLevel,
  });

  /// Creates DailyMetrics from a list of MoodEntries
  /// Aggregates and calculates metrics from individual entries
  factory DailyMetrics.fromEntries(DateTime date, String userId, List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return DailyMetrics(
        date: date,
        userId: userId,
        averageMood: 5.0,
        eveningMood: MoodLevel.neutral,
        morningMood: MoodLevel.neutral,
        totalSleepHours: 7.0,
        sleepQuality: 3,
        averageEnergy: 5.0,
        averageAnxiety: 3.0,
        averageIrritability: 3.0,
        entryCount: 0,
        medications: [],
        activities: [],
        triggers: [],
        stabilityScore: 50,
        riskLevel: RiskLevel.low,
      );
    }

    // Calculate averages
    final double avgMood = entries.map((e) => e.moodLevel.value).reduce((a, b) => a + b) / entries.length;
    final double avgEnergy = entries.map((e) => e.energyLevel).reduce((a, b) => a + b) / entries.length;
    final double avgAnxiety = entries.map((e) => e.anxietyLevel).reduce((a, b) => a + b) / entries.length;
    final double avgIrritability = entries.map((e) => e.irritabilityLevel).reduce((a, b) => a + b) / entries.length;

    // Find first and last entries for morning/evening mood
    final sortedEntries = entries..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final morningMood = sortedEntries.first.moodLevel;
    final eveningMood = sortedEntries.last.moodLevel;

    // Calculate sleep metrics
    final sleepEntries = entries.where((e) => e.sleepHours > 0).toList();
    final totalSleep = sleepEntries.isNotEmpty
        ? sleepEntries.map((e) => e.sleepHours).reduce((a, b) => a + b) / sleepEntries.length
        : 7.0;
    final sleepQual = sleepEntries.isNotEmpty
        ? (sleepEntries.map((e) => e.sleepQuality).reduce((a, b) => a + b) / sleepEntries.length).round()
        : 3;

    // Aggregate medications, activities, and triggers
    final medications = {...entries.expand((e) => e.medications)}.toList()..sort();
    final activities = {...entries.expand((e) => e.activities)}.toList()..sort();
    final triggers = {...entries.expand((e) => e.triggers)}.toList()..sort();

    // Calculate stability score based on mood variance
    final moodVariance = _calculateVariance(entries.map((e) => e.moodLevel.value).toList());
    final stabilityScore = _calculateStabilityScore(moodVariance, totalSleep, avgAnxiety);

    // Determine risk level
    final riskLevel = _calculateRiskLevel(avgMood, moodVariance, totalSleep, avgAnxiety);

    return DailyMetrics(
      date: date,
      userId: userId,
      averageMood: avgMood,
      eveningMood: eveningMood,
      morningMood: morningMood,
      totalSleepHours: totalSleep,
      sleepQuality: sleepQual,
      averageEnergy: avgEnergy,
      averageAnxiety: avgAnxiety,
      averageIrritability: avgIrritability,
      entryCount: entries.length,
      medications: medications,
      activities: activities,
      triggers: triggers,
      stabilityScore: stabilityScore,
      riskLevel: riskLevel,
    );
  }

  /// Creates DailyMetrics from Firestore data
  factory DailyMetrics.fromFirestore(Map<String, dynamic> data, String id) {
    return DailyMetrics(
      date: DateTime.parse(data['date']),
      userId: data['userId'] ?? '',
      averageMood: (data['averageMood'] ?? 5.0).toDouble(),
      eveningMood: MoodLevel.fromValue(data['eveningMood'] ?? 5),
      morningMood: MoodLevel.fromValue(data['morningMood'] ?? 5),
      totalSleepHours: (data['totalSleepHours'] ?? 7.0).toDouble(),
      sleepQuality: data['sleepQuality'] ?? 3,
      bedTime: data['bedTime'] != null ? DateTime.parse(data['bedTime']) : null,
      wakeTime: data['wakeTime'] != null ? DateTime.parse(data['wakeTime']) : null,
      averageEnergy: (data['averageEnergy'] ?? 5.0).toDouble(),
      averageAnxiety: (data['averageAnxiety'] ?? 3.0).toDouble(),
      averageIrritability: (data['averageIrritability'] ?? 3.0).toDouble(),
      entryCount: data['entryCount'] ?? 0,
      medications: List<String>.from(data['medications'] ?? []),
      activities: List<String>.from(data['activities'] ?? []),
      triggers: List<String>.from(data['triggers'] ?? []),
      stabilityScore: data['stabilityScore'] ?? 50,
      riskLevel: RiskLevel.fromString(data['riskLevel'] ?? 'low'),
    );
  }

  /// Converts DailyMetrics to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'date': date.toIso8601String(),
      'userId': userId,
      'averageMood': averageMood,
      'eveningMood': eveningMood.value,
      'morningMood': morningMood.value,
      'totalSleepHours': totalSleepHours,
      'sleepQuality': sleepQuality,
      'bedTime': bedTime?.toIso8601String(),
      'wakeTime': wakeTime?.toIso8601String(),
      'averageEnergy': averageEnergy,
      'averageAnxiety': averageAnxiety,
      'averageIrritability': averageIrritability,
      'entryCount': entryCount,
      'medications': medications,
      'activities': activities,
      'triggers': triggers,
      'stabilityScore': stabilityScore,
      'riskLevel': riskLevel.toString(),
    };
  }

  /// Calculates variance of mood values
  static double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Calculates stability score (0-100)
  /// Based on mood variance, sleep, and anxiety
  static int _calculateStabilityScore(
    double moodVariance,
    double sleepHours,
    double anxietyLevel,
  ) {
    // Lower variance = higher stability
    final varianceScore = (10 - moodVariance.clamp(0, 10)) * 5;
    
    // Optimal sleep (7-9 hours) = higher stability
    final sleepScore = (10 - (sleepHours - 8).abs().clamp(0, 5)) * 3;
    
    // Lower anxiety = higher stability
    final anxietyScore = (10 - anxietyLevel) * 2;
    
    return ((varianceScore + sleepScore + anxietyScore) / 3).round().clamp(0, 100);
  }

  /// Calculates risk level based on various factors
  static RiskLevel _calculateRiskLevel(
    double avgMood,
    double moodVariance,
    double sleepHours,
    double anxietyLevel,
  ) {
    // High mood variance indicates instability
    if (moodVariance > 6) return RiskLevel.high;
    
    // Severe depression symptoms
    if (avgMood <= 2) return RiskLevel.high;
    
    // Severe mania symptoms
    if (avgMood >= 9) return RiskLevel.high;
    
    // Sleep deprivation (< 4 hours) increases risk
    if (sleepHours < 4) return RiskLevel.elevated;
    
    // High anxiety can indicate elevated risk
    if (anxietyLevel >= 8) return RiskLevel.elevated;
    
    // Moderate mood variance
    if (moodVariance > 3) return RiskLevel.moderate;
    
    // Low risk - stable mood patterns
    return RiskLevel.low;
  }

  /// Returns a human-readable summary of the day
  String get summary {
    return 'Mood: ${averageMood.toStringAsFixed(1)}/10 | Sleep: ${totalSleepHours.toStringAsFixed(1)}h | Stability: $stabilityScore%';
  }
}

/// Risk level for clinical assessment
enum RiskLevel {
  low('Low Risk', Colors.green),
  moderate('Moderate Risk', Colors.yellow),
  elevated('Elevated Risk', Colors.orange),
  high('High Risk', Colors.red);

  final String label;
  final Color color;

  const RiskLevel(this.label, this.color);

  /// Creates a RiskLevel from a string value
  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'moderate':
        return RiskLevel.moderate;
      case 'elevated':
        return RiskLevel.elevated;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }
}

/// Imports for color support
import 'package:flutter/material.dart';
