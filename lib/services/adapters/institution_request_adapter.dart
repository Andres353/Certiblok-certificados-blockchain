// lib/services/adapters/institution_request_adapter.dart
import '../institution_request_service.dart';
import '../supabase/supabase_institution_request_service.dart';

class InstitutionRequestAdapter {
  static bool _useSupabase = true; // Flag para cambiar entre Firebase y Supabase - AHORA USA SUPABASE

  // Cambiar entre Firebase y Supabase
  static void useSupabase(bool useSupabase) {
    _useSupabase = useSupabase;
    print('🔄 InstitutionRequestAdapter: ${useSupabase ? "Usando Supabase" : "Usando Firebase"}');
  }

  // Crear una nueva solicitud
  static Future<String> createRequest({
    required String institutionName,
    required String shortName,
    required String institutionType,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
    required String address,
    required String city,
    required String country,
    required String department,
    required String website,
    required String description,
    required String logoUrl,
    required String documents,
    required String ruc,
    required String ministerialResolution,
  }) async {
    print('🔍 InstitutionRequestAdapter.createRequest:');
    print('   - _useSupabase: $_useSupabase');
    print('   - institutionName: $institutionName');
    
    if (_useSupabase) {
      print('🔄 Creando solicitud en Supabase...');
      final result = await SupabaseInstitutionRequestService.createRequest(
        institutionName: institutionName,
        shortName: shortName,
        institutionType: institutionType,
        contactName: contactName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        address: address,
        city: city,
        country: country,
        department: department,
        website: website,
        description: description,
        logoUrl: logoUrl,
        documents: documents,
        ruc: ruc,
        ministerialResolution: ministerialResolution,
      );
      print('✅ Solicitud creada en Supabase con ID: $result');
      return result;
    } else {
      print('🔄 Creando solicitud en Firebase...');
      final result = await InstitutionRequestService.createRequest(
        institutionName: institutionName,
        shortName: shortName,
        institutionType: institutionType,
        contactName: contactName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        address: address,
        city: city,
        country: country,
        department: department,
        website: website,
        description: description,
        logoUrl: logoUrl,
        documents: documents,
        ruc: ruc,
        ministerialResolution: ministerialResolution,
      );
      print('✅ Solicitud creada en Firebase con ID: $result');
      return result;
    }
  }

  // Obtener todas las solicitudes
  static Future<List<InstitutionRequest>> getAllRequests() async {
    print('🔍 InstitutionRequestAdapter.getAllRequests:');
    print('   - _useSupabase: $_useSupabase');
    
    if (_useSupabase) {
      final requests = await SupabaseInstitutionRequestService.getAllRequests();
      print('   - Solicitudes desde Supabase: ${requests.length}');
      return requests;
    } else {
      final requests = await InstitutionRequestService.getAllRequests();
      print('   - Solicitudes desde Firebase: ${requests.length}');
      return requests;
    }
  }

  // Obtener solicitudes por estado
  static Future<List<InstitutionRequest>> getRequestsByStatus(String status) async {
    if (_useSupabase) {
      return await SupabaseInstitutionRequestService.getRequestsByStatus(status);
    } else {
      return await InstitutionRequestService.getRequestsByStatus(status);
    }
  }

  // Obtener una solicitud específica
  static Future<InstitutionRequest?> getRequestById(String id) async {
    if (_useSupabase) {
      return await SupabaseInstitutionRequestService.getRequestById(id);
    } else {
      return await InstitutionRequestService.getRequestById(id);
    }
  }

  // Aprobar una solicitud
  static Future<bool> approveRequest(String requestId, String reviewedBy) async {
    print('🔍 InstitutionRequestAdapter.approveRequest:');
    print('   - _useSupabase: $_useSupabase');
    print('   - requestId: $requestId');
    print('   - reviewedBy: $reviewedBy');
    
    if (_useSupabase) {
      return await SupabaseInstitutionRequestService.approveRequest(requestId, reviewedBy);
    } else {
      return await InstitutionRequestService.approveRequest(requestId, reviewedBy);
    }
  }

  // Rechazar una solicitud
  static Future<bool> rejectRequest(String requestId, String reviewedBy, String reason) async {
    if (_useSupabase) {
      return await SupabaseInstitutionRequestService.rejectRequest(requestId, reviewedBy, reason);
    } else {
      return await InstitutionRequestService.rejectRequest(requestId, reviewedBy, reason);
    }
  }

  // Obtener estadísticas de solicitudes
  static Future<Map<String, int>> getRequestStats() async {
    if (_useSupabase) {
      return await SupabaseInstitutionRequestService.getRequestStats();
    } else {
      return await InstitutionRequestService.getRequestStats();
    }
  }
}
