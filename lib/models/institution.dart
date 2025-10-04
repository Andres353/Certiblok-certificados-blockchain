// lib/models/institution.dart
// Modelo de datos para instituciones en el sistema multi-tenant

import 'package:cloud_firestore/cloud_firestore.dart';

class Institution {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String logoUrl;
  final String institutionCode; // Código único de la institución
  final InstitutionColors colors;
  final InstitutionSettings settings;
  final InstitutionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // ID del super admin que creó la institución

  Institution({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.logoUrl,
    required this.institutionCode,
    required this.colors,
    required this.settings,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Constructor desde Firestore
  factory Institution.fromFirestore(Map<String, dynamic> data, String id) {
    return Institution(
      id: id,
      name: data['name'] ?? '',
      shortName: data['shortName'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      institutionCode: data['institutionCode'] ?? '',
      colors: InstitutionColors.fromMap(data['colors'] ?? {}),
      settings: InstitutionSettings.fromMap(data['settings'] ?? {}),
      status: InstitutionStatus.fromString(data['status'] ?? 'active'),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'shortName': shortName,
      'description': description,
      'logoUrl': logoUrl,
      'institutionCode': institutionCode,
      'colors': colors.toMap(),
      'settings': settings.toMap(),
      'status': status.toString(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
    };
  }

  // Crear copia con cambios
  Institution copyWith({
    String? id,
    String? name,
    String? shortName,
    String? description,
    String? logoUrl,
    String? institutionCode,
    InstitutionColors? colors,
    InstitutionSettings? settings,
    InstitutionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Institution(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      institutionCode: institutionCode ?? this.institutionCode,
      colors: colors ?? this.colors,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

// Colores de la institución
class InstitutionColors {
  final String primary;
  final String secondary;
  final String accent;
  final String background;
  final String text;

  InstitutionColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.text,
  });

  factory InstitutionColors.fromMap(Map<String, dynamic> data) {
    return InstitutionColors(
      primary: data['primary'] ?? '#6C4DDC',
      secondary: data['secondary'] ?? '#8B7DDC',
      accent: data['accent'] ?? '#FF6B6B',
      background: data['background'] ?? '#FFFFFF',
      text: data['text'] ?? '#2E2F44',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary': primary,
      'secondary': secondary,
      'accent': accent,
      'background': background,
      'text': text,
    };
  }
}

// Configuraciones de la institución
class InstitutionSettings {
  final bool allowStudentRegistration;
  final bool requireEmailVerification;
  final bool allowPublicVerification;
  final bool enableBlockchain;
  final String defaultLanguage;
  final List<String> supportedPrograms;
  final Map<String, dynamic> customFields;

  InstitutionSettings({
    required this.allowStudentRegistration,
    required this.requireEmailVerification,
    required this.allowPublicVerification,
    required this.enableBlockchain,
    required this.defaultLanguage,
    required this.supportedPrograms,
    required this.customFields,
  });

  factory InstitutionSettings.fromMap(Map<String, dynamic> data) {
    return InstitutionSettings(
      allowStudentRegistration: data['allowStudentRegistration'] ?? true,
      requireEmailVerification: data['requireEmailVerification'] ?? true,
      allowPublicVerification: data['allowPublicVerification'] ?? true,
      enableBlockchain: data['enableBlockchain'] ?? true,
      defaultLanguage: data['defaultLanguage'] ?? 'es',
      supportedPrograms: List<String>.from(data['supportedPrograms'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowStudentRegistration': allowStudentRegistration,
      'requireEmailVerification': requireEmailVerification,
      'allowPublicVerification': allowPublicVerification,
      'enableBlockchain': enableBlockchain,
      'defaultLanguage': defaultLanguage,
      'supportedPrograms': supportedPrograms,
      'customFields': customFields,
    };
  }
}

// Estado de la institución
enum InstitutionStatus {
  active,
  inactive,
  suspended,
  pending;

  static InstitutionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return InstitutionStatus.active;
      case 'inactive':
        return InstitutionStatus.inactive;
      case 'suspended':
        return InstitutionStatus.suspended;
      case 'pending':
        return InstitutionStatus.pending;
      default:
        return InstitutionStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case InstitutionStatus.active:
        return 'active';
      case InstitutionStatus.inactive:
        return 'inactive';
      case InstitutionStatus.suspended:
        return 'suspended';
      case InstitutionStatus.pending:
        return 'pending';
    }
  }

  String get displayName {
    switch (this) {
      case InstitutionStatus.active:
        return 'Activa';
      case InstitutionStatus.inactive:
        return 'Inactiva';
      case InstitutionStatus.suspended:
        return 'Suspendida';
      case InstitutionStatus.pending:
        return 'Pendiente';
    }
  }
}
