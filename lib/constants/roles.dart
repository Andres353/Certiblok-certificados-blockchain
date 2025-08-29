// lib/constants/roles.dart
// Constantes para los roles del sistema de certificados blockchain de la Universidad del Valle

class UserRoles {
  // Roles principales del sistema
  static const String ADMIN_UV = 'admin_uv';           // Administrador general de la UV
  static const String EMISOR = 'emisor';               // Emisor de certificados (personal administrativo)
  static const String STUDENT = 'student';             // Estudiante de la UV
  static const String PUBLIC_USER = 'public_user';     // Usuario público (verificador de certificados)
  
  // Roles legacy (para compatibilidad)
  static const String USER = 'user';                   // Usuario general (deprecated)
  static const String SUPER_ADMIN = 'superadministrador'; // Super administrador (deprecated)
  
  // Niveles de permisos
  static const int LEVEL_ADMIN_UV = 4;     // Máximo nivel - Control total del sistema
  static const int LEVEL_EMISOR = 3;       // Alto nivel - Emitir y gestionar certificados
  static const int LEVEL_STUDENT = 2;      // Medio nivel - Ver y gestionar sus certificados
  static const int LEVEL_PUBLIC = 1;       // Bajo nivel - Solo verificar certificados
  
  // Descripciones de roles
  static const Map<String, String> ROLE_DESCRIPTIONS = {
    ADMIN_UV: 'Administrador General de la Universidad del Valle',
    EMISOR: 'Emisor de Certificados (Personal Administrativo)',
    STUDENT: 'Estudiante de la Universidad del Valle',
    PUBLIC_USER: 'Usuario Público (Verificador de Certificados)',
  };
  
  // Permisos por rol
  static const Map<String, List<String>> ROLE_PERMISSIONS = {
    ADMIN_UV: [
      'manage_system',
      'approve_emisors',
      'manage_faculties',
      'manage_programs',
      'view_all_certificates',
      'system_configuration',
    ],
    EMISOR: [
      'issue_certificates',
      'manage_students',
      'view_program_certificates',
      'edit_certificate_templates',
      'validate_student_info',
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
  };
  
  // Verificar si un rol tiene un permiso específico
  static bool hasPermission(String role, String permission) {
    final permissions = ROLE_PERMISSIONS[role];
    return permissions != null && permissions.contains(permission);
  }
  
  // Obtener nivel de un rol
  static int getRoleLevel(String role) {
    switch (role) {
      case ADMIN_UV:
        return LEVEL_ADMIN_UV;
      case EMISOR:
        return LEVEL_EMISOR;
      case STUDENT:
        return LEVEL_STUDENT;
      case PUBLIC_USER:
        return LEVEL_PUBLIC;
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
    return [ADMIN_UV, EMISOR, STUDENT, PUBLIC_USER];
  }
  
  // Roles que pueden emitir certificados
  static List<String> getCertificateIssuers() {
    return [ADMIN_UV, EMISOR];
  }
  
  // Roles que pueden ver certificados
  static List<String> getCertificateViewers() {
    return [ADMIN_UV, EMISOR, STUDENT, PUBLIC_USER];
  }
}
