// lib/services/application_service.dart
// Servicio para gestionar postulaciones a programas

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/application.dart';
import 'user_context_service.dart';
import 'programs_opportunities_service.dart';
import 'certificate_service.dart';

class ApplicationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'applications';

  // Crear nueva postulación
  static Future<String> createApplication({
    required String programId,
    required String cvFilePath,
    required String cvFileName,
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

      // Obtener información del programa
      final program = await ProgramsOpportunitiesService.getProgramById(programId);
      if (program == null) {
        throw Exception('Programa no encontrado');
      }

      // Verificar que el estudiante puede postularse
      final canApply = await ProgramsOpportunitiesService.canStudentApply(programId, context.userId);
      if (!canApply) {
        throw Exception('No puedes postularte a este programa');
      }

      // Subir CV a Firebase Storage
      final cvUrl = await _uploadCV(cvFilePath, context.userId, cvFileName);

      // Obtener detalles de los certificados seleccionados
      final certificateDetails = await _getCertificateDetails(selectedCertificates);

      final now = DateTime.now();
      final docRef = await _firestore.collection(_collection).add({
        'studentId': context.userId,
        'studentName': context.userName,
        'studentEmail': context.userEmail,
        'programId': programId,
        'programTitle': program.title,
        'institutionId': program.institutionId,
        'institutionName': program.institutionName,
        'status': 'pending',
        'cvUrl': cvUrl,
        'cvFileName': cvFileName,
        'selectedCertificates': selectedCertificates,
        'certificateDetails': certificateDetails,
        'motivationLetter': motivationLetter,
        'motivationPdfData': motivationPdfData,
        'motivationPdfFileName': motivationPdfFileName,
        'additionalDocuments': additionalDocuments ?? {},
        'submittedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Incrementar contador de aplicaciones del programa
      await ProgramsOpportunitiesService.incrementApplicationCount(programId);

      print('✅ Postulación creada exitosamente: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear postulación: $e');
    }
  }

  // Subir CV a Firebase Storage
  static Future<String> _uploadCV(String filePath, String studentId, String fileName) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('applications/cv/$studentId/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir CV: $e');
    }
  }

  // Obtener detalles de certificados seleccionados
  static Future<List<Map<String, dynamic>>> _getCertificateDetails(List<String> certificateIds) async {
    try {
      final details = <Map<String, dynamic>>[];
      
      for (String certId in certificateIds) {
        try {
          final certificate = await CertificateService.getCertificateById(certId);
          if (certificate != null) {
            details.add({
              'id': certificate.id,
              'title': certificate.title,
              'type': certificate.certificateType,
              'issuedAt': certificate.issuedAt.toIso8601String(),
              'institutionName': certificate.institutionName,
            });
          }
        } catch (e) {
          print('Error obteniendo certificado $certId: $e');
        }
      }
      
      return details;
    } catch (e) {
      print('Error obteniendo detalles de certificados: $e');
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

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: context.userId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Application.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
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

      Query query = _firestore.collection(_collection);

      // Si no es super admin, filtrar por institución
      if (!context.isSuperAdmin) {
        final institutionId = context.institutionId;
        if (institutionId != null) {
          query = query.where('institutionId', isEqualTo: institutionId);
        }
      }

      // Aplicar filtros adicionales
      if (programId != null) {
        query = query.where('programId', isEqualTo: programId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Application.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener postulaciones de la institución: $e');
    }
  }

  // Obtener postulación por ID
  static Future<Application?> getApplicationById(String applicationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(applicationId).get();
      if (doc.exists) {
        return Application.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
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

      final now = DateTime.now();
      final updates = {
        'status': status.toString(),
        'reviewedBy': context.userId,
        'reviewedByName': context.userName,
        'reviewedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      if (notes != null) {
        updates['notes'] = notes;
      }
      if (rejectionReason != null) {
        updates['rejectionReason'] = rejectionReason;
      }

      await _firestore.collection(_collection).doc(applicationId).update(updates);

      print('✅ Estado de postulación actualizado: $applicationId -> ${status.displayName}');
    } catch (e) {
      throw Exception('Error al actualizar estado de postulación: $e');
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
        throw Exception('Esta postulación no puede ser retirada');
      }

      await _firestore.collection(_collection).doc(applicationId).update({
        'status': 'withdrawn',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Decrementar contador de aplicaciones del programa
      await ProgramsOpportunitiesService.decrementApplicationCount(application.programId);

      print('✅ Postulación retirada: $applicationId');
    } catch (e) {
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

      // Obtener certificados del estudiante
      final certificates = await CertificateService.getCertificates(
        studentId: context.userId,
        status: 'active',
      );

      return certificates.map((cert) => {
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
