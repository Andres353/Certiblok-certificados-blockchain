// lib/services/application_service.dart
// Servicio para gestionar postulaciones a programas

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/application.dart';
import 'user_context_service.dart';
import 'supabase/supabase_certificate_service.dart';
import 'supabase/supabase_programs_service.dart';
import 'image_upload_service.dart';

class ApplicationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'applications';
  
  // Cliente de Supabase
  static SupabaseClient get _supabase => Supabase.instance.client;

  // Crear nueva postulación
  static Future<String> createApplication({
    required String programId,
    String? cvFilePath,
    required String cvFileName,
    Uint8List? cvFileBytes, // Bytes del CV para web
    required List<String> selectedCertificates,
    required String motivationLetter,
    String? motivationPdfData,
    String? motivationPdfFileName,
    Map<String, dynamic>? additionalDocuments,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el usuario sea estudiante
      if (context.userRole != 'student') {
        throw Exception('Solo los estudiantes pueden postularse');
      }

      // Obtener información del programa usando Supabase
      final program = await SupabaseProgramsService.getProgramById(programId);
      if (program == null) {
        throw Exception('Programa no encontrado');
      }

      // Verificar que el estudiante puede postularse
      // canStudentApply ahora lanza excepciones específicas en lugar de retornar false
      await SupabaseProgramsService.canStudentApply(programId, context.userId);

      // Subir CV a Supabase Storage
      final cvUrl = await _uploadCV(cvFilePath, cvFileBytes, context.userId, cvFileName);

      // Obtener detalles de los certificados seleccionados
      final certificateDetails = await _getCertificateDetails(selectedCertificates);

      print('📋 Programa obtenido: ${program.title}');
      print('📋 InstitutionId: ${program.institutionId}');
      print('📋 InstitutionName: ${program.institutionName}');
      print('📋 CV URL: $cvUrl');
      print('📋 Context UserName: ${context.userName}');
      print('📋 Context UserEmail: ${context.userEmail}');
      print('📋 Context UserId: ${context.userId}');

      // Validar que tenemos todos los datos necesarios
      if (context.userName.isEmpty || context.userEmail.isEmpty) {
        throw Exception('Datos del usuario incompletos. Por favor, cierra sesión y vuelve a iniciar.');
      }

      // Crear postulación en Supabase (no en Firestore)
      final now = DateTime.now().toIso8601String();
      final response = await _supabase.from('applications').insert({
        'student_id': context.userId,
        'student_name': context.userName,
        'student_email': context.userEmail,
        'program_id': programId,
        'program_title': program.title,
        'institution_id': program.institutionId,
        'institution_name': program.institutionName,
        'status': 'pending',
        'cv_url': cvUrl,
        'cv_file_name': cvFileName,
        'selected_certificates': selectedCertificates,
        'certificate_details': certificateDetails,
        'motivation_letter': motivationLetter,
        'motivation_pdf_data': motivationPdfData,
        'motivation_pdf_file_name': motivationPdfFileName,
        'additional_documents': additionalDocuments ?? {},
        'submitted_at': now,
        'created_at': now,
        'updated_at': now,
      }).select('id').single();
      
      final applicationId = response['id'] as String;

      // Incrementar contador de aplicaciones del programa en Supabase
      try {
        await SupabaseProgramsService.updateProgram(programId, {
          'current_applications': program.currentApplications + 1,
        });
      } catch (e) {
        print('⚠️ Error incrementando contador de aplicaciones: $e');
        // No fallar si hay error incrementando el contador
      }

      print('✅ Postulación creada exitosamente: $applicationId');
      return applicationId;
    } catch (e) {
      throw Exception('Error al crear postulación: $e');
    }
  }

  // Subir CV usando ImageUploadService (igual que pasantías y certificados)
  static Future<String> _uploadCV(String? filePath, Uint8List? fileBytes, String studentId, String fileName) async {
    try {
      print('📤 Subiendo CV: $fileName');
      print('   StudentId: $studentId');
      
      Uint8List bytes;
      
      if (fileBytes != null) {
        print('   Usando bytes proporcionados');
        bytes = fileBytes;
      } else if (filePath != null) {
        print('   Usando path, leyendo bytes...');
      final file = File(filePath);
        bytes = await file.readAsBytes();
        print('   Bytes leídos: ${bytes.length} bytes');
      } else {
        throw Exception('No se proporcionó archivo CV');
      }
      
      // Validar tamaño (igual que PDFs de programas: max 700KB)
      // Validar tamaño del archivo (máximo 50MB para Supabase Storage)
      const int maxSize = 50 * 1024 * 1024; // 50MB para Supabase Storage
      if (bytes.length > maxSize) {
        throw Exception('El CV es demasiado grande (${(bytes.length / 1024 / 1024).toStringAsFixed(1)}MB). El límite es ${(maxSize / 1024 / 1024).toStringAsFixed(0)}MB. Por favor, comprime el archivo o usa uno más pequeño.');
      }
      
      // Subir PDF a Supabase Storage
      final pdfUrl = await ImageUploadService.uploadPdfBytes(
        bytes,
        'applications/cv/$studentId/$fileName',
      );
      
      print('✅ CV subido exitosamente a Supabase Storage');
      return pdfUrl; // Retornar URL de Supabase Storage
    } catch (e, stackTrace) {
      print('❌ Error al subir CV: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error al subir CV: $e');
    }
  }

  // Obtener detalles de certificados seleccionados
  static Future<List<Map<String, dynamic>>> _getCertificateDetails(List<String> certificateIds) async {
    try {
      print('📜 Obteniendo detalles de ${certificateIds.length} certificados');
      final details = <Map<String, dynamic>>[];
      
      for (String certId in certificateIds) {
        try {
          print('   Obteniendo certificado: $certId');
          final certificate = await SupabaseCertificateService.getCertificate(certId);
          if (certificate != null) {
            print('   ✅ Certificado encontrado: ${certificate.title}');
            details.add({
              'id': certificate.id,
              'title': certificate.title,
              'type': certificate.certificateType,
              'issuedAt': certificate.issuedAt.toIso8601String(),
              'institutionName': certificate.institutionName,
            });
          } else {
            print('   ⚠️ Certificado no encontrado: $certId');
          }
        } catch (e) {
          print('❌ Error obteniendo certificado $certId: $e');
        }
      }
      
      print('📜 Total de certificados obtenidos: ${details.length}');
      return details;
    } catch (e, stackTrace) {
      print('❌ Error obteniendo detalles de certificados: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Obtener postulaciones de un estudiante
  static Future<List<Application>> getStudentApplications() async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('applications')
          .select('*')
          .eq('student_id', context.userId)
          .order('submitted_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return (response as List).map((doc) => Application.fromSupabase(doc as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Error al obtener postulaciones: $e');
    }
  }

  // Obtener postulaciones de una institución
  static Future<List<Application>> getInstitutionApplications({
    String? programId,
    String? status,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos
      if (!['super_admin', 'admin_institution', 'emisor'].contains(context.userRole)) {
        throw Exception('No tienes permisos para ver postulaciones');
      }

      // Construir consulta en Supabase
      var query = _supabase.from('applications').select('*');

      // Si no es super admin, filtrar por institución
      if (!context.isSuperAdmin) {
        final institutionId = context.institutionId;
        if (institutionId != null) {
          query = query.eq('institution_id', institutionId);
        }
      }

      // Aplicar filtros adicionales
      if (programId != null) {
        query = query.eq('program_id', programId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      // Ejecutar la consulta y ordenar
      var response = await query.order('submitted_at', ascending: false);

      // Convertir a objetos Application
      if (response.isEmpty) {
        return [];
      }
      
      var allApplications = (response as List).map((doc) => Application.fromSupabase(doc as Map<String, dynamic>)).toList();

      // Si es super admin, retornar todas las aplicaciones
      if (context.isSuperAdmin) {
        return allApplications;
      }

      // Para admin_institution: mostrar todas las aplicaciones de su institución
      // Para emisor: filtrar por programas creados por el usuario
      if (context.userRole == 'admin_institution') {
        // Los administradores ven todas las aplicaciones de su institución
        print('📊 Administrador: mostrando todas las aplicaciones de la institución');
        return allApplications;
      }

      // Para emisor, filtrar por programas creados por el usuario
      print('🔍 Emisor: Filtrando aplicaciones por usuario: ${context.userId}');
      
      final userPrograms = await _supabase
          .from('programs_opportunities')
          .select('id')
          .eq('created_by', context.userId);

      print('📊 Programas creados por el usuario: ${(userPrograms as List).length}');

      if (userPrograms.isEmpty) {
        // El usuario no ha creado ningún programa, retornar lista vacía
        print('⚠️ El usuario no ha creado ningún programa');
        return [];
      }

      final userProgramIds = (userPrograms as List).map((p) => p['id'].toString()).toSet();
      print('📋 IDs de programas del usuario: $userProgramIds');

      // Filtrar aplicaciones solo para programas creados por el usuario
      final filteredApplications = allApplications.where((app) {
        final matches = userProgramIds.contains(app.programId);
        if (matches) {
          print('✅ Aplicación ${app.id} pertenece a programa ${app.programId} del usuario');
        }
        return matches;
      }).toList();

      print('📊 Total aplicaciones filtradas: ${filteredApplications.length}');
      return filteredApplications;
    } catch (e) {
      print('❌ Error obteniendo postulaciones: $e');
      throw Exception('Error al obtener postulaciones de la institución: $e');
    }
  }

  // Obtener postulación por ID
  static Future<Application?> getApplicationById(String applicationId) async {
    try {
      final response = await _supabase
          .from('applications')
          .select('*')
          .eq('id', applicationId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Application.fromSupabase(response);
    } catch (e) {
      print('❌ Error obteniendo postulación: $e');
      throw Exception('Error al obtener postulación: $e');
    }
  }

  // Actualizar estado de postulación
  static Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? notes,
    String? rejectionReason,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos
      if (!['super_admin', 'admin_institution', 'emisor'].contains(context.userRole)) {
        throw Exception('No tienes permisos para actualizar postulaciones');
      }

      // Obtener la postulación completa primero para enviar el email
      final applicationResponse = await _supabase
          .from('applications')
          .select('*')
          .eq('id', applicationId)
          .single();

      if (applicationResponse.isEmpty) {
        throw Exception('Postulación no encontrada');
      }

      final programId = applicationResponse['program_id'] as String;

      // Si se está aprobando, verificar el límite de aplicaciones
      if (status == ApplicationStatus.approved) {
        // Obtener el programa para verificar el límite
        final program = await SupabaseProgramsService.getProgramById(programId);
        
        if (program != null) {
          // Contar cuántas aplicaciones ya están aprobadas
          final approvedCountResponse = await _supabase
              .from('applications')
              .select('id')
              .eq('program_id', programId)
              .eq('status', 'approved');
          
          final approvedCount = (approvedCountResponse as List).length;
          
          print('📊 Verificando límite de programa:');
          print('   - Aprobadas actualmente: $approvedCount');
          print('   - Límite máximo: ${program.maxApplications}');
          
          // Verificar si ya se alcanzó el límite
          if (approvedCount >= program.maxApplications) {
            throw Exception('El programa ha alcanzado su límite máximo de ${program.maxApplications} postulantes aprobados. No se pueden aprobar más aplicaciones.');
          }
        }
      }

      // Actualizar estado en Supabase
      final now = DateTime.now().toIso8601String();
      final statusString = status.toString().split('.').last; // Convertir enum a string
      
      final updates = <String, dynamic>{
        'status': statusString,
        'reviewed_at': now,
        'updated_at': now,
      };

      // Solo agregar reviewed_by si el userId es válido y existe en la tabla users
      // Para admin_institution, el userId puede ser el institutionId, así que verificamos primero
      try {
        final userId = context.userId;
        if (userId.isNotEmpty) {
          // Verificar que sea un UUID válido (formato básico)
          if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(userId)) {
            // Verificar que el userId existe en la tabla users
            // Si es admin_institution, el userId puede ser el institutionId, así que verificamos
            if (context.userRole == 'admin_institution') {
              // Para admin_institution, buscar el usuario real en la tabla users
              // o simplemente no usar reviewed_by ya que no tienen un registro en users
              print('⚠️ admin_institution: No se puede usar reviewed_by (userId es institutionId)');
              // No agregar reviewed_by para admin_institution
            } else {
              // Para otros roles, verificar que el userId existe en users
              try {
                final userCheck = await _supabase
                    .from('users')
                    .select('id')
                    .eq('id', userId)
                    .maybeSingle();
                
                if (userCheck != null) {
                  updates['reviewed_by'] = userId;
                  updates['reviewed_by_name'] = context.userName;
                  print('✅ reviewed_by asignado: $userId');
                } else {
                  print('⚠️ userId no existe en tabla users: $userId');
                  // No agregar reviewed_by si no existe en users
                }
              } catch (e) {
                print('⚠️ Error verificando userId en users: $e');
                // No agregar reviewed_by si hay error
              }
            }
          } else {
            print('⚠️ userId no es un UUID válido: $userId');
            // No agregar reviewed_by si no es válido
          }
        }
      } catch (e) {
        print('⚠️ Error validando userId: $e');
        // Continuar sin reviewed_by si hay error
      }

      if (notes != null && notes.isNotEmpty) {
        updates['notes'] = notes;
      }
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        updates['rejection_reason'] = rejectionReason;
      }

      print('📝 Actualizando postulación con: $updates');
      
      try {
        final updateResponse = await _supabase
            .from('applications')
            .update(updates)
            .eq('id', applicationId)
            .select();
        
        if (updateResponse.isEmpty) {
          throw Exception('No se pudo actualizar la postulación');
        }
        
        print('✅ Postulación actualizada exitosamente');
      } catch (e) {
        final errorMessage = e.toString();
        print('❌ Error al actualizar postulación: $errorMessage');
        
        // Verificar si es un error de foreign key
        if (errorMessage.contains('foreign key') || 
            errorMessage.contains('violates foreign key constraint') ||
            errorMessage.contains('reviewed_by')) {
          // Si el error es por reviewed_by, intentar sin ese campo
          print('⚠️ Error de foreign key en reviewed_by, intentando sin ese campo...');
          updates.remove('reviewed_by');
          updates.remove('reviewed_by_name');
          
          final updateResponse = await _supabase
              .from('applications')
              .update(updates)
              .eq('id', applicationId)
              .select();
          
          if (updateResponse.isEmpty) {
            throw Exception('No se pudo actualizar la postulación');
          }
          
          print('✅ Postulación actualizada exitosamente (sin reviewed_by)');
        } else {
          rethrow;
        }
      }

      // Enviar email de notificación al estudiante
      try {
        await _sendApplicationStatusEmail(
          studentName: applicationResponse['student_name'] ?? 'Estudiante',
          studentEmail: applicationResponse['student_email'] ?? '',
          programTitle: applicationResponse['program_title'] ?? 'Programa',
          status: status,
          rejectionReason: rejectionReason,
        );
      } catch (emailError) {
        print('⚠️ Error enviando email (no crítico): $emailError');
        // No fallar toda la operación si el email falla
      }

      print('✅ Estado de postulación actualizado: $applicationId -> ${status.displayName}');
    } catch (e) {
      throw Exception('Error al actualizar estado de postulación: $e');
    }
  }

  // Enviar email de notificación de estado de postulación
  static Future<void> _sendApplicationStatusEmail({
    required String studentName,
    required String studentEmail,
    required String programTitle,
    required ApplicationStatus status,
    String? rejectionReason,
  }) async {
    try {
      const serviceId = 'service_bdav8mg';
      const templateId = 'template_2fs5k3c';
      const userId = 'o1eUKl5D0Qq9fJ1Jv';

      String subject;
      String message;

      if (status == ApplicationStatus.approved) {
        subject = '✅ Postulación Aprobada - $programTitle';
        message = '''
Estimado/a $studentName,

¡Felicitaciones! Tu postulación al programa "$programTitle" ha sido APROBADA.

Estamos emocionados de recibirte en nuestro programa. Pronto te contactaremos con los próximos pasos y detalles adicionales.

Si tienes alguna pregunta, no dudes en contactarnos.

¡Bienvenido al equipo!

Saludos cordiales,
Equipo de CertiBlock
        ''';
      } else if (status == ApplicationStatus.rejected) {
        subject = '❌ Resultado de tu Postulación - $programTitle';
        message = '''
Estimado/a $studentName,

Lamentamos informarte que tu postulación al programa "$programTitle" no fue seleccionada en esta ocasión.

${rejectionReason != null && rejectionReason.isNotEmpty ? 'Motivo del rechazo:\n$rejectionReason\n\n' : ''}
Sabemos que esto puede ser decepcionante, pero te animamos a que sigas postulándote a otros programas que se ajusten a tu perfil.

Si tienes alguna pregunta sobre este proceso o deseas retroalimentación adicional, no dudes en contactarnos.

Gracias por tu interés y te deseamos el mejor de los éxitos en tus futuras postulaciones.

Saludos cordiales,
Equipo de CertiBlock
        ''';
      } else if (status == ApplicationStatus.under_review) {
        subject = '📋 Postulación en Revisión - $programTitle';
        message = '''
Estimado/a $studentName,

Esta es una confirmación de que hemos recibido tu postulación al programa "$programTitle" y actualmente se encuentra en proceso de revisión.

Nuestro equipo está evaluando cuidadosamente tu solicitud. Te notificaremos tan pronto como tengamos un resultado.

Mientras tanto, si tienes alguna pregunta, no dudes en contactarnos.

Saludos cordiales,
Equipo de CertiBlock
        ''';
      } else {
        // Para otros estados, no enviar email
        return;
      }

      // Enviar email usando EmailJS
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
          'to_email': studentEmail,
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
        print('✅ Email enviado exitos hacia: $studentEmail');
      } else {
        throw Exception('Error enviando email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error enviando email de notificación: $e');
      rethrow;
    }
  }

  // Retirar postulación
  static Future<void> withdrawApplication(String applicationId) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener la postulación
      final application = await getApplicationById(applicationId);
      if (application == null) {
        throw Exception('Postulación no encontrada');
      }

      // Verificar que el usuario sea el dueño de la postulación
      if (application.studentId != context.userId) {
        throw Exception('No tienes permisos para retirar esta postulación');
      }

      // Verificar que se puede retirar
      if (!application.canBeWithdrawn) {
        throw Exception('Esta postulación no puede ser retirada. Solo puedes retirar postulaciones pendientes o en revisión.');
      }

      // Actualizar estado en Supabase
      final now = DateTime.now().toIso8601String();
      await _supabase
          .from('applications')
          .update({
            'status': 'withdrawn',
            'updated_at': now,
          })
          .eq('id', applicationId);

      // Decrementar contador de aplicaciones del programa en Supabase
      try {
        final program = await SupabaseProgramsService.getProgramById(application.programId);
        if (program != null && program.currentApplications > 0) {
          await SupabaseProgramsService.updateProgram(application.programId, {
            'current_applications': program.currentApplications - 1,
          });
        }
      } catch (e) {
        print('⚠️ Error decrementando contador de aplicaciones: $e');
        // No fallar si hay error decrementando el contador
      }

      print('✅ Postulación retirada: $applicationId');
    } catch (e) {
      print('❌ Error retirando postulación: $e');
      throw Exception('Error al retirar postulación: $e');
    }
  }

  // Obtener estadísticas de postulaciones
  static Future<Map<String, int>> getApplicationStats() async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      Query query = _firestore.collection(_collection);

      // Si no es super admin, filtrar por institución
      if (!context.isSuperAdmin) {
        final institutionId = context.institutionId;
        if (institutionId != null) {
          query = query.where('institutionId', isEqualTo: institutionId);
        }
      }

      final querySnapshot = await query.get();

      int total = querySnapshot.docs.length;
      int pending = 0;
      int underReview = 0;
      int approved = 0;
      int rejected = 0;
      int withdrawn = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'under_review':
            underReview++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'withdrawn':
            withdrawn++;
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'under_review': underReview,
        'approved': approved,
        'rejected': rejected,
        'withdrawn': withdrawn,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de postulaciones: $e');
    }
  }

  // Obtener certificados disponibles para un estudiante
  static Future<List<Map<String, dynamic>>> getStudentCertificates() async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener certificados del estudiante usando Supabase
      final certificates = await SupabaseCertificateService.getCertificatesByStudent(context.userId);

      // Filtrar solo certificados activos
      final activeCertificates = certificates.where((cert) => cert.status == 'active').toList();

      return activeCertificates.map((cert) => {
        'id': cert.id,
        'title': cert.title,
        'type': cert.certificateType,
        'issuedAt': cert.issuedAt.toIso8601String(),
        'institutionName': cert.institutionName,
        'description': cert.description,
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener certificados del estudiante: $e');
    }
  }
}
