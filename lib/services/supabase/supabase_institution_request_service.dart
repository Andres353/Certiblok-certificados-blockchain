// lib/services/supabase/supabase_institution_request_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../institution_request_service.dart';
import 'supabase_email_notification_service.dart';
import '../../models/institution.dart';
import 'supabase_config.dart';
import 'supabase_institution_service.dart';
import 'supabase_auth_service.dart';

class SupabaseInstitutionRequestService {
  static SupabaseClient get _client => SupabaseConfig.client;
  static const String _collection = 'institution_requests';

  // Verificar si un string es un UUID válido
  static bool _isValidUUID(String id) {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(id);
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
    try {
      final response = await _client.from(_collection).insert({
        'institution_name': institutionName,
        'short_name': shortName,
        'institution_type': institutionType,
        'contact_name': contactName,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'address': address,
        'city': city,
        'country': country,
        'department': department,
        'website': website,
        'description': description,
        'logo_url': logoUrl,
        'documents': documents,
        'ruc': ruc,
        'ministerial_resolution': ministerialResolution,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        final requestId = response.first['id'].toString();
        print('✅ Solicitud de institución creada con ID: $requestId');
        return requestId;
      } else {
        throw Exception('No se pudo crear la solicitud');
      }
    } catch (e) {
      print('❌ Error al crear solicitud: $e');
      rethrow;
    }
  }

  // Obtener todas las solicitudes
  static Future<List<InstitutionRequest>> getAllRequests() async {
    try {
      final response = await _client
          .from(_collection)
          .select('*')
          .order('created_at', ascending: false);

      return response.map((data) {
        return InstitutionRequest.fromSupabase(data, data['id'].toString());
      }).toList();
    } catch (e) {
      print('Error al obtener solicitudes: $e');
      return [];
    }
  }

  // Obtener solicitudes por estado
  static Future<List<InstitutionRequest>> getRequestsByStatus(String status) async {
    try {
      final response = await _client
          .from(_collection)
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      return response.map((data) {
        return InstitutionRequest.fromSupabase(data, data['id'].toString());
      }).toList();
    } catch (e) {
      print('Error al obtener solicitudes por estado: $e');
      return [];
    }
  }

  // Obtener una solicitud específica
  static Future<InstitutionRequest?> getRequestById(String id) async {
    try {
      // Si el ID no es un UUID válido, buscar por otros campos
      if (!_isValidUUID(id)) {
        print('⚠️ ID no es UUID válido, buscando por otros campos: $id');
        
        // Buscar por institution_name o contact_email como alternativa
        final response = await _client
            .from(_collection)
            .select('*')
            .or('institution_name.ilike.%$id%,contact_email.ilike.%$id%')
            .limit(1);
        
        if (response.isNotEmpty) {
          return InstitutionRequest.fromSupabase(response.first, response.first['id'].toString());
        }
        
        // Si no se encuentra, devolver null
        print('❌ Solicitud no encontrada con ID: $id');
        return null;
      }
      
      // Si es UUID válido, buscar normalmente
      final response = await _client
          .from(_collection)
          .select('*')
          .eq('id', id)
          .single();

      return InstitutionRequest.fromSupabase(response, response['id'].toString());
    } catch (e) {
      print('Error al obtener solicitud: $e');
      return null;
    }
  }

  // Aprobar una solicitud
  static Future<bool> approveRequest(String requestId, String reviewedBy) async {
    try {
      print('🔄 Iniciando aprobación de solicitud: $requestId');
      
      // Obtener la solicitud
      final InstitutionRequest? request = await getRequestById(requestId);
      if (request == null) {
        print('❌ Solicitud no encontrada: $requestId');
        return false;
      }

      // Verificar que la solicitud no esté ya aprobada o rechazada
      if (request.status == 'approved') {
        print('⚠️ La solicitud ya está aprobada: $requestId');
        return false;
      }
      
      if (request.status == 'rejected') {
        print('⚠️ La solicitud ya fue rechazada: $requestId');
        return false;
      }

      print('✅ Solicitud encontrada: ${request.institutionName}');

      // Generar código único para la institución
      print('🔄 Generando código único para la institución...');
      final String institutionCode = await SupabaseInstitutionService.generateUniqueCode(request.shortName);
      print('✅ Código generado: $institutionCode');

      // Crear la institución
      final Institution institution = Institution(
        id: '',
        name: request.institutionName,
        shortName: request.shortName,
        description: request.description,
        logoUrl: request.logoUrl,
        institutionCode: institutionCode,
        colors: InstitutionColors(
          primary: _getDefaultColorForType(request.institutionType),
          secondary: _getSecondaryColorForType(request.institutionType),
          accent: _getSecondaryColorForType(request.institutionType),
          background: '#FFFFFF',
          text: '#2E2F44',
        ),
        settings: InstitutionSettings(
          supportedPrograms: _getDefaultProgramsForType(request.institutionType),
          allowStudentRegistration: true,
          requireEmailVerification: true,
          allowPublicVerification: true,
          enableBlockchain: true,
          defaultLanguage: 'es',
          customFields: {},
        ),
        status: InstitutionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: reviewedBy,
      );

      // Guardar la institución
      print('🔄 Creando institución en Supabase...');
      final currentUserId = SupabaseAuthService.getCurrentUserId();
      String? userIdToUse;
      String createdByForInstitution;
      
      if (currentUserId == null) {
        print('⚠️ No hay usuario autenticado en Supabase, usando UUID fijo para super admin');
        userIdToUse = null; // Usar null para reviewed_by (sin foreign key constraint)
        createdByForInstitution = '00000000-0000-0000-0000-000000000001'; // UUID fijo para created_by
        print('🔄 Usando null para reviewed_by y UUID fijo para created_by');
      } else {
        userIdToUse = currentUserId;
        createdByForInstitution = currentUserId;
        print('🔄 Usando UUID del usuario autenticado: $userIdToUse');
      }
      
      final String institutionId = await SupabaseInstitutionService.createInstitution(
        name: institution.name,
        shortName: institution.shortName,
        description: institution.description,
        logoUrl: institution.logoUrl,
        institutionCode: institutionCode,
        colors: institution.colors,
        settings: institution.settings,
        createdBy: createdByForInstitution, // Usar UUID válido
      );

      print('✅ Institución creada con ID: $institutionId');

      // Actualizar la solicitud como aprobada
      print('🔄 Actualizando estado de solicitud...');
      
      // Si el requestId no es UUID válido, buscar por otros campos
      if (!_isValidUUID(requestId)) {
        print('⚠️ Actualizando solicitud con ID no UUID: $requestId');
        // Buscar la solicitud por nombre de institución o email
        final searchResponse = await _client
            .from(_collection)
            .select('id')
            .or('institution_name.ilike.%$requestId%,contact_email.ilike.%$requestId%')
            .limit(1);
        
        if (searchResponse.isNotEmpty) {
          final realId = searchResponse.first['id'].toString();
          await _client.from(_collection).update({
            'status': 'approved',
            'reviewed_by': userIdToUse, // Usar UUID válido o null
            'reviewed_at': DateTime.now().toIso8601String(),
            'institution_id': institutionId,
          }).eq('id', realId);
        } else {
          print('❌ No se pudo encontrar la solicitud para actualizar');
          return false;
        }
      } else {
        // Si es UUID válido, actualizar normalmente
        await _client.from(_collection).update({
          'status': 'approved',
          'reviewed_by': userIdToUse, // Usar UUID válido o null
          'reviewed_at': DateTime.now().toIso8601String(),
          'institution_id': institutionId,
        }).eq('id', requestId);
      }

      print('✅ Solicitud aprobada y institución creada: $institutionId');

      // Enviar notificación por email
      print('📧 Enviando notificación de aprobación...');
      await SupabaseEmailNotificationService.sendApprovalNotification(
        institutionName: request.institutionName,
        contactEmail: request.contactEmail,
        contactName: request.contactName,
        institutionId: institutionId,
        institutionCode: institutionCode,
      );

      return true;
    } catch (e) {
      print('Error al aprobar solicitud: $e');
      return false;
    }
  }

  // Rechazar una solicitud
  static Future<bool> rejectRequest(String requestId, String reviewedBy, String reason) async {
    try {
      // Obtener la solicitud para enviar notificación
      final InstitutionRequest? request = await getRequestById(requestId);
      if (request == null) {
        print('❌ Solicitud no encontrada: $requestId');
        return false;
      }

      // Verificar que la solicitud no esté ya aprobada o rechazada
      if (request.status == 'approved') {
        print('⚠️ La solicitud ya está aprobada: $requestId');
        return false;
      }
      
      if (request.status == 'rejected') {
        print('⚠️ La solicitud ya fue rechazada: $requestId');
        return false;
      }

      // Actualizar estado de la solicitud
      if (!_isValidUUID(requestId)) {
        print('⚠️ Rechazando solicitud con ID no UUID: $requestId');
        // Buscar la solicitud por nombre de institución o email
        final searchResponse = await _client
            .from(_collection)
            .select('id')
            .or('institution_name.ilike.%$requestId%,contact_email.ilike.%$requestId%')
            .limit(1);
        
        if (searchResponse.isNotEmpty) {
          final realId = searchResponse.first['id'].toString();
          await _client.from(_collection).update({
            'status': 'rejected',
            'reviewed_by': reviewedBy,
            'reviewed_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
          }).eq('id', realId);
        } else {
          print('❌ No se pudo encontrar la solicitud para rechazar');
          return false;
        }
      } else {
        // Si es UUID válido, actualizar normalmente
        await _client.from(_collection).update({
          'status': 'rejected',
          'reviewed_by': reviewedBy,
          'reviewed_at': DateTime.now().toIso8601String(),
          'rejection_reason': reason,
        }).eq('id', requestId);
      }

      print('✅ Solicitud rechazada: $requestId');

      // Enviar notificación por email
      print('📧 Enviando notificación de rechazo...');
      await SupabaseEmailNotificationService.sendRejectionNotification(
        institutionName: request.institutionName,
        contactEmail: request.contactEmail,
        contactName: request.contactName,
        rejectionReason: reason,
      );

      return true;
    } catch (e) {
      print('❌ Error al rechazar solicitud: $e');
      return false;
    }
  }

  // Obtener estadísticas de solicitudes
  static Future<Map<String, int>> getRequestStats() async {
    try {
      final response = await _client.from(_collection).select('status');
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (var data in response) {
        final status = data['status'] as String? ?? 'pending';
        
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return {
        'total': response.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  // Colores por defecto según tipo de institución
  static String _getDefaultColorForType(String type) {
    switch (type) {
      case 'university':
        return '#1976D2'; // Azul
      case 'college':
        return '#4CAF50'; // Verde
      case 'school':
        return '#FF9800'; // Naranja
      case 'institute':
        return '#9C27B0'; // Púrpura
      case 'academy':
        return '#E91E63'; // Rosa
      default:
        return '#607D8B'; // Azul gris
    }
  }

  static String _getSecondaryColorForType(String type) {
    switch (type) {
      case 'university':
        return '#42A5F5'; // Azul claro
      case 'college':
        return '#66BB6A'; // Verde claro
      case 'school':
        return '#FFB74D'; // Naranja claro
      case 'institute':
        return '#BA68C8'; // Púrpura claro
      case 'academy':
        return '#F06292'; // Rosa claro
      default:
        return '#90A4AE'; // Azul gris claro
    }
  }

  // Programas por defecto según tipo
  static List<String> _getDefaultProgramsForType(String type) {
    switch (type) {
      case 'university':
        return ['Pregrado', 'Posgrado', 'Maestría', 'Doctorado'];
      case 'college':
        return ['Bachillerato', 'Técnico', 'Tecnológico'];
      case 'school':
        return ['Primaria', 'Secundaria', 'Bachillerato'];
      case 'institute':
        return ['Técnico', 'Tecnológico', 'Especialización'];
      case 'academy':
        return ['Cursos', 'Diplomados', 'Certificaciones'];
      default:
        return ['General'];
    }
  }

}
