import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'models/trusted_ally.dart';
import 'models/mood_entry.dart';

/// Servicio para gestionar Trusted Allies - contactos de confianza
class TrustedAllyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'trusted_allies';
  static const String _notificationsCollection = 'ally_notifications';

  /// Obtener todos los aliados de confianza de un usuario
  static Future<List<TrustedAlly>> getAllies(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt')
          .get();
      
      return snapshot.docs.map((doc) => TrustedAlly.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting allies: $e');
      return [];
    }
  }

  /// Añadir un nuevo aliado de confianza
  static Future<bool> addAlly(TrustedAlly ally) async {
    try {
      await _firestore.collection(_collection).doc(ally.id).set(ally.toMap());
      return true;
    } catch (e) {
      print('Error adding ally: $e');
      return false;
    }
  }

  /// Eliminar un aliado
  static Future<bool> removeAlly(String userId, String allyId) async {
    try {
      await _firestore.collection(_collection).doc(allyId).delete();
      return true;
    } catch (e) {
      print('Error removing ally: $e');
      return false;
    }
  }

  /// Actualizar configuración de notificaciones de un aliado
  static Future<bool> updateAllySettings(
    String allyId,
    NotificationSettings settings,
  ) async {
    try {
      await _firestore.collection(_collection).doc(allyId).update({
        'notificationSettings': settings.toMap(),
      });
      return true;
    } catch (e) {
      print('Error updating ally settings: $e');
      return false;
    }
  }

  /// Notificar a un aliado sobre un cambio de estado
  static Future<void> notifyAlly({
    required String userId,
    required String allyId,
    required MoodEntry moodEntry,
    required AlertType alertType,
    String? customMessage,
  }) async {
    try {
      final notification = AllyNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}_$allyId',
        userId: userId,
        allyId: allyId,
        alertType: alertType,
        moodScore: moodEntry.moodScore,
        timestamp: DateTime.now(),
        customMessage: customMessage,
        isRead: false,
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      print('Error notifying ally: $e');
    }
  }

  /// Notificar a TODOS los aliados cuando hay un estado de alerta
  static Future<void> notifyAllAllies({
    required String userId,
    required MoodEntry moodEntry,
    required AlertType alertType,
    String? customMessage,
  }) async {
    final allies = await getAllies(userId);
    
    for (final ally in allies) {
      if (ally.notificationSettings.enabledForType(alertType)) {
        await notifyAlly(
          userId: userId,
          allyId: ally.id,
          moodEntry: moodEntry,
          alertType: alertType,
          customMessage: customMessage,
        );
      }
    }
  }

  /// Obtener historial de notificaciones enviadas
  static Future<List<AllyNotification>> getNotificationHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => AllyNotification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }

  /// Obtener aliados por nivel de confianza
  static Future<List<TrustedAlly>> getAlliesByTrustLevel(
    String userId,
    TrustLevel level,
  ) async {
    final allies = await getAllies(userId);
    return allies.where((ally) => ally.trustLevel == level).toList();
  }

  /// Verificar si hay aliados activos
  static Future<bool> hasActiveAllies(String userId) async {
    final allies = await getAllies(userId);
    return allies.any((ally) => ally.isActive);
  }

  /// Generar enlace de invitación para nuevo aliado
  static Future<String> generateInviteLink(String userId) async {
    final token = base64UrlEncode(utf8.encode('$userId:${DateTime.now().millisecondsSinceEpoch}'));
    return 'bipolarclarity://invite/$token';
  }

  /// Aceptar invitación de aliado
  static Future<bool> acceptInvite(String inviteToken, String allyId) async {
    try {
      // Decodificar y verificar token
      final decoded = utf8.decode(base64Url.decode(inviteToken));
      final parts = decoded.split(':');
      if (parts.length != 2) return false;
      
      final userId = parts[0];
      
      // Crear relación de aliado
      final ally = TrustedAlly(
        id: '${userId}_$allyId',
        userId: userId,
        allyId: allyId,
        trustLevel: TrustLevel.medium,
        status: AllyStatus.active,
        createdAt: DateTime.now(),
        notificationSettings: NotificationSettings(),
      );
      
      return await addAlly(ally);
    } catch (e) {
      print('Error accepting invite: $e');
      return false;
    }
  }
}
