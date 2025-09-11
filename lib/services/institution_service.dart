// lib/services/institution_service.dart
// Servicio para gestionar instituciones en el sistema multi-tenant

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/institution.dart';

class InstitutionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'institutions';

  // Crear nueva institución
  static Future<String> createInstitution({
    required String name,
    required String shortName,
    required String description,
    required String logoUrl,
    required InstitutionColors colors,
    required InstitutionSettings settings,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'name': name,
        'shortName': shortName,
        'description': description,
        'logoUrl': logoUrl,
        'colors': colors.toMap(),
        'settings': settings.toMap(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear institución: $e');
    }
  }

  // Obtener institución por ID
  static Future<Institution?> getInstitution(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Institution.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener institución: $e');
    }
  }

  // Obtener todas las instituciones
  static Future<List<Institution>> getAllInstitutions() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      return querySnapshot.docs
          .map((doc) => Institution.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener instituciones: $e');
    }
  }

  // Obtener instituciones por estado
  static Future<List<Institution>> getInstitutionsByStatus(
      InstitutionStatus status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status.name)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Institution.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener instituciones por estado: $e');
    }
  }

  // Actualizar institución
  static Future<void> updateInstitution(String id, Institution institution) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...institution.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar institución: $e');
    }
  }

  // Cambiar estado de institución
  static Future<void> updateInstitutionStatus(
      String id, InstitutionStatus status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar estado de institución: $e');
    }
  }

  // Eliminar institución (soft delete)
  static Future<void> deleteInstitution(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al eliminar institución: $e');
    }
  }

  // Buscar instituciones por nombre
  static Future<List<Institution>> searchInstitutions(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .get();

      final institutions = querySnapshot.docs
          .map((doc) => Institution.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filtrar por nombre (Firestore no soporta búsqueda de texto completo)
      return institutions
          .where((institution) =>
              institution.name.toLowerCase().contains(query.toLowerCase()) ||
              institution.shortName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar instituciones: $e');
    }
  }

  // Obtener estadísticas de instituciones
  static Future<Map<String, int>> getInstitutionStats() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      int total = querySnapshot.docs.length;
      int active = 0;
      int inactive = 0;
      int suspended = 0;
      int pending = 0;

      for (var doc in querySnapshot.docs) {
        final status = InstitutionStatus.fromString(doc.data()['status'] ?? '');
        switch (status) {
          case InstitutionStatus.active:
            active++;
            break;
          case InstitutionStatus.inactive:
            inactive++;
            break;
          case InstitutionStatus.suspended:
            suspended++;
            break;
          case InstitutionStatus.pending:
            pending++;
            break;
        }
      }

      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        'suspended': suspended,
        'pending': pending,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Verificar si existe una institución con el mismo nombre
  static Future<bool> institutionExists(String name) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar existencia de institución: $e');
    }
  }

  // Obtener instituciones creadas por un super admin
  static Future<List<Institution>> getInstitutionsByCreator(
      String createdBy) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('createdBy', isEqualTo: createdBy)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Institution.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener instituciones por creador: $e');
    }
  }
}
