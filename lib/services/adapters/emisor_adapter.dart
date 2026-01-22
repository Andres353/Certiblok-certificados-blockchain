// lib/services/adapters/emisor_adapter.dart
// Adapter para gestionar emisores entre Firebase y Supabase

import 'package:cloud_firestore/cloud_firestore.dart';
import '../supabase/supabase_emisor_service.dart';

class EmisorAdapter {
  static bool _useSupabase = true; // Cambiar a false para usar Firebase

  // Obtener emisores de una institución
  static Future<List<Map<String, dynamic>>> getEmisoresByInstitution(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseEmisorService.getEmisoresByInstitution(institutionId);
    } else {
      return await _getEmisoresFromFirebase(institutionId);
    }
  }

  // Obtener carreras de una institución
  static Future<List<Map<String, dynamic>>> getCarrerasByInstitution(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseEmisorService.getCarrerasByInstitution(institutionId);
    } else {
      return await _getCarrerasFromFirebase(institutionId);
    }
  }

  // Crear emisor
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
    if (_useSupabase) {
      return await SupabaseEmisorService.createEmisor(
        email: email,
        fullName: fullName,
        institutionId: institutionId,
        institutionName: institutionName,
        selectedCarreraIds: selectedCarreraIds,
        carreras: carreras,
        generatePassword: generatePassword,
        customPassword: customPassword,
      );
    } else {
      return await _createEmisorInFirebase(
        email: email,
        fullName: fullName,
        institutionId: institutionId,
        institutionName: institutionName,
        selectedCarreraIds: selectedCarreraIds,
        carreras: carreras,
        generatePassword: generatePassword,
        customPassword: customPassword,
      );
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
    if (_useSupabase) {
      return await SupabaseEmisorService.updateEmisor(
        emisorId: emisorId,
        email: email,
        fullName: fullName,
        selectedCarreraIds: selectedCarreraIds,
        carreras: carreras,
        generatePassword: generatePassword,
        customPassword: customPassword,
        keepPassword: keepPassword,
      );
    } else {
      return await _updateEmisorInFirebase(
        emisorId: emisorId,
        email: email,
        fullName: fullName,
        selectedCarreraIds: selectedCarreraIds,
        carreras: carreras,
        generatePassword: generatePassword,
        customPassword: customPassword,
      );
    }
  }

  // Eliminar emisor
  static Future<bool> deleteEmisor(String emisorId) async {
    if (_useSupabase) {
      return await SupabaseEmisorService.deleteEmisor(emisorId);
    } else {
      return await _deleteEmisorFromFirebase(emisorId);
    }
  }

  // Cambiar estado del emisor
  static Future<bool> toggleEmisorStatus(String emisorId, bool isActive) async {
    if (_useSupabase) {
      return await SupabaseEmisorService.toggleEmisorStatus(emisorId, isActive);
    } else {
      return await _toggleEmisorStatusInFirebase(emisorId, isActive);
    }
  }

  // Obtener estadísticas de emisores
  static Future<Map<String, int>> getEmisorStats(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseEmisorService.getEmisorStats(institutionId);
    } else {
      return await _getEmisorStatsFromFirebase(institutionId);
    }
  }

  // Verificar si un email existe
  static Future<bool> emailExists(String email) async {
    if (_useSupabase) {
      return await SupabaseEmisorService.emailExists(email);
    } else {
      return await _emailExistsInFirebase(email);
    }
  }

  // ========== MÉTODOS FIREBASE (FALLBACK) ==========

  static Future<List<Map<String, dynamic>>> _getEmisoresFromFirebase(String institutionId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'emisor')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error obteniendo emisores de Firebase: $e');
      throw Exception('Error obteniendo emisores: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _getCarrerasFromFirebase(String institutionId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('programs')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } catch (e) {
      print('Error obteniendo carreras de Firebase: $e');
      throw Exception('Error obteniendo carreras: $e');
    }
  }

  static Future<Map<String, dynamic>> _createEmisorInFirebase({
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
      // Implementación Firebase (placeholder)
      throw Exception('Firebase implementation not available');
    } catch (e) {
      print('Error creando emisor en Firebase: $e');
      throw Exception('Error creando emisor: $e');
    }
  }

  static Future<Map<String, dynamic>> _updateEmisorInFirebase({
    required String emisorId,
    required String email,
    required String fullName,
    required Set<String> selectedCarreraIds,
    required List<Map<String, dynamic>> carreras,
    bool generatePassword = false,
    String? customPassword,
  }) async {
    try {
      // Implementación Firebase (placeholder)
      throw Exception('Firebase implementation not available');
    } catch (e) {
      print('Error actualizando emisor en Firebase: $e');
      throw Exception('Error actualizando emisor: $e');
    }
  }

  static Future<bool> _deleteEmisorFromFirebase(String emisorId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(emisorId).delete();
      return true;
    } catch (e) {
      print('Error eliminando emisor de Firebase: $e');
      throw Exception('Error eliminando emisor: $e');
    }
  }

  static Future<bool> _toggleEmisorStatusInFirebase(String emisorId, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(emisorId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error cambiando estado del emisor en Firebase: $e');
      throw Exception('Error cambiando estado del emisor: $e');
    }
  }

  static Future<Map<String, int>> _getEmisorStatsFromFirebase(String institutionId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'emisor')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      int total = querySnapshot.docs.length;
      int active = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] != false;
      }).length;
      int suspended = total - active;

      return {
        'total': total,
        'active': active,
        'suspended': suspended,
      };
    } catch (e) {
      print('Error obteniendo estadísticas de emisores de Firebase: $e');
      return {
        'total': 0,
        'active': 0,
        'suspended': 0,
      };
    }
  }

  static Future<bool> _emailExistsInFirebase(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando email en Firebase: $e');
      return false;
    }
  }
}
