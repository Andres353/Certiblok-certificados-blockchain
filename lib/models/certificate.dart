// lib/models/certificate.dart
// Modelo para certificados emitidos

import 'package:cloud_firestore/cloud_firestore.dart';

class Certificate {
  final String id;
  final String studentId;
  final String studentName;
  final String certificateType;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final String institutionId;
  final String institutionName;
  final String institutionCode;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String status;
  final String qrCode;
  final String hash;
  final String? templateId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Propiedades adicionales para compatibilidad con la pantalla
  final String? studentEmail;
  final String? studentIdInInstitution;
  final String? programName;
  final String? issuedByName;
  final String? issuedByRole;
  final DateTime? revokedAt;
  final String? revokedReason;
  final String? uniqueHash;
  final String? blockchainHash;
  final List<Map<String, dynamic>>? validationHistory;
  final String? pdfUrl;
  final String? pdfFileName;

  Certificate({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.certificateType,
    required this.title,
    required this.description,
    required this.data,
    required this.institutionId,
    required this.institutionName,
    required this.institutionCode,
    required this.issuedAt,
    this.expiresAt,
    required this.status,
    required this.qrCode,
    required this.hash,
    this.templateId,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.studentEmail,
    this.studentIdInInstitution,
    this.programName,
    this.issuedByName,
    this.issuedByRole,
    this.revokedAt,
    this.revokedReason,
    this.uniqueHash,
    this.blockchainHash,
    this.validationHistory,
    this.pdfUrl,
    this.pdfFileName,
  });

  // Constructor desde Firebase
  factory Certificate.fromFirebase(Map<String, dynamic> data, String id) {
    return Certificate(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      certificateType: data['certificateType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      institutionCode: data['institutionCode'] ?? '',
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      qrCode: data['qrCode'] ?? '',
      hash: data['hash'] ?? '',
      templateId: data['templateId'],
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentEmail: data['studentEmail'],
      studentIdInInstitution: data['studentIdInInstitution'],
      programName: data['programName'],
      issuedByName: data['issuedByName'],
      issuedByRole: data['issuedByRole'],
      revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
      revokedReason: data['revokedReason'],
      uniqueHash: data['uniqueHash'],
      blockchainHash: data['blockchainHash'],
      validationHistory: data['validationHistory'] != null 
          ? List<Map<String, dynamic>>.from(data['validationHistory']) 
          : null,
      pdfUrl: data['pdfUrl'],
      pdfFileName: data['pdfFileName'],
    );
  }

  // Constructor desde Supabase
  factory Certificate.fromSupabase(Map<String, dynamic> data) {
    return Certificate(
      id: data['id'] ?? '',
      studentId: data['student_id'] ?? '',
      studentName: data['student_name'] ?? '',
      certificateType: data['certificate_type'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      institutionId: data['institution_id'] ?? '',
      institutionName: data['institution_name'] ?? '',
      institutionCode: data['institution_code'] ?? '',
      issuedAt: DateTime.parse(data['issued_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: data['expires_at'] != null ? DateTime.parse(data['expires_at']) : null,
      status: data['status'] ?? 'active',
      qrCode: data['qr_code'] ?? '',
      hash: data['hash'] ?? '',
      templateId: data['template_id'],
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
      studentEmail: data['student_email'],
      studentIdInInstitution: data['student_id_in_institution'],
      programName: data['program_name'],
      issuedByName: data['issued_by_name'],
      issuedByRole: data['issued_by_role'],
      revokedAt: data['revoked_at'] != null ? DateTime.parse(data['revoked_at']) : null,
      revokedReason: data['revoked_reason'],
      uniqueHash: data['unique_hash'],
      blockchainHash: data['blockchain_hash'],
      validationHistory: data['validation_history'] != null 
          ? List<Map<String, dynamic>>.from(data['validation_history']) 
          : null,
      pdfUrl: data['pdf_url'],
      pdfFileName: data['pdf_file_name'],
    );
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'certificateType': certificateType,
      'title': title,
      'description': description,
      'data': data,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'institutionCode': institutionCode,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'status': status,
      'qrCode': qrCode,
      'hash': hash,
      'templateId': templateId,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'studentEmail': studentEmail,
      'studentIdInInstitution': studentIdInInstitution,
      'programName': programName,
      'issuedByName': issuedByName,
      'issuedByRole': issuedByRole,
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
      'revokedReason': revokedReason,
      'uniqueHash': uniqueHash,
      'blockchainHash': blockchainHash,
      'validationHistory': validationHistory,
      'pdfUrl': pdfUrl,
      'pdfFileName': pdfFileName,
    };
  }

  // Convertir a Map para Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'certificate_type': certificateType,
      'title': title,
      'description': description,
      'data': data,
      'institution_id': institutionId,
      'institution_name': institutionName,
      'institution_code': institutionCode,
      'issued_at': issuedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'status': status,
      'qr_code': qrCode,
      'hash': hash,
      'template_id': templateId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'student_email': studentEmail,
      'student_id_in_institution': studentIdInInstitution,
      'program_name': programName,
      'issued_by_name': issuedByName,
      'issued_by_role': issuedByRole,
      'revoked_at': revokedAt?.toIso8601String(),
      'revoked_reason': revokedReason,
      'unique_hash': uniqueHash,
      'blockchain_hash': blockchainHash,
      'validation_history': validationHistory,
      'pdf_url': pdfUrl,
      'pdf_file_name': pdfFileName,
    };
  }

  // Copiar con cambios
  Certificate copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? certificateType,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    String? institutionId,
    String? institutionName,
    String? institutionCode,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? status,
    String? qrCode,
    String? hash,
    String? templateId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentEmail,
    String? studentIdInInstitution,
    String? programName,
    String? issuedByName,
    String? issuedByRole,
    DateTime? revokedAt,
    String? revokedReason,
    String? uniqueHash,
    String? blockchainHash,
    List<Map<String, dynamic>>? validationHistory,
    String? pdfUrl,
    String? pdfFileName,
  }) {
    return Certificate(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      certificateType: certificateType ?? this.certificateType,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      institutionCode: institutionCode ?? this.institutionCode,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      hash: hash ?? this.hash,
      templateId: templateId ?? this.templateId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentEmail: studentEmail ?? this.studentEmail,
      studentIdInInstitution: studentIdInInstitution ?? this.studentIdInInstitution,
      programName: programName ?? this.programName,
      issuedByName: issuedByName ?? this.issuedByName,
      issuedByRole: issuedByRole ?? this.issuedByRole,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedReason: revokedReason ?? this.revokedReason,
      uniqueHash: uniqueHash ?? this.uniqueHash,
      blockchainHash: blockchainHash ?? this.blockchainHash,
      validationHistory: validationHistory ?? this.validationHistory,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfFileName: pdfFileName ?? this.pdfFileName,
    );
  }

  @override
  String toString() {
    return 'Certificate(id: $id, title: $title, studentName: $studentName, institutionName: $institutionName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Certificate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
