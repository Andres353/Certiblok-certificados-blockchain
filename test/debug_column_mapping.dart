// test/debug_column_mapping.dart
// Test de depuración para verificar el mapeo de columnas

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/services/csv_student_import_service.dart';

void main() {
  test('Debug: Verificar mapeo de columnas', () {
    final csvContent = 'correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa\n'
        'test@example.com,Test User,2024001,1234567890,Programa Test,PROG-001';
    
    final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
    
    print('\n🔍 DEBUG: Verificando mapeo de columnas');
    print('CSV Content:');
    print(csvContent);
    print('\n');
    
    try {
      final students = CsvStudentImportService.parseCsv(csvBytes);
      students.then((result) {
        print('✅ CSV parseado exitosamente');
        print('📊 Estudiantes: ${result.length}');
        if (result.isNotEmpty) {
          print('📋 Primer estudiante:');
          result.first.forEach((key, value) {
            print('  $key: $value');
          });
        }
      });
    } catch (e) {
      print('❌ Error: $e');
      print('\n🔍 Analizando el error...');
      
      // Intentar parsear manualmente
      final csvString = utf8.decode(csvBytes);
      final lines = csvString.split('\n');
      if (lines.isNotEmpty) {
        final headers = lines[0].split(',');
        print('\n📋 Headers encontrados:');
        for (int i = 0; i < headers.length; i++) {
          print('  [$i] "${headers[i]}" (trimmed: "${headers[i].trim()}", lowercase: "${headers[i].trim().toLowerCase()}")');
        }
      }
    }
  });
}
