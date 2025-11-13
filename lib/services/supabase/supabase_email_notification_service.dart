// lib/services/supabase/supabase_email_notification_service.dart
// Servicio para enviar notificaciones por email a las instituciones usando Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:bcrypt/bcrypt.dart';
import 'dart:convert';

class SupabaseEmailNotificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Enviar notificación de aprobación con credenciales temporales
  static Future<void> sendApprovalNotification({
    required String institutionName,
    required String contactEmail,
    required String contactName,
    required String institutionId,
    required String institutionCode,
  }) async {
    try {
      print('📧 Enviando notificación de aprobación a: $contactEmail');
      
      // Generar credenciales temporales
      final tempPassword = _generateTemporaryPassword();
      // Usar el email real de la institución en lugar del artificial
      final adminEmail = contactEmail;
      
      // Crear usuario admin de la institución
      await _createInstitutionAdmin(
        email: adminEmail,
        password: tempPassword,
        institutionId: institutionId,
        institutionName: institutionName,
        contactName: contactName,
      );
      
      // Enviar email de notificación
      await _sendApprovalEmail(
        institutionName: institutionName,
        contactEmail: contactEmail,
        contactName: contactName,
        adminEmail: adminEmail,
        tempPassword: tempPassword,
        institutionCode: institutionCode,
      );
      
      print('✅ Notificación de aprobación enviada exitosamente');
    } catch (e) {
      print('❌ Error enviando notificación de aprobación: $e');
      throw Exception('Error enviando notificación: $e');
    }
  }

  // Enviar notificación de rechazo
  static Future<void> sendRejectionNotification({
    required String institutionName,
    required String contactEmail,
    required String contactName,
    required String rejectionReason,
  }) async {
    try {
      print('📧 Enviando notificación de rechazo a: $contactEmail');
      
      // Enviar email de rechazo
      await _sendRejectionEmail(
        institutionName: institutionName,
        contactEmail: contactEmail,
        contactName: contactName,
        rejectionReason: rejectionReason,
      );
      
      print('✅ Notificación de rechazo enviada exitosamente');
    } catch (e) {
      print('❌ Error enviando notificación de rechazo: $e');
      throw Exception('Error enviando notificación: $e');
    }
  }

  // Crear usuario admin de la institución
  static Future<void> _createInstitutionAdmin({
    required String email,
    required String password,
    required String institutionId,
    required String institutionName,
    required String contactName,
  }) async {
    try {
      // Verificar si el usuario ya existe en Supabase
      final existingUsers = await _client
          .from('users')
          .select('id, email')
          .eq('email', email)
          .limit(1);

      String userId;
      
      if (existingUsers.isNotEmpty) {
        // Usuario ya existe, actualizar datos
        userId = existingUsers.first['id'].toString();
        print('🔄 Usuario ya existe, actualizando datos: $email');
        
        // Actualizar contraseña en Supabase
        await _client.from('users').update({
          'password_hash': _hashPassword(password),
          'must_change_password': true,
          'is_temporary_password': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
        
        print('✅ Contraseña actualizada en Supabase');
      } else {
        // Crear nuevo usuario en Supabase
        final response = await _client.from('users').insert({
          'email': email,
          'password_hash': _hashPassword(password),
          'full_name': contactName,
          'role': 'admin_institution',
          'institution_id': institutionId,
          'is_verified': true,
          'must_change_password': true,
          'is_temporary_password': true,
          'created_at': DateTime.now().toIso8601String(),
        }).select();

        if (response.isNotEmpty) {
          userId = response.first['id'].toString();
          print('✅ Nuevo usuario creado en Supabase: $email');
        } else {
          throw Exception('No se pudo crear el usuario en Supabase');
        }
      }

      // Actualizar datos del admin en la institución
      final institutionAdminData = {
        'admin_email': email,
        'admin_password_hash': _hashPassword(password), // Guardar hash, no contraseña en texto plano
        'admin_must_change_password': true,
        'admin_is_temporary_password': true,
        'admin_name': contactName,
        'admin_user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('institutions').update(institutionAdminData).eq('id', institutionId);

      print('✅ Usuario admin creado/actualizado: $email');
      print('🆔 ID del usuario: $userId');
      print('🏛️ Datos del admin en institución: $institutionAdminData');
    } catch (e) {
      print('❌ Error creando usuario admin: $e');
      throw Exception('Error creando usuario admin: $e');
    }
  }

  // Hash de contraseña usando bcrypt
  static String _hashPassword(String password) {
    // Usar bcrypt para hashear la contraseña (igual que en SupabaseAuthService)
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  // Generar contraseña temporal
  static String _generateTemporaryPassword() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#';
    final random = DateTime.now().millisecondsSinceEpoch;
    String password = '';
    
    for (int i = 0; i < 12; i++) {
      password += chars[(random + i) % chars.length];
    }
    
    return password;
  }

  // Enviar email de aprobación
  static Future<void> _sendApprovalEmail({
    required String institutionName,
    required String contactEmail,
    required String contactName,
    required String adminEmail,
    required String tempPassword,
    required String institutionCode,
  }) async {
    try {
      // Usar las mismas credenciales de EmailJS que el registro de estudiantes
      const serviceId = 'service_bdav8mg';
      const templateId = 'template_2fs5k3c';
      const userId = 'o1eUKl5D0Qq9fJ1Jv';

      final String subject = '✅ Solicitud Aprobada - $institutionName';
      final String message = '''
Estimado/a $contactName,

¡Excelentes noticias! Su solicitud de registro para $institutionName ha sido APROBADA.

Sus credenciales de acceso son:
• Email: $adminEmail (su email institucional)
• Contraseña temporal: $tempPassword
• Código de Institución: $institutionCode

IMPORTANTE: 
- Debe cambiar su contraseña en el primer acceso por seguridad
- Use estas credenciales para hacer login en la plataforma
- El sistema le pedirá cambiar la contraseña automáticamente
- El código de institución es único y necesario para el registro de estudiantes

Próximos pasos:
1. Haga logout del Super Admin si está logueado
2. Acceda a la plataforma con las credenciales proporcionadas
3. Cambie su contraseña temporal por una personal
4. Complete la configuración de su institución
5. Comparta el código $institutionCode con sus estudiantes para el registro
6. Comience a usar el sistema

¡Bienvenido a CertiBlock!

Saludos cordiales,
Equipo de CertiBlock
      ''';

      // Enviar email usando EmailJS
      await _sendEmailViaEmailJS(
        toEmail: contactEmail,
        subject: subject,
        message: message,
        serviceId: serviceId,
        templateId: templateId,
        userId: userId,
      );

      print('✅ Email de aprobación enviado a: $contactEmail');
    } catch (e) {
      print('❌ Error enviando email de aprobación: $e');
      // Fallback: mostrar en consola
      print('''
📧 EMAIL DE APROBACIÓN (FALLBACK):
═══════════════════════════════════════════════════════════════
Para: $contactEmail
Asunto: ✅ Solicitud Aprobada - $institutionName

Estimado/a $contactName,

¡Excelentes noticias! Su solicitud de registro para $institutionName ha sido APROBADA.

Sus credenciales de acceso son:
• Email: $adminEmail (su email institucional)
• Contraseña temporal: $tempPassword
• Código de Institución: $institutionCode

IMPORTANTE: 
- Debe cambiar su contraseña en el primer acceso por seguridad
- El código de institución es único y necesario para el registro de estudiantes

Próximos pasos:
1. Acceda a la plataforma con las credenciales proporcionadas
2. Cambie su contraseña temporal por una personal
3. Complete la configuración de su institución
4. Comparta el código $institutionCode con sus estudiantes para el registro
5. Comience a usar el sistema

¡Bienvenido a CertiBlock!

Saludos cordiales,
Equipo de CertiBlock
═══════════════════════════════════════════════════════════════
      ''');
    }
  }

  // Enviar email de rechazo
  static Future<void> _sendRejectionEmail({
    required String institutionName,
    required String contactEmail,
    required String contactName,
    required String rejectionReason,
  }) async {
    try {
      // Usar las mismas credenciales de EmailJS que el registro de estudiantes
      const serviceId = 'service_bdav8mg';
      const templateId = 'template_2fs5k3c';
      const userId = 'o1eUKl5D0Qq9fJ1Jv';

      final String subject = '❌ Solicitud Rechazada - $institutionName';
      final String message = '''
Estimado/a $contactName,

Lamentamos informarle que su solicitud de registro para $institutionName ha sido RECHAZADA.

Motivo del rechazo:
$rejectionReason

Si considera que esta decisión es incorrecta o desea más información, puede contactarnos.

Gracias por su interés en CertiBlock.

Saludos cordiales,
Equipo de CertiBlock
      ''';

      // Enviar email usando EmailJS
      await _sendEmailViaEmailJS(
        toEmail: contactEmail,
        subject: subject,
        message: message,
        serviceId: serviceId,
        templateId: templateId,
        userId: userId,
      );

      print('✅ Email de rechazo enviado a: $contactEmail');
    } catch (e) {
      print('❌ Error enviando email de rechazo: $e');
      // Fallback: mostrar en consola
      print('''
📧 EMAIL DE RECHAZO (FALLBACK):
═══════════════════════════════════════════════════════════════
Para: $contactEmail
Asunto: ❌ Solicitud Rechazada - $institutionName

Estimado/a $contactName,

Lamentamos informarle que su solicitud de registro para $institutionName ha sido RECHAZADA.

Motivo del rechazo:
$rejectionReason

Si considera que esta decisión es incorrecta o desea más información, puede contactarnos.

Gracias por su interés en CertiBlock.

Saludos cordiales,
Equipo de CertiBlock
═══════════════════════════════════════════════════════════════
      ''');
    }
  }

  // Método para enviar email usando EmailJS
  static Future<void> _sendEmailViaEmailJS({
    required String toEmail,
    required String subject,
    required String message,
    required String serviceId,
    required String templateId,
    required String userId,
  }) async {
    final String url = 'https://api.emailjs.com/api/v1.0/email/send';
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> data = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'name': 'CertiBlock',
        'to_email': toEmail,
        'message': message,
        'subject': subject,
      }
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      print('✅ Email enviado exitosamente via EmailJS');
    } else {
      throw Exception('Error enviando email: ${response.statusCode} - ${response.body}');
    }
  }
}
