import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crisis_plan.dart';

/// Servicio para gestionar el Plan de Crisis / Safety Plan
class CrisisPlanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'crisis_plans';

  /// Obtener el plan de crisis de un usuario
  static Future<CrisisPlan?> getPlan(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return CrisisPlan.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting crisis plan: $e');
      return null;
    }
  }

  /// Crear o actualizar plan de crisis
  static Future<bool> savePlan(CrisisPlan plan) async {
    try {
      if (plan.id.isEmpty) {
        plan = CrisisPlan(
          id: _generateId(),
          userId: plan.userId,
          emergencyContacts: plan.emergencyContacts,
          warningSigns: plan.warningSigns,
          copingStrategies: plan.copingStrategies,
          environmentalChanges: plan.environmentalChanges,
          socialContacts: plan.socialContacts,
          professionalResources: plan.professionalResources,
          preferredEmergencyService: plan.preferredEmergencyService,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      await _firestore
          .collection(_collection)
          .doc(plan.userId)
          .set(plan.toMap());
      
      return true;
    } catch (e) {
      print('Error saving crisis plan: $e');
      return false;
    }
  }

  /// Añadir contacto de emergencia
  static Future<bool> addEmergencyContact(
    String userId,
    CrisisContact contact,
  ) async {
    try {
      final plan = await getPlan(userId);
      if (plan == null) return false;

      final updatedContacts = List<CrisisContact>.from(plan.emergencyContacts)
        ..add(contact);

      final updatedPlan = plan.copyWith(emergencyContacts: updatedContacts);
      return await savePlan(updatedPlan);
    } catch (e) {
      print('Error adding emergency contact: $e');
      return false;
    }
  }

  /// Eliminar contacto de emergencia
  static Future<bool> removeEmergencyContact(
    String userId,
    String contactId,
  ) async {
    try {
      final plan = await getPlan(userId);
      if (plan == null) return false;

      final updatedContacts = plan.emergencyContacts
          .where((c) => c.id != contactId)
          .toList();

      final updatedPlan = plan.copyWith(emergencyContacts: updatedContacts);
      return await savePlan(updatedPlan);
    } catch (e) {
      print('Error removing emergency contact: $e');
      return false;
    }
  }

  /// Añadir señal de advertencia
  static Future<bool> addWarningSign(
    String userId,
    String sign,
  ) async {
    try {
      final plan = await getPlan(userId);
      if (plan == null) return false;

      final updatedSigns = List<String>.from(plan.warningSigns)..add(sign);
      final updatedPlan = plan.copyWith(warningSigns: updatedSigns);
      return await savePlan(updatedPlan);
    } catch (e) {
      print('Error adding warning sign: $e');
      return false;
    }
  }

  /// Añadir estrategia de afrontamiento
  static Future<bool> addCopingStrategy(
    String userId,
    String strategy,
  ) async {
    try {
      final plan = await getPlan(userId);
      if (plan == null) return false;

      final updated = List<String>.from(plan.copingStrategies)..add(strategy);
      final updatedPlan = plan.copyWith(copingStrategies: updated);
      return await savePlan(updatedPlan);
    } catch (e) {
      print('Error adding coping strategy: $e');
      return false;
    }
  }

  /// Obtener contactos de emergencia (solo los no profesionales)
  static Future<List<CrisisContact>> getPersonalContacts(String userId) async {
    final plan = await getPlan(userId);
    if (plan == null) return [];

    return plan.emergencyContacts
        .where((c) => !c.isHealthcareProfessional)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Obtener recursos profesionales
  static Future<List<CrisisContact>> getProfessionalContacts(String userId) async {
    final plan = await getPlan(userId);
    if (plan == null) return [];

    return plan.emergencyContacts
        .where((c) => c.isHealthcareProfessional)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Verificar si el plan está completo
  static bool isPlanComplete(CrisisPlan plan) {
    return plan.emergencyContacts.isNotEmpty &&
        plan.warningSigns.isNotEmpty &&
        plan.copingStrategies.isNotEmpty &&
        plan.professionalResources.isNotEmpty;
  }

  /// Generar ID único
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(10000)}';
  }

  /// Plantilla de plan de crisis básico (para nuevos usuarios)
  static CrisisPlan getTemplate(String userId) {
    return CrisisPlan.empty(userId)
      ..warningSigns = [
        'Dificultad para dormir',
        'Aumento de ansiedad',
        'Cambios en el apetito',
        'Aislamiento social',
        'Pensamientos negativos recurrentes',
      ]
      ..copingStrategies = [
        'Técnicas de respiración profunda',
        'Llamar a un contacto de confianza',
        'Paseo corto al aire libre',
        'Escuchar música relajante',
        'Escribir en un diario',
        'Ejercicio ligero',
      ]
      ..environmentalChanges = [
        'Mantener espacios bien iluminados',
        'Evitar alcohol y cafeína',
        'Mantener rutina de sueño regular',
        'Organizar el entorno',
      ]
      ..socialContacts = [
        'Hablar con un amigo o familiar',
        'Contactar grupo de apoyo',
        'Participar en actividad social ligera',
      ]
      ..professionalResources = [
        'Psiquiatra tratante',
        'Psicólogo/Salud mental',
        'Línea de crisis local',
      ];
  }
}
