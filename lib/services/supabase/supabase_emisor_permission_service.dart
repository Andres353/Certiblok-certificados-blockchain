// lib/services/supabase/supabase_emisor_permission_service.dart
// Servicio para controlar permisos de emisores por área académica usando Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_context_service.dart';
import '../../models/emisor_assignment.dart';

class SupabaseEmisorPermissionService {
  static final SupabaseClient _client = Supabase.instance.client;

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
      final emisorResponse = await _client
          .from('users')
          .select('*')
          .eq('id', userContext!.userId)
          .single();

      // Obtener asignaciones del emisor
      final assignments = await getEmisorAssignments(userContext.userId);
      if (assignments.isEmpty) return false;

      // Obtener información del estudiante (consolidado en 'users')
      final studentResponse = await _client
          .from('users')
          .select('*')
          .eq('id', studentId)
          .single();

      // Verificar que pertenezca a la institución
      if (studentResponse['institution_id'] != institutionId) {
        return false;
      }

      final String? studentCarreraId = studentResponse['program_id'];
      final String? studentFacultadId = studentResponse['faculty_id'];
      final String? studentProgramId = studentResponse['program_id'];

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
      print('❌ Error verificando permisos de emisor: $e');
      return false;
    }
  }

  /// Obtiene las asignaciones de un emisor
  static Future<List<EmisorAssignment>> getEmisorAssignments(String emisorId) async {
    try {
      final emisorResponse = await _client
          .from('users')
          .select('*')
          .eq('id', emisorId)
          .single();

      final assignmentsData = emisorResponse['assignments'] as List<dynamic>? ?? [];

      return assignmentsData
          .map((assignment) => EmisorAssignment.fromMap(assignment as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo asignaciones del emisor: $e');
      return [];
    }
  }

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
        final emisorResponse = await _client
            .from('users')
            .select('*')
            .eq('id', userContext.userId)
            .single();

        emisorTypeStr = emisorResponse['emisor_type'] ?? 'general';
        assignments = await getEmisorAssignments(userContext.userId);
      }

      // Obtener todos los estudiantes de la institución desde 'users'
      final studentsResponse = await _client
          .from('users')
          .select('*')
          .eq('role', 'student')
          .eq('institution_id', institutionId);

      List<Map<String, dynamic>> allowedStudents = [];

      for (var student in studentsResponse) {
        final studentId = student['id'];
        final String? studentCarreraId = student['program_id'];
        final String? studentFacultadId = student['faculty_id'];
        final String? studentProgramId = student['program_id'];

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
            // Filtrar por asignaciones específicas del emisor
            print('🔍 Emisor con asignaciones: ${assignments.length} asignaciones');
            for (final assignment in assignments) {
              print('  - Asignación: tipo=${assignment.type}, areaId=${assignment.areaId}');
              print('  - Estudiante: program_id=${studentCarreraId}, faculty_id=${studentFacultadId}');
              if (assignment.coversStudent(
                studentFacultyId: studentFacultadId,
                studentCareerId: studentCarreraId,
                studentProgramId: studentProgramId,
              )) {
                print('  ✅ Estudiante cumple con la asignación');
                canEmit = true;
                break;
              }
            }
          }
        }

        if (canEmit) {
          allowedStudents.add({
            'id': studentId,
            'fullName': student['full_name'] ?? 'Sin nombre',
            'email': student['email'] ?? 'Sin email',
            'studentId': student['student_id'] ?? 'Sin ID',
            'studentIdInInstitution': student['student_id'] ?? 'Sin ID',
            'program': student['program'] ?? 'Sin programa',
            'faculty': student['faculty'] ?? 'Sin facultad',
            'programId': studentCarreraId,
            'facultyId': studentFacultadId,
          });
        }
      }

      return allowedStudents;
    } catch (e) {
      print('❌ Error obteniendo estudiantes para emisor: $e');
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

      final emisorResponse = await _client
          .from('users')
          .select('*')
          .eq('id', userContext!.userId)
          .single();

      final emisorType = emisorResponse['emisor_type'] ?? 'general';

      return {
        'canEmit': true,
        'emisorType': emisorType,
        'carreraId': emisorResponse['program_id'],
        'carreraName': emisorResponse['program'],
        'facultadId': emisorResponse['faculty_id'],
        'facultadName': emisorResponse['faculty'],
        'institutionId': emisorResponse['institution_id'],
        'institutionName': emisorResponse['institution_name'],
      };
    } catch (e) {
      print('❌ Error obteniendo permisos del emisor: $e');
      return {
        'canEmit': false,
        'reason': 'Error interno: $e',
      };
    }
  }
}
