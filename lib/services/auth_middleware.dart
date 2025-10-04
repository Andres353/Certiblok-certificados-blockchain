// lib/services/auth_middleware.dart
// Middleware de autorización y seguridad

import 'secure_auth_service.dart';

class AuthMiddleware {
  static final SecureAuthService _authService = SecureAuthService();

  // 1. VERIFICAR AUTENTICACIÓN
  static Future<bool> isAuthenticated() async {
    final session = await _authService.getCurrentSession();
    return session != null;
  }

  // 2. VERIFICAR ROL ESPECÍFICO
  static Future<bool> hasRole(String requiredRole) async {
    final session = await _authService.getCurrentSession();
    if (session == null) return false;
    
    return session['role'] == requiredRole;
  }

  // 3. VERIFICAR PERMISO ESPECÍFICO
  static Future<bool> hasPermission(String permission) async {
    final session = await _authService.getCurrentSession();
    if (session == null) return false;
    
    return await _authService.hasPermission(session['userId'], permission);
  }

  // 4. OBTENER USUARIO ACTUAL
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _authService.getCurrentSession();
  }

  // 5. VERIFICAR ACCESO A INSTITUCIÓN
  static Future<bool> hasInstitutionAccess(String institutionId) async {
    final session = await _authService.getCurrentSession();
    if (session == null) return false;
    
    // Super admin puede acceder a cualquier institución
    if (session['role'] == 'super_admin') return true;
    
    // Otros usuarios solo pueden acceder a su institución
    return session['institutionId'] == institutionId;
  }

  // 6. VERIFICAR ACCESO A RECURSO
  static Future<bool> canAccessResource(String resourceType, String resourceId) async {
    final session = await _authService.getCurrentSession();
    if (session == null) return false;
    
    final role = session['role'];
    final userId = session['userId'];
    
    switch (resourceType) {
      case 'certificate':
        // Los estudiantes solo pueden ver sus propios certificados
        if (role == 'student') {
          // Aquí deberías verificar si el certificado pertenece al usuario
          // Por ahora, asumimos que sí
          return true;
        }
        // Otros roles pueden ver todos los certificados
        return true;
        
      case 'user':
        // Solo super_admin y admin pueden gestionar usuarios
        return role == 'super_admin' || role == 'admin';
        
      case 'institution':
        // Solo super_admin puede gestionar instituciones
        return role == 'super_admin';
        
      default:
        return false;
    }
  }

  // 7. VERIFICAR ACCESO COMPLETO (AUTENTICACIÓN + AUTORIZACIÓN)
  static Future<Map<String, dynamic>> verifyAccess({
    required String requiredRole,
    String? requiredPermission,
    String? resourceType,
    String? resourceId,
  }) async {
    // Verificar autenticación
    if (!await isAuthenticated()) {
      return {
        'authorized': false,
        'message': 'Usuario no autenticado',
        'code': 'NOT_AUTHENTICATED'
      };
    }

    // Verificar rol
    if (!await hasRole(requiredRole)) {
      return {
        'authorized': false,
        'message': 'Rol insuficiente',
        'code': 'INSUFFICIENT_ROLE'
      };
    }

    // Verificar permiso específico
    if (requiredPermission != null && !await hasPermission(requiredPermission)) {
      return {
        'authorized': false,
        'message': 'Permiso insuficiente',
        'code': 'INSUFFICIENT_PERMISSION'
      };
    }

    // Verificar acceso al recurso
    if (resourceType != null && resourceId != null) {
      if (!await canAccessResource(resourceType, resourceId)) {
        return {
          'authorized': false,
          'message': 'Acceso denegado al recurso',
          'code': 'RESOURCE_ACCESS_DENIED'
        };
      }
    }

    return {
      'authorized': true,
      'message': 'Acceso autorizado',
      'code': 'AUTHORIZED'
    };
  }

  // 8. OBTENER INFORMACIÓN DE SEGURIDAD
  static Future<Map<String, dynamic>> getSecurityInfo() async {
    final session = await _authService.getCurrentSession();
    if (session == null) {
      return {
        'authenticated': false,
        'role': null,
        'permissions': [],
        'institutionId': null,
      };
    }

    final role = session['role'];
    final permissions = await _getRolePermissions(role);
    
    return {
      'authenticated': true,
      'role': role,
      'permissions': permissions,
      'institutionId': session['institutionId'],
      'userId': session['userId'],
    };
  }

  // 9. OBTENER PERMISOS DEL ROL
  static Future<List<String>> _getRolePermissions(String role) async {
    final rolePermissions = {
      'super_admin': ['*'],
      'admin': [
        'manage_users',
        'manage_certificates',
        'view_reports',
        'manage_institutions',
      ],
      'emisor': [
        'create_certificates',
        'view_own_certificates',
        'manage_own_templates',
      ],
      'student': [
        'view_own_certificates',
        'download_certificates',
      ],
    };

    return rolePermissions[role] ?? [];
  }

  // 10. VERIFICAR SI ES PRIMER LOGIN
  static Future<bool> isFirstLogin() async {
    final session = await _authService.getCurrentSession();
    if (session == null) return false;
    
    // Aquí podrías verificar si es la primera vez que el usuario se loguea
    // Por ejemplo, verificando la fecha de último login
    return false; // Implementar lógica específica
  }

  // 11. VERIFICAR SI NECESITA CAMBIAR CONTRASEÑA
  static Future<bool> needsPasswordChange() async {
    final session = await _authService.getCurrentSession();
    if (session == null) return false;
    
    // Aquí podrías verificar si el usuario necesita cambiar su contraseña
    // Por ejemplo, si es una contraseña temporal o si ha expirado
    return false; // Implementar lógica específica
  }
}
