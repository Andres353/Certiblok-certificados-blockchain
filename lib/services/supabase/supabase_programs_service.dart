// lib/services/supabase/supabase_programs_service.dart
// Servicio de Supabase para gestión de programas y pasantías

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import '../../models/program_opportunity.dart';

class SupabaseProgramsService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Obtener todos los programas (para debugging)
  static Future<List<ProgramOpportunity>> getAllProgramsForDebug() async {
    try {
      final response = await _client
          .from('programs_opportunities')
          .select('*')
          .order('created_at', ascending: false);
      
      return response.map((data) => ProgramOpportunity.fromSupabase(data)).toList();
    } catch (e) {
      return [];
    }
  }

  // Crear programa de oportunidad
  static Future<String> createProgramOpportunity({
    required String title,
    required String description,
    required String institutionId,
    required String institutionName,
    String? facultyId,
    required String facultyName,
    required List<String> careerIds,
    required List<String> careerNames,
    required List<String> requirements,
    required DateTime applicationDeadline,
    required int maxApplications,
    required String createdBy,
    required String createdByName,
    Map<String, dynamic>? additionalInfo,
    String? imageUrl,
    String? pdfUrl,
    String? pdfFileName,
    String? pdfData,
  }) async {
    try {
      print('🔄 Creando programa de oportunidad en Supabase...');
      
      final programData = {
        'title': title,
        'description': description,
        'institution_id': institutionId,
        'institution_name': institutionName,
        'faculty_id': facultyId,
        'faculty_name': facultyName,
        'career_ids': careerIds,
        'career_names': careerNames,
        'requirements': requirements,
        'application_deadline': applicationDeadline.toIso8601String(),
        'max_applications': maxApplications,
        'current_applications': 0,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'additional_info': additionalInfo ?? {},
        'image_url': imageUrl,
        'pdf_url': pdfUrl,
        'pdf_file_name': pdfFileName,
        'pdf_data': pdfData,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('programs_opportunities')
          .insert(programData)
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error creando programa: $e');
    }
  }

  // Verificar si un estudiante puede aplicar
  static Future<bool> canStudentApply(String programId, String studentId) async {
    try {
      print('🔄 Verificando si estudiante puede aplicar...');
      
      // Obtener el programa
      print('   programId: $programId');
      print('   studentId: $studentId');
      
      final programResponse = await _client
          .from('programs_opportunities')
          .select('*')
          .eq('id', programId)
          .maybeSingle();

      if (programResponse == null || programResponse.isEmpty) {
        print('❌ Programa no encontrado con ID: $programId');
        return false;
      }

      print('📋 Programa encontrado: ${programResponse['title'] ?? 'Sin título'}');
      
      final program = ProgramOpportunity.fromSupabase(programResponse);
      
      // Verificar si el programa está activo y abierto
      if (!program.isActive) {
        print('⚠️ Programa no está activo');
        return false;
      }
      
      if (!program.isOpenForApplications) {
        print('⚠️ Programa no está abierto para postulaciones');
        return false;
      }

      // Verificar si la fecha límite no ha pasado
      if (program.applicationDeadline.isBefore(DateTime.now())) {
        print('⚠️ Fecha límite de postulación ha pasado');
        return false;
      }

      // Verificar si el estudiante ya aplicó (esto se puede implementar más adelante)
      // Por ahora, permitir que todos los estudiantes apliquen si cumplen los requisitos básicos
      
      print('✅ Estudiante puede aplicar al programa');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error verificando elegibilidad: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Cambiar estado del programa
  static Future<void> toggleProgramStatus(String programId, bool isActive) async {
    try {
      print('🔄 Cambiando estado del programa: $programId');
      
      await _client
          .from('programs_opportunities')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', programId);

      print('✅ Estado del programa actualizado');
    } catch (e) {
      print('❌ Error actualizando estado: $e');
      throw Exception('Error actualizando estado: $e');
    }
  }

  // Obtener programas por institución
  static Future<List<ProgramOpportunity>> getProgramsByInstitution(String institutionId) async {
    try {
      print('🔄 Obteniendo programas por institución: $institutionId');
      
      final response = await _client
          .from('programs_opportunities')
          .select('*')
          .eq('institution_id', institutionId)
          .order('created_at', ascending: false);

      return response.map((data) => ProgramOpportunity.fromSupabase(data)).toList();
    } catch (e) {
      print('❌ Error obteniendo programas por institución: $e');
      return [];
    }
  }

  // Obtener programa por ID
  static Future<ProgramOpportunity?> getProgramById(String programId) async {
    try {
      print('🔄 Obteniendo programa por ID: $programId');
      
      final response = await _client
          .from('programs_opportunities')
          .select('*')
          .eq('id', programId)
          .single();

      return ProgramOpportunity.fromSupabase(response);
    } catch (e) {
      print('❌ Error obteniendo programa: $e');
      return null;
    }
  }

  // Actualizar programa
  static Future<void> updateProgram(String programId, Map<String, dynamic> updates) async {
    try {
      print('🔄 Actualizando programa: $programId');
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await _client
          .from('programs_opportunities')
          .update(updates)
          .eq('id', programId);

      print('✅ Programa actualizado');
    } catch (e) {
      print('❌ Error actualizando programa: $e');
      throw Exception('Error actualizando programa: $e');
    }
  }

  // Eliminar programa
  static Future<void> deleteProgram(String programId) async {
    try {
      print('🔄 Eliminando programa: $programId');
      
      await _client
          .from('programs_opportunities')
          .delete()
          .eq('id', programId);

      print('✅ Programa eliminado');
    } catch (e) {
      print('❌ Error eliminando programa: $e');
      throw Exception('Error eliminando programa: $e');
    }
  }
}
