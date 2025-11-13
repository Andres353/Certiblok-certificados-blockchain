// lib/services/supabase/supabase_emisor_service.dart
// Servicio para gestionar emisores en Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class SupabaseEmisorService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Generar contraseña segura automáticamente
  static String _generateSecurePassword() {
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    String allChars = lowerCase + upperCase + numbers + symbols;
    Random random = Random.secure();
    
    String password = '';
    
    // Asegurar al menos un carácter de cada tipo
    password += lowerCase[random.nextInt(lowerCase.length)];
    password += upperCase[random.nextInt(upperCase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += symbols[random.nextInt(symbols.length)];
    
    // Completar con caracteres aleatorios
    for (int i = 4; i < 12; i++) {
      password += allChars[random.nextInt(allChars.length)];
    }
    
    // Mezclar la contraseña
    List<String> passwordList = password.split('');
    passwordList.shuffle(random);
    return passwordList.join('');
  }

  // Obtener todos los emisores de una institución
  static Future<List<Map<String, dynamic>>> getEmisoresByInstitution(String institutionId) async {
    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('role', 'emisor')
          .eq('institution_id', institutionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo emisores: $e');
      throw Exception('Error obteniendo emisores: $e');
    }
  }

  // Obtener carreras de una institución
  static Future<List<Map<String, dynamic>>> getCarrerasByInstitution(String institutionId) async {
    try {
      final response = await _client
          .from('programs')
          .select('*')
          .eq('institution_id', institutionId)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo carreras: $e');
      throw Exception('Error obteniendo carreras: $e');
    }
  }

  // Verificar si un email ya existe
  static Future<bool> emailExists(String email) async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('email', email)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error verificando email: $e');
      return false;
    }
  }

  // Crear nuevo emisor
  static Future<Map<String, dynamic>> createEmisor({
    required String email,
    required String fullName,
    required String institutionId,
    required String institutionName,
    required Set<String> selectedCarreraIds,
    required List<Map<String, dynamic>> carreras,
    bool generatePassword = true,
    String? customPassword,
  }) async {
    try {
      // Verificar si el email ya existe
      if (await emailExists(email)) {
        throw Exception('El email ya está registrado');
      }

      // Generar o usar contraseña
      String password = generatePassword ? _generateSecurePassword() : (customPassword ?? '');

      // Crear asignaciones basadas en las carreras seleccionadas
      List<Map<String, dynamic>> assignments = [];
      
      if (selectedCarreraIds.contains('all')) {
        // Emisor general - puede emitir a todos los estudiantes
        assignments.add({
          'id': 'general_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'general',
          'areaId': 'all',
          'areaName': 'Todos los estudiantes',
        });
      } else {
        // Emisor específico - solo a las carreras seleccionadas
        for (final carreraId in selectedCarreraIds) {
          final carrera = carreras.firstWhere((c) => c['id'] == carreraId);
          assignments.add({
            'id': 'carrera_${carreraId}_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'carrera',
            'areaId': carreraId,
            'areaName': carrera['name'],
            'parentAreaId': carrera['faculty_id'],
            'parentAreaName': carrera['faculty_name'],
          });
        }
      }

      // Crear nuevo emisor
      final emisorData = {
        'email': email,
        'full_name': fullName,
        'password_hash': password, // Almacenar como texto plano temporalmente
        'role': 'emisor',
        'institution_id': institutionId,
        'institution_name': institutionName,
        'emisor_type': selectedCarreraIds.contains('all') ? 'general' : 'carrera',
        'assignments': assignments,
        'is_verified': true,
        'must_change_password': true,
        'is_temporary_password': generatePassword,
        'is_active': true,
        'verification_code': '000000',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('users')
          .insert(emisorData)
          .select()
          .single();

      return {
        'success': true,
        'emisor': response,
        'password': password,
      };
    } catch (e) {
      print('Error creando emisor: $e');
      throw Exception('Error creando emisor: $e');
    }
  }

  // Actualizar emisor
  static Future<Map<String, dynamic>> updateEmisor({
    required String emisorId,
    required String email,
    required String fullName,
    required Set<String> selectedCarreraIds,
    required List<Map<String, dynamic>> carreras,
    bool generatePassword = false,
    String? customPassword,
    bool keepPassword = false,
  }) async {
    try {
      // Crear asignaciones basadas en las carreras seleccionadas
      List<Map<String, dynamic>> assignments = [];
      
      if (selectedCarreraIds.contains('all')) {
        assignments.add({
          'id': 'general_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'general',
          'areaId': 'all',
          'areaName': 'Todos los estudiantes',
        });
      } else {
        for (final carreraId in selectedCarreraIds) {
          final carrera = carreras.firstWhere((c) => c['id'] == carreraId);
          assignments.add({
            'id': 'carrera_${carreraId}_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'carrera',
            'areaId': carreraId,
            'areaName': carrera['name'],
            'parentAreaId': carrera['faculty_id'],
            'parentAreaName': carrera['faculty_name'],
          });
        }
      }

      // Preparar datos de actualización
      Map<String, dynamic> updateData = {
        'email': email,
        'full_name': fullName,
        'emisor_type': selectedCarreraIds.contains('all') ? 'general' : 'carrera',
        'assignments': assignments,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Agregar contraseña solo si no se debe mantener la actual
      if (!keepPassword) {
        if (generatePassword) {
          updateData['password_hash'] = _generateSecurePassword();
          updateData['must_change_password'] = true;
          updateData['is_temporary_password'] = true;
        } else if (customPassword != null && customPassword.isNotEmpty) {
          updateData['password_hash'] = customPassword;
          updateData['must_change_password'] = true;
          updateData['is_temporary_password'] = false;
        }
      }

      final response = await _client
          .from('users')
          .update(updateData)
          .eq('id', emisorId)
          .select()
          .single();

      return {
        'success': true,
        'emisor': response,
        'password': generatePassword ? updateData['password_hash'] : null,
      };
    } catch (e) {
      print('Error actualizando emisor: $e');
      throw Exception('Error actualizando emisor: $e');
    }
  }

  // Eliminar emisor
  static Future<bool> deleteEmisor(String emisorId) async {
    try {
      await _client
          .from('users')
          .delete()
          .eq('id', emisorId);

      return true;
    } catch (e) {
      print('Error eliminando emisor: $e');
      throw Exception('Error eliminando emisor: $e');
    }
  }

  // Cambiar estado del emisor (activar/suspender)
  static Future<bool> toggleEmisorStatus(String emisorId, bool isActive) async {
    try {
      await _client
          .from('users')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', emisorId);

      return true;
    } catch (e) {
      print('Error cambiando estado del emisor: $e');
      throw Exception('Error cambiando estado del emisor: $e');
    }
  }

  // Obtener estadísticas de emisores
  static Future<Map<String, int>> getEmisorStats(String institutionId) async {
    try {
      final response = await _client
          .from('users')
          .select('is_active')
          .eq('role', 'emisor')
          .eq('institution_id', institutionId);

      int total = response.length;
      int active = response.where((e) => e['is_active'] == true).length;
      int suspended = total - active;

      return {
        'total': total,
        'active': active,
        'suspended': suspended,
      };
    } catch (e) {
      print('Error obteniendo estadísticas de emisores: $e');
      return {
        'total': 0,
        'active': 0,
        'suspended': 0,
      };
    }
  }
}
