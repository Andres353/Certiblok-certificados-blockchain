// lib/services/supabase/supabase_institution_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/institution.dart';
import 'supabase_config.dart';

class SupabaseInstitutionService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Obtener todas las instituciones
  static Future<List<Institution>> getAllInstitutions() async {
    try {
      final response = await _client
          .from('institutions')
          .select('*')
          .order('created_at', ascending: false);

      return response.map((data) {
        return Institution.fromSupabase(data);
      }).toList();
    } catch (e) {
      print('Error obteniendo instituciones: $e');
      return [];
    }
  }

  // Obtener institución por ID
  static Future<Institution?> getInstitution(String id) async {
    try {
      final response = await _client
          .from('institutions')
          .select('*')
          .eq('id', id)
          .single();

      return Institution.fromSupabase(response);
    } catch (e) {
      print('Error obteniendo institución: $e');
      return null;
    }
  }

  // Crear nueva institución
  static Future<String> createInstitution({
    required String name,
    required String shortName,
    required String description,
    required String logoUrl,
    required String institutionCode,
    required InstitutionColors colors,
    required InstitutionSettings settings,
    required String createdBy,
  }) async {
    try {
      final data = {
        'name': name,
        'short_name': shortName,
        'description': description,
        'logo_url': logoUrl,
        'institution_code': institutionCode,
        'colors': colors.toMap(),
        'settings': settings.toMap(),
        'status': 'active',
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('institutions')
          .insert(data)
          .select()
          .single();

      return response['id'].toString();
    } catch (e) {
      print('Error creando institución: $e');
      rethrow;
    }
  }

  // Actualizar institución
  static Future<bool> updateInstitution(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      
      await _client
          .from('institutions')
          .update(data)
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error actualizando institución: $e');
      return false;
    }
  }

  // Eliminar institución
  static Future<bool> deleteInstitution(String id) async {
    try {
      await _client
          .from('institutions')
          .delete()
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error eliminando institución: $e');
      return false;
    }
  }

  // Generar código único para institución
  static Future<String> generateUniqueCode(String shortName) async {
    try {
      String baseCode = shortName.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (baseCode.length > 6) {
        baseCode = baseCode.substring(0, 6);
      }

      String code = baseCode;
      int counter = 1;

      while (true) {
        final existing = await _client
            .from('institutions')
            .select('id')
            .eq('institution_code', code)
            .limit(1);

        if (existing.isEmpty) {
          break;
        }

        code = '${baseCode}${counter.toString().padLeft(2, '0')}';
        counter++;
      }

      return code;
    } catch (e) {
      print('Error generando código único: $e');
      return '${shortName.toUpperCase().substring(0, 3)}${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  // Obtener estadísticas de instituciones
  static Future<Map<String, int>> getInstitutionStats() async {
    try {
      final response = await _client
          .from('institutions')
          .select('status');

      int total = response.length;
      int active = 0;
      int inactive = 0;
      int suspended = 0;
      int pending = 0;

      for (var institution in response) {
        switch (institution['status']) {
          case 'active':
            active++;
            break;
          case 'inactive':
            inactive++;
            break;
          case 'suspended':
            suspended++;
            break;
          case 'pending':
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
      print('Error obteniendo estadísticas: $e');
      return {'total': 0, 'active': 0, 'inactive': 0, 'suspended': 0, 'pending': 0};
    }
  }

  // Buscar instituciones por nombre
  static Future<List<Institution>> searchInstitutions(String query) async {
    try {
      final response = await _client
          .from('institutions')
          .select('*')
          .or('name.ilike.%$query%,short_name.ilike.%$query%,institution_code.ilike.%$query%')
          .order('name');

      return response.map((data) {
        return Institution.fromSupabase(data);
      }).toList();
    } catch (e) {
      print('Error buscando instituciones: $e');
      return [];
    }
  }

  // Obtener institución por código
  static Future<Institution?> getInstitutionByCode(String code) async {
    try {
      final response = await _client
          .from('institutions')
          .select('*')
          .eq('institution_code', code)
          .single();

      return Institution.fromSupabase(response);
    } catch (e) {
      print('Error obteniendo institución por código: $e');
      return null;
    }
  }

  // Generar código de carrera
  static Future<String> generateCareerCode(String institutionId, String careerType) async {
    try {
      // Generar código único basado en timestamp y random
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final code = 'CAREER-$random';
      
      // Verificar que no exista
      final existing = await _client
          .from('faculties')
          .select('id')
          .eq('career_code', code)
          .limit(1);
      
      if (existing.isEmpty) {
        return code;
      } else {
        // Si existe, generar uno nuevo
        return generateCareerCode(institutionId, careerType);
      }
    } catch (e) {
      print('Error generando código de carrera: $e');
      return 'CAREER-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Obtener carrera por código
  static Future<Map<String, dynamic>?> getCareerByCode(String code) async {
    try {
      print('🔍 Buscando carrera con código: "$code"');
      
      // Buscar en la tabla programs por program_code
      final response = await _client
          .from('programs')
          .select('*')
          .eq('program_code', code)
          .eq('status', 'active')
          .single();

      print('📊 Respuesta de Supabase: $response');
      
      if (response['name'] != null) {
        print('✅ Carrera encontrada por código: ${response['name']}');
        print('📋 Datos de la carrera:');
        print('   - ID: ${response['id']}');
        print('   - Nombre: ${response['name']}');
        print('   - Institution ID: ${response['institution_id']}');
        print('   - Faculty Name: ${response['faculty_name']}');
        print('   - Faculty ID: ${response['faculty_id']}');
        return response;
      } else {
        print('❌ Carrera no encontrada o datos incompletos');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo carrera por código "$code": $e');
      return null;
    }
  }

}
