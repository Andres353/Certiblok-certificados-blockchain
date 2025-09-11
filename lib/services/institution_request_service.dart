import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/institution.dart';
import 'institution_service.dart';
import 'email_notification_service.dart';

class InstitutionRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'institution_requests';

  // Obtener todas las solicitudes
  static Future<List<InstitutionRequest>> getAllRequests() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return InstitutionRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error al obtener solicitudes: $e');
      return [];
    }
  }

  // Obtener solicitudes por estado
  static Future<List<InstitutionRequest>> getRequestsByStatus(String status) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return InstitutionRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error al obtener solicitudes por estado: $e');
      return [];
    }
  }

  // Obtener una solicitud específica
  static Future<InstitutionRequest?> getRequestById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (doc.exists) {
        return InstitutionRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
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

      print('✅ Solicitud encontrada: ${request.institutionName}');

      // Crear la institución
      final Institution institution = Institution(
        id: '',
        name: request.institutionName,
        shortName: request.shortName,
        description: request.description,
        logoUrl: request.logoUrl,
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
      print('🔄 Creando institución en Firestore...');
      final String institutionId = await InstitutionService.createInstitution(
        name: institution.name,
        shortName: institution.shortName,
        description: institution.description,
        logoUrl: institution.logoUrl,
        colors: institution.colors,
        settings: institution.settings,
        createdBy: reviewedBy,
      );

      print('✅ Institución creada con ID: $institutionId');

      // Actualizar la solicitud como aprobada
      print('🔄 Actualizando estado de solicitud...');
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'approved',
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
        'institutionId': institutionId,
      });

      print('✅ Solicitud aprobada y institución creada: $institutionId');

      // Enviar notificación por email
      print('📧 Enviando notificación de aprobación...');
      await EmailNotificationService.sendApprovalNotification(
        institutionName: request.institutionName,
        contactEmail: request.contactEmail,
        contactName: request.contactName,
        institutionId: institutionId,
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

      // Actualizar estado de la solicitud
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'rejected',
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      print('✅ Solicitud rechazada: $requestId');

      // Enviar notificación por email
      print('📧 Enviando notificación de rechazo...');
      await EmailNotificationService.sendRejectionNotification(
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
      final QuerySnapshot allRequests = await _firestore.collection(_collection).get();
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (var doc in allRequests.docs) {
        final data = doc.data() as Map<String, dynamic>;
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
        'total': allRequests.docs.length,
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

// Modelo para las solicitudes de institución
class InstitutionRequest {
  final String id;
  final String institutionName;
  final String shortName;
  final String institutionType;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final String city;
  final String country;
  final String website;
  final String description;
  final String logoUrl;
  final String documents;
  final String status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? institutionId;

  InstitutionRequest({
    required this.id,
    required this.institutionName,
    required this.shortName,
    required this.institutionType,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    required this.city,
    required this.country,
    required this.website,
    required this.description,
    required this.logoUrl,
    required this.documents,
    this.status = 'pending',
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.institutionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'institutionName': institutionName,
      'shortName': shortName,
      'institutionType': institutionType,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'city': city,
      'country': country,
      'website': website,
      'description': description,
      'logoUrl': logoUrl,
      'documents': documents,
      'status': status,
      'requestedAt': requestedAt,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'rejectionReason': rejectionReason,
      'institutionId': institutionId,
    };
  }

  static InstitutionRequest fromMap(Map<String, dynamic> map, String id) {
    return InstitutionRequest(
      id: id,
      institutionName: map['institutionName'] ?? '',
      shortName: map['shortName'] ?? '',
      institutionType: map['institutionType'] ?? '',
      contactName: map['contactName'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      website: map['website'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      documents: map['documents'] ?? '',
      status: map['status'] ?? 'pending',
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null 
          ? (map['reviewedAt'] as Timestamp).toDate() 
          : null,
      rejectionReason: map['rejectionReason'],
      institutionId: map['institutionId'],
    );
  }

  String getInstitutionTypeLabel() {
    switch (institutionType) {
      case 'university': return 'Universidad';
      case 'college': return 'Colegio';
      case 'school': return 'Escuela';
      case 'institute': return 'Instituto';
      case 'academy': return 'Academia';
      case 'other': return 'Otro';
      default: return institutionType;
    }
  }

  String getStatusLabel() {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'approved': return 'Aprobada';
      case 'rejected': return 'Rechazada';
      default: return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}
