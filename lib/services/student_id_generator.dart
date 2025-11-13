// lib/services/student_id_generator.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase/supabase_config.dart';

class StudentIdGenerator {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Generar un ID de estudiante único basado en el año actual
  static Future<String> generateStudentId() async {
    try {
      final currentYear = DateTime.now().year;
      final yearPrefix = currentYear.toString();
      
      // Buscar el último ID de estudiante del año actual en Supabase
      final response = await _client
          .from('users')
          .select('student_id')
          .eq('role', 'student')
          .gte('student_id', yearPrefix)
          .lt('student_id', '${currentYear + 1}')
          .order('student_id', ascending: false)
          .limit(1);

      int nextNumber = 1;
      
      if (response.isNotEmpty) {
        final lastStudentId = response.first['student_id'] as String;
        
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
      
      print('✅ ID de estudiante generado en Supabase: $studentId');
      return studentId;
      
    } catch (e) {
      print('❌ Error generando ID de estudiante en Supabase: $e');
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
      final response = await _client
          .from('users')
          .select('id')
          .eq('student_id', studentId)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando ID de estudiante en Supabase: $e');
      return false;
    }
  }

  /// Obtener estadísticas de IDs de estudiante
  static Future<Map<String, dynamic>> getStudentIdStats() async {
    try {
      final currentYear = DateTime.now().year;
      
      // Contar estudiantes del año actual
      final currentYearResponse = await _client
          .from('users')
          .select('id')
          .eq('role', 'student')
          .gte('student_id', currentYear.toString())
          .lt('student_id', '${currentYear + 1}');
      
      // Contar todos los estudiantes
      final allStudentsResponse = await _client
          .from('users')
          .select('id')
          .eq('role', 'student');
      
      return {
        'currentYear': currentYear,
        'studentsThisYear': currentYearResponse.length,
        'totalStudents': allStudentsResponse.length,
        'nextStudentId': await generateStudentId(),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas en Supabase: $e');
      return {
        'currentYear': DateTime.now().year,
        'studentsThisYear': 0,
        'totalStudents': 0,
        'nextStudentId': '${DateTime.now().year}001',
      };
    }
  }
}

