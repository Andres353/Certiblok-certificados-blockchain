// lib/services/update_super_admin_password.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateSuperAdminPassword {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Actualizar contraseña de super admin por email
  static Future<Map<String, dynamic>> updatePasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Buscar el super admin por email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .where('role', isEqualTo: 'super_admin')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Super administrador no encontrado',
        };
      }

      // Actualizar la contraseña
      await _firestore
          .collection('users')
          .doc(querySnapshot.docs.first.id)
          .update({
        'password': newPassword.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Contraseña actualizada para super admin: $email');

      return {
        'success': true,
        'message': 'Contraseña actualizada exitosamente',
        'adminId': querySnapshot.docs.first.id,
        'email': email.trim(),
      };
    } catch (e) {
      print('❌ Error actualizando contraseña: $e');
      return {
        'success': false,
        'message': 'Error al actualizar contraseña: $e',
      };
    }
  }

  /// Actualizar contraseña de super admin por ID
  static Future<Map<String, dynamic>> updatePasswordById({
    required String adminId,
    required String newPassword,
  }) async {
    try {
      // Actualizar la contraseña
      await _firestore
          .collection('users')
          .doc(adminId)
          .update({
        'password': newPassword.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Contraseña actualizada para super admin ID: $adminId');

      return {
        'success': true,
        'message': 'Contraseña actualizada exitosamente',
        'adminId': adminId,
      };
    } catch (e) {
      print('❌ Error actualizando contraseña: $e');
      return {
        'success': false,
        'message': 'Error al actualizar contraseña: $e',
      };
    }
  }
}

