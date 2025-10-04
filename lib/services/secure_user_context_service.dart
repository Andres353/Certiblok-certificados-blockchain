// lib/services/secure_user_context_service.dart
// Servicio seguro para manejar el contexto del usuario

import 'package:cloud_firestore/cloud_firestore.dart';
import 'secure_auth_service.dart';
import 'auth_middleware.dart';
import '../models/institution.dart';
import 'institution_service.dart';

class SecureUserContext {
  final String userId;
  final String userRole;
  final String? institutionId;
  final String? institutionName;
  final Institution? currentInstitution;
  final String userEmail;
  final String userName;
  final bool mustChangePassword;
  final bool isTemporaryPassword;
  final String? program;
  final String? faculty;
  final String? programId;
  final String? facultyId;
  final List<String> permissions;
  final DateTime lastLogin;
  final bool isActive;

  SecureUserContext({
    required this.userId,
    required this.userRole,
    this.institutionId,
    this.institutionName,
    this.currentInstitution,
    required this.userEmail,
    required this.userName,
    this.mustChangePassword = false,
    this.isTemporaryPassword = false,
    this.program,
    this.faculty,
    this.programId,
    this.facultyId,
    this.permissions = const [],
    required this.lastLogin,
    this.isActive = true,
  });

  // Verificar si el usuario requiere institución específica
  bool get requiresInstitution {
    const institutionSpecificRoles = ['admin', 'emisor', 'student'];
    return institutionSpecificRoles.contains(userRole);
  }

  // Verificar si el usuario es super admin
  bool get isSuperAdmin {
    return userRole == 'super_admin';
  }

  // Verificar si el usuario es admin
  bool get isAdmin {
    return userRole == 'admin';
  }

  // Verificar si el usuario es emisor
  bool get isEmisor {
    return userRole == 'emisor';
  }

  // Verificar si el usuario es estudiante
  bool get isStudent {
    return userRole == 'student';
  }

  // Verificar si tiene un permiso específico
  bool hasPermission(String permission) {
    return permissions.contains('*') || permissions.contains(permission);
  }

  // Verificar si puede gestionar usuarios
  bool get canManageUsers {
    return isSuperAdmin || isAdmin;
  }

  // Verificar si puede gestionar certificados
  bool get canManageCertificates {
    return isSuperAdmin || isAdmin || isEmisor;
  }

  // Verificar si puede ver reportes
  bool get canViewReports {
    return isSuperAdmin || isAdmin;
  }

  // Verificar si puede gestionar instituciones
  bool get canManageInstitutions {
    return isSuperAdmin;
  }

  // Obtener información de la institución
  String get institutionDisplayName {
    return institutionName ?? 'Sin institución';
  }

  // Verificar si necesita cambiar contraseña
  bool get needsPasswordChange {
    return mustChangePassword || isTemporaryPassword;
  }

  // Verificar si la sesión está activa
  bool get isSessionActive {
    return isActive && DateTime.now().difference(lastLogin).inHours < 8;
  }
}

class SecureUserContextService {
  static SecureUserContext? _currentContext;
  static final SecureAuthService _authService = SecureAuthService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener contexto actual
  static SecureUserContext? get currentContext => _currentContext;

  // Verificar si está inicializado
  static bool get isInitialized => _currentContext != null;

  // Cargar contexto del usuario actual
  static Future<SecureUserContext?> loadCurrentUserContext() async {
    try {
      final session = await _authService.getCurrentSession();
      if (session == null) {
        _currentContext = null;
        return null;
      }

      final userId = session['userId'];
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        _currentContext = null;
        return null;
      }

      final userData = userDoc.data()!;
      final institutionId = userData['institutionId'] ?? '';
      
      // Cargar información de la institución si es necesario
      Institution? institution;
      if (institutionId.isNotEmpty) {
        institution = await InstitutionService.getInstitution(institutionId);
      }

      // Obtener permisos del rol
      final permissions = await _getRolePermissions(userData['role'] ?? 'student');

      _currentContext = SecureUserContext(
        userId: userId,
        userRole: userData['role'] ?? 'student',
        institutionId: institutionId,
        institutionName: institution?.name,
        currentInstitution: institution,
        userEmail: userData['email'] ?? '',
        userName: userData['fullName'] ?? '',
        mustChangePassword: userData['mustChangePassword'] ?? false,
        isTemporaryPassword: userData['isTemporaryPassword'] ?? false,
        program: userData['program'],
        faculty: userData['faculty'],
        programId: userData['programId'],
        facultyId: userData['facultyId'],
        permissions: permissions,
        lastLogin: (userData['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: userData['isActive'] ?? true,
      );

      return _currentContext;

    } catch (e) {
      print('Error cargando contexto de usuario: $e');
      _currentContext = null;
      return null;
    }
  }

  // Obtener permisos del rol
  static Future<List<String>> _getRolePermissions(String role) async {
    const rolePermissions = {
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

  // Verificar si necesita cambiar contraseña
  static bool needsPasswordChange() {
    return _currentContext?.needsPasswordChange ?? false;
  }

  // Verificar si es super admin
  static bool isSuperAdmin() {
    return _currentContext?.isSuperAdmin ?? false;
  }

  // Verificar si es admin
  static bool isAdmin() {
    return _currentContext?.isAdmin ?? false;
  }

  // Verificar si es emisor
  static bool isEmisor() {
    return _currentContext?.isEmisor ?? false;
  }

  // Verificar si es estudiante
  static bool isStudent() {
    return _currentContext?.isStudent ?? false;
  }

  // Verificar si tiene un permiso específico
  static bool hasPermission(String permission) {
    return _currentContext?.hasPermission(permission) ?? false;
  }

  // Verificar si puede gestionar usuarios
  static bool canManageUsers() {
    return _currentContext?.canManageUsers ?? false;
  }

  // Verificar si puede gestionar certificados
  static bool canManageCertificates() {
    return _currentContext?.canManageCertificates ?? false;
  }

  // Verificar si puede ver reportes
  static bool canViewReports() {
    return _currentContext?.canViewReports ?? false;
  }

  // Verificar si puede gestionar instituciones
  static bool canManageInstitutions() {
    return _currentContext?.canManageInstitutions ?? false;
  }

  // Obtener ID de la institución actual
  static String? getCurrentInstitutionId() {
    return _currentContext?.institutionId;
  }

  // Obtener nombre de la institución actual
  static String getCurrentInstitutionName() {
    return _currentContext?.institutionDisplayName ?? 'Sin institución';
  }

  // Obtener ID del usuario actual
  static String? getCurrentUserId() {
    return _currentContext?.userId;
  }

  // Obtener rol del usuario actual
  static String? getCurrentUserRole() {
    return _currentContext?.userRole;
  }

  // Obtener email del usuario actual
  static String? getCurrentUserEmail() {
    return _currentContext?.userEmail;
  }

  // Obtener nombre del usuario actual
  static String? getCurrentUserName() {
    return _currentContext?.userName;
  }

  // Limpiar contexto
  static void clearContext() {
    _currentContext = null;
  }

  // Actualizar contexto después de cambios
  static Future<void> refreshContext() async {
    await loadCurrentUserContext();
  }

  // Verificar si la sesión está activa
  static bool isSessionActive() {
    return _currentContext?.isSessionActive ?? false;
  }

  // Obtener información de seguridad
  static Map<String, dynamic> getSecurityInfo() {
    if (_currentContext == null) {
      return {
        'authenticated': false,
        'role': null,
        'permissions': [],
        'institutionId': null,
        'userId': null,
      };
    }

    return {
      'authenticated': true,
      'role': _currentContext!.userRole,
      'permissions': _currentContext!.permissions,
      'institutionId': _currentContext!.institutionId,
      'userId': _currentContext!.userId,
      'isActive': _currentContext!.isActive,
      'lastLogin': _currentContext!.lastLogin.toIso8601String(),
    };
  }
}
