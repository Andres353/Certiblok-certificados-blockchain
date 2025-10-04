// lib/services/certificate_service.dart
// Servicio para gestionar certificados con aislamiento por institución

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_context_service.dart';
import 'emisor_permission_service.dart';

class Certificate {
  final String id;
  final String uniqueHash;           // Hash SHA-256 único
  final String institutionId;
  final String institutionName;
  final String institutionCode;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentIdInInstitution; // CI o ID interno
  final String programId;
  final String programName;
  final String facultyId;
  final String facultyName;
  final String certificateType;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final String? blockchainHash;      // Hash en blockchain (futuro)
  final String qrCode;               // Código QR para validación
  final DateTime issuedAt;
  final String issuedBy;             // ID del emisor
  final String issuedByName;         // Nombre del emisor
  final String issuedByRole;         // Rol del emisor
  final String status;               // 'active', 'revoked', 'expired'
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? revokedBy;
  final String? revokedReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> validationHistory; // Historial de validaciones

  Certificate({
    required this.id,
    required this.uniqueHash,
    required this.institutionId,
    required this.institutionName,
    required this.institutionCode,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.studentIdInInstitution,
    required this.programId,
    required this.programName,
    required this.facultyId,
    required this.facultyName,
    required this.certificateType,
    required this.title,
    required this.description,
    required this.data,
    this.blockchainHash,
    required this.qrCode,
    required this.issuedAt,
    required this.issuedBy,
    required this.issuedByName,
    required this.issuedByRole,
    required this.status,
    this.expiresAt,
    this.revokedAt,
    this.revokedBy,
    this.revokedReason,
    required this.createdAt,
    required this.updatedAt,
    required this.validationHistory,
  });

  factory Certificate.fromFirestore(Map<String, dynamic> data, String id) {
    return Certificate(
      id: id,
      uniqueHash: data['uniqueHash'] ?? '',
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      institutionCode: data['institutionCode'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      studentIdInInstitution: data['studentIdInInstitution'] ?? '',
      programId: data['programId'] ?? '',
      programName: data['programName'] ?? '',
      facultyId: data['facultyId'] ?? '',
      facultyName: data['facultyName'] ?? '',
      certificateType: data['certificateType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      blockchainHash: data['blockchainHash'],
      qrCode: data['qrCode'] ?? '',
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      issuedBy: data['issuedBy'] ?? '',
      issuedByName: data['issuedByName'] ?? '',
      issuedByRole: data['issuedByRole'] ?? '',
      status: data['status'] ?? 'active',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
      revokedBy: data['revokedBy'],
      revokedReason: data['revokedReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validationHistory: List<Map<String, dynamic>>.from(data['validationHistory'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uniqueHash': uniqueHash,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'institutionCode': institutionCode,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentIdInInstitution': studentIdInInstitution,
      'programId': programId,
      'programName': programName,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'certificateType': certificateType,
      'title': title,
      'description': description,
      'data': data,
      'blockchainHash': blockchainHash,
      'qrCode': qrCode,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'issuedBy': issuedBy,
      'issuedByName': issuedByName,
      'issuedByRole': issuedByRole,
      'status': status,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
      'revokedBy': revokedBy,
      'revokedReason': revokedReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'validationHistory': validationHistory,
    };
  }
}

class CertificateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'certificates';

  // Generar hash único del certificado
  static String _generateUniqueHash(String certificateId, DateTime issuedAt, String studentId, String institutionId) {
    final data = '$certificateId-$issuedAt-$studentId-$institutionId';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generar código QR para validación
  static String _generateQRCode(String certificateId, String institutionCode) {
    // URL de validación pública
    return 'https://certiblock.com/validate/$certificateId';
  }

  // Crear nuevo certificado con validación de permisos mejorada
  static Future<String> createCertificate({
    required String studentId,
    required String certificateType,
    required String title,
    required String description,
    required Map<String, dynamic> data,
    String? institutionId, // Para super admin
    DateTime? expiresAt,
  }) async {
    try {
      // Verificar contexto de usuario
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener información del estudiante
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        throw Exception('Estudiante no encontrado');
      }

      final studentData = studentDoc.data()!;
      final studentName = studentData['fullName'] ?? '';
      final studentEmail = studentData['email'] ?? '';
      final studentIdInInstitution = studentData['ci'] ?? studentData['studentId'] ?? '';

      // Determinar institución según el rol
      String targetInstitutionId;
      String institutionName;
      String institutionCode;

      if (context.isSuperAdmin) {
        // Super admin debe especificar institución
        targetInstitutionId = institutionId ?? '';
        if (targetInstitutionId.isEmpty) {
          throw Exception('Super admin debe especificar institución');
        }
        
        // Obtener información de la institución
        final institutionDoc = await _firestore.collection('institutions').doc(targetInstitutionId).get();
        if (!institutionDoc.exists) {
          throw Exception('Institución no encontrada');
        }
        
        final institutionData = institutionDoc.data()!;
        institutionName = institutionData['name'] ?? '';
        institutionCode = institutionData['institutionCode'] ?? '';
      } else {
        // Otros usuarios usan su institución actual
        targetInstitutionId = context.institutionId ?? '';
        if (targetInstitutionId.isEmpty) {
          throw Exception('Usuario debe tener institución asignada');
        }
        
        // Obtener información de la institución desde Firestore
        final institutionDoc = await _firestore.collection('institutions').doc(targetInstitutionId).get();
        if (!institutionDoc.exists) {
          throw Exception('Institución no encontrada');
        }
        
        final institutionData = institutionDoc.data()!;
        institutionName = institutionData['name'] ?? '';
        institutionCode = institutionData['institutionCode'] ?? '';
      }

      // Verificar permisos según el rol
      if (context.userRole == 'emisor') {
        // Verificar si el emisor puede emitir para este estudiante
        final canEmit = await EmisorPermissionService.canEmitForStudent(
          studentId: studentId,
          institutionId: targetInstitutionId,
        );
        
        if (!canEmit) {
          throw Exception('No tienes permisos para emitir certificados para este estudiante');
        }
      } else if (!['super_admin', 'admin_institution'].contains(context.userRole)) {
        throw Exception('No tienes permisos para emitir certificados');
      }

      // Obtener información académica del estudiante
      final programId = studentData['programId'] ?? '';
      final programName = studentData['program'] ?? '';
      final facultyId = studentData['facultyId'] ?? '';
      final facultyName = studentData['faculty'] ?? '';

      // Crear documento del certificado
      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();
      final certificateId = docRef.id;

      // Generar hash único y QR
      final uniqueHash = _generateUniqueHash(certificateId, now, studentId, targetInstitutionId);
      final qrCode = _generateQRCode(certificateId, institutionCode);

      // Crear el certificado
      final certificate = Certificate(
        id: certificateId,
        uniqueHash: uniqueHash,
        institutionId: targetInstitutionId,
        institutionName: institutionName,
        institutionCode: institutionCode,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        studentIdInInstitution: studentIdInInstitution,
        programId: programId,
        programName: programName,
        facultyId: facultyId,
        facultyName: facultyName,
        certificateType: certificateType,
        title: title,
        description: description,
        data: data,
        blockchainHash: null, // Se llenará en el futuro
        qrCode: qrCode,
        issuedAt: now,
        issuedBy: context.userId,
        issuedByName: context.userName,
        issuedByRole: context.userRole,
        status: 'active',
        expiresAt: expiresAt,
        createdAt: now,
        updatedAt: now,
        validationHistory: [],
      );

      // Guardar en Firestore
      final firestoreData = certificate.toFirestore();
      print('📄 Datos del certificado a guardar:');
      print('  - ID: $certificateId');
      print('  - Estudiante: $studentName ($studentId)');
      print('  - Institución: $institutionName ($targetInstitutionId)');
      print('  - Tipo: $certificateType');
      print('  - Título: $title');
      print('  - Hash único: $uniqueHash');
      print('  - QR Code: $qrCode');
      
      await docRef.set(firestoreData);

      print('✅ Certificado guardado exitosamente en Firestore: $certificateId');
      return certificateId;
    } catch (e) {
      print('❌ Error creando certificado: $e');
      throw Exception('Error al crear certificado: $e');
    }
  }

  // Forzar actualización de información de institución para un certificado específico
  static Future<void> forceUpdateInstitutionInfo(String certificateId) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null || context.institutionId == null) return;

      // Obtener información de la institución
      final institutionDoc = await _firestore
          .collection('institutions')
          .doc(context.institutionId!)
          .get();

      if (!institutionDoc.exists) return;

      final institutionData = institutionDoc.data()!;
      final institutionName = institutionData['name'] ?? '';
      final institutionCode = institutionData['institutionCode'] ?? '';

      // Actualizar el certificado específico
      await _firestore.collection(_collection).doc(certificateId).update({
        'institutionName': institutionName,
        'institutionCode': institutionCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Certificado $certificateId actualizado con información de institución');
      print('   - Nombre: "$institutionName"');
      print('   - Código: "$institutionCode"');
    } catch (e) {
      print('❌ Error actualizando certificado específico: $e');
    }
  }

  // Actualizar certificados existentes que tengan información de institución vacía
  static Future<void> updateInstitutionInfoForExistingCertificates() async {
    try {
      final context = UserContextService.currentContext;
      if (context == null || context.institutionId == null) return;

      // Obtener todos los certificados de la institución
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('institutionId', isEqualTo: context.institutionId)
          .get();

      // Obtener información de la institución
      final institutionDoc = await _firestore
          .collection('institutions')
          .doc(context.institutionId!)
          .get();

      if (!institutionDoc.exists) return;

      final institutionData = institutionDoc.data()!;
      final institutionName = institutionData['name'] ?? '';
      final institutionCode = institutionData['institutionCode'] ?? '';

      print('🔍 Información de institución encontrada:');
      print('   - Nombre: "$institutionName"');
      print('   - Código: "$institutionCode"');
      print('   - Total certificados a revisar: ${querySnapshot.docs.length}');

      // Actualizar certificados que tengan información vacía
      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final currentInstitutionName = data['institutionName']?.toString() ?? '';
        final currentInstitutionCode = data['institutionCode']?.toString() ?? '';
        
        final needsUpdate = (data['institutionName'] == null || data['institutionName'].toString().isEmpty) ||
                           (data['institutionCode'] == null || data['institutionCode'].toString().isEmpty);

        print('📋 Certificado ${doc.id}:');
        print('   - Nombre actual: "$currentInstitutionName"');
        print('   - Código actual: "$currentInstitutionCode"');
        print('   - Necesita actualización: $needsUpdate');

        if (needsUpdate) {
          batch.update(doc.reference, {
            'institutionName': institutionName,
            'institutionCode': institutionCode,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
          print('   ✅ Marcado para actualización');
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('✅ Actualizados $updateCount certificados con información de institución');
      }
    } catch (e) {
      print('❌ Error actualizando información de institución: $e');
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

      // Obtener todos los certificados y filtrar en memoria para evitar problemas de índice
      Query query = _firestore.collection(_collection);

      // Solo aplicar filtro de institución si no es super admin
      if (!context.isSuperAdmin) {
        final institutionId = context.institutionId;
        if (institutionId == null || institutionId.isEmpty) {
          throw Exception('Usuario debe tener institución asignada');
        }
        query = query.where('institutionId', isEqualTo: institutionId);
      }

      // Actualizar certificados existentes con información de institución vacía PRIMERO
      await updateInstitutionInfoForExistingCertificates();
      
      // Ahora obtener los certificados actualizados
      final querySnapshot = await query.get();
      print('📋 Obteniendo certificados: ${querySnapshot.docs.length} documentos encontrados');
      
      // Convertir a objetos Certificate
      List<Certificate> certificates = querySnapshot.docs
          .map((doc) => Certificate.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      print('📋 Certificados convertidos: ${certificates.length} objetos');

      // Aplicar filtros adicionales en memoria
      if (studentId != null) {
        certificates = certificates.where((cert) => cert.studentId == studentId).toList();
      }
      if (certificateType != null) {
        certificates = certificates.where((cert) => cert.certificateType == certificateType).toList();
      }
      if (status != null) {
        certificates = certificates.where((cert) => cert.status == status).toList();
      }

      // Ordenar por fecha de emisión (descendente)
      certificates.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

      // Aplicar límite
      if (limit != null && limit > 0) {
        certificates = certificates.take(limit).toList();
      }

      print('📋 Certificados finales devueltos: ${certificates.length}');
      return certificates;
    } catch (e) {
      throw Exception('Error al obtener certificados: $e');
    }
  }

  // Validar certificado por QR o ID
  static Future<CertificateValidationResult> validateCertificate({
    String? qrCode,
    String? certificateId,
  }) async {
    try {
      String? targetId = certificateId;
      
      // Si se proporciona QR, extraer ID del certificado
      if (qrCode != null && qrCode.isNotEmpty) {
        // Extraer ID del QR (formato: https://certiblock.com/validate/{id})
        final uri = Uri.tryParse(qrCode);
        if (uri != null) {
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 2 && pathSegments[0] == 'validate') {
            targetId = pathSegments[1];
          }
        }
      }
      
      if (targetId == null || targetId.isEmpty) {
        return CertificateValidationResult(
          isValid: false,
          message: 'ID de certificado no válido',
        );
      }
      
      // Buscar certificado
      final doc = await _firestore.collection(_collection).doc(targetId).get();
      if (!doc.exists) {
        return CertificateValidationResult(
          isValid: false,
          message: 'Certificado no encontrado',
        );
      }
      
      final certificate = Certificate.fromFirestore(doc.data()!, doc.id);
      
      // Verificar estado
      if (certificate.status != 'active') {
        String statusMessage = '';
        switch (certificate.status) {
          case 'revoked':
            statusMessage = 'Certificado revocado';
            break;
          case 'expired':
            statusMessage = 'Certificado expirado';
            break;
          default:
            statusMessage = 'Certificado no válido';
        }
        
        return CertificateValidationResult(
          isValid: false,
          message: statusMessage,
          certificate: certificate,
        );
      }
      
      // Verificar expiración
      if (certificate.expiresAt != null && DateTime.now().isAfter(certificate.expiresAt!)) {
        return CertificateValidationResult(
          isValid: false,
          message: 'Certificado expirado',
          certificate: certificate,
        );
      }
      
      // Registrar validación
      await _recordValidation(targetId, true, 'Validación exitosa');
      
      return CertificateValidationResult(
        isValid: true,
        message: 'Certificado válido',
        certificate: certificate,
      );
    } catch (e) {
      print('❌ Error validando certificado: $e');
      return CertificateValidationResult(
        isValid: false,
        message: 'Error al validar certificado: $e',
      );
    }
  }
  
  // Registrar validación en el historial
  static Future<void> _recordValidation(String certificateId, bool isValid, String message) async {
    try {
      await _firestore.collection(_collection).doc(certificateId).update({
        'validationHistory': FieldValue.arrayUnion([{
          'timestamp': FieldValue.serverTimestamp(),
          'isValid': isValid,
          'message': message,
          'validatedAt': DateTime.now().toIso8601String(),
        }]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error registrando validación: $e');
    }
  }
  
  // Revocar certificado
  static Future<bool> revokeCertificate(String certificateId, String reason) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Verificar permisos
      if (!['super_admin', 'admin_institution'].contains(context.userRole)) {
        throw Exception('No tienes permisos para revocar certificados');
      }
      
      await _firestore.collection(_collection).doc(certificateId).update({
        'status': 'revoked',
        'revokedAt': FieldValue.serverTimestamp(),
        'revokedBy': context.userId,
        'revokedReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Certificado revocado: $certificateId');
      return true;
    } catch (e) {
      print('❌ Error revocando certificado: $e');
      return false;
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

// Clase para resultado de validación de certificados
class CertificateValidationResult {
  final bool isValid;
  final String message;
  final Certificate? certificate;
  final DateTime validatedAt;

  CertificateValidationResult({
    required this.isValid,
    required this.message,
    this.certificate,
    DateTime? validatedAt,
  }) : validatedAt = validatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'message': message,
      'certificate': certificate?.toFirestore(),
      'validatedAt': validatedAt.toIso8601String(),
    };
  }
}
