// lib/data/sample_institutions.dart
// Datos de ejemplo para instituciones académicas

import '../models/institution.dart';

class SampleInstitutions {
  // Institución de ejemplo 1: Universidad Tecnológica
  static Institution get universidadTecnologica => Institution(
    id: 'inst_001',
    name: 'Universidad Tecnológica del Futuro',
    shortName: 'UTF',
    description: 'Universidad líder en tecnología e innovación educativa',
    logoUrl: 'https://via.placeholder.com/200x100/6C4DDC/FFFFFF?text=UTF',
    colors: InstitutionColors(
      primary: '#6C4DDC',
      secondary: '#8B7DDC',
      accent: '#FF6B6B',
      background: '#FFFFFF',
      text: '#2E2F44',
    ),
    settings: InstitutionSettings(
      allowStudentRegistration: true,
      requireEmailVerification: true,
      allowPublicVerification: true,
      enableBlockchain: true,
      defaultLanguage: 'es',
      supportedPrograms: [
        'Ingeniería de Sistemas',
        'Ingeniería Industrial',
        'Administración de Empresas',
        'Psicología',
        'Medicina',
        'Derecho',
      ],
      customFields: {
        'website': 'https://www.utf.edu.co',
        'phone': '+57 1 234 5678',
        'address': 'Calle 123 #45-67, Bogotá, Colombia',
        'accreditation': 'Acreditada por el Ministerio de Educación',
      },
    ),
    status: InstitutionStatus.active,
    createdAt: DateTime.now().subtract(Duration(days: 30)),
    updatedAt: DateTime.now(),
    createdBy: 'super_admin_001',
  );

  // Institución de ejemplo 2: Colegio San Patricio
  static Institution get colegioSanPatricio => Institution(
    id: 'inst_002',
    name: 'Colegio San Patricio',
    shortName: 'CSP',
    description: 'Institución educativa de excelencia académica',
    logoUrl: 'https://via.placeholder.com/200x100/2E8B57/FFFFFF?text=CSP',
    colors: InstitutionColors(
      primary: '#2E8B57',
      secondary: '#3CB371',
      accent: '#FFD700',
      background: '#FFFFFF',
      text: '#2F4F4F',
    ),
    settings: InstitutionSettings(
      allowStudentRegistration: true,
      requireEmailVerification: true,
      allowPublicVerification: true,
      enableBlockchain: true,
      defaultLanguage: 'es',
      supportedPrograms: [
        'Bachillerato Académico',
        'Bachillerato Técnico',
        'Técnico en Sistemas',
        'Técnico en Administración',
      ],
      customFields: {
        'website': 'https://www.sanpatricio.edu.co',
        'phone': '+57 1 987 6543',
        'address': 'Carrera 45 #78-90, Medellín, Colombia',
        'accreditation': 'Certificado de Calidad Educativa',
      },
    ),
    status: InstitutionStatus.active,
    createdAt: DateTime.now().subtract(Duration(days: 15)),
    updatedAt: DateTime.now(),
    createdBy: 'super_admin_001',
  );

  // Institución de ejemplo 3: Instituto Técnico Industrial
  static Institution get institutoTecnico => Institution(
    id: 'inst_003',
    name: 'Instituto Técnico Industrial',
    shortName: 'ITI',
    description: 'Formación técnica especializada para la industria',
    logoUrl: 'https://via.placeholder.com/200x100/DC143C/FFFFFF?text=ITI',
    colors: InstitutionColors(
      primary: '#DC143C',
      secondary: '#FF6347',
      accent: '#32CD32',
      background: '#FFFFFF',
      text: '#2F4F4F',
    ),
    settings: InstitutionSettings(
      allowStudentRegistration: true,
      requireEmailVerification: true,
      allowPublicVerification: true,
      enableBlockchain: true,
      defaultLanguage: 'es',
      supportedPrograms: [
        'Técnico en Mecánica Industrial',
        'Técnico en Electricidad',
        'Técnico en Electrónica',
        'Técnico en Automatización',
        'Técnico en Soldadura',
      ],
      customFields: {
        'website': 'https://www.iti.edu.co',
        'phone': '+57 1 555 1234',
        'address': 'Avenida 80 #12-34, Cali, Colombia',
        'accreditation': 'Certificado por SENA',
      },
    ),
    status: InstitutionStatus.active,
    createdAt: DateTime.now().subtract(Duration(days: 7)),
    updatedAt: DateTime.now(),
    createdBy: 'super_admin_001',
  );

  // Lista de todas las instituciones de ejemplo
  static List<Institution> get allInstitutions => [
    universidadTecnologica,
    colegioSanPatricio,
    institutoTecnico,
  ];

  // Obtener institución por ID
  static Institution? getInstitutionById(String id) {
    try {
      return allInstitutions.firstWhere((institution) => institution.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener instituciones por tipo
  static List<Institution> getUniversities() {
    return allInstitutions.where((institution) => 
      institution.name.toLowerCase().contains('universidad')).toList();
  }

  static List<Institution> getColleges() {
    return allInstitutions.where((institution) => 
      institution.name.toLowerCase().contains('colegio')).toList();
  }

  static List<Institution> getInstitutes() {
    return allInstitutions.where((institution) => 
      institution.name.toLowerCase().contains('instituto')).toList();
  }

  // Buscar instituciones por nombre
  static List<Institution> searchInstitutions(String query) {
    return allInstitutions.where((institution) =>
      institution.name.toLowerCase().contains(query.toLowerCase()) ||
      institution.shortName.toLowerCase().contains(query.toLowerCase()) ||
      institution.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Obtener estadísticas de ejemplo
  static Map<String, int> getSampleStats() {
    return {
      'total': allInstitutions.length,
      'active': allInstitutions.where((i) => i.status == InstitutionStatus.active).length,
      'inactive': allInstitutions.where((i) => i.status == InstitutionStatus.inactive).length,
      'suspended': allInstitutions.where((i) => i.status == InstitutionStatus.suspended).length,
      'pending': allInstitutions.where((i) => i.status == InstitutionStatus.pending).length,
    };
  }
}
