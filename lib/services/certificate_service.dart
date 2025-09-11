// lib/services/certificate_service.dart
// Servicio para gestionar certificados con aislamiento por institución

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/institution.dart';
import 'user_context_service.dart';

class Certificate {
  final String id;
  final String institutionId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String certificateType;
  final String program;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final String? blockchainHash;
  final String? qrCode;
  final DateTime issuedAt;
  final String issuedBy;
  final String status; // 'active', 'revoked', 'expired'
  final DateTime? expiresAt;

  Certificate({
    required this.id,
    required this.institutionId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.certificateType,
    required this.program,
    required this.title,
    required this.description,
    required this.data,
    this.blockchainHash,
    this.qrCode,
    required this.issuedAt,
    required this.issuedBy,
    required this.status,
    this.expiresAt,
  });

  factory Certificate.fromFirestore(Map<String, dynamic> data, String id) {
    return Certificate(
      id: id,
      institutionId: data['institutionId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      certificateType: data['certificateType'] ?? '',
      program: data['program'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      blockchainHash: data['blockchainHash'],
      qrCode: data['qrCode'],
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      issuedBy: data['issuedBy'] ?? '',
      status: data['status'] ?? 'active',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'institutionId': institutionId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'certificateType': certificateType,
      'program': program,
      'title': title,
      'description': description,
      'data': data,
      'blockchainHash': blockchainHash,
      'qrCode': qrCode,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'issuedBy': issuedBy,
      'status': status,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}

class CertificateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'certificates';

  // Crear nuevo certificado (con aislamiento por institución)
  static Future<String> createCertificate({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String certificateType,
    required String program,
    required String title,
    required String description,
    required Map<String, dynamic> data,
    String? blockchainHash,
    String? qrCode,
    String? issuedBy,
    DateTime? expiresAt,
  }) async {
    try {
      // Verificar contexto de usuario
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos
      if (!context.canIssueCertificates) {
        throw Exception('No tienes permisos para emitir certificados');
      }

      // Obtener ID de institución
      String institutionId;
      if (context.isSuperAdmin) {
        // Super admin debe especificar institución
        institutionId = data['institutionId'] ?? context.institutionId ?? '';
        if (institutionId.isEmpty) {
          throw Exception('Super admin debe especificar institución');
        }
      } else {
        // Otros usuarios usan su institución actual
        institutionId = context.institutionId ?? '';
        if (institutionId.isEmpty) {
          throw Exception('Usuario debe tener institución asignada');
        }
      }

      final docRef = await _firestore.collection(_collection).add({
        'institutionId': institutionId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'certificateType': certificateType,
        'program': program,
        'title': title,
        'description': description,
        'data': data,
        'blockchainHash': blockchainHash,
        'qrCode': qrCode,
        'issuedAt': FieldValue.serverTimestamp(),
        'issuedBy': issuedBy ?? context.userId,
        'status': 'active',
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear certificado: $e');
    }
  }

  // Obtener certificados (con filtro por institución)
  static Future<List<Certificate>> getCertificates({
    String? studentId,
    String? certificateType,
    String? status,
    int? limit,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      Query query = _firestore.collection(_collection);

      // Aplicar filtro de institución
      if (!context.isSuperAdmin) {
        final institutionId = context.institutionId;
        if (institutionId == null || institutionId.isEmpty) {
          throw Exception('Usuario debe tener institución asignada');
        }
        query = query.where('institutionId', isEqualTo: institutionId);
      }

      // Aplicar filtros adicionales
      if (studentId != null) {
        query = query.where('studentId', isEqualTo: studentId);
      }
      if (certificateType != null) {
        query = query.where('certificateType', isEqualTo: certificateType);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Ordenar por fecha de emisión
      query = query.orderBy('issuedAt', descending: true);

      // Aplicar límite
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => Certificate.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener certificados: $e');
    }
  }

  // Obtener certificado por ID (con verificación de acceso)
  static Future<Certificate?> getCertificateById(String certificateId) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      final doc = await _firestore.collection(_collection).doc(certificateId).get();
      if (!doc.exists) {
        return null;
      }

      final certificate = Certificate.fromFirestore(doc.data()!, doc.id);

      // Verificar acceso a la institución
      if (!UserContextService.hasAccessToInstitution(certificate.institutionId)) {
        throw Exception('No tienes acceso a este certificado');
      }

      return certificate;
    } catch (e) {
      throw Exception('Error al obtener certificado: $e');
    }
  }

  // Buscar certificados por QR code (público)
  static Future<Certificate?> getCertificateByQRCode(String qrCode) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('qrCode', isEqualTo: qrCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Certificate.fromFirestore(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Error al buscar certificado por QR: $e');
    }
  }

  // Actualizar certificado (con verificación de acceso)
  static Future<void> updateCertificate(String certificateId, Map<String, dynamic> updates) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar acceso al certificado
      final certificate = await getCertificateById(certificateId);
      if (certificate == null) {
        throw Exception('Certificado no encontrado');
      }

      // Verificar permisos
      if (!context.canIssueCertificates) {
        throw Exception('No tienes permisos para actualizar certificados');
      }

      await _firestore.collection(_collection).doc(certificateId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar certificado: $e');
    }
  }

  // Revocar certificado
  static Future<void> revokeCertificate(String certificateId, String reason) async {
    try {
      await updateCertificate(certificateId, {
        'status': 'revoked',
        'revocationReason': reason,
        'revokedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al revocar certificado: $e');
    }
  }

  // Obtener estadísticas de certificados (con filtro por institución)
  static Future<Map<String, int>> getCertificateStats() async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      Query query = _firestore.collection(_collection);

      // Aplicar filtro de institución
      if (!context.isSuperAdmin) {
        final institutionId = context.institutionId;
        if (institutionId == null || institutionId.isEmpty) {
          throw Exception('Usuario debe tener institución asignada');
        }
        query = query.where('institutionId', isEqualTo: institutionId);
      }

      final querySnapshot = await query.get();
      
      int total = querySnapshot.docs.length;
      int active = 0;
      int revoked = 0;
      int expired = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'active';
        
        switch (status) {
          case 'active':
            active++;
            break;
          case 'revoked':
            revoked++;
            break;
          case 'expired':
            expired++;
            break;
        }
      }

      return {
        'total': total,
        'active': active,
        'revoked': revoked,
        'expired': expired,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Verificar validez de certificado
  static Future<bool> verifyCertificate(String certificateId) async {
    try {
      final certificate = await getCertificateById(certificateId);
      if (certificate == null) return false;

      // Verificar estado
      if (certificate.status != 'active') return false;

      // Verificar expiración
      if (certificate.expiresAt != null && 
          certificate.expiresAt!.isBefore(DateTime.now())) {
        return false;
      }

      // Verificar hash de blockchain (si existe)
      if (certificate.blockchainHash != null) {
        // Aquí se implementaría la verificación blockchain
        // Por ahora, asumimos que es válido
        return true;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
