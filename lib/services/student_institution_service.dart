// lib/services/student_institution_service.dart
// Servicio para manejar relaciones muchos-a-muchos entre estudiantes e instituciones

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/institution.dart';
import 'institution_service.dart';

class StudentInstitutionService {
  static const String _collection = 'student_institutions';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Agregar estudiante a una institución
  static Future<Map<String, dynamic>> addStudentToInstitution({
    required String studentId,
    required String institutionId,
    required String studentIdInInstitution, // ID del estudiante en esa institución específica
    String? program, // Programa específico en esa institución
    String? faculty, // Facultad específica en esa institución
    String? programId, // ID del programa en la base de datos
    String? facultyId, // ID de la facultad en la base de datos
    String? status = 'active', // active, inactive, graduated, etc.
  }) async {
    try {
      // Verificar si la relación ya existe
      final existingRelation = await _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId)
          .where('institutionId', isEqualTo: institutionId)
          .limit(1)
          .get();

      if (existingRelation.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'El estudiante ya está registrado en esta institución',
        };
      }

      // Obtener información de la institución
      final institution = await InstitutionService.getInstitution(institutionId);
      if (institution == null) {
        return {
          'success': false,
          'message': 'Institución no encontrada',
        };
      }

      // Crear la relación
      final docRef = await _firestore.collection(_collection).add({
        'studentId': studentId,
        'institutionId': institutionId,
        'institutionName': institution.name,
        'institutionCode': institution.institutionCode,
        'studentIdInInstitution': studentIdInInstitution,
        'program': program,
        'faculty': faculty,
        'programId': programId,
        'facultyId': facultyId,
        'status': status,
        'enrolledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Estudiante agregado a la institución exitosamente',
        'relationId': docRef.id,
      };
    } catch (e) {
      print('❌ Error agregando estudiante a institución: $e');
      return {
        'success': false,
        'message': 'Error al agregar estudiante a la institución: $e',
      };
    }
  }

  // Obtener todas las instituciones de un estudiante
  static Future<List<Map<String, dynamic>>> getStudentInstitutions(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'active')
          .orderBy('enrolledAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo instituciones del estudiante: $e');
      return [];
    }
  }

  // Obtener todos los estudiantes de una institución
  static Future<List<Map<String, dynamic>>> getInstitutionStudents(String institutionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'active')
          .orderBy('enrolledAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo estudiantes de la institución: $e');
      return [];
    }
  }

  // Verificar si un estudiante pertenece a una institución
  static Future<bool> isStudentInInstitution(String studentId, String institutionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId)
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando relación estudiante-institución: $e');
      return false;
    }
  }

  // Actualizar información de la relación
  static Future<Map<String, dynamic>> updateStudentInstitution({
    required String relationId,
    String? program,
    String? faculty,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (program != null) updateData['program'] = program;
      if (faculty != null) updateData['faculty'] = faculty;
      if (status != null) updateData['status'] = status;

      await _firestore.collection(_collection).doc(relationId).update(updateData);

      return {
        'success': true,
        'message': 'Información actualizada exitosamente',
      };
    } catch (e) {
      print('❌ Error actualizando relación estudiante-institución: $e');
      return {
        'success': false,
        'message': 'Error al actualizar la información: $e',
      };
    }
  }

  // Remover estudiante de una institución
  static Future<Map<String, dynamic>> removeStudentFromInstitution(String relationId) async {
    try {
      await _firestore.collection(_collection).doc(relationId).update({
        'status': 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Estudiante removido de la institución exitosamente',
      };
    } catch (e) {
      print('❌ Error removiendo estudiante de institución: $e');
      return {
        'success': false,
        'message': 'Error al remover estudiante de la institución: $e',
      };
    }
  }

  // Obtener relación específica por código de institución
  static Future<Map<String, dynamic>?> getStudentInstitutionByCode({
    required String studentId,
    required String institutionCode,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId)
          .where('institutionCode', isEqualTo: institutionCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo relación por código: $e');
      return null;
    }
  }
}
