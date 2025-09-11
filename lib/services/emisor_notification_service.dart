// lib/services/emisor_notification_service.dart
// Servicio para enviar notificaciones a emisores

import 'package:http/http.dart' as http;
import 'dart:convert';

class EmisorNotificationService {
  // Configuración de EmailJS (usando las mismas credenciales que funcionan)
  static const String _emailjsServiceId = 'service_bdav8mg';
  static const String _emailjsTemplateId = 'template_2fs5k3c'; // Volver al template que funciona
  static const String _emailjsUserId = 'o1eUKl5D0Qq9fJ1Jv';
  static const String _emailjsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // Enviar credenciales de emisor por email
  static Future<Map<String, dynamic>> sendEmisorCredentials({
    required String email,
    required String fullName,
    required String password,
    required String institutionName,
    required String adminName,
  }) async {
    try {
      // Validar que el email no esté vacío
      if (email.isEmpty) {
        print('❌ Error: Email vacío');
        return {
          'success': false,
          'message': 'Error: Email vacío',
        };
      }
      
      // Validar formato de email
      if (!email.contains('@') || !email.contains('.')) {
        print('❌ Error: Email inválido - $email');
        return {
          'success': false,
          'message': 'Error: Email inválido - $email',
        };
      }
      
      print('📧 Enviando credenciales de emisor a: $email');
      print('📧 Datos: $fullName, $institutionName, $adminName');
      print('📧 Email length: ${email.length}');
      print('📧 Email isEmpty: ${email.isEmpty}');
      
      // Mostrar todos los parámetros que se envían
      print('📧 PARÁMETROS ENVIADOS:');
      print('📧 name: CertiBlock');
      print('📧 to_email: $email');
      print('📧 subject: Credenciales de Emisor - Certiblock');
      print('📧 message: ¡Hola $fullName! Has sido registrado...');
      print('📧 CONTRASEÑA: $password');

      final response = await http.post(
        Uri.parse(_emailjsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id': _emailjsUserId,
          'template_params': {
            // Usar exactamente los mismos parámetros que el template de instituciones
            'name': 'CertiBlock',
            'to_email': email,
            'message': '''
¡Hola $fullName!

Has sido registrado como Emisor en la plataforma Certiblock.

🔑 CONTRASEÑA TEMPORAL: $password

IMPORTANTE: 
- Debes cambiar tu contraseña en el primer acceso por seguridad
- El sistema te pedirá cambiar la contraseña automáticamente
- Usa estas credenciales para hacer login en la plataforma

🌐 Accede a: https://certiblock.com/login

¡Gracias!
Equipo Certiblock
            ''',
            'subject': 'Credenciales de Emisor - Certiblock',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email enviado exitosamente');
        print('📧 CREDENCIALES DEL EMISOR:');
        print('📧 Email: $email');
        print('📧 Contraseña: $password');
        print('📧 Nombre: $fullName');
        print('📧 Institución: $institutionName');
        return {
          'success': true,
          'message': 'Credenciales enviadas por email exitosamente',
          'credentials': {
            'email': email,
            'password': password,
            'fullName': fullName,
            'institutionName': institutionName,
          },
        };
      } else {
        print('❌ Error enviando email: ${response.statusCode} - ${response.body}');
        print('📧 CREDENCIALES DEL EMISOR (FALLBACK):');
        print('📧 Email: $email');
        print('📧 Contraseña: $password');
        print('📧 Nombre: $fullName');
        print('📧 Institución: $institutionName');
        return {
          'success': false,
          'message': 'Error enviando email: ${response.statusCode}. Credenciales mostradas en consola.',
          'credentials': {
            'email': email,
            'password': password,
            'fullName': fullName,
            'institutionName': institutionName,
          },
        };
      }
    } catch (e) {
      print('❌ Excepción enviando email: $e');
      return {
        'success': false,
        'message': 'Error enviando email: $e',
      };
    }
  }

  // Enviar notificación de bienvenida (sin contraseña)
  static Future<Map<String, dynamic>> sendWelcomeNotification({
    required String email,
    required String fullName,
    required String institutionName,
    required String adminName,
  }) async {
    try {
      print('📧 Enviando notificación de bienvenida a: $email');

      final response = await http.post(
        Uri.parse(_emailjsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _emailjsServiceId,
          'template_id': 'template_emisor_welcome', // Template diferente
          'user_id': _emailjsUserId,
          'template_params': {
            'to_email': email,
            'to_name': fullName,
            'institution_name': institutionName,
            'admin_name': adminName,
            'login_url': 'https://certiblock.com/login',
            'support_email': 'soporte@certiblock.com',
            // Parámetros que espera el template de instituciones
            'contact_email': email,
            'contact_name': fullName,
            'admin_email': email,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notificación de bienvenida enviada exitosamente');
        return {
          'success': true,
          'message': 'Notificación de bienvenida enviada exitosamente',
        };
      } else {
        print('❌ Error enviando notificación: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Error enviando notificación: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Excepción enviando notificación: $e');
      return {
        'success': false,
        'message': 'Error enviando notificación: $e',
      };
    }
  }
}
