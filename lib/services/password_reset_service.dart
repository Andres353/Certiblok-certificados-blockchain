// lib/services/password_reset_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordResetService {
  // Configuración de EmailJS (usando las mismas credenciales que funcionan)
  static const String _emailjsServiceId = 'service_bdav8mg';
  static const String _emailjsTemplateId = 'template_2fs5k3c';
  static const String _emailjsUserId = 'o1eUKl5D0Qq9fJ1Jv';
  static const String _emailjsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Generar código de verificación de 6 dígitos
  static String generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Verificar si el email existe en la base de datos
  static Future<bool> emailExists(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando email: $e');
      return false;
    }
  }

  /// Enviar código de verificación por email
  static Future<Map<String, dynamic>> sendResetCode(String email) async {
    try {
      // Verificar si el email existe
      final exists = await emailExists(email);
      if (!exists) {
        return {
          'success': false,
          'message': 'No se encontró una cuenta con este email'
        };
      }

      // Generar código de verificación
      final verificationCode = generateVerificationCode();
      
      // Guardar código en Firestore con timestamp
      await FirebaseFirestore.instance
          .collection('password_reset_codes')
          .doc(email.trim())
          .set({
        'code': verificationCode,
        'email': email.trim(),
        'createdAt': Timestamp.now(),
        'used': false,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 15)) // Expira en 15 minutos
        ),
      });

      // Enviar email usando EmailJS
      await _sendEmailViaEmailJS(
        toEmail: email.trim(),
        verificationCode: verificationCode,
      );

      return {
        'success': true,
        'message': 'Código de verificación enviado a tu email'
      };
    } catch (e) {
      print('❌ Error enviando código de reset: $e');
      return {
        'success': false,
        'message': 'Error enviando código de verificación: $e'
      };
    }
  }

  /// Verificar código de reset
  static Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('password_reset_codes')
          .doc(email.trim())
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'message': 'Código no encontrado o expirado'
        };
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final isUsed = data['used'] as bool;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      // Verificar si el código ya fue usado
      if (isUsed) {
        return {
          'success': false,
          'message': 'Este código ya fue utilizado'
        };
      }

      // Verificar si el código expiró
      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'message': 'El código ha expirado. Solicita uno nuevo.'
        };
      }

      // Verificar si el código coincide
      if (storedCode != code.trim()) {
        return {
          'success': false,
          'message': 'Código incorrecto'
        };
      }

      return {
        'success': true,
        'message': 'Código verificado correctamente'
      };
    } catch (e) {
      print('❌ Error verificando código: $e');
      return {
        'success': false,
        'message': 'Error verificando código: $e'
      };
    }
  }

  /// Resetear contraseña
  static Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    try {
      // Verificar que el código existe y es válido
      final doc = await FirebaseFirestore.instance
          .collection('password_reset_codes')
          .doc(email.trim())
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'message': 'Código no encontrado. Solicita uno nuevo.'
        };
      }

      final data = doc.data()!;
      final isUsed = data['used'] as bool;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (isUsed) {
        return {
          'success': false,
          'message': 'Este código ya fue utilizado'
        };
      }

      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'message': 'El código ha expirado. Solicita uno nuevo.'
        };
      }

      // Actualizar contraseña en la base de datos
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Usuario no encontrado'
        };
      }

      final userDoc = userQuery.docs.first;
      await userDoc.reference.update({
        'password': newPassword.trim(),
        'mustChangePassword': false,
        'isTemporaryPassword': false,
        'updatedAt': Timestamp.now(),
      });

      // Marcar código como usado
      await doc.reference.update({
        'used': true,
        'usedAt': Timestamp.now(),
      });

      return {
        'success': true,
        'message': 'Contraseña actualizada exitosamente'
      };
    } catch (e) {
      print('❌ Error reseteando contraseña: $e');
      return {
        'success': false,
        'message': 'Error actualizando contraseña: $e'
      };
    }
  }

  /// Enviar email usando EmailJS
  static Future<void> _sendEmailViaEmailJS({
    required String toEmail,
    required String verificationCode,
  }) async {
    final url = Uri.parse(_emailjsUrl);
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': _emailjsServiceId,
        'template_id': _emailjsTemplateId,
        'user_id': _emailjsUserId,
        'template_params': {
          'to_email': toEmail,
          'to_name': 'Usuario',
          'message': 'Hola,\n\nTu código de verificación para restablecer la contraseña es: $verificationCode\n\nEste código expira en 15 minutos.\n\nSi no solicitaste este cambio, ignora este mensaje.\n\nSaludos,\nEquipo de Certiblock',
          'subject': 'Código de Verificación - Restablecer Contraseña',
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error enviando email: ${response.body}');
    }

    print('✅ Email de reset de contraseña enviado exitosamente');
  }

  /// Limpiar códigos expirados (método de utilidad)
  static Future<void> cleanupExpiredCodes() async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('password_reset_codes')
          .where('expiresAt', isLessThan: now)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Códigos expirados limpiados');
    } catch (e) {
      print('❌ Error limpiando códigos expirados: $e');
    }
  }
}

