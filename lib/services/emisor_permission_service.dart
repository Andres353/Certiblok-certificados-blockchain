// lib/services/emisor_permission_service.dart
// Servicio para controlar permisos de emisores por área académica

import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/emisor_types.dart';
import '../services/user_context_service.dart';
import '../models/emisor_assignment.dart';
import 'supabase/supabase_emisor_permission_service.dart';

class EmisorPermissionService {
  static final SupabaseClient _client = Supabase.instance.client;
  static bool _useSupabase = true; // Cambiar a false para usar Firebase

  /// Verifica si un emisor puede emitir certificados para un estudiante específico
  static Future<bool> canEmitForStudent({
    required String studentId,
    required String institutionId,
  }) async {
    if (_useSupabase) {
      return await SupabaseEmisorPermissionService.canEmitForStudent(
        studentId: studentId,
        institutionId: institutionId,
      );
    } else {
      // Implementación Firebase (legacy)
      return await _canEmitForStudentFirebase(studentId, institutionId);
    }
  }

  /// Obtiene las asignaciones de un emisor
  static Future<List<EmisorAssignment>> getEmisorAssignments(String emisorId) async {
    if (_useSupabase) {
      return await SupabaseEmisorPermissionService.getEmisorAssignments(emisorId);
    } else {
      // Implementación Firebase (legacy)
      return await _getEmisorAssignmentsFirebase(emisorId);
    }
  }

  /// Obtiene la lista de estudiantes para los que el emisor puede emitir certificados
  static Future<List<Map<String, dynamic>>> getStudentsForEmisor({
    required String institutionId,
  }) async {
    if (_useSupabase) {
      return await SupabaseEmisorPermissionService.getStudentsForEmisor(
        institutionId: institutionId,
      );
    } else {
      // Implementación Firebase (legacy)
      return await _getStudentsForEmisorFirebase(institutionId);
    }
  }

  // ========== MÉTODOS FIREBASE (LEGACY) ==========

  static Future<bool> _canEmitForStudentFirebase(String studentId, String institutionId) async {
    // Implementación Firebase (placeholder)
    return false;
  }

  static Future<List<EmisorAssignment>> _getEmisorAssignmentsFirebase(String emisorId) async {
    // Implementación Firebase (placeholder)
    return [];
  }

  static Future<List<Map<String, dynamic>>> _getStudentsForEmisorFirebase(String institutionId) async {
    // Implementación Firebase (placeholder)
    return [];
  }

  /// Obtiene información de permisos del emisor actual
  static Future<Map<String, dynamic>> getEmisorPermissions() async {
    if (_useSupabase) {
      return await SupabaseEmisorPermissionService.getEmisorPermissions();
    } else {
      // Implementación Firebase (placeholder)
      return {'canEmit': false, 'reason': 'Firebase not implemented'};
    }
  }
}
