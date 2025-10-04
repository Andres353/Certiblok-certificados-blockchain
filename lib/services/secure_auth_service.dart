// lib/services/secure_auth_service.dart
// Servicio de autenticación seguro y profesional

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/institution.dart';
import 'institution_service.dart';
import 'alert_service.dart';

class SecureAuthService {
  static const String _jwtSecret = 'certiblock_secure_secret_key_2024';
  static const String _sessionKey = 'user_session';
  static const int _sessionDurationHours = 8;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // 1. HASH DE CONTRASEÑAS CON SALT
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // 2. GENERAR JWT TOKEN SEGURO
  String _generateJWT(String userId, String role, String institutionId) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = {
      'userId': userId,
      'role': role,
      'institutionId': institutionId,
      'iat': now,
      'exp': now + (_sessionDurationHours * 3600),
      'jti': _uuid.v4(), // JWT ID único
    };

    // Crear header
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    // Codificar header y payload
    final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
    final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));

    // Crear signature
    final signature = _createSignature('$encodedHeader.$encodedPayload');
    final encodedSignature = base64Url.encode(signature);

    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  List<int> _createSignature(String data) {
    final key = utf8.encode(_jwtSecret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).bytes;
  }

  // 3. VALIDAR JWT TOKEN
  Map<String, dynamic>? _validateJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final header = jsonDecode(utf8.decode(base64Url.decode(parts[0])));
      final payload = jsonDecode(utf8.decode(base64Url.decode(parts[1])));
      final signature = base64Url.decode(parts[2]);

      // Verificar signature
      final expectedSignature = _createSignature('${parts[0]}.${parts[1]}');
      if (!_compareBytes(signature, expectedSignature)) return null;

      // Verificar expiración
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (payload['exp'] < now) return null;

      return payload;
    } catch (e) {
      print('Error validando JWT: $e');
      return null;
    }
  }

  bool _compareBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // 4. LOGIN SEGURO
  Future<Map<String, dynamic>> secureLogin(String email, String password) async {
    try {
      // Buscar usuario en la base de datos
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Credenciales inválidas',
          'code': 'INVALID_CREDENTIALS'
        };
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;

      // Verificar si el usuario está activo
      if (userData['isActive'] == false) {
        return {
          'success': false,
          'message': 'Usuario inactivo',
          'code': 'USER_INACTIVE'
        };
      }

      // Verificar contraseña
      final storedPassword = userData['passwordHash'] ?? '';
      final salt = userData['salt'] ?? '';
      final hashedPassword = _hashPassword(password, salt);

      if (storedPassword != hashedPassword) {
        // Registrar intento de login fallido
        await _logSecurityEvent(userId, 'LOGIN_FAILED', 'Invalid password');
        
        return {
          'success': false,
          'message': 'Credenciales inválidas',
          'code': 'INVALID_CREDENTIALS'
        };
      }

      // Generar JWT token
      final token = _generateJWT(
        userId,
        userData['role'] ?? 'student',
        userData['institutionId'] ?? '',
      );

      // Guardar sesión
      await _saveSession(userId, token, userData['role'] ?? 'student');

      // Registrar login exitoso
      await _logSecurityEvent(userId, 'LOGIN_SUCCESS', 'User logged in successfully');

      return {
        'success': true,
        'userId': userId,
        'role': userData['role'] ?? 'student',
        'institutionId': userData['institutionId'] ?? '',
        'token': token,
        'mustChangePassword': userData['mustChangePassword'] ?? false,
        'isTemporaryPassword': userData['isTemporaryPassword'] ?? false,
      };

    } catch (e) {
      print('Error en login seguro: $e');
      return {
        'success': false,
        'message': 'Error interno del servidor',
        'code': 'INTERNAL_ERROR'
      };
    }
  }

  // 5. REGISTRO SEGURO
  Future<Map<String, dynamic>> secureRegister({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    required String role,
    String? institutionId,
  }) async {
    try {
      // Verificar si el email ya existe
      final existingQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'El email ya está registrado',
          'code': 'EMAIL_EXISTS'
        };
      }

      // Generar salt y hash de contraseña
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);

      // Crear usuario
      final userData = {
        'email': email.trim(),
        'passwordHash': passwordHash,
        'salt': salt,
        'fullName': fullName.trim(),
        'studentId': studentId.trim(),
        'role': role,
        'institutionId': institutionId ?? '',
        'isActive': true,
        'mustChangePassword': false,
        'isTemporaryPassword': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
        'loginAttempts': 0,
        'lockedUntil': null,
      };

      final docRef = await _firestore.collection('users').add(userData);

      // Registrar evento de seguridad
      await _logSecurityEvent(docRef.id, 'USER_REGISTERED', 'New user registered');

      return {
        'success': true,
        'userId': docRef.id,
        'message': 'Usuario registrado exitosamente',
      };

    } catch (e) {
      print('Error en registro seguro: $e');
      return {
        'success': false,
        'message': 'Error interno del servidor',
        'code': 'INTERNAL_ERROR'
      };
    }
  }

  // 6. VALIDAR SESIÓN ACTUAL
  Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      
      if (sessionData == null) return null;

      final session = jsonDecode(sessionData);
      final token = session['token'];
      final userId = session['userId'];

      // Validar JWT
      final payload = _validateJWT(token);
      if (payload == null) {
        await _clearSession();
        return null;
      }

      // Verificar que el usuario sigue activo
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data()?['isActive'] != true) {
        await _clearSession();
        return null;
      }

      return {
        'userId': userId,
        'role': payload['role'],
        'institutionId': payload['institutionId'],
        'token': token,
      };

    } catch (e) {
      print('Error validando sesión: $e');
      await _clearSession();
      return null;
    }
  }

  // 7. LOGOUT SEGURO
  Future<void> secureLogout() async {
    try {
      final session = await getCurrentSession();
      if (session != null) {
        await _logSecurityEvent(session['userId'], 'LOGOUT', 'User logged out');
      }
      await _clearSession();
    } catch (e) {
      print('Error en logout: $e');
    }
  }

  // 8. GUARDAR SESIÓN
  Future<void> _saveSession(String userId, String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = {
      'userId': userId,
      'token': token,
      'role': role,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_sessionKey, jsonEncode(sessionData));
  }

  // 9. LIMPIAR SESIÓN
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // 10. REGISTRAR EVENTOS DE SEGURIDAD
  Future<void> _logSecurityEvent(String userId, String event, String description) async {
    try {
      await _firestore.collection('security_logs').add({
        'userId': userId,
        'event': event,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'unknown', // En producción, obtener IP real
        'userAgent': 'flutter_app',
      });
    } catch (e) {
      print('Error registrando evento de seguridad: $e');
    }
  }

  // 11. VERIFICAR PERMISOS
  Future<bool> hasPermission(String userId, String permission) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final role = userData['role'] ?? 'student';

      // Definir permisos por rol
      final rolePermissions = {
        'super_admin': ['*'], // Todos los permisos
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

      final permissions = rolePermissions[role] ?? [];
      return permissions.contains('*') || permissions.contains(permission);

    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  // 12. MIGRAR USUARIOS EXISTENTES (FUNCIÓN TEMPORAL)
  Future<void> migrateExistingUsers() async {
    try {
      final usersQuery = await _firestore.collection('users').get();
      
      for (final doc in usersQuery.docs) {
        final data = doc.data();
        
        // Solo migrar si no tiene passwordHash
        if (data['passwordHash'] == null && data['password'] != null) {
          final salt = _generateSalt();
          final passwordHash = _hashPassword(data['password'], salt);
          
          await doc.reference.update({
            'passwordHash': passwordHash,
            'salt': salt,
            'isActive': true,
            'loginAttempts': 0,
            'lockedUntil': null,
          });
          
          // Eliminar contraseña en texto plano
          await doc.reference.update({
            'password': FieldValue.delete(),
          });
          
          print('✅ Usuario migrado: ${data['email']}');
        }
      }
      
      print('✅ Migración de usuarios completada');
    } catch (e) {
      print('Error en migración: $e');
    }
  }
}
