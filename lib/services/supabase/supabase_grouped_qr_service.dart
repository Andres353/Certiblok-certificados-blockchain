// lib/services/supabase/supabase_grouped_qr_service.dart
// Servicio para gestionar QRs agrupados en Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_app/models/grouped_qr.dart';
import 'package:frontend_app/services/user_context_service.dart';

class SupabaseGroupedQRService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Guardar QR agrupado
  static Future<String> saveGroupedQR({
    required String name,
    required String qrUrl,
    required List<String> certificateIds,
    required List<String> certificateTitles,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      final groupedQRData = {
        'name': name,
        'qr_url': qrUrl,
        'certificate_ids': certificateIds,
        'certificate_titles': certificateTitles,
        'student_id': context.userId,
        'student_name': context.userName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('grouped_qrs')
          .insert(groupedQRData)
          .select()
          .single();

      print('🔍 DEBUG - QR agrupado guardado en Supabase: ${response['id']}');
      return response['id'].toString();
    } catch (e) {
      print('❌ Error guardando QR agrupado en Supabase: $e');
      rethrow;
    }
  }

  // Obtener todos los QRs agrupados del usuario
  static Future<List<GroupedQR>> getGroupedQRs() async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        return [];
      }

      final response = await _client
          .from('grouped_qrs')
          .select('*')
          .eq('student_id', context.userId)
          .order('created_at', ascending: false);

      final List<GroupedQR> qrs = response.map((data) => GroupedQR.fromSupabase(data)).toList();
      
      print('🔍 DEBUG - QRs agrupados encontrados en Supabase: ${qrs.length}');
      return qrs;
    } catch (e) {
      print('❌ Error obteniendo QRs agrupados de Supabase: $e');
      return [];
    }
  }

  // Eliminar QR agrupado
  static Future<void> deleteGroupedQR(String qrId) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el QR pertenece al usuario actual
      final response = await _client
          .from('grouped_qrs')
          .select('id')
          .eq('id', qrId)
          .eq('student_id', context.userId)
          .single();

      if (response.isEmpty) {
        throw Exception('QR agrupado no encontrado o no tienes permisos para eliminarlo');
      }

      await _client
          .from('grouped_qrs')
          .delete()
          .eq('id', qrId);

      print('🔍 DEBUG - QR agrupado eliminado de Supabase: $qrId');
    } catch (e) {
      print('❌ Error eliminando QR agrupado de Supabase: $e');
      rethrow;
    }
  }

  // Obtener QR por ID
  static Future<GroupedQR?> getGroupedQRById(String qrId) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        return null;
      }

      final response = await _client
          .from('grouped_qrs')
          .select('*')
          .eq('id', qrId)
          .eq('student_id', context.userId)
          .single();

      if (response.isNotEmpty) {
        return GroupedQR.fromSupabase(response);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo QR agrupado por ID de Supabase: $e');
      return null;
    }
  }

  // Actualizar QR agrupado
  static Future<void> updateGroupedQR({
    required String qrId,
    required String name,
    required String qrUrl,
    required List<String> certificateIds,
    required List<String> certificateTitles,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el QR pertenece al usuario actual
      final existingResponse = await _client
          .from('grouped_qrs')
          .select('id')
          .eq('id', qrId)
          .eq('student_id', context.userId)
          .single();

      if (existingResponse.isEmpty) {
        throw Exception('QR agrupado no encontrado o no tienes permisos para actualizarlo');
      }

      final updateData = {
        'name': name,
        'qr_url': qrUrl,
        'certificate_ids': certificateIds,
        'certificate_titles': certificateTitles,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('grouped_qrs')
          .update(updateData)
          .eq('id', qrId);

      print('🔍 DEBUG - QR agrupado actualizado en Supabase: $qrId');
    } catch (e) {
      print('❌ Error actualizando QR agrupado en Supabase: $e');
      rethrow;
    }
  }
}
