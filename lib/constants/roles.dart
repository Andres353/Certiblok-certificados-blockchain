// lib/constants/roles.dart
// Constantes para los roles del sistema multi-tenant de certificados blockchain

class UserRoles {
  // Roles principales del sistema multi-tenant
  static const String SUPER_ADMIN = 'super_admin';           // Super administrador del sistema (gestiona todas las instituciones)
  static const String ADMIN_INSTITUTION = 'admin_institution'; // Administrador de una institución específica
  static const String EMISOR = 'emisor';                     // Emisor de certificados (personal administrativo de una institución)
  static const String STUDENT = 'student';                   // Estudiante de una institución específica
  static const String PUBLIC_USER = 'public_user';           // Usuario público (verificador de certificados)
  
  // Roles legacy (para compatibilidad)
  static const String USER = 'user';                         // Usuario general (deprecated)
  static const String ADMIN_UV = 'admin_uv';                 // Legacy - Administrador UV (deprecated)
  
  // Niveles de permisos
  static const int LEVEL_SUPER_ADMIN = 5;        // Máximo nivel - Control total del sistema multi-tenant
  static const int LEVEL_ADMIN_INSTITUTION = 4;  // Alto nivel - Control de una institución específica
  static const int LEVEL_EMISOR = 3;             // Medio-alto nivel - Emitir y gestionar certificados
  static const int LEVEL_STUDENT = 2;            // Medio nivel - Ver y gestionar sus certificados
  static const int LEVEL_PUBLIC = 1;             // Bajo nivel - Solo verificar certificados
  
  // Descripciones de roles
  static const Map<String, String> ROLE_DESCRIPTIONS = {
    SUPER_ADMIN: 'Super Administrador del Sistema (Gestiona todas las instituciones)',
    ADMIN_INSTITUTION: 'Administrador de Institución (Gestiona una institución específica)',
    EMISOR: 'Emisor de Certificados (Personal Administrativo de Institución)',
    STUDENT: 'Estudiante (Usuario de una institución específica)',
    PUBLIC_USER: 'Usuario Público (Verificador de Certificados)',
    // Legacy roles
    ADMIN_UV: 'Administrador General de la Universidad del Valle (Legacy)',
  };
  
  // Permisos por rol
  static const Map<String, List<String>> ROLE_PERMISSIONS = {
    SUPER_ADMIN: [
      'manage_all_institutions',
      'create_institutions',
      'delete_institutions',
      'manage_system_settings',
      'view_system_analytics',
      'manage_super_admins',
      'view_all_certificates',
      'system_configuration',
    ],
    ADMIN_INSTITUTION: [
      'manage_institution',
      'manage_institution_users',
      'approve_emisors',
      'manage_faculties',
      'manage_programs',
      'view_institution_certificates',
      'institution_configuration',
      'manage_institution_settings',
    ],
    EMISOR: [
      'issue_certificates',
      'manage_students',
      'view_program_certificates',
      'edit_certificate_templates',
      'validate_student_info',
      'view_institution_certificates',
    ],
    STUDENT: [
      'view_own_certificates',
      'organize_certificates',
      'share_certificates',
      'download_certificates',
      'view_academic_history',
    ],
    PUBLIC_USER: [
      'verify_certificates',
      'scan_qr_codes',
      'view_public_certificates',
    ],
    // Legacy roles
    ADMIN_UV: [
      'manage_system',
      'approve_emisors',
      'manage_faculties',
      'manage_programs',
      'view_all_certificates',
      'system_configuration',
    ],
  };
  
  // Verificar si un rol tiene un permiso específico
  static bool hasPermission(String role, String permission) {
    final permissions = ROLE_PERMISSIONS[role];
    return permissions != null && permissions.contains(permission);
  }
  
  // Obtener nivel de un rol
  static int getRoleLevel(String role) {
    switch (role) {
      case SUPER_ADMIN:
        return LEVEL_SUPER_ADMIN;
      case ADMIN_INSTITUTION:
        return LEVEL_ADMIN_INSTITUTION;
      case EMISOR:
        return LEVEL_EMISOR;
      case STUDENT:
        return LEVEL_STUDENT;
      case PUBLIC_USER:
        return LEVEL_PUBLIC;
      // Legacy roles
      case ADMIN_UV:
        return LEVEL_ADMIN_INSTITUTION; // Mapear a nivel de admin de institución
      default:
        return 0;
    }
  }
  
  // Verificar si un rol puede acceder a otro rol
  static bool canAccessRole(String userRole, String targetRole) {
    return getRoleLevel(userRole) >= getRoleLevel(targetRole);
  }
  
  // Obtener descripción de un rol
  static String getRoleDescription(String role) {
    return ROLE_DESCRIPTIONS[role] ?? 'Rol no definido';
  }
  
  // Lista de roles válidos
  static List<String> getValidRoles() {
    return [SUPER_ADMIN, ADMIN_INSTITUTION, EMISOR, STUDENT, PUBLIC_USER];
  }
  
  // Roles que pueden emitir certificados
  static List<String> getCertificateIssuers() {
    return [SUPER_ADMIN, ADMIN_INSTITUTION, EMISOR];
  }
  
  // Roles que pueden ver certificados
  static List<String> getCertificateViewers() {
    return [SUPER_ADMIN, ADMIN_INSTITUTION, EMISOR, STUDENT, PUBLIC_USER];
  }
  
  // Roles de administración de instituciones
  static List<String> getInstitutionAdmins() {
    return [SUPER_ADMIN, ADMIN_INSTITUTION];
  }
  
  // Roles que requieren institución específica
  static List<String> getInstitutionSpecificRoles() {
    return [ADMIN_INSTITUTION, EMISOR, STUDENT];
  }
}
