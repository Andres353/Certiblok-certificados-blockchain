// lib/services/adapters/certificate_adapter.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../certificate_service.dart' as cert_service;
import '../supabase/supabase_certificate_service.dart';
import '../../models/certificate.dart';

class CertificateAdapter {
  static bool _useSupabase = true; // Flag para cambiar entre Firebase y Supabase

  // Cambiar entre Firebase y Supabase
  static void useSupabase(bool useSupabase) {
    _useSupabase = useSupabase;
    print('🔄 CertificateAdapter: ${useSupabase ? "Usando Supabase" : "Usando Firebase"}');
  }

  // Crear nuevo certificado
  static Future<String> createCertificate({
    required String studentId,
    required String certificateType,
    required String title,
    required String description,
    required Map<String, dynamic> data,
    String? institutionId,
    DateTime? expiresAt,
  }) async {
    if (_useSupabase) {
      return await SupabaseCertificateService.createCertificate(
        studentId: studentId,
        certificateType: certificateType,
        title: title,
        description: description,
        data: data,
        institutionId: institutionId,
        expiresAt: expiresAt,
      );
    } else {
      return await cert_service.CertificateService.createCertificate(
        studentId: studentId,
        certificateType: certificateType,
        title: title,
        description: description,
        data: data,
        institutionId: institutionId,
        expiresAt: expiresAt,
      );
    }
  }

  // Obtener certificado por ID
  static Future<dynamic> getCertificate(String id) async {
    if (_useSupabase) {
      return await SupabaseCertificateService.getCertificate(id);
    } else {
      return await cert_service.CertificateService.getCertificateById(id);
    }
  }

  // Obtener certificado para verificación pública (sin autenticación)
  static Future<dynamic> getCertificatePublic(String id) async {
    if (_useSupabase) {
      return await SupabaseCertificateService.getCertificatePublic(id);
    } else {
      return await cert_service.CertificateService.getCertificateById(id);
    }
  }

  // Obtener certificados por estudiante
  static Future<List<dynamic>> getCertificatesByStudent(String studentId) async {
    if (_useSupabase) {
      final supabaseCerts = await SupabaseCertificateService.getCertificatesByStudent(studentId);
      return supabaseCerts.map((cert) => cert.toMap()).toList();
    } else {
      final certificates = await cert_service.CertificateService.getCertificates(
        studentId: studentId,
      );
      return certificates;
    }
  }

  // Obtener certificados por institución
  static Future<List<dynamic>> getCertificatesByInstitution(String institutionId) async {
    if (_useSupabase) {
      final supabaseCerts = await SupabaseCertificateService.getCertificatesByInstitution(institutionId);
      return supabaseCerts.map((cert) => cert.toMap()).toList();
    } else {
      // Firebase filtra por institución automáticamente según el contexto del usuario
      final certificates = await cert_service.CertificateService.getCertificates();
      return certificates.where((cert) => cert.institutionId == institutionId).toList();
    }
  }

  // Obtener certificados emitidos por un emisor específico
  static Future<List<dynamic>> getCertificatesByEmisor(String emisorId) async {
    if (_useSupabase) {
      final supabaseCerts = await SupabaseCertificateService.getCertificatesByEmisor(emisorId);
      return supabaseCerts.map((cert) => cert.toMap()).toList();
    } else {
      // Firebase: filtrar por issuedBy
      final certificates = await cert_service.CertificateService.getCertificates();
      return certificates.where((cert) => cert.issuedBy == emisorId).toList();
    }
  }

  // Validar certificado
  static Future<bool> validateCertificate(String certificateId) async {
    if (_useSupabase) {
      return await SupabaseCertificateService.validateCertificate(certificateId);
    } else {
      final result = await cert_service.CertificateService.validateCertificate(
        certificateId: certificateId,
      );
      return result.isValid;
    }
  }

  // Revocar certificado
  static Future<bool> revokeCertificate(String certificateId, String reason) async {
    if (_useSupabase) {
      return await SupabaseCertificateService.revokeCertificate(certificateId, reason);
    } else {
      return await cert_service.CertificateService.revokeCertificate(certificateId, reason);
    }
  }

  // Obtener estadísticas de certificados
  static Future<Map<String, int>> getCertificateStats() async {
    if (_useSupabase) {
      return await SupabaseCertificateService.getCertificateStats();
    } else {
      return await cert_service.CertificateService.getCertificateStats();
    }
  }

  // Buscar certificados
  static Future<List<dynamic>> searchCertificates(String query) async {
    if (_useSupabase) {
      final supabaseCerts = await SupabaseCertificateService.searchCertificates(query);
      return supabaseCerts.map((cert) => cert.toMap()).toList();
    } else {
      // Firebase no tiene método de búsqueda directo, usar getCertificates
      final certificates = await cert_service.CertificateService.getCertificates();
      return certificates.where((cert) => 
        cert.title.toLowerCase().contains(query.toLowerCase()) ||
        cert.studentName.toLowerCase().contains(query.toLowerCase()) ||
        cert.institutionName.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  // Generar hash único del certificado
  static String generateUniqueHash(String certificateId, DateTime issuedAt, String studentId, String institutionId) {
    if (_useSupabase) {
      return SupabaseCertificateService.generateUniqueHash(certificateId, issuedAt, studentId, institutionId);
    } else {
      // Usar implementación local para Firebase
      final data = '$certificateId-$issuedAt-$studentId-$institutionId';
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      return digest.toString();
    }
  }

  // Generar código QR para validación
  static String generateQRCode(String certificateId, String institutionCode) {
    if (_useSupabase) {
      return SupabaseCertificateService.generateQRCode(certificateId, institutionCode);
    } else {
      // Detectar el puerto automáticamente basado en la URL actual
      final currentUrl = Uri.base.toString();
      String port = '8081'; // Puerto por defecto
      
      if (currentUrl.contains(':8080')) {
        port = '8080';
      } else if (currentUrl.contains(':8081')) {
        port = '8081';
      } else if (currentUrl.contains(':8082')) {
        port = '8082';
      }
      
      return 'http://localhost:$port/#/verify/certificate/$certificateId';
    }
  }

  // Obtener certificados (método genérico)
  static Future<List<dynamic>> getCertificates({String? studentId, String? institutionId}) async {
    if (_useSupabase) {
      List<Map<String, dynamic>> certificates;
      if (studentId != null) {
        final supabaseCerts = await SupabaseCertificateService.getCertificatesByStudent(studentId);
        certificates = supabaseCerts.map((cert) => cert.toMap()).toList();
      } else if (institutionId != null) {
        final supabaseCerts = await SupabaseCertificateService.getCertificatesByInstitution(institutionId);
        certificates = supabaseCerts.map((cert) => cert.toMap()).toList();
      } else {
        final supabaseCerts = await SupabaseCertificateService.getCertificatesByInstitution(institutionId ?? '');
        certificates = supabaseCerts.map((cert) => cert.toMap()).toList();
      }
      
      // Convertir a objetos Certificate
      return certificates.map((data) => Certificate.fromSupabase(data)).toList();
    } else {
      return await cert_service.CertificateService.getCertificates();
    }
  }

  // Forzar actualización de información de institución
  static Future<void> forceUpdateInstitutionInfo(String certificateId) async {
    if (_useSupabase) {
      // Implementar en Supabase si es necesario
      print('⚠️ forceUpdateInstitutionInfo no implementado en Supabase');
    } else {
      await cert_service.CertificateService.forceUpdateInstitutionInfo(certificateId);
    }
  }
}
