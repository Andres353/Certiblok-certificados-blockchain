// lib/services/user_context_service.dart
// Servicio para manejar el contexto del usuario multi-tenant

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/institution.dart';
import '../constants/roles.dart';
import '../data/sample_institutions.dart';
import 'institution_service.dart';

class UserContext {
  final String userId;
  final String userRole;
  final String? institutionId;
  final Institution? currentInstitution;
  final String userEmail;
  final String userName;
  final bool mustChangePassword;
  final bool isTemporaryPassword;

  UserContext({
    required this.userId,
    required this.userRole,
    this.institutionId,
    this.currentInstitution,
    required this.userEmail,
    required this.userName,
    this.mustChangePassword = false,
    this.isTemporaryPassword = false,
  });

  // Verificar si el usuario requiere institución específica
  bool get requiresInstitution {
    return UserRoles.getInstitutionSpecificRoles().contains(userRole);
  }

  // Verificar si el usuario es super admin
  bool get isSuperAdmin {
    return userRole == UserRoles.SUPER_ADMIN;
  }

  // Verificar si el usuario es admin de institución
  bool get isInstitutionAdmin {
    return userRole == UserRoles.ADMIN_INSTITUTION;
  }

  // Verificar si el usuario puede emitir certificados
  bool get canIssueCertificates {
    return UserRoles.getCertificateIssuers().contains(userRole);
  }

  // Verificar si el usuario puede ver certificados
  bool get canViewCertificates {
    return UserRoles.getCertificateViewers().contains(userRole);
  }

  // Convertir a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userRole': userRole,
      'institutionId': institutionId,
      'userEmail': userEmail,
      'userName': userName,
      'mustChangePassword': mustChangePassword,
      'isTemporaryPassword': isTemporaryPassword,
    };
  }

  // Crear desde Map
  factory UserContext.fromMap(Map<String, dynamic> map, Institution? institution) {
    return UserContext(
      userId: map['userId'] ?? '',
      userRole: map['userRole'] ?? '',
      institutionId: map['institutionId'],
      currentInstitution: institution,
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      mustChangePassword: map['mustChangePassword'] ?? false,
      isTemporaryPassword: map['isTemporaryPassword'] ?? false,
    );
  }
}

class UserContextService {
  static UserContext? _currentContext;
  static Institution? _currentInstitution;

  // Obtener contexto actual
  static UserContext? get currentContext => _currentContext;
  static Institution? get currentInstitution => _currentInstitution;

  // Establecer contexto de usuario
  static Future<void> setUserContext(UserContext context) async {
    _currentContext = context;
    _currentInstitution = context.currentInstitution;
    
    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_context', jsonEncode(context.toMap()));
  }

  // Establecer institución actual
  static Future<void> setCurrentInstitution(Institution institution) async {
    _currentInstitution = institution;
    
    if (_currentContext != null) {
      _currentContext = UserContext(
        userId: _currentContext!.userId,
        userRole: _currentContext!.userRole,
        institutionId: institution.id,
        currentInstitution: institution,
        userEmail: _currentContext!.userEmail,
        userName: _currentContext!.userName,
        mustChangePassword: _currentContext!.mustChangePassword,
        isTemporaryPassword: _currentContext!.isTemporaryPassword,
      );
      
      // Actualizar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_context', jsonEncode(_currentContext!.toMap()));
    }
  }

  // Cargar contexto desde SharedPreferences
  static Future<UserContext?> loadUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextString = prefs.getString('user_context');
      
      if (contextString != null) {
        final contextMap = jsonDecode(contextString);
        final institutionId = contextMap['institutionId'];
        
        // Cargar institución si existe
        Institution? institution;
        if (institutionId != null) {
          try {
            // Cargar desde InstitutionService
            institution = await InstitutionService.getInstitution(institutionId);
          } catch (e) {
            print('Error loading institution: $e');
            // Fallback a datos de ejemplo si hay error
            institution = SampleInstitutions.getInstitutionById(institutionId);
          }
        }
        
        _currentContext = UserContext.fromMap(contextMap, institution);
        _currentInstitution = institution;
        
        return _currentContext;
      }
    } catch (e) {
      print('Error loading user context: $e');
    }
    
    return null;
  }

  // Limpiar contexto (logout)
  static Future<void> clearUserContext() async {
    _currentContext = null;
    _currentInstitution = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_context');
  }

  // Verificar si el usuario tiene acceso a una institución específica
  static bool hasAccessToInstitution(String institutionId) {
    if (_currentContext == null) return false;
    
    // Super admin tiene acceso a todas las instituciones
    if (_currentContext!.isSuperAdmin) return true;
    
    // Otros usuarios solo tienen acceso a su institución
    return _currentContext!.institutionId == institutionId;
  }

  // Verificar si el usuario puede realizar una acción específica
  static bool canPerformAction(String action) {
    if (_currentContext == null) return false;
    
    return UserRoles.hasPermission(_currentContext!.userRole, action);
  }

  // Obtener filtro de institución para consultas
  static String? getInstitutionFilter() {
    if (_currentContext == null) return null;
    
    // Super admin no tiene filtro (ve todo)
    if (_currentContext!.isSuperAdmin) return null;
    
    // Otros usuarios solo ven datos de su institución
    return _currentContext!.institutionId;
  }

  // Verificar si el usuario necesita seleccionar institución
  static bool needsInstitutionSelection() {
    if (_currentContext == null) return false;
    
    return _currentContext!.requiresInstitution && 
           _currentContext!.institutionId == null;
  }

  // Verificar si el usuario debe cambiar contraseña
  static bool needsPasswordChange() {
    if (_currentContext == null) return false;
    
    return _currentContext!.mustChangePassword;
  }
}

