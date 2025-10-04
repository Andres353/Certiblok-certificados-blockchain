// lib/services/super_admin_creator.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear un super administrador
  static Future<Map<String, dynamic>> createSuperAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Verificar si el email ya existe
      final existingQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'El email ya está registrado',
        };
      }

      // Crear el super administrador
      final docRef = await _firestore.collection('users').add({
        'email': email.trim(),
        'password': password.trim(),
        'name': name.trim(),
        'role': 'super_admin',
        'isVerified': true,
        'mustChangePassword': false,
        'isTemporaryPassword': false,
        'createdAt': FieldValue.serverTimestamp(),
        'permissions': {
          'canManageInstitutions': true,
          'canManageUsers': true,
          'canManageSystem': true,
          'canViewAllData': true,
        },
      });

      print('✅ Super administrador creado con ID: ${docRef.id}');

      return {
        'success': true,
        'message': 'Super administrador creado exitosamente',
        'adminId': docRef.id,
        'email': email.trim(),
      };
    } catch (e) {
      print('❌ Error creando super administrador: $e');
      return {
        'success': false,
        'message': 'Error al crear super administrador: $e',
      };
    }
  }

  /// Crear múltiples super administradores
  static Future<List<Map<String, dynamic>>> createMultipleSuperAdmins(
    List<Map<String, String>> admins,
  ) async {
    List<Map<String, dynamic>> results = [];
    
    for (var admin in admins) {
      final result = await createSuperAdmin(
        email: admin['email']!,
        password: admin['password']!,
        name: admin['name']!,
      );
      results.add(result);
    }
    
    return results;
  }
}
