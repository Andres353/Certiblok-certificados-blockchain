// lib/services/adapters/programs_adapter.dart
// Adapter para gestión de programas y pasantías (Firebase/Supabase)

import '../programs_opportunities_service.dart';
import '../supabase/supabase_programs_service.dart';
import '../../models/program_opportunity.dart';

class ProgramsAdapter {
  static const bool _useSupabase = true;

  // Obtener todos los programas (para debugging)
  static Future<List<ProgramOpportunity>> getAllProgramsForDebug() async {
    if (_useSupabase) {
      return await SupabaseProgramsService.getAllProgramsForDebug();
    } else {
      return await ProgramsOpportunitiesService.getAllProgramsForDebug();
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
    if (_useSupabase) {
      return await SupabaseProgramsService.createProgramOpportunity(
        title: title,
        description: description,
        institutionId: institutionId,
        institutionName: institutionName,
        facultyId: facultyId,
        facultyName: facultyName,
        careerIds: careerIds,
        careerNames: careerNames,
        requirements: requirements,
        applicationDeadline: applicationDeadline,
        maxApplications: maxApplications,
        createdBy: createdBy,
        createdByName: createdByName,
        additionalInfo: additionalInfo,
        imageUrl: imageUrl,
        pdfUrl: pdfUrl,
        pdfFileName: pdfFileName,
        pdfData: pdfData,
      );
    } else {
      return await ProgramsOpportunitiesService.createProgramOpportunity(
        title: title,
        description: description,
        institutionId: institutionId,
        institutionName: institutionName,
        facultyId: facultyId ?? '',
        facultyName: facultyName,
        careerIds: careerIds,
        careerNames: careerNames,
        requirements: requirements,
        applicationDeadline: applicationDeadline,
        maxApplications: maxApplications,
        createdBy: createdBy,
        createdByName: createdByName,
        additionalInfo: additionalInfo,
        imageUrl: imageUrl,
        pdfUrl: pdfUrl,
        pdfFileName: pdfFileName,
        pdfData: pdfData,
      );
    }
  }

  // Verificar si un estudiante puede aplicar
  static Future<bool> canStudentApply(String programId, String studentId) async {
    if (_useSupabase) {
      return await SupabaseProgramsService.canStudentApply(programId, studentId);
    } else {
      return await ProgramsOpportunitiesService.canStudentApply(programId, studentId);
    }
  }

  // Cambiar estado del programa
  static Future<void> toggleProgramStatus(String programId, bool isActive) async {
    if (_useSupabase) {
      return await SupabaseProgramsService.toggleProgramStatus(programId, isActive);
    } else {
      return await ProgramsOpportunitiesService.toggleProgramStatus(programId, isActive);
    }
  }

  // Obtener programas por institución
  static Future<List<ProgramOpportunity>> getProgramsByInstitution(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseProgramsService.getProgramsByInstitution(institutionId);
    } else {
      return await ProgramsOpportunitiesService.getProgramsByInstitution(institutionId);
    }
  }

  // Obtener programa por ID
  static Future<ProgramOpportunity?> getProgramById(String programId) async {
    if (_useSupabase) {
      return await SupabaseProgramsService.getProgramById(programId);
    } else {
      return await ProgramsOpportunitiesService.getProgramById(programId);
    }
  }

  // Actualizar programa
  static Future<void> updateProgram(String programId, Map<String, dynamic> updates) async {
    if (_useSupabase) {
      return await SupabaseProgramsService.updateProgram(programId, updates);
    } else {
      return await ProgramsOpportunitiesService.updateProgram(programId, updates);
    }
  }

  // Eliminar programa
  static Future<void> deleteProgram(String programId) async {
    if (_useSupabase) {
      return await SupabaseProgramsService.deleteProgram(programId);
    } else {
      return await ProgramsOpportunitiesService.deleteProgram(programId);
    }
  }
}
