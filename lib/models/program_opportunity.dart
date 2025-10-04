// lib/models/program_opportunity.dart
// Modelo para oportunidades de programas y pasantías

import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramOpportunity {
  final String id;
  final String title;
  final String description;
  final String institutionId;
  final String institutionName;
  final String facultyId;
  final String facultyName;
  final List<String> careerIds;
  final List<String> careerNames;
  final List<String> requirements;
  final bool isActive;
  final DateTime applicationDeadline;
  final int maxApplications;
  final int currentApplications;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> additionalInfo;
  final String? imageUrl;
  final String? pdfUrl;
  final String? pdfFileName;
  final String? pdfData; // Base64 puro del PDF (igual que certificados)

  ProgramOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.institutionId,
    required this.institutionName,
    required this.facultyId,
    required this.facultyName,
    required this.careerIds,
    required this.careerNames,
    required this.requirements,
    required this.isActive,
    required this.applicationDeadline,
    required this.maxApplications,
    required this.currentApplications,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    required this.additionalInfo,
    this.imageUrl,
    this.pdfUrl,
    this.pdfFileName,
    this.pdfData,
  });

  factory ProgramOpportunity.fromFirestore(Map<String, dynamic> data, String id) {
    return ProgramOpportunity(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      facultyId: data['facultyId'] ?? '',
      facultyName: data['facultyName'] ?? '',
      careerIds: List<String>.from(data['careerIds'] ?? []),
      careerNames: List<String>.from(data['careerNames'] ?? []),
      requirements: List<String>.from(data['requirements'] ?? []),
      isActive: data['isActive'] ?? true,
      applicationDeadline: (data['applicationDeadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxApplications: data['maxApplications'] ?? 0,
      currentApplications: data['currentApplications'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      imageUrl: data['imageUrl'],
      pdfUrl: data['pdfUrl'],
      pdfFileName: data['pdfFileName'],
      pdfData: data['pdfData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'careerIds': careerIds,
      'careerNames': careerNames,
      'requirements': requirements,
      'isActive': isActive,
      'applicationDeadline': Timestamp.fromDate(applicationDeadline),
      'maxApplications': maxApplications,
      'currentApplications': currentApplications,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'pdfFileName': pdfFileName,
      'pdfData': pdfData,
    };
  }

  // Verificar si el programa está abierto para postulaciones
  bool get isOpenForApplications {
    if (!isActive) return false;
    return DateTime.now().isBefore(applicationDeadline);
  }

  // Verificar si hay cupos disponibles
  bool get hasAvailableSlots {
    return currentApplications < maxApplications;
  }

  // Obtener días restantes para postularse
  int get daysUntilDeadline {
    final now = DateTime.now();
    final deadline = applicationDeadline;
    return deadline.difference(now).inDays;
  }

  // Obtener estado del programa
  String get status {
    if (!isActive) return 'Inactivo';
    if (!isOpenForApplications) return 'Cerrado';
    if (!hasAvailableSlots) return 'Sin cupos';
    return 'Abierto';
  }

  // Obtener color del estado
  String get statusColor {
    switch (status) {
      case 'Abierto':
        return '#4CAF50'; // Verde
      case 'Sin cupos':
        return '#FF9800'; // Naranja
      case 'Cerrado':
        return '#F44336'; // Rojo
      case 'Inactivo':
        return '#9E9E9E'; // Gris
      default:
        return '#9E9E9E';
    }
  }

  ProgramOpportunity copyWith({
    String? title,
    String? description,
    bool? isActive,
    DateTime? applicationDeadline,
    int? maxApplications,
    int? currentApplications,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
    String? imageUrl,
    String? pdfUrl,
    String? pdfFileName,
    String? pdfData,
  }) {
    return ProgramOpportunity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      institutionId: institutionId,
      institutionName: institutionName,
      facultyId: facultyId,
      facultyName: facultyName,
      careerIds: careerIds,
      careerNames: careerNames,
      requirements: requirements,
      isActive: isActive ?? this.isActive,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      maxApplications: maxApplications ?? this.maxApplications,
      currentApplications: currentApplications ?? this.currentApplications,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      imageUrl: imageUrl ?? this.imageUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfFileName: pdfFileName ?? this.pdfFileName,
      pdfData: pdfData ?? this.pdfData,
    );
  }
}
