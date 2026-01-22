// lib/services/adapters/auth_adapter.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth_service.dart' as firebase_auth;
import '../supabase/supabase_auth_service.dart';
import '../user_context_service.dart';
import '../auth_security_service.dart';

class AuthAdapter {
  static bool _useSupabase = false; // Flag para cambiar entre Firebase y Supabase
  static const int _accountLockoutMinutes = 15; // Tiempo de bloqueo de cuenta

  // Cambiar entre Firebase y Supabase
  static void useSupabase(bool useSupabase) {
    _useSupabase = useSupabase;
    print('🔄 AuthAdapter: ${useSupabase ? "Usando Supabase" : "Usando Firebase"}');
  }

  // Login de usuario
  static Future<String?> loginUser(String email, String password) async {
    if (_useSupabase) {
      return await SupabaseAuthService.loginUser(email, password);
    } else {
      // Llamar a la función global de Firebase
      return await firebase_auth.loginUser(email, password);
    }
  }

  // Login con contexto
  static Future<UserContext?> loginWithContext(String email, String password) async {
    // Verificar si la cuenta está bloqueada
    final isLocked = await AuthSecurityService.isAccountLocked(email);
    if (isLocked) {
      final remainingTime = await AuthSecurityService.getRemainingLockoutTime(email);
      throw Exception(
        'Cuenta bloqueada por múltiples intentos fallidos. '
        'Intenta de nuevo en ${remainingTime ?? _accountLockoutMinutes} minutos.'
      );
    }

    UserContext? result;
    if (_useSupabase) {
      result = await SupabaseAuthService.loginWithContext(email, password);
    } else {
      // Llamar a la función global de Firebase
      result = await firebase_auth.loginWithContext(email, password);
    }

    // Si el login fue exitoso, limpiar intentos fallidos y registrar actividad
    if (result != null) {
      await AuthSecurityService.clearFailedLoginAttempts(email);
      await AuthSecurityService.recordUserActivity();
      // Iniciar monitoreo de sesión
      AuthSecurityService.startSessionMonitoring();
    } else {
      // Si el login falló, registrar intento fallido
      await AuthSecurityService.recordFailedLoginAttempt(email);
    }

    return result;
  }

  // Cerrar sesión
  static Future<void> logout() async {
    // Detener monitoreo de sesión
    AuthSecurityService.stopSessionMonitoring();
    
    if (_useSupabase) {
      await SupabaseAuthService.logout();
    } else {
      // Llamar a la función global de Firebase
      await firebase_auth.logout();
    }
    
    // Limpiar datos de seguridad
    await AuthSecurityService.clearAllSecurityData();
  }

  // Obtener usuario actual
  static dynamic getCurrentUser() {
    if (_useSupabase) {
      return Supabase.instance.client.auth.currentUser;
    } else {
      return null; // Firebase no tiene método estático
    }
  }

  // Resetear contraseña
  static Future<bool> resetPassword(String email) async {
    if (_useSupabase) {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(email);
        return true;
      } catch (e) {
        print('Error al resetear contraseña: $e');
        return false;
      }
    } else {
      return false; // Firebase no tiene método estático
    }
  }

  // Actualizar contraseña
  static Future<bool> updatePassword(String newPassword) async {
    if (_useSupabase) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        return true;
      } catch (e) {
        print('Error al actualizar contraseña: $e');
        return false;
      }
    } else {
      return false; // Firebase no tiene método estático
    }
  }

  // Registrar estudiante
  static Future<Map<String, dynamic>> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    String? phone,
    String? document,
    String? birthDate,
    String? address,
  }) async {
    if (_useSupabase) {
      return await SupabaseAuthService.registerStudent(
        email: email,
        password: password,
        fullName: fullName,
        studentId: studentId,
        phone: phone,
        document: document,
        birthDate: birthDate,
        address: address,
      );
    } else {
      // Llamar al método estático de Firebase
      return await firebase_auth.AuthService.registerStudent(
        email: email,
        password: password,
        fullName: fullName,
        studentId: studentId,
        phone: phone,
        document: document,
        birthDate: birthDate,
        address: address,
      );
    }
  }
}