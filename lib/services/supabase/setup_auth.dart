// lib/services/supabase/setup_auth.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'supabase_auth_service.dart';
import '../adapters/auth_adapter.dart';
import '../adapters/institution_adapter.dart';
import '../adapters/institution_request_adapter.dart';

class SetupAuth {
  // Activar autenticación Supabase
  static Future<void> enableSupabaseAuth() async {
    try {
      print('🔄 Activando autenticación Supabase...');
      
      // Activar todos los adaptadores para usar Supabase
      AuthAdapter.useSupabase(true);
      InstitutionAdapter.useSupabase(true);
      InstitutionRequestAdapter.useSupabase(true);
      
      print('✅ Autenticación Supabase activada');
    } catch (e) {
      print('❌ Error al activar autenticación Supabase: $e');
      rethrow;
    }
  }

  // Crear usuario de prueba
  static Future<void> createTestUser() async {
    try {
      print('👤 Creando usuario de prueba...');
      
      // Crear usuario estudiante de prueba
      final result = await SupabaseAuthService.registerStudent(
        email: 'test@certiblock.com',
        password: 'TestPassword123!',
        fullName: 'Usuario de Prueba',
        studentId: 'TEST001',
      );
      
      if (result['success']) {
        print('✅ Usuario de prueba creado exitosamente');
        print('📧 Email: test@certiblock.com');
        print('🔑 Password: TestPassword123!');
      } else {
        print('❌ Error al crear usuario: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error al crear usuario de prueba: $e');
      rethrow;
    }
  }

  // Crear super admin
  static Future<void> createSuperAdmin() async {
    try {
      print('👑 Creando super admin...');
      
      // Crear super admin directamente en Supabase
      final response = await Supabase.instance.client.from('users').insert({
        'email': 'admin@certiblock.com',
        'password_hash': _hashPassword('AdminPassword123!'),
        'full_name': 'Super Administrador',
        'role': 'super_admin',
        'is_verified': true,
        'must_change_password': false,
        'is_temporary_password': false,
        'created_at': DateTime.now().toIso8601String(),
        'verification_code': '000000',
      }).select();
      
      if (response.isNotEmpty) {
        print('✅ Super admin creado exitosamente');
        print('📧 Email: admin@certiblock.com');
        print('🔑 Password: AdminPassword123!');
        print('👑 Rol: super_admin');
      } else {
        throw Exception('No se pudo crear el super admin');
      }
    } catch (e) {
      print('❌ Error al crear super admin: $e');
      rethrow;
    }
  }

  // Hash de contraseñas
  static String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  // Probar login
  static Future<void> testLogin() async {
    try {
      print('🧪 Probando login...');
      
      // Probar login con usuario de prueba
      final userContext = await SupabaseAuthService.loginWithContext(
        'test@certiblock.com',
        'TestPassword123!',
      );
      
      if (userContext != null) {
        print('✅ Login exitoso');
        print('👤 Usuario: ${userContext.userName}');
        print('🎭 Rol: ${userContext.userRole}');
        print('🏢 Institución: ${userContext.institutionName ?? "Sin institución"}');
      } else {
        print('❌ Login falló');
      }
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  // Configuración completa
  static Future<void> setupComplete() async {
    try {
      print('🚀 Configurando autenticación completa...');
      
      // 1. Activar Supabase
      await enableSupabaseAuth();
      
      // 2. Crear usuario de prueba
      await createTestUser();
      
      // 3. Crear super admin
      await createSuperAdmin();
      
      // 4. Probar login
      await testLogin();
      
      print('🎉 Configuración completa exitosa!');
    } catch (e) {
      print('❌ Error en configuración: $e');
      rethrow;
    }
  }

  // Desactivar autenticación Supabase
  static Future<void> disableSupabaseAuth() async {
    try {
      print('🔄 Desactivando autenticación Supabase...');
      
      // Desactivar todos los adaptadores para usar Firebase
      AuthAdapter.useSupabase(false);
      InstitutionAdapter.useSupabase(false);
      InstitutionRequestAdapter.useSupabase(false);
      
      print('✅ Autenticación Supabase desactivada - Volviendo a Firebase');
    } catch (e) {
      print('❌ Error al desactivar autenticación Supabase: $e');
      rethrow;
    }
  }
}
