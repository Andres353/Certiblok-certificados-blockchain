// lib/services/institution_status_service.dart
// Servicio para verificar el estado de las instituciones

import '../models/institution.dart';
import 'adapters/institution_adapter.dart';

class InstitutionStatusService {
  // Verificar si la institución del usuario está suspendida
  static Future<bool> isInstitutionSuspended(String institutionId) async {
    try {
      final institutions = await InstitutionAdapter.getAllInstitutions();
      final institution = institutions.firstWhere(
        (inst) => inst.id == institutionId,
        orElse: () => Institution(
          id: institutionId,
          name: 'Institución Desconocida',
          shortName: 'UNK',
          description: 'Institución no encontrada',
          logoUrl: '',
          institutionCode: 'UNK',
          colors: InstitutionColors(
            primary: '#6C4DDC',
            secondary: '#9C27B0',
            accent: '#FF5722',
            background: '#FFFFFF',
            text: '#000000',
          ),
          settings: InstitutionSettings(
            allowStudentRegistration: true,
            requireEmailVerification: true,
            allowPublicVerification: true,
            enableBlockchain: true,
            defaultLanguage: 'es',
            supportedPrograms: [],
            customFields: {},
          ),
          status: InstitutionStatus.active, // Por defecto activa si no se encuentra
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: '',
        ),
      );
      
      print('🔍 Verificando estado de institución: ${institution.name}');
      print('   - ID: ${institution.id}');
      print('   - Estado: ${institution.status}');
      print('   - Es suspendida: ${institution.status == InstitutionStatus.suspended}');
      
      return institution.status == InstitutionStatus.suspended;
    } catch (e) {
      print('Error verificando estado de institución: $e');
      return false; // En caso de error, asumir que no está suspendida
    }
  }

  // Obtener información de la institución suspendida
  static Future<Institution?> getSuspendedInstitutionInfo(String institutionId) async {
    try {
      final institutions = await InstitutionAdapter.getAllInstitutions();
      final institution = institutions.firstWhere(
        (inst) => inst.id == institutionId,
        orElse: () => Institution(
          id: '',
          name: '',
          shortName: '',
          description: '',
          logoUrl: '',
          institutionCode: '',
          colors: InstitutionColors(
            primary: '#6C4DDC',
            secondary: '#9C27B0',
            accent: '#FF5722',
            background: '#FFFFFF',
            text: '#000000',
          ),
          settings: InstitutionSettings(
            allowStudentRegistration: true,
            requireEmailVerification: true,
            allowPublicVerification: true,
            enableBlockchain: true,
            defaultLanguage: 'es',
            supportedPrograms: [],
            customFields: {},
          ),
          status: InstitutionStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: '',
        ),
      );
      
      return institution.status == InstitutionStatus.suspended ? institution : null;
    } catch (e) {
      print('Error obteniendo información de institución: $e');
      return null;
    }
  }
}
