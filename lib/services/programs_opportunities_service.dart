// lib/services/programs_opportunities_service.dart
// Servicio para gestionar oportunidades de programas y pasantías

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program_opportunity.dart';
import 'user_context_service.dart';

class ProgramsOpportunitiesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'programs_opportunities';

  // Obtener todas las oportunidades disponibles para un estudiante
  static Future<List<ProgramOpportunity>> getAvailablePrograms({
    String? institutionId,
    String? facultyId,
    String? careerId,
  }) async {
    try {
      print('🔄 Iniciando carga de programas...');
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      print('👤 Usuario: ${context.userRole}, Institución: ${context.institutionId}');

      Query query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      // Si no es super admin, filtrar por institución
      if (!context.isSuperAdmin) {
        final targetInstitutionId = institutionId ?? context.institutionId;
        if (targetInstitutionId != null) {
          query = query.where('institutionId', isEqualTo: targetInstitutionId);
          print('🏢 Filtrando por institución: $targetInstitutionId');
        }
      }

      // Aplicar filtros adicionales
      if (facultyId != null) {
        query = query.where('facultyId', isEqualTo: facultyId);
        print('🎓 Filtrando por facultad: $facultyId');
      }
      if (careerId != null) {
        query = query.where('careerId', isEqualTo: careerId);
        print('📚 Filtrando por carrera: $careerId');
      }

      print('🔍 Ejecutando consulta...');
      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      print('📊 Documentos encontrados: ${querySnapshot.docs.length}');

      final programs = <ProgramOpportunity>[];
      for (var doc in querySnapshot.docs) {
        try {
          print('📄 Procesando documento: ${doc.id}');
          final program = ProgramOpportunity.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          programs.add(program);
          print('✅ Programa procesado: ${program.title}');
        } catch (e) {
          print('❌ Error procesando documento ${doc.id}: $e');
          print('📋 Datos del documento: ${doc.data()}');
        }
      }

      print('🎯 Total de programas cargados: ${programs.length}');
      return programs;
    } catch (e) {
      print('❌ Error en getAvailablePrograms: $e');
      throw Exception('Error al obtener programas disponibles: $e');
    }
  }

  // Método de debugging para cargar todos los programas
  static Future<List<ProgramOpportunity>> getAllProgramsForDebug() async {
    try {
      print('🔍 [DEBUG] Cargando todos los programas...');
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      print('📊 [DEBUG] Total documentos en colección: ${querySnapshot.docs.length}');

      final programs = <ProgramOpportunity>[];
      for (var doc in querySnapshot.docs) {
        try {
          print('📄 [DEBUG] Procesando: ${doc.id}');
          print('📋 [DEBUG] Datos: ${doc.data()}');
          final program = ProgramOpportunity.fromFirestore(doc.data(), doc.id);
          programs.add(program);
        } catch (e) {
          print('❌ [DEBUG] Error en ${doc.id}: $e');
        }
      }

      return programs;
    } catch (e) {
      print('❌ [DEBUG] Error general: $e');
      return [];
    }
  }

  // Obtener programa por ID
  static Future<ProgramOpportunity?> getProgramById(String programId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(programId).get();
      if (doc.exists) {
        return ProgramOpportunity.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener programa: $e');
    }
  }

  // Crear nueva oportunidad de programa
  static Future<String> createProgramOpportunity({
    required String title,
    required String description,
    required String institutionId,
    required String institutionName,
    required String facultyId,
    required String facultyName,
    required List<String> careerIds,
    required List<String> careerNames,
    required List<String> requirements,
    required DateTime applicationDeadline,
    required int maxApplications,
    required String createdBy,
    required String createdByName,
    Map<String, dynamic>? additionalInfo,
    String? imageUrl,
    String? pdfUrl,
    String? pdfFileName,
    String? pdfData,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos
      if (!['super_admin', 'admin_institution'].contains(context.userRole)) {
        throw Exception('No tienes permisos para crear programas');
      }

      // Todos los PDFs se almacenan como base64 en Firestore
      print('📄 PDF almacenado como base64 en Firestore');

      final now = DateTime.now();
      final docRef = await _firestore.collection(_collection).add({
        'title': title,
        'description': description,
        'institutionId': institutionId,
        'institutionName': institutionName,
        'facultyId': facultyId,
        'facultyName': facultyName,
        'careerIds': careerIds,
        'careerNames': careerNames,
        'requirements': requirements,
        'isActive': true,
        'applicationDeadline': Timestamp.fromDate(applicationDeadline),
        'maxApplications': maxApplications,
        'currentApplications': 0,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'additionalInfo': additionalInfo ?? {},
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
        'pdfFileName': pdfFileName,
        'pdfData': pdfData,
      });

      print('✅ Programa creado exitosamente: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creando programa: $e');
      throw Exception('Error al crear programa: $e');
    }
  }

  // Actualizar programa
  static Future<void> updateProgram(String programId, Map<String, dynamic> updates) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos
      if (!['super_admin', 'admin_institution'].contains(context.userRole)) {
        throw Exception('No tienes permisos para actualizar programas');
      }

      await _firestore.collection(_collection).doc(programId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Programa actualizado: $programId');
    } catch (e) {
      throw Exception('Error al actualizar programa: $e');
    }
  }

  // Cambiar estado del programa
  static Future<void> toggleProgramStatus(String programId, bool isActive) async {
    try {
      await updateProgram(programId, {'isActive': isActive});
    } catch (e) {
      throw Exception('Error al cambiar estado del programa: $e');
    }
  }

  // Incrementar contador de aplicaciones
  static Future<void> incrementApplicationCount(String programId) async {
    try {
      await _firestore.collection(_collection).doc(programId).update({
        'currentApplications': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementando contador de aplicaciones: $e');
    }
  }

  // Decrementar contador de aplicaciones
  static Future<void> decrementApplicationCount(String programId) async {
    try {
      await _firestore.collection(_collection).doc(programId).update({
        'currentApplications': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error decrementando contador de aplicaciones: $e');
    }
  }

  // Obtener programas de una institución específica
  static Future<List<ProgramOpportunity>> getInstitutionPrograms(String institutionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('institutionId', isEqualTo: institutionId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProgramOpportunity.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener programas de la institución: $e');
    }
  }

  // Buscar programas por título
  static Future<List<ProgramOpportunity>> searchPrograms(String query) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      Query firestoreQuery = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      // Si no es super admin, filtrar por institución
      if (!context.isSuperAdmin) {
        final institutionId = context.institutionId;
        if (institutionId != null) {
          firestoreQuery = firestoreQuery.where('institutionId', isEqualTo: institutionId);
        }
      }

      final querySnapshot = await firestoreQuery.get();

      // Filtrar por título en memoria (Firestore no soporta búsqueda de texto completo)
      final allPrograms = querySnapshot.docs
          .map((doc) => ProgramOpportunity.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return allPrograms
          .where((program) =>
              program.title.toLowerCase().contains(query.toLowerCase()) ||
              program.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar programas: $e');
    }
  }

  // Obtener estadísticas de programas
  static Future<Map<String, int>> getProgramStats() async {
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
      int active = 0;
      int inactive = 0;
      int open = 0;
      int closed = 0;

      for (var doc in querySnapshot.docs) {
        final program = ProgramOpportunity.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        
        if (program.isActive) {
          active++;
          if (program.isOpenForApplications) {
            open++;
          } else {
            closed++;
          }
        } else {
          inactive++;
        }
      }

      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        'open': open,
        'closed': closed,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Verificar si un estudiante puede postularse a un programa
  static Future<bool> canStudentApply(String programId, String studentId) async {
    try {
      // Obtener el programa
      final program = await getProgramById(programId);
      if (program == null) return false;

      // Verificar que el programa esté abierto
      if (!program.isOpenForApplications) return false;

      // NOTA: No verificamos cupos aquí porque los cupos solo se validan al APROBAR postulaciones
      // Los estudiantes pueden postularse ilimitadamente, pero solo se pueden aprobar hasta maxApplications

      // Verificar que el estudiante no haya postulado previamente
      final applicationQuery = await _firestore
          .collection('applications')
          .where('studentId', isEqualTo: studentId)
          .where('programId', isEqualTo: programId)
          .where('status', whereIn: ['pending', 'under_review', 'approved'])
          .limit(1)
          .get();

      return applicationQuery.docs.isEmpty;
    } catch (e) {
      print('Error verificando si puede postularse: $e');
      return false;
    }
  }

  // Obtener programas por institución
  static Future<List<ProgramOpportunity>> getProgramsByInstitution(String institutionId) async {
    try {
      print('🔄 Obteniendo programas por institución: $institutionId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('institutionId', isEqualTo: institutionId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProgramOpportunity.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo programas por institución: $e');
      return [];
    }
  }

  // Eliminar programa
  static Future<void> deleteProgram(String programId) async {
    try {
      print('🔄 Eliminando programa: $programId');
      
      await _firestore
          .collection(_collection)
          .doc(programId)
          .delete();

      print('✅ Programa eliminado');
    } catch (e) {
      print('❌ Error eliminando programa: $e');
      throw Exception('Error eliminando programa: $e');
    }
  }
}
