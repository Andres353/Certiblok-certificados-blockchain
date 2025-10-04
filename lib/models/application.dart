// lib/models/application.dart
// Modelo para postulaciones a programas y pasantías

import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  pending,
  under_review,
  approved,
  rejected,
  withdrawn;

  static ApplicationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'under_review':
        return ApplicationStatus.under_review;
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ApplicationStatus.pending:
        return 'pending';
      case ApplicationStatus.under_review:
        return 'under_review';
      case ApplicationStatus.approved:
        return 'approved';
      case ApplicationStatus.rejected:
        return 'rejected';
      case ApplicationStatus.withdrawn:
        return 'withdrawn';
    }
  }

  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pendiente';
      case ApplicationStatus.under_review:
        return 'En Revisión';
      case ApplicationStatus.approved:
        return 'Aprobada';
      case ApplicationStatus.rejected:
        return 'Rechazada';
      case ApplicationStatus.withdrawn:
        return 'Retirada';
    }
  }

  String get color {
    switch (this) {
      case ApplicationStatus.pending:
        return '#FF9800'; // Naranja
      case ApplicationStatus.under_review:
        return '#2196F3'; // Azul
      case ApplicationStatus.approved:
        return '#4CAF50'; // Verde
      case ApplicationStatus.rejected:
        return '#F44336'; // Rojo
      case ApplicationStatus.withdrawn:
        return '#9E9E9E'; // Gris
    }
  }
}

class Application {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String programId;
  final String programTitle;
  final String institutionId;
  final String institutionName;
  final ApplicationStatus status;
  final String cvUrl;
  final String cvFileName;
  final List<String> selectedCertificates;
  final List<Map<String, dynamic>> certificateDetails;
  final String motivationLetter;
  final String? motivationPdfData; // Base64 del PDF de carta de motivación
  final String? motivationPdfFileName;
  final Map<String, dynamic> additionalDocuments;
  final DateTime submittedAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.programId,
    required this.programTitle,
    required this.institutionId,
    required this.institutionName,
    required this.status,
    required this.cvUrl,
    required this.cvFileName,
    required this.selectedCertificates,
    required this.certificateDetails,
    required this.motivationLetter,
    this.motivationPdfData,
    this.motivationPdfFileName,
    required this.additionalDocuments,
    required this.submittedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application.fromFirestore(Map<String, dynamic> data, String id) {
    return Application(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      programId: data['programId'] ?? '',
      programTitle: data['programTitle'] ?? '',
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      status: ApplicationStatus.fromString(data['status'] ?? 'pending'),
      cvUrl: data['cvUrl'] ?? '',
      cvFileName: data['cvFileName'] ?? '',
      selectedCertificates: List<String>.from(data['selectedCertificates'] ?? []),
      certificateDetails: List<Map<String, dynamic>>.from(data['certificateDetails'] ?? []),
      motivationLetter: data['motivationLetter'] ?? '',
      motivationPdfData: data['motivationPdfData'],
      motivationPdfFileName: data['motivationPdfFileName'],
      additionalDocuments: Map<String, dynamic>.from(data['additionalDocuments'] ?? {}),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'],
      reviewedByName: data['reviewedByName'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'programId': programId,
      'programTitle': programTitle,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'status': status.toString(),
      'cvUrl': cvUrl,
      'cvFileName': cvFileName,
      'selectedCertificates': selectedCertificates,
      'certificateDetails': certificateDetails,
      'motivationLetter': motivationLetter,
      'motivationPdfData': motivationPdfData,
      'motivationPdfFileName': motivationPdfFileName,
      'additionalDocuments': additionalDocuments,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'notes': notes,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Verificar si la aplicación puede ser editada
  bool get canBeEdited {
    return status == ApplicationStatus.pending;
  }

  // Verificar si la aplicación puede ser retirada
  bool get canBeWithdrawn {
    return status == ApplicationStatus.pending || status == ApplicationStatus.under_review;
  }

  // Obtener días desde que se envió
  int get daysSinceSubmitted {
    return DateTime.now().difference(submittedAt).inDays;
  }

  // Obtener días desde que se revisó
  int? get daysSinceReviewed {
    if (reviewedAt == null) return null;
    return DateTime.now().difference(reviewedAt!).inDays;
  }

  Application copyWith({
    ApplicationStatus? status,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? notes,
    String? rejectionReason,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      programId: programId,
      programTitle: programTitle,
      institutionId: institutionId,
      institutionName: institutionName,
      status: status ?? this.status,
      cvUrl: cvUrl,
      cvFileName: cvFileName,
      selectedCertificates: selectedCertificates,
      certificateDetails: certificateDetails,
      motivationLetter: motivationLetter,
      motivationPdfData: motivationPdfData,
      motivationPdfFileName: motivationPdfFileName,
      additionalDocuments: additionalDocuments,
      submittedAt: submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
