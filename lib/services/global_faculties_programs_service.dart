// lib/services/global_faculties_programs_service.dart
// Servicio para obtener todas las facultades y programas disponibles del sistema

import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalFacultiesProgramsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las facultades activas del sistema
  static Future<List<Map<String, dynamic>>> getAllFaculties() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('faculties')
          .where('status', isEqualTo: 'active')
          .get();

      final faculties = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'code': data['code'] ?? '',
              'description': data['description'] ?? '',
              'institutionId': data['institutionId'] ?? '',
              'institutionName': data['institutionName'] ?? '',
              'programsCount': data['programsCount'] ?? 0,
              'status': data['status'] ?? 'active',
            };
          })
          .toList();
      
      // Ordenar localmente
      faculties.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return faculties;
    } catch (e) {
      print('Error obteniendo facultades globales: $e');
      return [];
    }
  }

  // Obtener todos los programas activos del sistema
  static Future<List<Map<String, dynamic>>> getAllPrograms() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('programs')
          .where('status', isEqualTo: 'active')
          .get();

      final programs = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'code': data['code'] ?? '',
              'careerCode': data['careerCode'] ?? data['code'] ?? '',
              'duration': data['duration'] ?? 10,
              'modality': data['modality'] ?? 'presencial',
              'description': data['description'] ?? '',
              'facultyId': data['facultyId'] ?? '',
              'facultyName': data['facultyName'] ?? '',
              'facultyCode': data['facultyCode'] ?? '',
              'institutionId': data['institutionId'] ?? '',
              'institutionName': data['institutionName'] ?? '',
              'status': data['status'] ?? 'active',
            };
          })
          .toList();
      
      // Ordenar localmente
      programs.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return programs;
    } catch (e) {
      print('Error obteniendo programas globales: $e');
      return [];
    }
  }

  // Obtener facultades que no pertenecen a la institución actual
  static Future<List<Map<String, dynamic>>> getAvailableFacultiesForInstitution(String institutionId) async {
    try {
      print('Obteniendo facultades disponibles para institución: $institutionId');
      // Obtener todas las facultades activas
      final allFaculties = await getAllFaculties();
      print('Total de facultades encontradas: ${allFaculties.length}');
      
      // Filtrar las que no pertenecen a la institución actual
      final availableFaculties = allFaculties.where((faculty) => 
        faculty['institutionId'] != institutionId
      ).toList();
      
      print('Facultades disponibles: ${availableFaculties.length}');
      return availableFaculties;
    } catch (e) {
      print('Error obteniendo facultades disponibles: $e');
      return [];
    }
  }

  // Obtener programas que no pertenecen a la institución actual
  static Future<List<Map<String, dynamic>>> getAvailableProgramsForInstitution(String institutionId) async {
    try {
      print('Obteniendo programas disponibles para institución: $institutionId');
      // Obtener todos los programas activos
      final allPrograms = await getAllPrograms();
      print('Total de programas encontrados: ${allPrograms.length}');
      
      // Filtrar los que no pertenecen a la institución actual
      final availablePrograms = allPrograms.where((program) => 
        program['institutionId'] != institutionId
      ).toList();
      
      print('Programas disponibles: ${availablePrograms.length}');
      return availablePrograms;
    } catch (e) {
      print('Error obteniendo programas disponibles: $e');
      return [];
    }
  }

  // Agregar facultad existente a una institución
  static Future<Map<String, dynamic>> addExistingFacultyToInstitution({
    required String facultyId,
    required String targetInstitutionId,
    required String targetInstitutionName,
  }) async {
    try {
      // Obtener datos de la facultad original
      DocumentSnapshot facultyDoc = await _firestore
          .collection('faculties')
          .doc(facultyId)
          .get();

      if (!facultyDoc.exists) {
        return {'success': false, 'message': 'Facultad no encontrada'};
      }

      final facultyData = facultyDoc.data() as Map<String, dynamic>;
      
      // Crear nueva facultad para la institución destino
      DocumentReference newFacultyRef = await _firestore.collection('faculties').add({
        'name': facultyData['name'],
        'code': facultyData['code'],
        'description': facultyData['description'] ?? '',
        'status': 'active',
        'programsCount': 0,
        'institutionId': targetInstitutionId,
        'institutionName': targetInstitutionName,
        'originalFacultyId': facultyId, // Referencia a la facultad original
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': 'admin', // Se puede personalizar según el contexto
      });

      return {
        'success': true,
        'message': 'Facultad agregada exitosamente',
        'newFacultyId': newFacultyRef.id,
      };
    } catch (e) {
      print('Error agregando facultad existente: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Agregar programa existente a una institución
  static Future<Map<String, dynamic>> addExistingProgramToInstitution({
    required String programId,
    required String targetInstitutionId,
    required String targetInstitutionName,
    required String targetFacultyId,
    required String targetFacultyName,
  }) async {
    try {
      // Obtener datos del programa original
      DocumentSnapshot programDoc = await _firestore
          .collection('programs')
          .doc(programId)
          .get();

      if (!programDoc.exists) {
        return {'success': false, 'message': 'Programa no encontrado'};
      }

      final programData = programDoc.data() as Map<String, dynamic>;
      
      // Generar nuevo código de carrera para la institución destino
      final institutionShortName = targetInstitutionName.split(' ').map((word) => word[0]).join('').toUpperCase();
      final newCareerCode = '${institutionShortName.substring(0, 3)}-${programData['name'].split(' ').map((word) => word[0]).join('').toUpperCase()}';
      
      // Crear nuevo programa para la institución destino
      DocumentReference newProgramRef = await _firestore.collection('programs').add({
        'name': programData['name'],
        'code': newCareerCode,
        'careerCode': newCareerCode,
        'duration': programData['duration'] ?? 10,
        'modality': programData['modality'] ?? 'presencial',
        'description': programData['description'] ?? '',
        'status': 'active',
        'facultyId': targetFacultyId,
        'facultyName': targetFacultyName,
        'facultyCode': programData['facultyCode'],
        'institutionId': targetInstitutionId,
        'institutionName': targetInstitutionName,
        'originalProgramId': programId, // Referencia al programa original
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': 'admin', // Se puede personalizar según el contexto
      });

      // Actualizar contador de programas en la facultad destino
      await _firestore.collection('faculties').doc(targetFacultyId).update({
        'programsCount': FieldValue.increment(1),
      });

      return {
        'success': true,
        'message': 'Programa agregado exitosamente',
        'newProgramId': newProgramRef.id,
        'newCareerCode': newCareerCode,
      };
    } catch (e) {
      print('Error agregando programa existente: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Buscar facultades por nombre
  static Future<List<Map<String, dynamic>>> searchFaculties(String query) async {
    try {
      final allFaculties = await getAllFaculties();
      return allFaculties.where((faculty) =>
        faculty['name'].toLowerCase().contains(query.toLowerCase()) ||
        faculty['code'].toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      print('Error buscando facultades: $e');
      return [];
    }
  }

  // Buscar programas por nombre
  static Future<List<Map<String, dynamic>>> searchPrograms(String query) async {
    try {
      final allPrograms = await getAllPrograms();
      return allPrograms.where((program) =>
        program['name'].toLowerCase().contains(query.toLowerCase()) ||
        program['code'].toLowerCase().contains(query.toLowerCase()) ||
        program['careerCode'].toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      print('Error buscando programas: $e');
      return [];
    }
  }
}
