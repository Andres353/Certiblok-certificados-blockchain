// lib/services/adapters/careers_adapter.dart
// Adapter para gestionar carreras entre Firebase y Supabase

import 'package:cloud_firestore/cloud_firestore.dart';
import '../supabase/supabase_careers_service.dart';

class CareersAdapter {
  static bool _useSupabase = true; // Cambiar a false para usar Firebase

  // Obtener programas de una institución
  static Future<List<Map<String, dynamic>>> getProgramsByInstitution(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseCareersService.getProgramsByInstitution(institutionId);
    } else {
      return await _getProgramsFromFirebase(institutionId);
    }
  }

  // Obtener facultades de una institución
  static Future<List<Map<String, dynamic>>> getFacultiesByInstitution(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseCareersService.getFacultiesByInstitution(institutionId);
    } else {
      return await _getFacultiesFromFirebase(institutionId);
    }
  }

  // Crear programa
  static Future<Map<String, dynamic>> createProgram({
    required String name,
    required String code,
    String? facultyId,
    required String facultyName,
    required String institutionId,
    required String institutionName,
    int duration = 10,
    String modality = 'presencial',
    String? description,
  }) async {
    if (_useSupabase) {
      return await SupabaseCareersService.createProgram(
        name: name,
        code: code,
        facultyId: facultyId,
        facultyName: facultyName,
        institutionId: institutionId,
        institutionName: institutionName,
        duration: duration,
        modality: modality,
        description: description,
      );
    } else {
      return await _createProgramInFirebase(
        name: name,
        code: code,
        facultyId: facultyId,
        facultyName: facultyName,
        institutionId: institutionId,
        institutionName: institutionName,
        duration: duration,
        modality: modality,
        description: description,
      );
    }
  }

  // Actualizar programa
  static Future<Map<String, dynamic>> updateProgram({
    required String programId,
    required String name,
    required String code,
    required String facultyId,
    required String facultyName,
    int? duration,
    String? modality,
    String? description,
  }) async {
    if (_useSupabase) {
      return await SupabaseCareersService.updateProgram(
        programId: programId,
        name: name,
        code: code,
        facultyId: facultyId,
        facultyName: facultyName,
        duration: duration,
        modality: modality,
        description: description,
      );
    } else {
      return await _updateProgramInFirebase(
        programId: programId,
        name: name,
        code: code,
        facultyId: facultyId,
        facultyName: facultyName,
        duration: duration,
        modality: modality,
        description: description,
      );
    }
  }

  // Eliminar programa
  static Future<bool> deleteProgram(String programId) async {
    if (_useSupabase) {
      return await SupabaseCareersService.deleteProgram(programId);
    } else {
      return await _deleteProgramFromFirebase(programId);
    }
  }

  // Crear facultad
  static Future<Map<String, dynamic>> createFaculty({
    required String name,
    required String code,
    required String institutionId,
    required String institutionName,
    String? description,
  }) async {
    if (_useSupabase) {
      return await SupabaseCareersService.createFaculty(
        name: name,
        code: code,
        institutionId: institutionId,
        institutionName: institutionName,
        description: description,
      );
    } else {
      return await _createFacultyInFirebase(
        name: name,
        code: code,
        institutionId: institutionId,
        institutionName: institutionName,
        description: description,
      );
    }
  }

  // Actualizar facultad
  static Future<Map<String, dynamic>> updateFaculty({
    required String facultyId,
    required String name,
    required String code,
    String? description,
  }) async {
    if (_useSupabase) {
      return await SupabaseCareersService.updateFaculty(
        facultyId: facultyId,
        name: name,
        code: code,
        description: description,
      );
    } else {
      return await _updateFacultyInFirebase(
        facultyId: facultyId,
        name: name,
        code: code,
        description: description,
      );
    }
  }

  // Eliminar facultad
  static Future<bool> deleteFaculty(String facultyId) async {
    if (_useSupabase) {
      return await SupabaseCareersService.deleteFaculty(facultyId);
    } else {
      return await _deleteFacultyFromFirebase(facultyId);
    }
  }

  // Obtener estadísticas de carreras
  static Future<Map<String, int>> getCareersStats(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseCareersService.getCareersStats(institutionId);
    } else {
      return await _getCareersStatsFromFirebase(institutionId);
    }
  }

  // Generar código único para programa
  static Future<String> generateUniqueProgramCode(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseCareersService.generateUniqueProgramCode(institutionId);
    } else {
      return await _generateUniqueProgramCodeFromFirebase(institutionId);
    }
  }

  // Generar código único para facultad
  static Future<String> generateUniqueFacultyCode(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseCareersService.generateUniqueFacultyCode(institutionId);
    } else {
      return await _generateUniqueFacultyCodeFromFirebase(institutionId);
    }
  }

  // ========== MÉTODOS FIREBASE (FALLBACK) ==========

  static Future<List<Map<String, dynamic>>> _getProgramsFromFirebase(String institutionId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('programs')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } catch (e) {
      print('Error obteniendo programas de Firebase: $e');
      throw Exception('Error obteniendo programas: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _getFacultiesFromFirebase(String institutionId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('faculties')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } catch (e) {
      print('Error obteniendo facultades de Firebase: $e');
      throw Exception('Error obteniendo facultades: $e');
    }
  }

  static Future<Map<String, dynamic>> _createProgramInFirebase({
    required String name,
    required String code,
    String? facultyId,
    required String facultyName,
    required String institutionId,
    required String institutionName,
    int duration = 10,
    String modality = 'presencial',
    String? description,
  }) async {
    try {
      final programData = {
        'name': name,
        'code': code,
        'facultyId': facultyId,
        'facultyName': facultyName,
        'institutionId': institutionId,
        'institutionName': institutionName,
        'duration': duration,
        'modality': modality,
        'description': description,
        'status': 'active',
        'isGlobal': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('programs')
          .add(programData);

      return {
        'success': true,
        'program': {'id': docRef.id, ...programData},
      };
    } catch (e) {
      print('Error creando programa en Firebase: $e');
      throw Exception('Error creando programa: $e');
    }
  }

  static Future<Map<String, dynamic>> _updateProgramInFirebase({
    required String programId,
    required String name,
    required String code,
    required String facultyId,
    required String facultyName,
    int? duration,
    String? modality,
    String? description,
  }) async {
    try {
      final updateData = {
        'name': name,
        'code': code,
        'facultyId': facultyId,
        'facultyName': facultyName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (duration != null) updateData['duration'] = duration;
      if (modality != null) updateData['modality'] = modality;
      if (description != null) updateData['description'] = description;

      await FirebaseFirestore.instance
          .collection('programs')
          .doc(programId)
          .update(updateData);

      return {
        'success': true,
        'program': {'id': programId, ...updateData},
      };
    } catch (e) {
      print('Error actualizando programa en Firebase: $e');
      throw Exception('Error actualizando programa: $e');
    }
  }

  static Future<bool> _deleteProgramFromFirebase(String programId) async {
    try {
      await FirebaseFirestore.instance
          .collection('programs')
          .doc(programId)
          .update({
            'status': 'inactive',
            'deletedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('Error eliminando programa de Firebase: $e');
      throw Exception('Error eliminando programa: $e');
    }
  }

  static Future<Map<String, dynamic>> _createFacultyInFirebase({
    required String name,
    required String code,
    required String institutionId,
    required String institutionName,
    String? description,
  }) async {
    try {
      final facultyData = {
        'name': name,
        'code': code,
        'institutionId': institutionId,
        'institutionName': institutionName,
        'description': description,
        'status': 'active',
        'programsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('faculties')
          .add(facultyData);

      return {
        'success': true,
        'faculty': {'id': docRef.id, ...facultyData},
      };
    } catch (e) {
      print('Error creando facultad en Firebase: $e');
      throw Exception('Error creando facultad: $e');
    }
  }

  static Future<Map<String, dynamic>> _updateFacultyInFirebase({
    required String facultyId,
    required String name,
    required String code,
    String? description,
  }) async {
    try {
      final updateData = {
        'name': name,
        'code': code,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (description != null) updateData['description'] = description;

      await FirebaseFirestore.instance
          .collection('faculties')
          .doc(facultyId)
          .update(updateData);

      return {
        'success': true,
        'faculty': {'id': facultyId, ...updateData},
      };
    } catch (e) {
      print('Error actualizando facultad en Firebase: $e');
      throw Exception('Error actualizando facultad: $e');
    }
  }

  static Future<bool> _deleteFacultyFromFirebase(String facultyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('faculties')
          .doc(facultyId)
          .update({
            'status': 'inactive',
            'deletedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('Error eliminando facultad de Firebase: $e');
      throw Exception('Error eliminando facultad: $e');
    }
  }

  static Future<Map<String, int>> _getCareersStatsFromFirebase(String institutionId) async {
    try {
      final programsSnapshot = await FirebaseFirestore.instance
          .collection('programs')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      final facultiesSnapshot = await FirebaseFirestore.instance
          .collection('faculties')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      int totalPrograms = programsSnapshot.docs.length;
      int activePrograms = programsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      int totalFaculties = facultiesSnapshot.docs.length;
      int activeFaculties = facultiesSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;

      return {
        'total_programs': totalPrograms,
        'active_programs': activePrograms,
        'total_faculties': totalFaculties,
        'active_faculties': activeFaculties,
      };
    } catch (e) {
      print('Error obteniendo estadísticas de carreras de Firebase: $e');
      return {
        'total_programs': 0,
        'active_programs': 0,
        'total_faculties': 0,
        'active_faculties': 0,
      };
    }
  }

  static Future<String> _generateUniqueProgramCodeFromFirebase(String institutionId) async {
    String baseCode = 'PROG';
    int counter = 1;
    
    while (true) {
      String code = '$baseCode${counter.toString().padLeft(3, '0')}';
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('programs')
          .where('code', isEqualTo: code)
          .where('institutionId', isEqualTo: institutionId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return code;
      }
      counter++;
    }
  }

  static Future<String> _generateUniqueFacultyCodeFromFirebase(String institutionId) async {
    String baseCode = 'FAC';
    int counter = 1;
    
    while (true) {
      String code = '$baseCode${counter.toString().padLeft(3, '0')}';
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('faculties')
          .where('code', isEqualTo: code)
          .where('institutionId', isEqualTo: institutionId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return code;
      }
      counter++;
    }
  }
}
