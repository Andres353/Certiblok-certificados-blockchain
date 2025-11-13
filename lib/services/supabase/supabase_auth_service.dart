// lib/services/supabase/supabase_auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../user_context_service.dart';
import '../institution_service.dart';
import '../../models/institution.dart';
import '../../data/sample_institutions.dart';

class SupabaseAuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Obtener usuario actual
  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  // 1. HASH DE CONTRASEÑAS CON BCRYPT (MÁS SEGURO)
  static String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  static bool _verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }

  // 2. REGISTRO DE ESTUDIANTE
  static Future<Map<String, dynamic>> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    String? phone,
    String? document,
    String? birthDate,
    String? address,
  }) async {
    try {
      // Verificar si el email ya existe
      final existingQuery = await _client
          .from('users')
          .select('id')
          .eq('email', email.trim())
          .limit(1);

      if (existingQuery.isNotEmpty) {
        return {
          'success': false,
          'message': 'El email ya está registrado',
        };
      }

      // Crear el estudiante en Supabase
      // Construir el mapa de datos base
      final userData = <String, dynamic>{
        'email': email.trim(),
        'password_hash': _hashPassword(password.trim()),
        'full_name': fullName.trim(),
        'student_id': studentId.trim(),
        'role': 'student',
        'phone': phone?.trim().isEmpty ?? true ? null : phone?.trim(),
        // Campos comentados hasta que se agreguen las columnas a la BD
        // TODO: Descomentar camp cuando se ejecute el script add_student_fields.sql
        // 'document': document?.trim().isEmpty ?? true ? null : document?.trim(),
        // 'birth_date': birthDate?.trim().isEmpty ?? true ? null : birthDate?.trim(),
        'is_verified': true, // Verificado automáticamente
        'must_change_password': true, // Debe cambiar contraseña temporal
        'is_temporary_password': true, // Contraseña temporal
        'created_at': DateTime.now().toIso8601String(),
        'verification_code': '000000', // Será actualizado por el frontend
      };
      
      // Solo agregar campos adicionales si tienen valor y las columnas existen
      // TODO: Descomentar cuando se ejecute el script add_student_fields.sql
      // if (document != null && document.trim().isNotEmpty) {
      //   userData['document'] = document.trim();
      // }
      // if (birthDate != null && birthDate.trim().isNotEmpty) {
      //   userData['birth_date'] = birthDate.trim();
      // }
      // if (address != null && address.trim().isNotEmpty) {
      //   userData['address'] = address.trim();
      // }
      
      final response = await _client.from('users').insert(userData).select();

      if (response.isNotEmpty) {
        print('✅ Estudiante registrado con ID: ${response.first['id']}');
        return {
          'success': true,
          'message': 'Estudiante registrado exitosamente',
          'userId': response.first['id'], // Cambiar nombre para claridad
          'studentId': response.first['student_id'], // ID de estudiante separado
        };
      } else {
        throw Exception('No se pudo crear el usuario');
      }
    } catch (e) {
      print('❌ Error registrando estudiante: $e');
      return {
        'success': false,
        'message': 'Error al registrar estudiante: $e',
      };
    }
  }

  // 3. REGISTRO DE USUARIO CON SUPABASE AUTH
  static Future<void> registerUser(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        // Guardar datos adicionales en la tabla users
        await _client.from('users').insert({
          'id': response.user!.id,
          'email': email.trim(),
          'role': 'user', // Rol por defecto al registrar
        });
        print('Usuario registrado con uid: ${response.user!.id}');
      }
    } catch (e) {
      print('Error al registrar usuario (Supabase): $e');
    }
  }

  // 4. OBTENER ROL DE USUARIO
  static Future<String?> getUserRole(String uid) async {
    try {
      final response = await _client
          .from('users')
          .select('role')
          .eq('id', uid)
          .single();

      print('Doc data para $uid: $response');
      if (response['role'] != null) {
        return response['role'] as String;
      } else {
        print('No existe campo role en documento');
      }
    } catch (e) {
      print('Error al obtener rol de usuario: $e');
    }
    return null;
  }

  // 5. LOGIN CON CONTEXTO (MÉTODO PRINCIPAL)
  static Future<UserContext?> loginWithContext(String email, String password) async {
    print('🚀 INICIANDO loginWithContext para: $email');
    try {
      // PRIMERO: Buscar en 'users' (super_admin, emisor, student)
      print('🔍 Buscando en tabla users...');
      try {
        final usersQuery = await _client
            .from('users')
            .select('*')
            .eq('email', email.trim())
            .limit(1);

        print('📊 Resultados en users: ${usersQuery.length} documentos encontrados');
        if (usersQuery.isNotEmpty) {
          final userData = usersQuery.first;
          print('Usuario encontrado en users: ${userData['role']}');

          // Verificar contraseña con bcrypt
          final storedPasswordHash = userData['password_hash'] ?? '';
          print('🔍 DEBUG PASSWORD COMPARISON (USERS):');
          print('   Contraseña ingresada: ${password.trim()}');
          print('   Hash almacenado: ${storedPasswordHash.length > 20 ? storedPasswordHash.substring(0, 20) + '...' : storedPasswordHash}');
          
          bool passwordMatches = false;
          
          // Si está hasheado con bcrypt, verificar con bcrypt
          if (storedPasswordHash.startsWith('\$2') && storedPasswordHash.length >= 28) {
            try {
              passwordMatches = _verifyPassword(password.trim(), storedPasswordHash);
              print('   Verificación bcrypt: $passwordMatches');
            } catch (e) {
              print('   Error en verificación bcrypt: $e');
              // Fallback a comparación directa si bcrypt falla
              passwordMatches = password.trim() == storedPasswordHash;
              print('   Fallback a texto plano: $passwordMatches');
            }
          } else {
            // Si está en texto plano, comparar directamente
            passwordMatches = password.trim() == storedPasswordHash;
            print('   Verificación texto plano: $passwordMatches');
          }
          
          if (passwordMatches) {
            // Verificar si está verificado
            if (userData['is_verified'] == true) {
              final role = userData['role'] ?? 'student';
              final institutionId = userData['institution_id'];
              
              // Cargar institución si existe
              Institution? institution;
              if (institutionId != null) {
                try {
                  institution = await InstitutionService.getInstitution(institutionId);
                } catch (e) {
                  print('Error loading institution: $e');
                  institution = SampleInstitutions.getInstitutionById(institutionId);
                }
              }

              // Verificar si debe cambiar contraseña
              final mustChangePassword = userData['must_change_password'] == true;
              final isTemporaryPassword = userData['is_temporary_password'] == true;

              print('🔍 DEBUG PASSWORD CHANGE (USERS):');
              print('   mustChangePassword: $mustChangePassword');
              print('   isTemporaryPassword: $isTemporaryPassword');
              print('   role: $role');

              // Crear contexto de usuario
              final context = UserContext(
                userId: userData['id'].toString(),
                userRole: role,
                institutionId: institutionId,
                currentInstitution: institution,
                userEmail: email.trim(),
                userName: userData['name'] ?? userData['full_name'] ?? email.trim(),
                mustChangePassword: mustChangePassword,
                isTemporaryPassword: isTemporaryPassword,
              );

              // Establecer contexto
              await UserContextService.setUserContext(context);
              
              return context;
            } else {
              print('Usuario no verificado');
              return null;
            }
          } else {
            print('Contraseña incorrecta para usuario en users');
          }
        }
      } catch (e) {
        print('Error al buscar en users: $e');
      }

      // SEGUNDO: Buscar en 'institutions' (admin_institution)
      print('🔍 Buscando en tabla institutions...');
      try {
        // Debug: Ver todas las instituciones con admin_email
        final allInstitutions = await _client
            .from('institutions')
            .select('id, name, admin_email, admin_password_hash')
            .not('admin_email', 'is', null);
        
        print('🔍 DEBUG - Todas las instituciones con admin_email:');
        for (final inst in allInstitutions) {
          final hash = inst['admin_password_hash']?.toString() ?? 'NULL';
          final hashPreview = hash.length > 20 ? hash.substring(0, 20) + '...' : hash;
          print('   - ${inst['name']}: ${inst['admin_email']} (hash: $hashPreview)');
        }
        
        final institutionsQuery = await _client
            .from('institutions')
            .select('*')
            .eq('admin_email', email.trim())
            .limit(1);

        print('📊 Resultados en institutions para "$email": ${institutionsQuery.length} documentos encontrados');
        if (institutionsQuery.isNotEmpty) {
          final institutionData = institutionsQuery.first;
          print('Institución encontrada: ${institutionData['name']}');

          // Verificar contraseña del admin (texto plano o hash)
          final storedPassword = institutionData['admin_password_hash'] ?? '';
          print('🔍 DEBUG PASSWORD COMPARISON (INSTITUTIONS):');
          print('   Contraseña ingresada: ${password.trim()}');
          print('   Contraseña almacenada: ${storedPassword.length > 20 ? storedPassword.substring(0, 20) + '...' : storedPassword}');
          
          bool passwordMatches = false;
          
          // Si está hasheado con bcrypt, verificar con bcrypt
          if (storedPassword.startsWith('\$2') && storedPassword.length >= 28) {
            try {
              passwordMatches = _verifyPassword(password.trim(), storedPassword);
              print('   Verificación bcrypt: $passwordMatches');
            } catch (e) {
              print('   Error en verificación bcrypt: $e');
              // Fallback a comparación directa si bcrypt falla
              passwordMatches = password.trim() == storedPassword;
              print('   Fallback a texto plano: $passwordMatches');
            }
          } else {
            // Si está en texto plano, comparar directamente
            passwordMatches = password.trim() == storedPassword;
            print('   Verificación texto plano: $passwordMatches');
          }

          if (passwordMatches) {
            final institutionId = institutionData['id'].toString();
            final institution = Institution.fromFirestore(institutionData, institutionId);

            // Verificar si debe cambiar contraseña
            final mustChangePassword = institutionData['admin_must_change_password'] == true;
            final isTemporaryPassword = institutionData['admin_is_temporary_password'] == true;

            print('🔍 DEBUG PASSWORD CHANGE (INSTITUTIONS):');
            print('   mustChangePassword: $mustChangePassword');
            print('   isTemporaryPassword: $isTemporaryPassword');
            print('   role: admin_institution');

            // Crear contexto de usuario
            final context = UserContext(
              userId: institutionId,
              userRole: 'admin_institution',
              institutionId: institutionId,
              currentInstitution: institution,
              userEmail: email.trim(),
              userName: institutionData['admin_name'] ?? email.trim(),
              mustChangePassword: mustChangePassword,
              isTemporaryPassword: isTemporaryPassword,
            );

            // Establecer contexto
            await UserContextService.setUserContext(context);
            
            return context;
          } else {
            print('Contraseña incorrecta para admin de institución');
          }
        }
      } catch (e) {
        print('Error al buscar en institutions: $e');
      }
    } catch (e, stacktrace) {
      print('Error inesperado: $e');
      print('Stacktrace: $stacktrace');
    }

    return null;
  }

  // 6. LOGIN SIMPLE (MÉTODO LEGACY)
  static Future<String?> loginUser(String email, String password) async {
    print('🚀 INICIANDO loginUser para: $email');
    try {
      // PRIMERO: Buscar en 'users' (todos los usuarios: student, emisor, etc.)
      print('🔍 Buscando en tabla users...');
      try {
        final usersQuery = await _client
            .from('users')
            .select('*')
            .eq('email', email.trim())
            .limit(1);

        print('📊 Resultados en users: ${usersQuery.length} documentos encontrados');
        if (usersQuery.isNotEmpty) {
          final userData = usersQuery.first;
          print('Usuario encontrado en users: ${userData['role']}');

          // Para usuarios en Supabase, verificar contraseña con bcrypt
          final storedPasswordHash = userData['password_hash'] ?? '';
          print('🔍 DEBUG PASSWORD COMPARISON:');
          print('   Contraseña ingresada: ${password.trim()}');
          print('   Hash almacenado: ${storedPasswordHash.substring(0, 20)}...');
          print('   ¿Coinciden?: ${_verifyPassword(password.trim(), storedPasswordHash)}');
          
          if (_verifyPassword(password.trim(), storedPasswordHash)) {
            // Verificar si está verificado
            if (userData['is_verified'] == true) {
              final role = userData['role'] ?? 'admin_institution';
              final institutionId = userData['institution_id'];
              
              // Cargar institución si existe
              Institution? institution;
              if (institutionId != null) {
                try {
                  institution = await InstitutionService.getInstitution(institutionId);
                } catch (e) {
                  print('Error loading institution: $e');
                  institution = SampleInstitutions.getInstitutionById(institutionId);
                }
              }

              // Verificar si debe cambiar contraseña
              final mustChangePassword = userData['must_change_password'] == true;
              final isTemporaryPassword = userData['is_temporary_password'] == true;

              print('🔍 DEBUG PASSWORD CHANGE (USERS):');
              print('   mustChangePassword: $mustChangePassword');
              print('   isTemporaryPassword: $isTemporaryPassword');
              print('   role: $role');

              // Crear contexto de usuario
              final context = UserContext(
                userId: userData['id'].toString(),
                userRole: role,
                institutionId: institutionId,
                currentInstitution: institution,
                userEmail: email.trim(),
                userName: userData['name'] ?? userData['full_name'] ?? email.trim(),
                mustChangePassword: mustChangePassword,
                isTemporaryPassword: isTemporaryPassword,
              );

              // Establecer contexto
              await UserContextService.setUserContext(context);

              // Verificar si debe cambiar contraseña
              if (mustChangePassword) {
                print('⚠️ Usuario debe cambiar contraseña - usando loginWithContext');
                return 'NEEDS_PASSWORD_CHANGE';
              }
              
              return role;
            } else {
              print('Usuario no verificado');
              return null;
            }
          } else {
            print('Contraseña incorrecta para usuario');
            return null;
          }
        }
      } catch (e) {
        print('Error al buscar en users: $e');
      }

      // SEGUNDO: Si no está en users, intentar Supabase Auth
      try {
        final response = await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password.trim(),
        );

        if (response.user != null) {
          print('Token renovado para: ${response.user!.email}');

          // Buscar rol en 'users'
          final role = await getUserRole(response.user!.id);
          if (role != null) {
            // Verificar si debe cambiar contraseña
            final userResponse = await _client
                .from('users')
                .select('must_change_password')
                .eq('id', response.user!.id)
                .single();
            final mustChangePassword = userResponse['must_change_password'] == true;
            
            if (mustChangePassword) {
              print('⚠️ Usuario debe cambiar contraseña - usando loginWithContext');
              return 'NEEDS_PASSWORD_CHANGE';
            }
          }
          return role;
        }
      } catch (e) {
        print('Supabase Auth Error: $e');
        return null;
      }
    } catch (e, stacktrace) {
      print('Error inesperado: $e');
      print('Stacktrace: $stacktrace');
    }

    print('❌ No se encontró usuario válido en ninguna colección');
    return null;
  }

  // 7. CERRAR SESIÓN
  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
      await UserContextService.clearUserContext();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // 8. MIGRAR USUARIOS EXISTENTES (FUNCIÓN TEMPORAL)
  static Future<void> migrateExistingUsers() async {
    try {
      final usersQuery = await _client.from('users').select('*');
      
      for (final user in usersQuery) {
        // Solo migrar si no tiene password_hash
        if (user['password_hash'] == null && user['password'] != null) {
          final passwordHash = _hashPassword(user['password']);
          
          await _client.from('users').update({
            'password_hash': passwordHash,
            'is_active': true,
            'login_attempts': 0,
            'locked_until': null,
          }).eq('id', user['id']);
          
          // Eliminar contraseña en texto plano
          await _client.from('users').update({
            'password': null,
          }).eq('id', user['id']);
          
          print('✅ Usuario migrado: ${user['email']}');
        }
      }
      
      print('✅ Migración de usuarios completada');
    } catch (e) {
      print('Error en migración: $e');
    }
  }
}
