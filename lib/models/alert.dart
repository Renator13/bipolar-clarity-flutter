import 'package:flutter/foundation.dart';

/// Alert type enumeration for different notification categories
enum AlertType {
  moodShift('Mood Shift', 'Significant change in mood detected'),
  sleepAlert('Sleep Alert', 'Sleep pattern disruption detected'),
  medicationReminder('Medication Reminder', 'Time for your medication'),
  patternAlert('Pattern Alert', 'New pattern detected in your data'),
  crisisAlert('Crisis Alert', 'Immediate attention may be needed'),
  weeklyInsight('Weekly Insight', 'Your weekly summary is ready'),
  checkInReminder('Check-In Reminder', 'Time for your daily mood check-in'),
  stabilityImprovement('Stability Improvement', 'Positive trends in your mood'),
  medicationEffectiveness('Medication Update', 'Track how medications affect you');

  final String title;
  final String description;

  const AlertType(this.title, this.description);
}

/// Priority level for alerts
enum AlertPriority {
  low('Low', Colors.blue),
  medium('Medium', Colors.orange),
  high('High', Colors.red),
  urgent('Urgent', Colors.purple);

  final String label;
  final Color color;

  const AlertPriority(this.label, this.color);
}

/// Represents an alert or notification for the user
/// Can be displayed in-app or sent as push notifications
class AlertModel {
  // Unique identifier for this alert
  final String id;
  
  // User ID this alert belongs to
  final String userId;
  
  // Type of alert
  final AlertType type;
  
  // Alert priority level
  final AlertPriority priority;
  
  // Alert title
  final String title;
  
  // Detailed alert message
  final String message;
  
  // Whether the alert has been read/dismissed
  final bool isRead;
  
  // Whether the alert has been actioned by the user
  final bool isActioned;
  
  // Optional action URL or deep link
  final String? actionUrl;
  
  // Optional metadata for additional context
  final Map<String, dynamic>? metadata;
  
  // Timestamp when the alert was created
  final DateTime createdAt;
  
  // Timestamp when the alert expires (if applicable)
  final DateTime? expiresAt;
  
  // Optional category for analytics
  final String? category;

  const AlertModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.isRead = false,
    this.isActioned = false,
    this.actionUrl,
    this.metadata,
    required this.createdAt,
    this.expiresAt,
    this.category,
  });

  /// Creates an AlertModel from Firestore data
  factory AlertModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AlertModel(
      id: id,
      userId: data['userId'] ?? '',
      type: _parseAlertType(data['type']),
      priority: _parseAlertPriority(data['priority']),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      isActioned: data['isActioned'] ?? false,
      actionUrl: data['actionUrl'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'])
          : null,
      category: data['category'],
    );
  }

  /// Converts AlertModel to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString(),
      'priority': priority.toString(),
      'title': title,
      'message': message,
      'isRead': isRead,
      'isActioned': isActioned,
      'actionUrl': actionUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'category': category,
    };
  }

  /// Creates a copy with modified fields
  AlertModel copyWith({
    String? id,
    String? userId,
    AlertType? type,
    AlertPriority? priority,
    String? title,
    String? message,
    bool? isRead,
    bool? isActioned,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? category,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      isActioned: isActioned ?? this.isActioned,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      category: category ?? this.category,
    );
  }

  /// Parses alert type from string
  static AlertType _parseAlertType(String? type) {
    if (type == null) return AlertType.patternAlert;
    switch (type) {
      case 'AlertType.moodShift':
        return AlertType.moodShift;
      case 'AlertType.sleepAlert':
        return AlertType.sleepAlert;
      case 'AlertType.medicationReminder':
        return AlertType.medicationReminder;
      case 'AlertType.patternAlert':
        return AlertType.patternAlert;
      case 'AlertType.crisisAlert':
        return AlertType.crisisAlert;
      case 'AlertType.weeklyInsight':
        return AlertType.weeklyInsight;
      case 'AlertType.checkInReminder':
        return AlertType.checkInReminder;
      case 'AlertType.stabilityImprovement':
        return AlertType.stabilityImprovement;
      case 'AlertType.medicationEffectiveness':
        return AlertType.medicationEffectiveness;
      default:
        return AlertType.patternAlert;
    }
  }

  /// Parses alert priority from string
  static AlertPriority _parseAlertPriority(String? priority) {
    if (priority == null) return AlertPriority.medium;
    switch (priority) {
      case 'AlertPriority.low':
        return AlertPriority.low;
      case 'AlertPriority.medium':
        return AlertPriority.medium;
      case 'AlertPriority.high':
        return AlertPriority.high;
      case 'AlertPriority.urgent':
        return AlertPriority.urgent;
      default:
        return AlertPriority.medium;
    }
  }

  /// Checks if the alert is still valid (not expired)
  bool get isValid {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Returns a formatted time string for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    // For older alerts, use a date format
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }
}

/// Represents a crisis alert with elevated urgency
/// Includes resources and immediate action steps
class CrisisAlert extends AlertModel {
  // Crisis helpline number
  final String? helplineNumber;
  
  // Immediate action steps for the user
  final List<String> actionSteps;
  
  // Whether emergency services have been contacted
  final bool emergencyContacted;
  
  // Trusted ally notification status
  final bool allyNotified;

  const CrisisAlert({
    required String id,
    required String userId,
    required String title,
    required String message,
    this.helplineNumber,
    required this.actionSteps,
    this.emergencyContacted = false,
    this.allyNotified = false,
    required DateTime createdAt,
    String? category,
  }) : super(
          id: id,
          userId: userId,
          type: AlertType.crisisAlert,
          priority: AlertPriority.urgent,
          title: title,
          message: message,
          isRead: false,
          isActioned: false,
          createdAt: createdAt,
          category: category ?? 'crisis',
        );

  /// Creates a CrisisAlert from base AlertModel
  factory CrisisAlert.fromAlertModel(AlertModel alert) {
    return CrisisAlert(
      id: alert.id,
      userId: alert.userId,
      title: alert.title,
      message: alert.message,
      helplineNumber: '988', // US Suicide Prevention Lifeline
      actionSteps: [
        'Take deep breaths and try to stay calm',
        'Remove access to any harmful items',
        'Call a trusted friend or family member',
        'Contact a crisis helpline',
        'Consider going to the nearest emergency room',
      ],
      createdAt: alert.createdAt,
      category: alert.category,
    );
  }

  /// Common crisis resources
  static const List<CrisisResource> resources = [
    CrisisResource(
      name: '988 Suicide & Crisis Lifeline',
      phone: '988',
      available: '24/7',
      description: 'Free and confidential support for people in distress',
    ),
    CrisisResource(
      name: 'Crisis Text Line',
      phone: 'Text HOME to 741741',
      available: '24/7',
      description: 'Free crisis counseling via text message',
    ),
    CrisisResource(
      name: 'International Association for Suicide Prevention',
      phone: 'Various',
      available: '24/7',
      description: 'Global crisis center directory',
      website: 'https://www.iasp.info/resources/Crisis_Centres/',
    ),
  ];
}

/// Crisis resource information
class CrisisResource {
  final String name;
  final String phone;
  final String available;
  final String description;
  final String? website;

  const CrisisResource({
    required this.name,
    required this.phone,
    required this.available,
    required this.description,
    this.website,
  });
}

/// Imports for color support
import 'package:flutter/material.dart';
