// lib/services/adapters/institution_adapter.dart
import '../institution_service.dart';
import '../supabase/supabase_institution_service.dart';
import '../../models/institution.dart';

class InstitutionAdapter {
  static bool _useSupabase = false; // Flag para cambiar entre Firebase y Supabase

  // Cambiar entre Firebase y Supabase
  static void useSupabase(bool useSupabase) {
    _useSupabase = useSupabase;
    print('🔄 InstitutionAdapter: ${useSupabase ? "Usando Supabase" : "Usando Firebase"}');
  }

  // Obtener todas las instituciones
  static Future<List<Institution>> getAllInstitutions() async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.getAllInstitutions();
    } else {
      return await InstitutionService.getAllInstitutions();
    }
  }

  // Obtener institución por ID
  static Future<Institution?> getInstitution(String id) async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.getInstitution(id);
    } else {
      return await InstitutionService.getInstitution(id);
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
    if (_useSupabase) {
      return await SupabaseInstitutionService.createInstitution(
        name: name,
        shortName: shortName,
        description: description,
        logoUrl: logoUrl,
        institutionCode: institutionCode,
        colors: colors,
        settings: settings,
        createdBy: createdBy,
      );
    } else {
      return await InstitutionService.createInstitution(
        name: name,
        shortName: shortName,
        description: description,
        logoUrl: logoUrl,
        institutionCode: institutionCode,
        colors: colors,
        settings: settings,
        createdBy: createdBy,
      );
    }
  }

  // Actualizar institución
  static Future<bool> updateInstitution(String id, Institution institution) async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.updateInstitution(id, institution.toFirestore());
    } else {
      await InstitutionService.updateInstitution(id, institution);
      return true;
    }
  }

  // Eliminar institución
  static Future<bool> deleteInstitution(String id) async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.deleteInstitution(id);
    } else {
      await InstitutionService.deleteInstitution(id);
      return true;
    }
  }

  // Generar código único para institución
  static Future<String> generateUniqueCode(String shortName) async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.generateUniqueCode(shortName);
    } else {
      return await InstitutionService.generateUniqueCode(shortName);
    }
  }

  // Obtener estadísticas de instituciones
  static Future<Map<String, int>> getInstitutionStats() async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.getInstitutionStats();
    } else {
      return await InstitutionService.getInstitutionStats();
    }
  }

  // Buscar instituciones por nombre
  static Future<List<Institution>> searchInstitutions(String query) async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.searchInstitutions(query);
    } else {
      return await InstitutionService.searchInstitutions(query);
    }
  }

  // Obtener institución por código
  static Future<Institution?> getInstitutionByCode(String code) async {
    if (_useSupabase) {
      // Buscar por código en Supabase
      try {
        final institutions = await SupabaseInstitutionService.getAllInstitutions();
        return institutions.firstWhere((inst) => inst.institutionCode == code);
      } catch (e) {
        return null;
      }
    } else {
      return await InstitutionService.getInstitutionByCode(code);
    }
  }

  // Generar código de carrera
  static Future<String> generateCareerCode(String institutionId) async {
    if (_useSupabase) {
      // Implementar generación de código en Supabase
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      return 'CAREER-$random';
    } else {
      return await InstitutionService.generateCareerCode(institutionId, 'default');
    }
  }

  // Obtener carrera por código
  static Future<Map<String, dynamic>?> getCareerByCode(String code) async {
    if (_useSupabase) {
      return await SupabaseInstitutionService.getCareerByCode(code);
    } else {
      return await InstitutionService.getCareerByCode(code);
    }
  }
}
