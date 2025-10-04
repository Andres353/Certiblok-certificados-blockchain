import 'package:cloud_firestore/cloud_firestore.dart';
import 'institution_service.dart';

class CareerCodeGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generar códigos de carrera para todos los programas existentes que no tienen código
  static Future<void> generateCodesForExistingPrograms() async {
    try {
      print('Iniciando generación de códigos de carrera para programas existentes...');

      // Obtener todos los programas que no tienen careerCode
      final programsSnapshot = await _firestore
          .collection('programs')
          .where('careerCode', isNull: true)
          .get();

      print('Encontrados ${programsSnapshot.docs.length} programas sin código de carrera');

      for (final doc in programsSnapshot.docs) {
        final programData = doc.data();
        final programId = doc.id;
        
        // Obtener información de la institución
        final institutionId = programData['institutionId'];
        final institutionDoc = await _firestore
            .collection('institutions')
            .doc(institutionId)
            .get();
        
        if (institutionDoc.exists) {
          final institutionData = institutionDoc.data()!;
          final institutionShortName = institutionData['shortName'] ?? 'INST';
          final programName = programData['name'];
          
          // Generar código de carrera
          final careerCode = await InstitutionService.generateCareerCode(
            institutionShortName,
            programName,
          );
          
          // Actualizar el programa con el código de carrera
          await _firestore.collection('programs').doc(programId).update({
            'careerCode': careerCode,
          });
          
          print('Código generado para ${programName}: $careerCode');
        }
      }

      print('Generación de códigos completada exitosamente');
    } catch (e) {
      print('Error generando códigos de carrera: $e');
      throw Exception('Error generando códigos de carrera: $e');
    }
  }

  // Generar códigos de carrera para una institución específica
  static Future<void> generateCodesForInstitution(String institutionId) async {
    try {
      print('Generando códigos de carrera para institución: $institutionId');

      // Obtener información de la institución
      final institutionDoc = await _firestore
          .collection('institutions')
          .doc(institutionId)
          .get();
      
      if (!institutionDoc.exists) {
        throw Exception('Institución no encontrada');
      }

      final institutionData = institutionDoc.data()!;
      final institutionShortName = institutionData['shortName'] ?? 'INST';

      // Obtener todos los programas de la institución que no tienen código
      final programsSnapshot = await _firestore
          .collection('programs')
          .where('institutionId', isEqualTo: institutionId)
          .where('careerCode', isNull: true)
          .get();

      print('Encontrados ${programsSnapshot.docs.length} programas sin código en ${institutionData['name']}');

      for (final doc in programsSnapshot.docs) {
        final programData = doc.data();
        final programId = doc.id;
        final programName = programData['name'];
        
        // Generar código de carrera
        final careerCode = await InstitutionService.generateCareerCode(
          institutionShortName,
          programName,
        );
        
        // Actualizar el programa con el código de carrera
        await _firestore.collection('programs').doc(programId).update({
          'careerCode': careerCode,
        });
        
        print('Código generado para ${programName}: $careerCode');
      }

      print('Generación de códigos completada para ${institutionData['name']}');
    } catch (e) {
      print('Error generando códigos de carrera para institución: $e');
      throw Exception('Error generando códigos de carrera: $e');
    }
  }

  // Verificar cuántos programas necesitan códigos
  static Future<Map<String, dynamic>> getProgramsNeedingCodes() async {
    try {
      final programsSnapshot = await _firestore
          .collection('programs')
          .where('careerCode', isNull: true)
          .get();

      final totalPrograms = programsSnapshot.docs.length;
      final programsByInstitution = <String, int>{};

      for (final doc in programsSnapshot.docs) {
        final institutionId = doc.data()['institutionId'] as String;
        programsByInstitution[institutionId] = (programsByInstitution[institutionId] ?? 0) + 1;
      }

      return {
        'total': totalPrograms,
        'byInstitution': programsByInstitution,
      };
    } catch (e) {
      print('Error obteniendo programas que necesitan códigos: $e');
      return {'total': 0, 'byInstitution': <String, int>{}};
    }
  }
}
