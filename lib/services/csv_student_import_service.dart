// lib/services/csv_student_import_service.dart
// Servicio para importar estudiantes desde archivos CSV

import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode;
import '../services/adapters/careers_adapter.dart';

class CsvStudentImportService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Configuración de EmailJS
  static const String _emailjsServiceId = 'service_bdav8mg';
  static const String _emailjsTemplateId = 'template_2fs5k3c';
  static const String _emailjsUserId = 'o1eUKl5D0Qq9fJ1Jv';
  static const String _emailjsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // Mapeo de nombres en español a inglés
  static const Map<String, String> columnMapping = {
    // Email
    'correo': 'email',
    'correo electronico': 'email',
    'correo electrónico': 'email',
    'email': 'email',
    'e-mail': 'email',
    // Nombre completo
    'nombre completo': 'full_name',
    'nombre': 'full_name',
    'nombres': 'full_name',
    'full_name': 'full_name',
    // Código estudiante
    'codigo estudiante': 'student_id',
    'código estudiante': 'student_id',
    'codigo': 'student_id',
    'código': 'student_id',
    'id estudiante': 'student_id',
    'identificación': 'student_id',
    'identificacion': 'student_id',
    'student_id': 'student_id',
    // Teléfono
    'telefono': 'phone',
    'teléfono': 'phone',
    'celular': 'phone',
    'phone': 'phone',
    // Nombre programa
    'nombre programa': 'program_name',
    'programa': 'program_name',
    'carrera': 'program_name',
    'program_name': 'program_name',
    // Código programa
    'codigo programa': 'program_code',
    'código programa': 'program_code',
    'codigo carrera': 'program_code',
    'código carrera': 'program_code',
    'program_code': 'program_code',
  };
  
  // Todos los campos son requeridos
  static const List<String> requiredColumnsEn = ['email', 'full_name', 'student_id', 'phone', 'program_name', 'program_code'];

  // Normalizar nombre de columna (español -> inglés)
  // SOLO debe usarse para los headers de la primera fila, NO para datos
  static String _normalizeColumnName(String columnName) {
    // Limpiar espacios extra y convertir a minúsculas
    final normalized = columnName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    
    // Buscar en el mapeo
    final mapped = columnMapping[normalized];
    
    // Si no se encuentra en el mapeo, retornar el valor normalizado
    // Esto es importante porque si es un dato (no un header), no debería estar en el mapeo
    return mapped ?? normalized;
  }

  // Intentar decodificar con diferentes codificaciones
  static String _decodeCsvBytes(Uint8List csvBytes) {
    // Primero intentar UTF-8
    try {
      return utf8.decode(csvBytes);
    } catch (e) {
      // Si falla, intentar con Latin1 (ISO-8859-1) que es común en Windows
      try {
        return latin1.decode(csvBytes);
      } catch (e2) {
        // Si también falla, intentar con allowMalformed para UTF-8
        try {
          return utf8.decode(csvBytes, allowMalformed: true);
        } catch (e3) {
          throw Exception(
            'Error de codificación: El archivo CSV no está en formato UTF-8 válido.\n\n'
            'Solución: Guarda el archivo CSV con codificación UTF-8.\n'
            'En Excel: Guardar como > CSV UTF-8 (delimitado por comas)\n'
            'En Google Sheets: Archivo > Descargar > Valores separados por comas (.csv)\n\n'
            'Error técnico: $e'
          );
        }
      }
    }
  }

  // Parsear CSV desde bytes
  static Future<List<Map<String, dynamic>>> parseCsv(Uint8List csvBytes) async {
    try {
      // Validar que el archivo no esté vacío
      if (csvBytes.isEmpty) {
        throw Exception('El archivo CSV está vacío. Por favor, selecciona un archivo válido.');
      }

      // Decodificar el CSV con manejo de diferentes codificaciones
      String csvString;
      try {
        csvString = _decodeCsvBytes(csvBytes);
      } catch (e) {
        // Si el error ya tiene un mensaje descriptivo, relanzarlo
        if (e.toString().contains('Error de codificación')) {
          rethrow;
        }
        // Si no, crear un mensaje más claro
        throw Exception(
          'Error al leer el archivo CSV: El archivo puede estar dañado o en un formato no compatible.\n\n'
          'Por favor, asegúrate de que:\n'
          '1. El archivo esté guardado en formato UTF-8\n'
          '2. El archivo no esté corrupto\n'
          '3. El archivo tenga la extensión .csv\n\n'
          'Error: ${e.toString()}'
        );
      }

      // Normalizar saltos de línea (Windows usa \r\n, Unix usa \n)
      csvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      
      // Parsear el CSV
      List<List<dynamic>> rows;
      try {
        // Dividir en líneas primero
        final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
        
        if (lines.isEmpty) {
          throw Exception('El archivo CSV está vacío');
        }
        
        // Usar CsvToListConverter para parsear
        final converter = const CsvToListConverter(
          fieldDelimiter: ',',
          eol: '\n',
        );
        
        // Parsear el CSV completo
        rows = converter.convert(csvString);
        
        // Si solo se parseó una fila pero hay múltiples líneas, el CSV está mal formateado
        if (rows.length == 1 && lines.length > 1) {
          // Intentar parsear línea por línea manualmente
          rows = [];
          for (final line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.isNotEmpty) {
              // Parsear cada línea individualmente
              final lineRows = converter.convert(trimmedLine + '\n');
              if (lineRows.isNotEmpty && lineRows.first.isNotEmpty) {
                rows.add(lineRows.first);
              }
            }
          }
        }
        
        // Validar que se parsearon múltiples filas (o al menos una)
        if (rows.isEmpty) {
          throw Exception('El CSV no contiene filas válidas');
        }
        
        // Validar que la primera fila tenga el número correcto de columnas
        if (rows.first.length < requiredColumnsEn.length) {
          throw Exception(
            'El archivo CSV no tiene suficientes columnas en la primera fila.\n\n'
            'Se esperan ${requiredColumnsEn.length} columnas, pero se encontraron ${rows.first.length}.\n\n'
            'Asegúrate de que el CSV tenga los encabezados correctos:\n'
            'correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa'
          );
        }
        
        // Si la primera fila tiene muchas más columnas de las esperadas, el CSV está mal parseado
        if (rows.first.length > requiredColumnsEn.length * 2) {
          throw Exception(
            'El archivo CSV parece estar mal formateado.\n\n'
            'La primera fila tiene ${rows.first.length} columnas cuando se esperan ${requiredColumnsEn.length}.\n\n'
            'Esto generalmente ocurre cuando:\n'
            '1. Las filas no están separadas correctamente por saltos de línea\n'
            '2. Hay comas dentro de los valores sin comillas\n'
            '3. El archivo tiene un formato incorrecto\n\n'
            'Asegúrate de que cada fila esté en una línea separada y que los datos estén separados por comas.'
          );
        }
        
        // Debug: verificar que las filas se parsearon correctamente
        if (kDebugMode && rows.length < 100) {
          print('🔍 CSV parseado - Total filas: ${rows.length}');
          if (rows.isNotEmpty) {
            print('🔍 Primera fila tiene ${rows.first.length} columnas');
            print('🔍 Headers: ${rows.first.map((e) => e.toString()).toList()}');
          }
          if (rows.length > 1) {
            print('🔍 Segunda fila tiene ${rows[1].length} columnas');
          }
        }
      } catch (e) {
        // Si el error ya tiene un mensaje descriptivo, relanzarlo
        if (e.toString().contains('no tiene suficientes columnas') ||
            e.toString().contains('mal formateado') ||
            e.toString().contains('está vacío')) {
          rethrow;
        }
        throw Exception(
          'Error al procesar el formato CSV: El archivo no tiene un formato CSV válido.\n\n'
          'Asegúrate de que:\n'
          '1. Los datos estén separados por comas\n'
          '2. Cada fila esté en una línea separada\n'
          '3. No haya caracteres especiales que rompan el formato\n\n'
          'Error: ${e.toString()}'
        );
      }
      
      if (rows.isEmpty) {
        throw Exception('El archivo CSV está vacío. Debe contener al menos una fila con los encabezados.');
      }

      // Detectar si la primera fila son encabezados o datos
      final firstRow = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      bool hasHeaders = false;
      List<String> headers;
      
      // Verificar si la primera fila parece ser encabezados (contiene palabras como "correo", "email", "nombre", etc.)
      final headerKeywords = ['correo', 'email', 'nombre', 'codigo', 'telefono', 'programa', 'carrera'];
      final firstRowText = firstRow.join(' ');
      hasHeaders = headerKeywords.any((keyword) => firstRowText.contains(keyword));
      
      if (hasHeaders) {
        // Primera fila son los headers - normalizar a inglés
        headers = rows.first.map((e) => _normalizeColumnName(e.toString())).toList();
        
        // Debug: mostrar headers normalizados (solo en modo debug y para archivos pequeños)
        if (kDebugMode && rows.length < 100) {
          print('🔍 Total filas parseadas: ${rows.length}');
          print('🔍 Headers originales: ${rows.first.map((e) => e.toString()).toList()}');
          print('🔍 Headers normalizados: $headers');
          if (rows.length > 1) {
            print('🔍 Primera fila de datos (primeros 3 valores): ${rows[1].take(3).map((e) => e.toString()).toList()}');
          }
        }
      } else {
        // No hay encabezados, usar encabezados por defecto en el orden esperado
        headers = requiredColumnsEn;
      }
      
      // Validar que tenga las columnas requeridas (solo si hay encabezados)
      if (hasHeaders) {
        final esNames = {
          'email': 'correo',
          'full_name': 'nombre completo',
          'student_id': 'codigo estudiante',
          'phone': 'telefono',
          'program_name': 'nombre programa',
          'program_code': 'codigo programa',
        };
        
        for (final requiredCol in requiredColumnsEn) {
          if (!headers.contains(requiredCol)) {
            final esName = esNames[requiredCol] ?? requiredCol;
            
            // Debug: mostrar qué headers se encontraron
            if (kDebugMode) {
              print('❌ Falta columna: $requiredCol ($esName)');
              print('📋 Headers encontrados: $headers');
              print('📋 Headers requeridos: $requiredColumnsEn');
            }
            
            throw Exception(
              'Falta la columna requerida: "$esName"\n\n'
              'El archivo CSV debe tener una primera fila con los encabezados:\n'
              'correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa\n\n'
              'O si no incluyes encabezados, asegúrate de que los datos estén en ese mismo orden.'
            );
          }
        }
      } else {
        // Si no hay encabezados, validar que haya al menos 6 columnas
        if (rows.first.length < requiredColumnsEn.length) {
          throw Exception(
            'El archivo CSV no tiene suficientes columnas.\n\n'
            'Se esperan ${requiredColumnsEn.length} columnas en este orden:\n'
            'correo, nombre completo, codigo estudiante, telefono, nombre programa, codigo programa\n\n'
            'Encontradas: ${rows.first.length} columnas.\n\n'
            'Solución: Agrega una fila de encabezados o asegúrate de que todas las filas tengan ${requiredColumnsEn.length} columnas.'
          );
        }
      }

      // Parsear datos
      final List<Map<String, dynamic>> students = [];
      
      // Determinar desde qué fila empezar (0 si no hay encabezados, 1 si hay)
      final startRow = hasHeaders ? 1 : 0;
      
      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Saltar filas vacías
        }

        final studentData = <String, dynamic>{};
        
        // Solo usar los headers que ya fueron normalizados (solo la primera fila)
        // NO normalizar las filas de datos
        for (int j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j]; // Este header ya está normalizado
          final value = row[j].toString().trim();
          // Agregar todos los valores, incluso si están vacíos, para validación
          studentData[header] = value;
        }

        // Validar que tenga los campos requeridos
        bool hasRequiredFields = true;
        for (final requiredCol in requiredColumnsEn) {
          if (studentData[requiredCol] == null || studentData[requiredCol].toString().trim().isEmpty) {
            hasRequiredFields = false;
            break;
          }
        }

        if (hasRequiredFields) {
          students.add(studentData);
        }
      }

      return students;
    } catch (e) {
      print('❌ Error parseando CSV: $e');
      
      // Si el error ya tiene un mensaje descriptivo, relanzarlo
      if (e.toString().contains('Error de codificación') || 
          e.toString().contains('Error al leer') ||
          e.toString().contains('Error al procesar') ||
          e.toString().contains('Falta la columna') ||
          e.toString().contains('está vacío')) {
        rethrow;
      }
      
      // Si es un error de formato, dar un mensaje más claro
      if (e is FormatException) {
        throw Exception(
          'Error de formato en el archivo CSV.\n\n'
          'El archivo puede tener problemas de codificación o formato.\n\n'
          'Solución:\n'
          '1. Abre el archivo CSV en Excel o Google Sheets\n'
          '2. Guarda el archivo como "CSV UTF-8 (delimitado por comas)"\n'
          '3. Vuelve a intentar importar el archivo\n\n'
          'Error técnico: ${e.message}'
        );
      }
      
      // Para otros errores, dar un mensaje genérico pero útil
      throw Exception(
        'Error al procesar el archivo CSV: ${e.toString()}\n\n'
        'Por favor, verifica que:\n'
        '1. El archivo esté en formato CSV válido\n'
        '2. El archivo tenga todas las columnas requeridas\n'
        '3. El archivo esté guardado en UTF-8\n'
        '4. No haya caracteres especiales que causen problemas'
      );
    }
  }

  // Validar datos de estudiantes
  static List<String> validateStudentData(Map<String, dynamic> studentData) {
    final errors = <String>[];

    // Validar email
    final email = studentData['email']?.toString().trim() ?? '';
    if (email.isEmpty) {
      errors.add('Correo es requerido');
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors.add('Correo inválido: $email');
    }

    // Validar nombre completo
    final fullName = studentData['full_name']?.toString().trim() ?? '';
    if (fullName.isEmpty) {
      errors.add('Nombre completo es requerido');
    }

    // Validar student_id
    final studentId = studentData['student_id']?.toString().trim() ?? '';
    if (studentId.isEmpty) {
      errors.add('Código estudiante es requerido');
    }

    // Validar teléfono
    final phone = studentData['phone']?.toString().trim() ?? '';
    if (phone.isEmpty) {
      errors.add('Teléfono es requerido');
    }

    // Validar nombre programa
    final programName = studentData['program_name']?.toString().trim() ?? '';
    if (programName.isEmpty) {
      errors.add('Nombre programa es requerido');
    }

    // Validar código programa
    final programCode = studentData['program_code']?.toString().trim() ?? '';
    if (programCode.isEmpty) {
      errors.add('Código programa es requerido');
    }

    return errors;
  }

  // Buscar programa por nombre o código
  static Future<Map<String, dynamic>?> findProgram({
    required String institutionId,
    String? programName,
    String? programCode,
  }) async {
    try {
      final programs = await CareersAdapter.getProgramsByInstitution(institutionId);

      // Primero intentar por código si está disponible
      if (programCode != null && programCode.trim().isNotEmpty) {
        final program = programs.firstWhere(
          (p) => p['program_code']?.toString().toUpperCase() == programCode.trim().toUpperCase(),
          orElse: () => {},
        );
        if (program.isNotEmpty) {
          return program;
        }
      }

      // Luego intentar por nombre
      if (programName != null && programName.trim().isNotEmpty) {
        final program = programs.firstWhere(
          (p) => p['name']?.toString().trim().toLowerCase() == programName.trim().toLowerCase(),
          orElse: () => {},
        );
        if (program.isNotEmpty) {
          return program;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error buscando programa: $e');
      return null;
    }
  }

  // Generar contraseña temporal segura
  static String _generateTemporaryPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = StringBuffer();
    
    for (int i = 0; i < 12; i++) {
      password.write(chars[(random + i) % chars.length]);
    }
    
    return password.toString();
  }

  // Enviar contraseña por correo usando EmailJS
  static Future<void> _sendPasswordEmail({
    required String email,
    required String fullName,
    required String tempPassword,
    required String institutionName,
  }) async {
    try {
      print('📧 Enviando contraseña a: $email');

      final message = '''
¡Hola $fullName!

Has sido registrado como estudiante en $institutionName a través de CertiBlock.

🔑 TUS CREDENCIALES DE ACCESO:
Email: $email
Contraseña temporal: $tempPassword

IMPORTANTE: 
- Debes cambiar tu contraseña en el primer acceso por seguridad
- El sistema te pedirá cambiar la contraseña automáticamente
- Usa estas credenciales para hacer login en la plataforma

🌐 Accede a la plataforma e inicia sesión con estas credenciales.

¡Bienvenido a CertiBlock!
Equipo CertiBlock
      ''';

      final response = await http.post(
        Uri.parse(_emailjsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id': _emailjsUserId,
          'template_params': {
            'name': 'CertiBlock',
            'to_email': email,
            'to_name': fullName,
            'full_name': fullName,
            'message': message,
            'subject': 'Bienvenido a $institutionName - Credenciales de Acceso',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email con contraseña enviado exitosamente a: $email');
      } else {
        throw Exception('Error enviando email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error enviando email a $email: $e');
      rethrow;
    }
  }

  // Importar un estudiante
  static Future<Map<String, dynamic>> importStudent({
    required Map<String, dynamic> studentData,
    required String institutionId,
    required String institutionName,
  }) async {
    try {
      final email = studentData['email']?.toString().trim() ?? '';
      final fullName = studentData['full_name']?.toString().trim() ?? '';
      final studentId = studentData['student_id']?.toString().trim() ?? '';
      final phone = studentData['phone']?.toString().trim() ?? '';
      final programName = studentData['program_name']?.toString().trim() ?? '';
      final programCode = studentData['program_code']?.toString().trim() ?? '';

      // Validar datos
      final validationErrors = validateStudentData(studentData);
      if (validationErrors.isNotEmpty) {
        return {
          'success': false,
          'message': 'Errores de validación: ${validationErrors.join(", ")}',
          'email': email,
        };
      }

      // Verificar si el email ya existe
      final existingUser = await _client
          .from('users')
          .select('id, email')
          .eq('email', email)
          .limit(1);

      if (existingUser.isNotEmpty) {
        return {
          'success': false,
          'message': 'El email ya está registrado',
          'email': email,
        };
      }

      // Buscar programa (requerido)
      Map<String, dynamic>? program;
      if (programCode.isNotEmpty) {
        program = await findProgram(
          institutionId: institutionId,
          programCode: programCode,
        );
      }
      
      if (program == null && programName.isNotEmpty) {
        program = await findProgram(
          institutionId: institutionId,
          programName: programName,
        );
      }

      // Generar contraseña temporal
      final tempPassword = _generateTemporaryPassword();
      final passwordHash = BCrypt.hashpw(tempPassword, BCrypt.gensalt());

      // Crear estudiante
      final userData = <String, dynamic>{
        'email': email,
        'password_hash': passwordHash,
        'full_name': fullName,
        'student_id': studentId,
        'phone': phone,
        'role': 'student',
        'institution_id': institutionId,
        'institution_name': institutionName,
        'is_verified': true,
        'must_change_password': true,
        'is_temporary_password': true,
        'created_at': DateTime.now().toIso8601String(),
        'verification_code': '000000',
      };

      // Asignar programa si se encontró
      if (program != null && program.isNotEmpty) {
        userData['program'] = program['name'] ?? programName;
        userData['program_id'] = program['id'];
        userData['faculty'] = program['faculty_name'] ?? 'Sin facultad';
        userData['faculty_id'] = program['faculty_id'];
      } else {
        // Si no se encontró el programa, guardar los datos proporcionados
        userData['program'] = programName;
      }

      final response = await _client.from('users').insert(userData).select();

      if (response.isNotEmpty) {
        // Enviar contraseña por correo
        bool emailSent = false;
        try {
          await _sendPasswordEmail(
            email: email,
            fullName: fullName,
            tempPassword: tempPassword,
            institutionName: institutionName,
          );
          emailSent = true;
        } catch (e) {
          print('⚠️ Error enviando email a $email: $e');
          // Continuar aunque falle el email
        }

        return {
          'success': true,
          'message': 'Estudiante importado exitosamente',
          'email': email,
          'userId': response.first['id'],
          'tempPassword': tempPassword,
          'emailSent': emailSent,
        };
      } else {
        return {
          'success': false,
          'message': 'No se pudo crear el estudiante',
          'email': email,
        };
      }
    } catch (e) {
      print('❌ Error importando estudiante: $e');
      return {
        'success': false,
        'message': 'Error al importar: $e',
        'email': studentData['email']?.toString() ?? 'Desconocido',
      };
    }
  }

  // Importar múltiples estudiantes
  static Future<Map<String, dynamic>> importStudents({
    required List<Map<String, dynamic>> studentsData,
    required String institutionId,
    required String institutionName,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <String, dynamic>{
      'successful': <Map<String, dynamic>>[],
      'failed': <Map<String, dynamic>>[],
      'total': studentsData.length,
    };

    for (int i = 0; i < studentsData.length; i++) {
      if (onProgress != null) {
        onProgress(i + 1, studentsData.length);
      }

      final result = await importStudent(
        studentData: studentsData[i],
        institutionId: institutionId,
        institutionName: institutionName,
      );

      if (result['success'] == true) {
        (results['successful'] as List<Map<String, dynamic>>).add(result);
      } else {
        (results['failed'] as List<Map<String, dynamic>>).add(result);
      }
    }

    return results;
  }
}
