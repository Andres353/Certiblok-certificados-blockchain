// lib/services/certificate_notification_service.dart
// Servicio para enviar notificaciones de certificados emitidos

import 'package:http/http.dart' as http;
import 'dart:convert';

class CertificateNotificationService {
  // Configuración de EmailJS
  static const String _emailjsServiceId = 'service_bdav8mg';
  static const String _emailjsTemplateId = 'template_2fs5k3c';
  static const String _emailjsUserId = 'o1eUKl5D0Qq9fJ1Jv';
  static const String _emailjsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // Enviar notificación de certificado emitido
  static Future<Map<String, dynamic>> notifyCertificateIssued({
    required String studentEmail,
    required String studentName,
    required String certificateTitle,
    required String certificateType,
    required String institutionName,
    required String certificateId,
    String? description,
  }) async {
    try {
      print('📧 Enviando notificación de certificado a: $studentEmail');
      
      // Validar email
      if (studentEmail.isEmpty || !studentEmail.contains('@')) {
        throw Exception('Email de estudiante inválido: $studentEmail');
      }

      // Preparar el mensaje
      final String subject = '🎓 Nuevo Certificado Emitido - $institutionName';
      final String message = _buildCertificateMessage(
        studentName: studentName,
        certificateTitle: certificateTitle,
        certificateType: certificateType,
        institutionName: institutionName,
        description: description,
        certificateId: certificateId,
      );

      // Enviar email usando EmailJS
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
            'name': 'CertiBlock',
            'to_email': studentEmail,
            'message': message,
            'subject': subject,
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notificación de certificado enviada exitosamente');
        return {
          'success': true,
          'message': 'Notificación enviada exitosamente',
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

  // Construir mensaje de certificado
  static String _buildCertificateMessage({
    required String studentName,
    required String certificateTitle,
    required String certificateType,
    required String institutionName,
    String? description,
    required String certificateId,
  }) {
    final String typeLabel = _getCertificateTypeLabel(certificateType);
    
    return '''
¡Hola $studentName!

🎉 ¡Felicitaciones! Se ha emitido un nuevo certificado para ti.

📋 DETALLES DEL CERTIFICADO:
• Título: $certificateTitle
• Tipo: $typeLabel
• Institución: $institutionName
• ID del Certificado: $certificateId
• Fecha de Emisión: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

${description != null && description.isNotEmpty ? '• Descripción: $description' : ''}

🔍 ¿CÓMO VER TU CERTIFICADO?
1. Inicia sesión en tu cuenta de CertiBlock
2. Ve a "Mis Certificados" en tu dashboard
3. Busca el certificado con el título: "$certificateTitle"

✅ Tu certificado está disponible y verificado en la blockchain, lo que garantiza su autenticidad y validez.

📱 ¿Necesitas ayuda?
Si tienes alguna pregunta o necesitas asistencia, no dudes en contactarnos.

¡Felicitaciones por tu logro!

Saludos cordiales,
Equipo de CertiBlock
    ''';
  }

  // Obtener etiqueta del tipo de certificado
  static String _getCertificateTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'graduation':
        return 'Certificado de Graduación';
      case 'constancy':
        return 'Constancia de Estudios';
      case 'achievement':
        return 'Certificado de Logro';
      case 'participation':
        return 'Certificado de Participación';
      default:
        return 'Certificado';
    }
  }

  // Enviar notificación de certificado revocado
  static Future<Map<String, dynamic>> notifyCertificateRevoked({
    required String studentEmail,
    required String studentName,
    required String certificateTitle,
    required String institutionName,
    required String certificateId,
    String? reason,
  }) async {
    try {
      print('📧 Enviando notificación de certificado revocado a: $studentEmail');
      
      final String subject = '⚠️ Certificado Revocado - $institutionName';
      final String message = '''
¡Hola $studentName!

Lamentamos informarte que tu certificado ha sido revocado.

📋 DETALLES DEL CERTIFICADO:
• Título: $certificateTitle
• Institución: $institutionName
• ID del Certificado: $certificateId
• Fecha de Revocación: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

${reason != null && reason.isNotEmpty ? '• Motivo: $reason' : ''}

❌ Este certificado ya no es válido y no debe ser utilizado.

📞 Si consideras que esta revocación es incorrecta, por favor contacta a tu institución.

Saludos cordiales,
Equipo de CertiBlock
      ''';

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
            'name': 'CertiBlock',
            'to_email': studentEmail,
            'message': message,
            'subject': subject,
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notificación de revocación enviada exitosamente');
        return {
          'success': true,
          'message': 'Notificación de revocación enviada exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error enviando notificación: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Excepción enviando notificación de revocación: $e');
      return {
        'success': false,
        'message': 'Error enviando notificación: $e',
      };
    }
  }
}
