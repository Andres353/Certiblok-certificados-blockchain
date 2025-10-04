// lib/services/student_id_generator.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentIdGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generar un ID de estudiante único basado en el año actual
  static Future<String> generateStudentId() async {
    try {
      final currentYear = DateTime.now().year;
      final yearPrefix = currentYear.toString();
      
      // Buscar el último ID de estudiante del año actual
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('studentId', isGreaterThanOrEqualTo: yearPrefix)
          .where('studentId', isLessThan: '${currentYear + 1}')
          .orderBy('studentId', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;
      
      if (querySnapshot.docs.isNotEmpty) {
        final lastStudentId = querySnapshot.docs.first.data()['studentId'] as String;
        
        // Extraer el número del último ID
        if (lastStudentId.startsWith(yearPrefix)) {
          final numberPart = lastStudentId.substring(yearPrefix.length);
          final lastNumber = int.tryParse(numberPart) ?? 0;
          nextNumber = lastNumber + 1;
        }
      }
      
      // Formatear el número con ceros a la izquierda (3 dígitos)
      final formattedNumber = nextNumber.toString().padLeft(3, '0');
      final studentId = '$yearPrefix$formattedNumber';
      
      print('✅ ID de estudiante generado: $studentId');
      return studentId;
      
    } catch (e) {
      print('❌ Error generando ID de estudiante: $e');
      // Fallback: usar timestamp si hay error
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${DateTime.now().year}${timestamp.toString().substring(8)}';
    }
  }

  /// Generar múltiples IDs de estudiante
  static Future<List<String>> generateMultipleStudentIds(int count) async {
    List<String> studentIds = [];
    
    for (int i = 0; i < count; i++) {
      final studentId = await generateStudentId();
      studentIds.add(studentId);
      
      // Pequeña pausa para evitar conflictos de concurrencia
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    return studentIds;
  }

  /// Verificar si un ID de estudiante ya existe
  static Future<bool> studentIdExists(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando ID de estudiante: $e');
      return false;
    }
  }

  /// Obtener estadísticas de IDs de estudiante
  static Future<Map<String, dynamic>> getStudentIdStats() async {
    try {
      final currentYear = DateTime.now().year;
      
      // Contar estudiantes del año actual
      final currentYearQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('studentId', isGreaterThanOrEqualTo: currentYear.toString())
          .where('studentId', isLessThan: '${currentYear + 1}')
          .get();
      
      // Contar todos los estudiantes
      final allStudentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      return {
        'currentYear': currentYear,
        'studentsThisYear': currentYearQuery.docs.length,
        'totalStudents': allStudentsQuery.docs.length,
        'nextStudentId': await generateStudentId(),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {
        'currentYear': DateTime.now().year,
        'studentsThisYear': 0,
        'totalStudents': 0,
        'nextStudentId': '${DateTime.now().year}001',
      };
    }
  }
}

