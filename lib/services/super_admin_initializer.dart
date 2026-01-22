// lib/services/super_admin_initializer.dart
// Inicializador para crear el Super Admin del sistema

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/roles.dart';

class SuperAdminInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear Super Admin si no existe
  static Future<void> initializeSuperAdmin() async {
    try {
      const String superAdminEmail = 'superadmin@gmail.com';
      const String superAdminPassword = 'superadmin123';
      const String superAdminName = 'Super Administrador';

      // Verificar si ya existe el Super Admin
      final existingUser = await _getSuperAdmin();
      if (existingUser != null) {
        // Silenciosamente retornar si ya existe (no mostrar error)
        return;
      }

      // Verificar si el usuario ya existe en Firebase Auth
      try {
        final signInMethods = await _auth.fetchSignInMethodsForEmail(superAdminEmail);
        if (signInMethods.isNotEmpty) {
          // El usuario ya existe en Auth, solo actualizar Firestore
          await _updateExistingSuperAdmin();
          return;
        }
      } catch (e) {
        // Si hay error al verificar, continuar con la creación
      }

      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: superAdminEmail,
        password: superAdminPassword,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Actualizar perfil del usuario
        await user.updateDisplayName(superAdminName);
        
        // Guardar en colección 'users' con rol de Super Admin
        await _firestore.collection('users').doc(user.uid).set({
          'email': superAdminEmail,
          'name': superAdminName,
          'role': UserRoles.SUPER_ADMIN,
          'isSuperAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        print('✅ Super Admin creado exitosamente');
      }
    } catch (e) {
      // Si el usuario ya existe en Auth pero no en Firestore, actualizar Firestore
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('email-already-in-use') || 
          errorStr.contains('already exists') ||
          errorStr.contains('already-in-use')) {
        // Silenciosamente actualizar si ya existe
        await _updateExistingSuperAdmin();
      } else {
        // Solo mostrar error si no es un error de duplicado
        print('⚠️ Error al inicializar Super Admin (puede que ya exista): $e');
      }
    }
  }

  // Obtener Super Admin existente
  static Future<Map<String, dynamic>?> _getSuperAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRoles.SUPER_ADMIN)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'uid': doc.id,
          ...doc.data(),
        };
      }
    } catch (e) {
      print('Error al buscar Super Admin: $e');
    }
    return null;
  }

  // Actualizar Super Admin existente
  static Future<void> _updateExistingSuperAdmin() async {
    try {
      const String superAdminEmail = 'superadmin@gmail.com';
      
      // Buscar usuario por email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: superAdminEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        await doc.reference.update({
          'role': UserRoles.SUPER_ADMIN,
          'isSuperAdmin': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Super Admin actualizado exitosamente');
      } else {
        print('❌ No se encontró usuario con email: $superAdminEmail');
      }
    } catch (e) {
      print('Error al actualizar Super Admin: $e');
    }
  }

  // Verificar si existe Super Admin
  static Future<bool> superAdminExists() async {
    final superAdmin = await _getSuperAdmin();
    return superAdmin != null;
  }

  // Obtener credenciales del Super Admin
  static Future<Map<String, String>?> getSuperAdminCredentials() async {
    final superAdmin = await _getSuperAdmin();
    if (superAdmin != null) {
      return {
        'email': superAdmin['email'] ?? 'superadmin@gmail.com',
        'password': 'superadmin123', // Password fija para desarrollo
        'name': superAdmin['name'] ?? 'Super Administrador',
      };
    }
    return null;
  }
}
