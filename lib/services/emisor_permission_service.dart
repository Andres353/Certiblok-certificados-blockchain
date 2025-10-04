// lib/services/emisor_permission_service.dart
// Servicio para controlar permisos de emisores por área académica

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/emisor_types.dart';
import '../services/user_context_service.dart';
import '../models/emisor_assignment.dart';

class EmisorPermissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica si un emisor puede emitir certificados para un estudiante específico
  static Future<bool> canEmitForStudent({
    required String studentId,
    required String institutionId,
  }) async {
    try {
      // Obtener contexto del emisor actual
      final userContext = UserContextService.currentContext;
      if (userContext?.userRole != 'emisor' || userContext?.institutionId != institutionId) {
        return false;
      }

      // Obtener información del emisor
      final emisorDoc = await _firestore
          .collection('users')
          .doc(userContext!.userId)
          .get();

      if (!emisorDoc.exists) {
        return false;
      }

      // Obtener asignaciones del emisor
      final assignments = await getEmisorAssignments(userContext.userId);
      if (assignments.isEmpty) return false;

      // Obtener información del estudiante (consolidado en 'users')
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        return false;
      }

      final studentData = studentDoc.data() as Map<String, dynamic>;
      // Verificar que pertenezca a la institución
      if ((studentData['institutionId'] as String?) != institutionId) {
        return false;
      }

      final String? studentCarreraId = studentData['programId'] as String?;
      final String? studentFacultadId = studentData['facultyId'] as String?;
      final String? studentProgramId = studentData['programId'] as String?;

      // Verificar si alguna asignación cubre al estudiante
      for (final assignment in assignments) {
        if (assignment.coversStudent(
          studentFacultyId: studentFacultadId,
          studentCareerId: studentCarreraId,
          studentProgramId: studentProgramId,
        )) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error verificando permisos de emisor: $e');
      return false;
    }
  }

  /// Obtiene las asignaciones de un emisor
  static Future<List<EmisorAssignment>> getEmisorAssignments(String emisorId) async {
    try {
      final emisorDoc = await _firestore
          .collection('users')
          .doc(emisorId)
          .get();

      if (!emisorDoc.exists) {
        return [];
      }

      final emisorData = emisorDoc.data()!;
      final assignmentsData = emisorData['assignments'] as List<dynamic>? ?? [];

      return assignmentsData
          .map((assignment) => EmisorAssignment.fromMap(assignment as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo asignaciones del emisor: $e');
      return [];
    }
  }

  // Métodos legacy removidos: validación ahora usa datos en 'users'

  /// Obtiene la lista de estudiantes para los que el emisor puede emitir certificados
  static Future<List<Map<String, dynamic>>> getStudentsForEmisor({
    required String institutionId,
  }) async {
    try {
      final userContext = UserContextService.currentContext;
      if (userContext == null) return [];
      if (userContext.institutionId != institutionId) return [];

      // Determinar política según rol
      bool isAdmin = userContext.userRole == 'admin_institution';
      bool isSuperAdmin = userContext.userRole == 'super_admin';
      bool isEmisor = userContext.userRole == 'emisor';

      List<EmisorAssignment> assignments = [];
      String? emisorTypeStr;

      if (isEmisor) {
        // Obtener información del emisor
        final emisorDoc = await _firestore
            .collection('users')
            .doc(userContext.userId)
            .get();

        if (!emisorDoc.exists) {
          return [];
        }

        final emisorData = emisorDoc.data()!;
        emisorTypeStr = (emisorData['emisorType'] as String?) ?? 'general';
        assignments = await getEmisorAssignments(userContext.userId);
      }

      // Obtener todos los estudiantes de la institución desde 'users'
      final studentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      List<Map<String, dynamic>> allowedStudents = [];

      for (var doc in studentsQuery.docs) {
        final studentData = doc.data();
        final studentId = doc.id;
        final String? studentCarreraId = studentData['programId'] as String?;
        final String? studentFacultadId = studentData['facultyId'] as String?;
        final String? studentProgramId = studentData['programId'] as String?;

        // Política de acceso
        bool canEmit = false;
        if (isAdmin || isSuperAdmin) {
          // Admin y SuperAdmin ven todos los estudiantes de la institución
          canEmit = true;
        } else if (isEmisor) {
          // Emisor general ve todos; emisor con asignaciones filtra
          if ((emisorTypeStr ?? 'general') == 'general') {
            canEmit = true;
          } else {
            for (final assignment in assignments) {
              if (assignment.coversStudent(
                studentFacultyId: studentFacultadId,
                studentCareerId: studentCarreraId,
                studentProgramId: studentProgramId,
              )) {
                canEmit = true;
                break;
              }
            }
          }
        }

        if (canEmit) {
          allowedStudents.add({
            'id': studentId,
            'fullName': studentData['fullName'],
            'email': studentData['email'],
            'program': studentData['program'],
            'faculty': studentData['faculty'],
            'programId': studentData['programId'],
            'facultyId': studentData['facultyId'],
            'studentIdInInstitution': studentData['ci'] ?? studentData['studentId'],
          });
        }
      }

      return allowedStudents;
    } catch (e) {
      print('Error obteniendo estudiantes para emisor: $e');
      return [];
    }
  }

  /// Obtiene información de permisos del emisor actual
  static Future<Map<String, dynamic>> getEmisorPermissions() async {
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.userRole != 'emisor') {
        return {
          'canEmit': false,
          'reason': 'No es un emisor',
        };
      }

      final emisorDoc = await _firestore
          .collection('users')
          .doc(userContext!.userId)
          .get();

      if (!emisorDoc.exists) {
        return {
          'canEmit': false,
          'reason': 'Emisor no encontrado',
        };
      }

      final emisorData = emisorDoc.data()!;
      final emisorType = emisorTypeFromString(emisorData['emisorType'] ?? 'general');

      return {
        'canEmit': true,
        'emisorType': emisorType,
        'carreraId': emisorData['carreraId'],
        'carreraName': emisorData['carreraName'],
        'facultadId': emisorData['facultadId'],
        'facultadName': emisorData['facultadName'],
        'institutionId': emisorData['institutionId'],
        'institutionName': emisorData['institutionName'],
      };
    } catch (e) {
      print('Error obteniendo permisos del emisor: $e');
      return {
        'canEmit': false,
        'reason': 'Error interno: $e',
      };
    }
  }

  /// Valida si un emisor puede acceder a una funcionalidad específica
  static Future<bool> canAccessFeature(String feature) async {
    try {
      final permissions = await getEmisorPermissions();
      
      if (!permissions['canEmit']) {
        return false;
      }

      final emisorType = permissions['emisorType'] as EmisorType;

      switch (feature) {
        case 'emit_certificates':
          return true; // Todos los emisores pueden emitir certificados
        case 'view_all_students':
          return emisorType == EmisorType.general;
        case 'view_carrera_students':
          return emisorType == EmisorType.general || emisorType == EmisorType.carrera;
        case 'view_facultad_students':
          return emisorType == EmisorType.general || emisorType == EmisorType.facultad;
        case 'manage_certificates':
          return emisorType == EmisorType.general;
        default:
          return false;
      }
    } catch (e) {
      print('Error validando acceso a funcionalidad: $e');
      return false;
    }
  }
}
