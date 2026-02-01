import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/mood_entry.dart';
import '../models/daily_metrics.dart';
import '../models/alert.dart';

/// Firestore Database Service
/// Handles all database operations for the Bipolar Clarity app
/// Provides CRUD operations for users, mood entries, and analytics
class FirestoreService extends ChangeNotifier {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _moodEntriesCollection => _firestore.collection('moodEntries');
  CollectionReference get _dailyMetricsCollection => _firestore.collection('dailyMetrics');
  CollectionReference get _alertsCollection => _firestore.collection('alerts');

  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== USER OPERATIONS ====================

  /// Creates a new user document in Firestore
  /// Called after successful Firebase Auth registration
  Future<bool> createUser(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _usersCollection.doc(user.id).set(user.toFirestore());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create user: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetches a user document from Firestore
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to fetch user: $e';
      return null;
    }
  }

  /// Updates a user document in Firestore
  Future<bool> updateUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _usersCollection.doc(user.id).update(user.toFirestore());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update user: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates the user's last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to update last active: $e');
    }
  }

  /// Updates the user's onboarding status
  Future<bool> completeOnboarding(String userId) async {
    return updateField(userId, 'hasCompletedOnboarding', true);
  }

  /// Updates the user's consent status
  Future<bool> provideConsent(String userId) async {
    return updateField(userId, 'hasProvidedConsent', true);
  }

  /// Generic method to update a single field in user document
  Future<bool> updateField(String userId, String field, dynamic value) async {
    try {
      await _usersCollection.doc(userId).update({field: value});
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update field: $e';
      return false;
    }
  }

  // ==================== MOOD ENTRY OPERATIONS ====================

  /// Creates a new mood entry
  /// Automatically updates daily metrics
  Future<bool> createMoodEntry(MoodEntry entry) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create the mood entry document
      final docRef = await _moodEntriesCollection.add(entry.toFirestore());
      
      // Update the entry with its generated ID
      await docRef.update({'id': docRef.id});
      
      // Recalculate and update daily metrics
      await _recalculateDailyMetrics(entry.userId, entry.timestamp);
      
      // Check for alerts based on the new entry
      await _checkForAlerts(entry);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create mood entry: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetches a mood entry by ID
  Future<MoodEntry?> getMoodEntry(String entryId) async {
    try {
      final doc = await _moodEntriesCollection.doc(entryId).get();
      if (doc.exists) {
        return MoodEntry.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to fetch mood entry: $e';
      return null;
    }
  }

  /// Fetches all mood entries for a user
  /// Optionally filter by date range
  Future<List<MoodEntry>> getMoodEntries({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _moodEntriesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MoodEntry.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to fetch mood entries: $e';
      return [];
    }
  }

  /// Updates an existing mood entry
  Future<bool> updateMoodEntry(MoodEntry entry) async {
    try {
      await _moodEntriesCollection.doc(entry.id).update(entry.toFirestore());
      await _recalculateDailyMetrics(entry.userId, entry.timestamp);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update mood entry: $e';
      return false;
    }
  }

  /// Deletes a mood entry
  Future<bool> deleteMoodEntry(String entryId, String userId, DateTime timestamp) async {
    try {
      await _moodEntriesCollection.doc(entryId).delete();
      await _recalculateDailyMetrics(userId, timestamp);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete mood entry: $e';
      return false;
    }
  }

  // ==================== DAILY METRICS OPERATIONS ====================

  /// Recalculates daily metrics for a specific date
  /// Called after mood entry creation/update/deletion
  Future<void> _recalculateDailyMetrics(String userId, DateTime date) async {
    try {
      // Get all entries for the date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final entries = await getMoodEntries(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Calculate metrics
      final metrics = DailyMetrics.fromEntries(startOfDay, userId, entries);
      
      // Save to Firestore
      await _dailyMetricsCollection.doc('${userId}_${startOfDay.toIso8601String().split('T')[0]}')
          .set(metrics.toFirestore());
    } catch (e) {
      debugPrint('Failed to recalculate daily metrics: $e');
    }
  }

  /// Fetches daily metrics for a date range
  Future<List<DailyMetrics>> getDailyMetrics({
    required String userId,
    required int days,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final snapshot = await _dailyMetricsCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DailyMetrics.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to fetch daily metrics: $e';
      return [];
    }
  }

  /// Gets the most recent daily metrics
  Future<DailyMetrics?> getLatestDailyMetrics(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final snapshot = await _dailyMetricsCollection
          .doc('${userId}_${startOfDay.toIso8601String().split('T')[0]}')
          .get();

      if (snapshot.exists) {
        return DailyMetrics.fromFirestore(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to fetch latest metrics: $e';
      return null;
    }
  }

  // ==================== ALERT OPERATIONS ====================

  /// Creates a new alert
  Future<bool> createAlert(AlertModel alert) async {
    try {
      await _alertsCollection.add(alert.toFirestore());
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create alert: $e';
      return false;
    }
  }

  /// Fetches unread alerts for a user
  Future<List<AlertModel>> getUnreadAlerts(String userId) async {
    try {
      final snapshot = await _alertsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AlertModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((alert) => alert.isValid)
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to fetch alerts: $e';
      return [];
    }
  }

  /// Marks an alert as read
  Future<bool> markAlertAsRead(String alertId) async {
    try {
      await _alertsCollection.doc(alertId).update({'isRead': true});
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Marks all alerts as read for a user
  Future<bool> markAllAlertsAsRead(String userId) async {
    try {
      final snapshot = await _alertsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark alerts as read: $e';
      return false;
    }
  }

  /// Checks for alerts based on mood entry data
  Future<void> _checkForAlerts(MoodEntry entry) async {
    // Mood shift detection
    final recentEntries = await getMoodEntries(
      userId: entry.userId,
      startDate: DateTime.now().subtract(const Duration(days: 3)),
    );

    if (recentEntries.length >= 2) {
      final moodDiff = (entry.moodLevel.value - recentEntries[1].moodLevel.value).abs();
      
      // Significant mood shift detected
      if (moodDiff >= 4) {
        await createAlert(AlertModel(
          id: '', // Will be generated by Firestore
          userId: entry.userId,
          type: AlertType.moodShift,
          priority: moodDiff >= 6 ? AlertPriority.high : AlertPriority.medium,
          title: 'Significant Mood Shift Detected',
          message: 'Your mood has changed significantly since your last check-in. Consider noting any factors that might have contributed to this change.',
          createdAt: DateTime.now(),
          actionUrl: '/insights',
        ));
      }
    }

    // Sleep alert
    if (entry.sleepHours < 5) {
      await createAlert(AlertModel(
        id: '',
        userId: entry.userId,
        type: AlertType.sleepAlert,
        priority: entry.sleepHours < 3 ? AlertPriority.high : AlertPriority.medium,
        title: 'Low Sleep Detected',
        message: 'You reported less than ${entry.sleepHours.round()} hours of sleep. Poor sleep can significantly impact mood stability.',
        createdAt: DateTime.now(),
        actionUrl: '/insights',
      ));
    }
  }

  // ==================== EMERGENCY CONTACT OPERATIONS ====================

  /// Updates the user's emergency contact
  Future<bool> updateEmergencyContact(String userId, EmergencyContact contact) async {
    try {
      await _usersCollection.doc(userId).update({
        'emergencyContact': contact.toMap(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update emergency contact: $e';
      return false;
    }
  }

  // ==================== ADMIN OPERATIONS (For René) ====================

  /// Fetches anonymized analytics for all users
  /// Only accessible by admin users
  Future<List<DailyMetrics>> getAllUsersAnalytics({
    required int days,
  }) async {
    try {
      // This would typically be secured with Firestore security rules
      // to only allow admin access
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final snapshot = await _dailyMetricsCollection
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DailyMetrics.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to fetch analytics: $e';
      return [];
    }
  }

  /// Clears the error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
