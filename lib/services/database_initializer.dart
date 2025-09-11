// lib/services/database_initializer.dart
// Servicio para inicializar la base de datos con datos de ejemplo

import 'institution_service.dart';
import '../models/institution.dart';
import '../data/sample_institutions.dart';

class DatabaseInitializer {
  // Poblar la base de datos con instituciones de ejemplo
  static Future<void> initializeSampleData() async {
    try {
      print('Inicializando datos de ejemplo...');
      
      // Verificar si ya existen instituciones
      final existingInstitutions = await InstitutionService.getAllInstitutions();
      if (existingInstitutions.isNotEmpty) {
        print('Ya existen instituciones en la base de datos. Saltando inicialización.');
        return;
      }
      
      // Crear instituciones de ejemplo
      for (final sampleInstitution in SampleInstitutions.allInstitutions) {
        try {
          await InstitutionService.createInstitution(
            name: sampleInstitution.name,
            shortName: sampleInstitution.shortName,
            description: sampleInstitution.description,
            logoUrl: sampleInstitution.logoUrl,
            colors: sampleInstitution.colors,
            settings: sampleInstitution.settings,
            createdBy: 'system_init',
          );
          print('Institución creada: ${sampleInstitution.name}');
        } catch (e) {
          print('Error creando institución ${sampleInstitution.name}: $e');
        }
      }
      
      print('Datos de ejemplo inicializados correctamente.');
    } catch (e) {
      print('Error inicializando datos de ejemplo: $e');
    }
  }
  
  // Limpiar todos los datos de ejemplo
  static Future<void> clearSampleData() async {
    try {
      print('Limpiando datos de ejemplo...');
      
      final institutions = await InstitutionService.getAllInstitutions();
      for (final institution in institutions) {
        try {
          await InstitutionService.deleteInstitution(institution.id);
          print('Institución eliminada: ${institution.name}');
        } catch (e) {
          print('Error eliminando institución ${institution.name}: $e');
        }
      }
      
      print('Datos de ejemplo eliminados correctamente.');
    } catch (e) {
      print('Error eliminando datos de ejemplo: $e');
    }
  }
  
  // Verificar estado de la base de datos
  static Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      final institutions = await InstitutionService.getAllInstitutions();
      final stats = await InstitutionService.getInstitutionStats();
      
      return {
        'institutionsCount': institutions.length,
        'stats': stats,
        'hasData': institutions.isNotEmpty,
        'status': 'connected',
      };
    } catch (e) {
      return {
        'institutionsCount': 0,
        'stats': {},
        'hasData': false,
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}

