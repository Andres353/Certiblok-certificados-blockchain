// test/concurrency_test.dart
// Pruebas de concurrencia para importación simultánea

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/services/csv_student_import_service.dart';

void main() {
  group('Pruebas de Concurrencia', () {
    test('Test 1: 5 importaciones simultáneas (50 estudiantes cada una)', () async {
      await _testConcurrentImports(5, 50);
    });

    test('Test 2: 10 importaciones simultáneas (100 estudiantes cada una)', () async {
      await _testConcurrentImports(10, 100);
    });

    test('Test 3: 20 importaciones simultáneas (50 estudiantes cada una)', () async {
      await _testConcurrentImports(20, 50);
    });

    test('Test 4: Importaciones secuenciales vs concurrentes', () async {
      await _compareSequentialVsConcurrent();
    });
  });
}

Future<void> _testConcurrentImports(int batchCount, int studentsPerBatch) async {
  print('\n🧪 Iniciando prueba de concurrencia: $batchCount lotes de $studentsPerBatch estudiantes');
  
  final stopwatch = Stopwatch()..start();
  final futures = <Future<Map<String, dynamic>>>[];
  final results = <Map<String, dynamic>>[];
  
  // Crear todas las tareas concurrentes
  for (int i = 0; i < batchCount; i++) {
    futures.add(_importStudentsBatch(studentsPerBatch, i));
  }
  
  // Ejecutar todas las tareas simultáneamente
  final completedResults = await Future.wait(futures);
  results.addAll(completedResults);
  
  stopwatch.stop();
  
  // Calcular estadísticas
  final totalStudents = results.fold<int>(0, (sum, result) => sum + (result['count'] as int));
  final successfulBatches = results.where((r) => r['success'] == true).length;
  final failedBatches = results.where((r) => r['success'] == false).length;
  
  print('✅ Prueba completada');
  print('⏱️  Tiempo total: ${stopwatch.elapsedMilliseconds}ms (${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s)');
  print('📊 Total estudiantes procesados: $totalStudents');
  print('✅ Lotes exitosos: $successfulBatches/$batchCount');
  print('❌ Lotes fallidos: $failedBatches/$batchCount');
  print('⚡ Velocidad: ${(totalStudents / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} estudiantes/segundo');
  print('⚡ Throughput: ${(batchCount / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} lotes/segundo\n');
  
  // Validar que al menos el 90% de los lotes fueron exitosos
  final successRate = (successfulBatches / batchCount) * 100;
  expect(successRate, greaterThan(90), reason: 'Tasa de éxito debe ser > 90%');
}

Future<void> _compareSequentialVsConcurrent() async {
  print('\n🧪 Comparando importaciones secuenciales vs concurrentes');
  
  const batchCount = 10;
  const studentsPerBatch = 50;
  
  // Test secuencial
  print('📊 Ejecutando importaciones SECUENCIALES...');
  final sequentialStopwatch = Stopwatch()..start();
  for (int i = 0; i < batchCount; i++) {
    await _importStudentsBatch(studentsPerBatch, i);
  }
  sequentialStopwatch.stop();
  final sequentialTime = sequentialStopwatch.elapsedMilliseconds;
  
  // Test concurrente
  print('📊 Ejecutando importaciones CONCURRENTES...');
  final concurrentStopwatch = Stopwatch()..start();
  final futures = List.generate(batchCount, (i) => _importStudentsBatch(studentsPerBatch, i));
  await Future.wait(futures);
  concurrentStopwatch.stop();
  final concurrentTime = concurrentStopwatch.elapsedMilliseconds;
  
  // Comparar resultados
  final improvement = ((sequentialTime - concurrentTime) / sequentialTime) * 100;
  
  print('⏱️  Tiempo secuencial: ${sequentialTime}ms');
  print('⏱️  Tiempo concurrente: ${concurrentTime}ms');
  print('⚡ Mejora: ${improvement.toStringAsFixed(2)}% más rápido');
  print('📈 Aceleración: ${(sequentialTime / concurrentTime).toStringAsFixed(2)}x\n');
  
  // Validar que la versión concurrente es más rápida
  expect(concurrentTime, lessThan(sequentialTime), 
    reason: 'Las importaciones concurrentes deben ser más rápidas');
}

Future<Map<String, dynamic>> _importStudentsBatch(int count, int batchId) async {
  try {
    // Generar CSV de prueba
    final csvContent = _generateTestCsv(count, batchId);
    final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
    
    // Parsear CSV
    final students = await CsvStudentImportService.parseCsv(csvBytes);
    
    return {
      'success': true,
      'count': students.length,
      'batchId': batchId,
    };
  } catch (e) {
    print('❌ Error en lote $batchId: $e');
    return {
      'success': false,
      'count': 0,
      'batchId': batchId,
      'error': e.toString(),
    };
  }
}

String _generateTestCsv(int count, int batchId) {
  final buffer = StringBuffer();
  
  // Encabezados
  buffer.writeln('correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa');
  
  // Generar estudiantes - construir cada fila completa antes de escribirla
  for (int i = 1; i <= count; i++) {
    final studentId = batchId * 10000 + i;
    final row = [
      'estudiante$studentId@example.com',
      'Estudiante $studentId',
      '2024${studentId.toString().padLeft(4, '0')}',
      '${1000000000 + studentId}',
      'Programa ${(i % 10) + 1}',
      'PROG-${(i % 10) + 1}',
    ].join(',');
    buffer.writeln(row);
  }
  
  return buffer.toString();
}
