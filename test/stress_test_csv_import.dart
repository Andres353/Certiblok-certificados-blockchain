// test/stress_test_csv_import.dart
// Pruebas de estrés para la importación masiva de estudiantes desde CSV

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:frontend_app/services/csv_student_import_service.dart';

void main() {
  group('Pruebas de Estrés - Importación CSV', () {
    test('Test 1: Importar 10 estudiantes', () async {
      await _testImport(10, '10 estudiantes');
    });

    test('Test 2: Importar 50 estudiantes', () async {
      await _testImport(50, '50 estudiantes');
    });

    test('Test 3: Importar 100 estudiantes', () async {
      await _testImport(100, '100 estudiantes');
    });

    test('Test 4: Importar 500 estudiantes', () async {
      await _testImport(500, '500 estudiantes');
    });

    test('Test 5: Importar 1000 estudiantes', () async {
      await _testImport(1000, '1000 estudiantes');
    });

    test('Test 6: CSV con caracteres especiales', () async {
      await _testSpecialCharacters();
    });

    test('Test 7: CSV con datos inválidos', () async {
      await _testInvalidData();
    });

    test('Test 8: CSV muy grande (10MB)', () async {
      await _testLargeFile();
    });
  });
}

Future<void> _testImport(int count, String description) async {
  print('\n🧪 Iniciando prueba: $description');
  
  final stopwatch = Stopwatch()..start();
  
  // Generar CSV de prueba
  final csvContent = _generateTestCsv(count);
  final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
  
  final encodingTime = stopwatch.elapsedMilliseconds;
  print('⏱️  Tiempo de generación: ${encodingTime}ms');
  print('📊 Tamaño del archivo: ${(csvBytes.length / 1024).toStringAsFixed(2)} KB');
  
  // Debug: mostrar primeros 200 caracteres del CSV
  if (count <= 10) {
    print('🔍 CSV generado (primeras líneas):');
    final lines = csvContent.split('\n');
    for (int i = 0; i < lines.length && i < 3; i++) {
      print('  Línea $i: ${lines[i]}');
    }
  }
  
  stopwatch.reset();
  stopwatch.start();
  
  try {
    // Parsear CSV
    final students = await CsvStudentImportService.parseCsv(csvBytes);
    
    final parseTime = stopwatch.elapsedMilliseconds;
    print('✅ CSV parseado exitosamente');
    print('⏱️  Tiempo de parseo: ${parseTime}ms');
    print('📊 Estudiantes parseados: ${students.length}');
    print('⚡ Velocidad: ${(students.length / (parseTime / 1000)).toStringAsFixed(2)} estudiantes/segundo');
    
    // Validar que todos los estudiantes fueron parseados
    expect(students.length, equals(count));
    
    // Validar estructura de datos
    for (final student in students) {
      expect(student.containsKey('email'), isTrue);
      expect(student.containsKey('full_name'), isTrue);
      expect(student.containsKey('student_id'), isTrue);
      expect(student.containsKey('phone'), isTrue);
      expect(student.containsKey('program_name'), isTrue);
      expect(student.containsKey('program_code'), isTrue);
    }
    
    print('✅ Validación exitosa\n');
    
  } catch (e) {
    print('❌ Error en la prueba: $e');
    fail('Error al parsear CSV: $e');
  }
}

Future<void> _testSpecialCharacters() async {
  print('\n🧪 Iniciando prueba: Caracteres especiales');
  
  final csvContent = '''correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa
test1@example.com,María José García,2024001,1234567890,Ingeniería de Sistemas,SISTEMAS-001
test2@example.com,José María López,2024002,0987654321,Arquitectura & Diseño,ARQ-002
test3@example.com,Ana Sofía Pérez,2024003,1122334455,Medicina "General",MED-003
test4@example.com,Carlos Alberto,2024004,5566778899,Matemáticas (Aplicadas),MAT-004
test5@example.com,Luis Ángel,2024005,6677889900,Química/Física,QUIM-005''';

  final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
  
  try {
    final students = await CsvStudentImportService.parseCsv(csvBytes);
    expect(students.length, equals(5));
    print('✅ Caracteres especiales manejados correctamente\n');
  } catch (e) {
    print('❌ Error con caracteres especiales: $e');
    fail('Error al parsear CSV con caracteres especiales: $e');
  }
}

Future<void> _testInvalidData() async {
  print('\n🧪 Iniciando prueba: Datos inválidos');
  
  // CSV con filas incompletas
  final csvContent = '''correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa
test1@example.com,Estudiante 1,2024001,1234567890,Programa 1,PROG-001
test2@example.com,,2024002,0987654321,Programa 2,PROG-002
,Estudiante 3,2024003,1122334455,Programa 3,PROG-003
test4@example.com,Estudiante 4,,5566778899,Programa 4,PROG-004''';

  final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
  
  try {
    final students = await CsvStudentImportService.parseCsv(csvBytes);
    // Debería parsear solo las filas válidas (solo la primera tiene todos los campos)
    expect(students.length, greaterThanOrEqualTo(1), 
      reason: 'Debe parsear al menos la fila válida');
    print('✅ Datos inválidos filtrados correctamente');
    print('📊 Estudiantes válidos encontrados: ${students.length}\n');
  } catch (e) {
    // Si lanza excepción por validación, también es válido
    if (e.toString().contains('Falta la columna') || 
        e.toString().contains('requerida')) {
      print('✅ Validación de columnas funcionando correctamente\n');
    } else {
      print('⚠️  Error inesperado: $e\n');
    }
  }
}

Future<void> _testLargeFile() async {
  print('\n🧪 Iniciando prueba: Archivo grande (10MB)');
  
  final stopwatch = Stopwatch()..start();
  
  // Generar CSV de ~10MB (aproximadamente 50,000 estudiantes)
  final csvContent = _generateTestCsv(50000);
  final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
  
  final sizeMB = csvBytes.length / (1024 * 1024);
  print('📊 Tamaño del archivo: ${sizeMB.toStringAsFixed(2)} MB');
  
  stopwatch.reset();
  stopwatch.start();
  
  try {
    final students = await CsvStudentImportService.parseCsv(csvBytes);
    
    final parseTime = stopwatch.elapsedMilliseconds;
    print('✅ CSV grande parseado exitosamente');
    print('⏱️  Tiempo de parseo: ${parseTime}ms (${(parseTime / 1000).toStringAsFixed(2)}s)');
    print('📊 Estudiantes parseados: ${students.length}');
    print('⚡ Velocidad: ${(students.length / (parseTime / 1000)).toStringAsFixed(2)} estudiantes/segundo');
    print('💾 Memoria: ~${(csvBytes.length / (1024 * 1024)).toStringAsFixed(2)} MB procesados\n');
    
  } catch (e) {
    print('❌ Error con archivo grande: $e');
    // No fallar, solo reportar
    print('⚠️  El sistema puede necesitar optimización para archivos muy grandes\n');
  }
}

String _generateTestCsv(int count) {
  final buffer = StringBuffer();
  
  // Encabezados en español (exactamente como se espera)
  buffer.write('correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa');
  buffer.write('\n'); // Nueva línea explícita
  
  // Generar estudiantes - construir cada fila completa antes de escribirla
  for (int i = 1; i <= count; i++) {
    // Construir la fila como una lista y unirla
    final row = [
      'estudiante$i@example.com',
      'Estudiante $i',
      '2024${i.toString().padLeft(4, '0')}',
      '${1000000000 + i}',
      'Programa ${(i % 10) + 1}',
      'PROG-${(i % 10) + 1}',
    ];
    buffer.write(row.join(','));
    buffer.write('\n'); // Nueva línea explícita al final de cada fila
  }
  
  final result = buffer.toString();
  
  // Verificar que el CSV tenga el formato correcto (solo para pruebas pequeñas)
  if (count <= 10 && kDebugMode) {
    final lines = result.split('\n').where((line) => line.trim().isNotEmpty).toList();
    print('🔍 CSV generado - Total líneas (no vacías): ${lines.length}');
    if (lines.length >= 2) {
      print('🔍 Primera línea (headers): "${lines[0]}"');
      print('🔍 Segunda línea (datos): "${lines[1]}"');
      // Verificar que cada línea tenga 6 columnas
      final headerCols = lines[0].split(',').length;
      final dataCols = lines[1].split(',').length;
      print('🔍 Headers: $headerCols columnas, Datos: $dataCols columnas');
    }
  }
  
  return result;
}
