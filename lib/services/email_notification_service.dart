// lib/services/email_notification_service.dart
// Servicio para enviar notificaciones por email a las instituciones

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
      // Verificar si el usuario ya existe
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String userId;
      
      if (existingUsers.docs.isNotEmpty) {
        // Usuario ya existe, actualizar datos
        userId = existingUsers.docs.first.id;
        print('🔄 Usuario ya existe, actualizando datos: $email');
        
        // Actualizar contraseña en Firebase Auth si es necesario
        try {
          final user = _auth.currentUser;
          if (user != null && user.email == email) {
            await user.updatePassword(password);
            print('✅ Contraseña actualizada en Firebase Auth');
          }
        } catch (e) {
          print('⚠️ No se pudo actualizar contraseña en Auth: $e');
        }
      } else {
        // Crear nuevo usuario en Firebase Auth solo si no existe
        try {
          final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          userId = userCredential.user!.uid;
          print('✅ Nuevo usuario creado en Firebase Auth: $email');
          
          // Cerrar sesión del usuario actual si existe
          await _auth.signOut();
        } catch (e) {
          // Si el email ya existe en Auth, usar el email como ID
          if (e.toString().contains('email-already-in-use')) {
            print('⚠️ Email ya existe en Auth, usando email como ID...');
            userId = email; // Usar el email como ID único
            print('✅ Usando email como ID: $userId');
          } else {
            throw e;
          }
        }
      }

      // Crear/actualizar perfil SOLO en la colección institutions
      final institutionAdminData = {
        'adminEmail': email,
        'adminPassword': password,
        'adminMustChangePassword': true,
        'adminIsTemporaryPassword': true,
        'adminName': contactName,
        'adminUserId': userId, // Guardar el userId para referencia
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('institutions').doc(institutionId).update(institutionAdminData);

      print('✅ Usuario admin creado/actualizado: $email');
      print('🆔 ID del usuario: $userId');
      print('🏛️ Datos del admin en institución: $institutionAdminData');
    } catch (e) {
      print('❌ Error creando usuario admin: $e');
      throw Exception('Error creando usuario admin: $e');
    }
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
