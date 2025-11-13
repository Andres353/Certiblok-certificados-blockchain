// lib/services/supabase/supabase_careers_service.dart
// Servicio para gestionar carreras y programas en Supabase

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCareersService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Obtener programas de una institución
  static Future<List<Map<String, dynamic>>> getProgramsByInstitution(String institutionId) async {
    try {
      final response = await _client
          .from('programs')
          .select('*')
          .eq('institution_id', institutionId)
          .eq('status', 'active')
          .order('name', ascending: true);


      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo programas: $e');
      throw Exception('Error obteniendo programas: $e');
    }
  }

  // Obtener facultades de una institución
  static Future<List<Map<String, dynamic>>> getFacultiesByInstitution(String institutionId) async {
    try {
      final response = await _client
          .from('faculties')
          .select('*')
          .eq('institution_id', institutionId)
          .eq('status', 'active')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo facultades: $e');
      throw Exception('Error obteniendo facultades: $e');
    }
  }

  // Crear nuevo programa
  static Future<Map<String, dynamic>> createProgram({
    required String name,
    required String code,
    String? facultyId,
    required String facultyName,
    required String institutionId,
    required String institutionName,
    int duration = 10,
    String modality = 'presencial',
    String? description,
  }) async {
    try {
      final programData = {
        'name': name,
        'program_code': code, // Usar program_code en lugar de code
        'faculty_id': facultyId,
        'faculty_name': facultyName,
        'institution_id': institutionId,
        'institution_name': institutionName,
        'duration': duration,
        'modality': modality,
        'description': description,
        'status': 'active',
        'is_global': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('programs')
          .insert(programData)
          .select()
          .single();

      return {
        'success': true,
        'program': response,
      };
    } catch (e) {
      print('Error creando programa: $e');
      throw Exception('Error creando programa: $e');
    }
  }

  // Actualizar programa
  static Future<Map<String, dynamic>> updateProgram({
    required String programId,
    required String name,
    required String code,
    required String facultyId,
    required String facultyName,
    int? duration,
    String? modality,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'program_code': code,
        'faculty_id': facultyId,
        'faculty_name': facultyName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (duration != null) updateData['duration'] = duration;
      if (modality != null) updateData['modality'] = modality;
      if (description != null) updateData['description'] = description;

      final response = await _client
          .from('programs')
          .update(updateData)
          .eq('id', programId)
          .select()
          .single();

      return {
        'success': true,
        'program': response,
      };
    } catch (e) {
      print('Error actualizando programa: $e');
      throw Exception('Error actualizando programa: $e');
    }
  }

  // Eliminar programa (soft delete)
  static Future<bool> deleteProgram(String programId) async {
    try {
      await _client
          .from('programs')
          .update({
            'status': 'inactive',
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', programId);

      return true;
    } catch (e) {
      print('Error eliminando programa: $e');
      throw Exception('Error eliminando programa: $e');
    }
  }

  // Crear nueva facultad
  static Future<Map<String, dynamic>> createFaculty({
    required String name,
    required String code,
    required String institutionId,
    required String institutionName,
    String? description,
  }) async {
    try {
      final facultyData = {
        'name': name,
        'program_code': code,
        'institution_id': institutionId,
        'institution_name': institutionName,
        'description': description,
        'status': 'active',
        'programs_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('faculties')
          .insert(facultyData)
          .select()
          .single();

      return {
        'success': true,
        'faculty': response,
      };
    } catch (e) {
      print('Error creando facultad: $e');
      throw Exception('Error creando facultad: $e');
    }
  }

  // Actualizar facultad
  static Future<Map<String, dynamic>> updateFaculty({
    required String facultyId,
    required String name,
    required String code,
    String? description,
  }) async {
    try {
      final updateData = {
        'name': name,
        'program_code': code,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (description != null) updateData['description'] = description;

      final response = await _client
          .from('faculties')
          .update(updateData)
          .eq('id', facultyId)
          .select()
          .single();

      return {
        'success': true,
        'faculty': response,
      };
    } catch (e) {
      print('Error actualizando facultad: $e');
      throw Exception('Error actualizando facultad: $e');
    }
  }

  // Eliminar facultad (soft delete)
  static Future<bool> deleteFaculty(String facultyId) async {
    try {
      await _client
          .from('faculties')
          .update({
            'status': 'inactive',
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', facultyId);

      return true;
    } catch (e) {
      print('Error eliminando facultad: $e');
      throw Exception('Error eliminando facultad: $e');
    }
  }

  // Obtener estadísticas de carreras
  static Future<Map<String, int>> getCareersStats(String institutionId) async {
    try {
      final programsResponse = await _client
          .from('programs')
          .select('id, status')
          .eq('institution_id', institutionId);

      final facultiesResponse = await _client
          .from('faculties')
          .select('id, status')
          .eq('institution_id', institutionId);

      int totalPrograms = programsResponse.length;
      int activePrograms = programsResponse.where((p) => p['status'] == 'active').length;
      int totalFaculties = facultiesResponse.length;
      int activeFaculties = facultiesResponse.where((f) => f['status'] == 'active').length;

      return {
        'total_programs': totalPrograms,
        'active_programs': activePrograms,
        'total_faculties': totalFaculties,
        'active_faculties': activeFaculties,
      };
    } catch (e) {
      print('Error obteniendo estadísticas de carreras: $e');
      return {
        'total_programs': 0,
        'active_programs': 0,
        'total_faculties': 0,
        'active_faculties': 0,
      };
    }
  }

  // Verificar si un código de programa existe (verificación global porque program_code es UNIQUE)
  static Future<bool> programCodeExists(String code, String institutionId) async {
    try {
      // Verificar globalmente porque program_code tiene restricción UNIQUE en toda la tabla
      final response = await _client
          .from('programs')
          .select('id')
          .eq('program_code', code)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error verificando código de programa: $e');
      return false;
    }
  }

  // Verificar si un código de facultad existe
  static Future<bool> facultyCodeExists(String code, String institutionId) async {
    try {
      final response = await _client
          .from('faculties')
          .select('id')
          .eq('program_code', code)
          .eq('institution_id', institutionId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error verificando código de facultad: $e');
      return false;
    }
  }

  // Generar código único para programa
  static Future<String> generateUniqueProgramCode(String institutionId) async {
    String baseCode = 'PROG';
    int counter = 1;
    
    while (true) {
      String code = '$baseCode${counter.toString().padLeft(3, '0')}';
      if (!await programCodeExists(code, institutionId)) {
        return code;
      }
      counter++;
    }
  }

  // Generar código único para facultad
  static Future<String> generateUniqueFacultyCode(String institutionId) async {
    String baseCode = 'FAC';
    int counter = 1;
    
    while (true) {
      String code = '$baseCode${counter.toString().padLeft(3, '0')}';
      if (!await facultyCodeExists(code, institutionId)) {
        return code;
      }
      counter++;
    }
  }
}
