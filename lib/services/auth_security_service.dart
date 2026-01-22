// lib/services/auth_security_service.dart
// Servicio de control de seguridad de autenticación

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/adapters/auth_adapter.dart';

class AuthSecurityService {
  static const String _lastActivityKey = 'auth_last_activity';
  static const String _failedLoginAttemptsKey = 'auth_failed_attempts';
  static const String _accountLockedUntilKey = 'auth_locked_until';
  static const String _sessionValidatedKey = 'auth_session_validated';
  
  // Configuración de seguridad
  static const int _inactivityTimeoutMinutes = 30; // Timeout después de 30 minutos de inactividad
  static const int _maxFailedAttempts = 5; // Máximo de intentos fallidos
  static const int _accountLockoutMinutes = 15; // Bloqueo por 15 minutos
  static const int _sessionValidationIntervalSeconds = 300; // Validar sesión cada 5 minutos

  // 1. REGISTRAR ACTIVIDAD DEL USUARIO
  static Future<void> recordUserActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastActivityKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error registrando actividad: $e');
    }
  }

  // 2. VERIFICAR SI LA SESIÓN HA EXPIRADO POR INACTIVIDAD
  static Future<bool> isSessionActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt(_lastActivityKey);
      
      if (lastActivity == null) {
        // Si no hay registro de actividad, considerar sesión activa si hay usuario
        final currentUser = AuthAdapter.getCurrentUser();
        if (currentUser != null) {
          await recordUserActivity();
          return true;
        }
        return false;
      }

      final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
      final now = DateTime.now();
      final difference = now.difference(lastActivityTime);

      // Si ha pasado más del tiempo de inactividad, cerrar sesión
      if (difference.inMinutes > _inactivityTimeoutMinutes) {
        print('⚠️ Sesión expirada por inactividad');
        await _forceLogout();
        return false;
      }

      return true;
    } catch (e) {
      print('Error verificando sesión activa: $e');
      return false;
    }
  }

  // 3. VERIFICAR Y LIMPIAR SESIÓN EXPIRADA
  static Future<bool> validateSession() async {
    try {
      // Verificar si la sesión de Supabase está activa
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        print('⚠️ No hay usuario autenticado en Supabase');
        await _forceLogout();
        return false;
      }

      // Verificar si el token ha expirado
      final session = supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        print('⚠️ Token de sesión expirado');
        await _forceLogout();
        return false;
      }

      // Verificar inactividad
      if (!await isSessionActive()) {
        return false;
      }

      // Actualizar timestamp de validación
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _sessionValidatedKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      return true;
    } catch (e) {
      print('Error validando sesión: $e');
      return false;
    }
  }

  // 4. REGISTRAR INTENTO DE LOGIN FALLIDO
  static Future<void> recordFailedLoginAttempt(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_failedLoginAttemptsKey}_$email';
      
      final attempts = prefs.getInt(key) ?? 0;
      final newAttempts = attempts + 1;
      
      await prefs.setInt(key, newAttempts);
      
      print('⚠️ Intento fallido #$newAttempts para $email');
      
      // Si se excede el máximo, bloquear cuenta
      if (newAttempts >= _maxFailedAttempts) {
        await _lockAccount(email);
      }
    } catch (e) {
      print('Error registrando intento fallido: $e');
    }
  }

  // 5. LIMPIAR INTENTOS FALLIDOS (cuando el login es exitoso)
  static Future<void> clearFailedLoginAttempts(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_failedLoginAttemptsKey}_$email';
      await prefs.remove(key);
      await prefs.remove('${_accountLockedUntilKey}_$email');
    } catch (e) {
      print('Error limpiando intentos fallidos: $e');
    }
  }

  // 6. VERIFICAR SI LA CUENTA ESTÁ BLOQUEADA
  static Future<bool> isAccountLocked(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockedUntilKey = '${_accountLockedUntilKey}_$email';
      final lockedUntil = prefs.getInt(lockedUntilKey);
      
      if (lockedUntil == null) {
        return false;
      }

      final lockedUntilTime = DateTime.fromMillisecondsSinceEpoch(lockedUntil);
      final now = DateTime.now();

      if (now.isAfter(lockedUntilTime)) {
        // El bloqueo ha expirado, limpiar
        await prefs.remove(lockedUntilKey);
        await prefs.remove('${_failedLoginAttemptsKey}_$email');
        return false;
      }

      return true;
    } catch (e) {
      print('Error verificando bloqueo de cuenta: $e');
      return false;
    }
  }

  // 7. OBTENER TIEMPO RESTANTE DE BLOQUEO
  static Future<int?> getRemainingLockoutTime(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockedUntilKey = '${_accountLockedUntilKey}_$email';
      final lockedUntil = prefs.getInt(lockedUntilKey);
      
      if (lockedUntil == null) {
        return null;
      }

      final lockedUntilTime = DateTime.fromMillisecondsSinceEpoch(lockedUntil);
      final now = DateTime.now();
      final difference = lockedUntilTime.difference(now);

      if (difference.isNegative) {
        return null;
      }

      return difference.inMinutes;
    } catch (e) {
      print('Error obteniendo tiempo de bloqueo: $e');
      return null;
    }
  }

  // 8. OBTENER INTENTOS FALLIDOS RESTANTES
  static Future<int> getRemainingAttempts(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_failedLoginAttemptsKey}_$email';
      final attempts = prefs.getInt(key) ?? 0;
      return _maxFailedAttempts - attempts;
    } catch (e) {
      return _maxFailedAttempts;
    }
  }

  // 9. BLOQUEAR CUENTA
  static Future<void> _lockAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockedUntilKey = '${_accountLockedUntilKey}_$email';
      
      final lockedUntil = DateTime.now().add(
        Duration(minutes: _accountLockoutMinutes),
      );
      
      await prefs.setInt(
        lockedUntilKey,
        lockedUntil.millisecondsSinceEpoch,
      );
      
      print('🔒 Cuenta bloqueada por $_accountLockoutMinutes minutos: $email');
    } catch (e) {
      print('Error bloqueando cuenta: $e');
    }
  }

  // 10. FORZAR LOGOUT
  static Future<void> _forceLogout() async {
    try {
      await AuthAdapter.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivityKey);
      await prefs.remove(_sessionValidatedKey);
      print('🔐 Sesión cerrada automáticamente por seguridad');
    } catch (e) {
      print('Error en force logout: $e');
    }
  }

  // 11. INICIAR MONITOREO DE SESIÓN (para usar en widgets)
  static Timer? _sessionMonitor;
  
  static void startSessionMonitoring() {
    // Cancelar monitor existente si hay uno
    _sessionMonitor?.cancel();
    
    // Validar sesión cada cierto intervalo
    _sessionMonitor = Timer.periodic(
      Duration(seconds: _sessionValidationIntervalSeconds),
      (timer) async {
        final isValid = await validateSession();
        if (!isValid) {
          timer.cancel();
          // La sesión ya fue cerrada en validateSession
        }
      },
    );
  }

  static void stopSessionMonitoring() {
    _sessionMonitor?.cancel();
    _sessionMonitor = null;
  }

  // 12. VERIFICAR SI NECESITA VALIDACIÓN DE SESIÓN
  static Future<bool> needsSessionValidation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastValidation = prefs.getInt(_sessionValidatedKey);
      
      if (lastValidation == null) {
        return true;
      }

      final lastValidationTime = DateTime.fromMillisecondsSinceEpoch(lastValidation);
      final now = DateTime.now();
      final difference = now.difference(lastValidationTime);

      return difference.inSeconds >= _sessionValidationIntervalSeconds;
    } catch (e) {
      return true;
    }
  }

  // 13. LIMPIAR TODOS LOS DATOS DE SEGURIDAD
  static Future<void> clearAllSecurityData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivityKey);
      await prefs.remove(_sessionValidatedKey);
      
      // Limpiar intentos fallidos (las claves dinámicas no se pueden limpiar fácilmente)
      // pero se limpiarán automáticamente con el tiempo
    } catch (e) {
      print('Error limpiando datos de seguridad: $e');
    }
  }

  // 14. OBTENER ESTADO DE SEGURIDAD
  static Future<Map<String, dynamic>> getSecurityStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt(_lastActivityKey);
      final lastValidation = prefs.getInt(_sessionValidatedKey);
      
      int? minutesSinceActivity;
      if (lastActivity != null) {
        final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
        minutesSinceActivity = DateTime.now().difference(lastActivityTime).inMinutes;
      }

      int? minutesSinceValidation;
      if (lastValidation != null) {
        final lastValidationTime = DateTime.fromMillisecondsSinceEpoch(lastValidation);
        minutesSinceValidation = DateTime.now().difference(lastValidationTime).inMinutes;
      }

      return {
        'sessionActive': await isSessionActive(),
        'minutesSinceActivity': minutesSinceActivity,
        'minutesSinceValidation': minutesSinceValidation,
        'inactivityTimeout': _inactivityTimeoutMinutes,
        'remainingActivityMinutes': lastActivity != null 
          ? _inactivityTimeoutMinutes - (minutesSinceActivity ?? 0)
          : null,
      };
    } catch (e) {
      print('Error obteniendo estado de seguridad: $e');
      return {
        'sessionActive': false,
        'error': e.toString(),
      };
    }
  }
}
