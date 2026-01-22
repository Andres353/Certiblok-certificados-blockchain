// test/performance_benchmark.dart
// Benchmark de rendimiento para operaciones críticas

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Benchmark de Rendimiento', () {
    test('Benchmark: Codificación UTF-8', () {
      _benchmarkUtf8Encoding();
    });

    test('Benchmark: Parseo CSV', () {
      _benchmarkCsvParsing();
    });

    test('Benchmark: Validación de datos', () {
      _benchmarkDataValidation();
    });

    test('Benchmark: Generación de contraseñas', () {
      _benchmarkPasswordGeneration();
    });
  });
}

void _benchmarkUtf8Encoding() {
  print('\n📊 Benchmark: Codificación UTF-8');
  
  final testData = 'correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa\n' * 1000;
  
  final stopwatch = Stopwatch();
  
  // Test 1: UTF-8 encoding
  stopwatch.start();
  for (int i = 0; i < 100; i++) {
    utf8.encode(testData);
  }
  stopwatch.stop();
  print('⏱️  UTF-8 Encoding (100 iteraciones): ${stopwatch.elapsedMilliseconds}ms');
  print('⚡ Promedio: ${(stopwatch.elapsedMilliseconds / 100).toStringAsFixed(2)}ms por operación');
  
  // Test 2: UTF-8 decoding
  final bytes = utf8.encode(testData);
  stopwatch.reset();
  stopwatch.start();
  for (int i = 0; i < 100; i++) {
    utf8.decode(bytes);
  }
  stopwatch.stop();
  print('⏱️  UTF-8 Decoding (100 iteraciones): ${stopwatch.elapsedMilliseconds}ms');
  print('⚡ Promedio: ${(stopwatch.elapsedMilliseconds / 100).toStringAsFixed(2)}ms por operación\n');
}

void _benchmarkCsvParsing() {
  print('📊 Benchmark: Parseo CSV');
  
  // Generar CSV de prueba
  final csvContent = StringBuffer();
  csvContent.writeln('correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa');
  for (int i = 1; i <= 1000; i++) {
    csvContent.writeln('test$i@example.com,Estudiante $i,2024${i.toString().padLeft(4, '0')},1234567890,Programa 1,PROG-001');
  }
  
  final csvString = csvContent.toString();
  final csvBytes = Uint8List.fromList(utf8.encode(csvString));
  
  final stopwatch = Stopwatch();
  
  // Simular parseo (sin usar la librería real para evitar dependencias)
  stopwatch.start();
  for (int i = 0; i < 50; i++) {
    final lines = csvString.split('\n');
    for (final line in lines) {
      if (line.isNotEmpty) {
        line.split(',');
      }
    }
  }
  stopwatch.stop();
  
  print('⏱️  Parseo CSV (50 iteraciones, 1000 filas): ${stopwatch.elapsedMilliseconds}ms');
  print('⚡ Promedio: ${(stopwatch.elapsedMilliseconds / 50).toStringAsFixed(2)}ms por operación');
  print('📊 Tamaño procesado: ${(csvBytes.length / 1024).toStringAsFixed(2)} KB\n');
}

void _benchmarkDataValidation() {
  print('📊 Benchmark: Validación de datos');
  
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final testEmails = List.generate(1000, (i) => 'test$i@example.com');
  final invalidEmails = ['invalid', 'test@', '@example.com', 'test@.com'];
  
  final stopwatch = Stopwatch();
  
  // Test validación de emails válidos
  stopwatch.start();
  int validCount = 0;
  for (final email in testEmails) {
    if (emailRegex.hasMatch(email)) {
      validCount++;
    }
  }
  stopwatch.stop();
  print('⏱️  Validación de 1000 emails válidos: ${stopwatch.elapsedMilliseconds}ms');
  print('✅ Emails válidos: $validCount/1000');
  
  // Test validación de emails inválidos
  stopwatch.reset();
  stopwatch.start();
  int invalidCount = 0;
  for (final email in invalidEmails) {
    if (!emailRegex.hasMatch(email)) {
      invalidCount++;
    }
  }
  stopwatch.stop();
  print('⏱️  Validación de emails inválidos: ${stopwatch.elapsedMilliseconds}ms');
  print('❌ Emails inválidos detectados: $invalidCount/${invalidEmails.length}\n');
}

void _benchmarkPasswordGeneration() {
  print('📊 Benchmark: Generación de contraseñas');
  
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
  
  final stopwatch = Stopwatch();
  
  // Generar 1000 contraseñas
  stopwatch.start();
  final passwords = <String>[];
  for (int i = 0; i < 1000; i++) {
    final random = DateTime.now().millisecondsSinceEpoch + i;
    final password = StringBuffer();
    for (int j = 0; j < 12; j++) {
      password.write(chars[(random + j) % chars.length]);
    }
    passwords.add(password.toString());
  }
  stopwatch.stop();
  
  print('⏱️  Generación de 1000 contraseñas: ${stopwatch.elapsedMilliseconds}ms');
  print('⚡ Promedio: ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}ms por contraseña');
  print('✅ Contraseñas únicas: ${passwords.toSet().length}/1000\n');
}
