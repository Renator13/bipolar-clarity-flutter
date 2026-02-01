import 'package:flutter/foundation.dart';

/// User model representing the authenticated user's profile data
/// This model is stored in Firestore and synced with Firebase Auth
class UserModel {
  // Unique user identifier from Firebase Auth
  final String id;
  
  // User's email address from Firebase Auth
  final String email;
  
  // User's display name
  final String? displayName;
  
  // User's profile photo URL
  final String? photoUrl;
  
  // Whether the user has completed onboarding
  final bool hasCompletedOnboarding;
  
  // Whether the user has provided consent for data processing
  final bool hasProvidedConsent;
  
  // User's selected theme preference
  final ThemeMode themeMode;
  
  // User's preferred notification settings
  final NotificationSettings notificationSettings;
  
  // Emergency contact information
  final EmergencyContact? emergencyContact;
  
  // User's timezone for proper time-based features
  final String timezone;
  
  // Timestamp when the user account was created
  final DateTime createdAt;
  
  // Timestamp of the last user activity
  final DateTime lastActiveAt;

  // Constructor with required and optional fields
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.hasCompletedOnboarding = false,
    this.hasProvidedConsent = false,
    this.themeMode = ThemeMode.system,
    required this.notificationSettings,
    this.emergencyContact,
    required this.timezone,
    required this.createdAt,
    required this.lastActiveAt,
  });

  /// Creates a UserModel from a Firestore document snapshot
  /// Parses the document data into a structured model object
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
      hasProvidedConsent: data['hasProvidedConsent'] ?? false,
      themeMode: _parseThemeMode(data['themeMode']),
      notificationSettings: NotificationSettings.fromMap(
        data['notificationSettings'] ?? {},
      ),
      emergencyContact: data['emergencyContact'] != null
          ? EmergencyContact.fromMap(data['emergencyContact'])
          : null,
      timezone: data['timezone'] ?? 'UTC',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      lastActiveAt: data['lastActiveAt'] != null
          ? DateTime.parse(data['lastActiveAt'])
          : DateTime.now(),
    );
  }

  /// Converts the UserModel to a Firestore-compatible Map
  /// Used for saving user data to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasProvidedConsent': hasProvidedConsent,
      'themeMode': themeMode.toString(),
      'notificationSettings': notificationSettings.toMap(),
      'emergencyContact': emergencyContact?.toMap(),
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  /// Creates a copy of this UserModel with modified fields
  /// Useful for immutable updates in state management
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? hasCompletedOnboarding,
    bool? hasProvidedConsent,
    ThemeMode? themeMode,
    NotificationSettings? notificationSettings,
    EmergencyContact? emergencyContact,
    String? timezone,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasProvidedConsent: hasProvidedConsent ?? this.hasProvidedConsent,
      themeMode: themeMode ?? this.themeMode,
      notificationSettings:
          notificationSettings ?? this.notificationSettings,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Parses theme mode string from Firestore to ThemeMode enum
  static ThemeMode _parseThemeMode(String? mode) {
    switch (mode) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

/// User notification preferences
/// Controls which notifications the user receives and when
class NotificationSettings {
  // Enable daily mood check-in reminders
  final bool dailyCheckInReminder;
  
  // Time of day for check-in reminders (24-hour format)
  final int checkInHour;
  
  // Enable medication reminders
  final bool medicationReminders;
  
  // Enable pattern alerts (mood changes, sleep disruptions)
  final bool patternAlerts;
  
  // Enable emergency contact notifications
  final bool emergencyContactAlerts;
  
  // Enable weekly insights reports
  final bool weeklyInsights;

  const NotificationSettings({
    this.dailyCheckInReminder = true,
    this.checkInHour = 20,
    this.medicationReminders = true,
    this.patternAlerts = true,
    this.emergencyContactAlerts = true,
    this.weeklyInsights = true,
  });

  /// Creates NotificationSettings from a Firestore map
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      dailyCheckInReminder: map['dailyCheckInReminder'] ?? true,
      checkInHour: map['checkInHour'] ?? 20,
      medicationReminders: map['medicationReminders'] ?? true,
      patternAlerts: map['patternAlerts'] ?? true,
      emergencyContactAlerts: map['emergencyContactAlerts'] ?? true,
      weeklyInsights: map['weeklyInsights'] ?? true,
    );
  }

  /// Converts NotificationSettings to a Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'dailyCheckInReminder': dailyCheckInReminder,
      'checkInHour': checkInHour,
      'medicationReminders': medicationReminders,
      'patternAlerts': patternAlerts,
      'emergencyContactAlerts': emergencyContactAlerts,
      'weeklyInsights': weeklyInsights,
    };
  }
}

/// Emergency contact information for crisis situations
/// Allows trusted allies to be notified when needed
class EmergencyContact {
  // Contact's full name
  final String name;
  
  // Contact's phone number in international format
  final String phoneNumber;
  
  // Contact's relationship to the user
  final String relationship;
  
  // Optional email for additional contact method
  final String? email;
  
  // Whether this contact has been verified
  final bool isVerified;
  
  // Timestamp when the contact was added
  final DateTime addedAt;

  const EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.email,
    this.isVerified = false,
    required this.addedAt,
  });

  /// Creates EmergencyContact from a Firestore map
  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
      email: map['email'],
      isVerified: map['isVerified'] ?? false,
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'])
          : DateTime.now(),
    );
  }

  /// Converts EmergencyContact to a Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'email': email,
      'isVerified': isVerified,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}
