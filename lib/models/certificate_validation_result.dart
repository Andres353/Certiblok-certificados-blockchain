// lib/models/certificate_validation_result.dart
// Modelo para resultados de validación de certificados

import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateValidationResult {
  final bool isValid;
  final String? certificateId;
  final String? studentName;
  final String? institutionName;
  final String? certificateType;
  final String? title;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? status;
  final String? errorMessage;
  final Map<String, dynamic>? certificateData;

  CertificateValidationResult({
    required this.isValid,
    this.certificateId,
    this.studentName,
    this.institutionName,
    this.certificateType,
    this.title,
    this.issuedAt,
    this.expiresAt,
    this.status,
    this.errorMessage,
    this.certificateData,
  });

  // Constructor para certificado válido
  factory CertificateValidationResult.valid({
    required String certificateId,
    required String studentName,
    required String institutionName,
    required String certificateType,
    required String title,
    required DateTime issuedAt,
    DateTime? expiresAt,
    required String status,
    Map<String, dynamic>? certificateData,
  }) {
    return CertificateValidationResult(
      isValid: true,
      certificateId: certificateId,
      studentName: studentName,
      institutionName: institutionName,
      certificateType: certificateType,
      title: title,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      status: status,
      certificateData: certificateData,
    );
  }

  // Constructor para certificado inválido
  factory CertificateValidationResult.invalid({
    required String errorMessage,
    String? certificateId,
  }) {
    return CertificateValidationResult(
      isValid: false,
      certificateId: certificateId,
      errorMessage: errorMessage,
    );
  }

  // Constructor desde Firebase
  factory CertificateValidationResult.fromFirebase(Map<String, dynamic> data) {
    if (data['isValid'] == true) {
      return CertificateValidationResult.valid(
        certificateId: data['certificateId'] ?? '',
        studentName: data['studentName'] ?? '',
        institutionName: data['institutionName'] ?? '',
        certificateType: data['certificateType'] ?? '',
        title: data['title'] ?? '',
        issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
        status: data['status'] ?? 'active',
        certificateData: data['certificateData'] != null 
            ? Map<String, dynamic>.from(data['certificateData']) 
            : null,
      );
    } else {
      return CertificateValidationResult.invalid(
        errorMessage: data['errorMessage'] ?? 'Certificado no válido',
        certificateId: data['certificateId'],
      );
    }
  }

  // Constructor desde Supabase
  factory CertificateValidationResult.fromSupabase(Map<String, dynamic> data) {
    if (data['is_valid'] == true) {
      return CertificateValidationResult.valid(
        certificateId: data['certificate_id'] ?? '',
        studentName: data['student_name'] ?? '',
        institutionName: data['institution_name'] ?? '',
        certificateType: data['certificate_type'] ?? '',
        title: data['title'] ?? '',
        issuedAt: DateTime.parse(data['issued_at'] ?? DateTime.now().toIso8601String()),
        expiresAt: data['expires_at'] != null ? DateTime.parse(data['expires_at']) : null,
        status: data['status'] ?? 'active',
        certificateData: data['certificate_data'] != null 
            ? Map<String, dynamic>.from(data['certificate_data']) 
            : null,
      );
    } else {
      return CertificateValidationResult.invalid(
        errorMessage: data['error_message'] ?? 'Certificado no válido',
        certificateId: data['certificate_id'],
      );
    }
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'isValid': isValid,
      'certificateId': certificateId,
      'studentName': studentName,
      'institutionName': institutionName,
      'certificateType': certificateType,
      'title': title,
      'issuedAt': issuedAt != null ? Timestamp.fromDate(issuedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'status': status,
      'errorMessage': errorMessage,
      'certificateData': certificateData,
    };
  }

  // Convertir a Map para Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'is_valid': isValid,
      'certificate_id': certificateId,
      'student_name': studentName,
      'institution_name': institutionName,
      'certificate_type': certificateType,
      'title': title,
      'issued_at': issuedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'status': status,
      'error_message': errorMessage,
      'certificate_data': certificateData,
    };
  }

  @override
  String toString() {
    if (isValid) {
      return 'CertificateValidationResult.valid(certificateId: $certificateId, studentName: $studentName, institutionName: $institutionName)';
    } else {
      return 'CertificateValidationResult.invalid(errorMessage: $errorMessage)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CertificateValidationResult && 
           other.isValid == isValid && 
           other.certificateId == certificateId;
  }

  @override
  int get hashCode => Object.hash(isValid, certificateId);
}
