// lib/services/grouped_qr_service.dart
// Servicio para gestionar QRs agrupados guardados

import 'package:frontend_app/models/grouped_qr.dart';
import 'package:frontend_app/services/supabase/supabase_grouped_qr_service.dart';

class GroupedQRService {

  // Guardar QR agrupado
  static Future<void> saveGroupedQR({
    required String name,
    required String qrUrl,
    required List<String> certificateIds,
    required List<String> certificateTitles,
  }) async {
    try {
      // Usar Supabase como fuente principal
      await SupabaseGroupedQRService.saveGroupedQR(
        name: name,
        qrUrl: qrUrl,
        certificateIds: certificateIds,
        certificateTitles: certificateTitles,
      );
      
      print('🔍 DEBUG - QR guardado exitosamente en Supabase: $name');
      
    } catch (e) {
      print('❌ Error guardando QR agrupado: $e');
      throw Exception('Error guardando QR agrupado: $e');
    }
  }

  // Obtener todos los QRs agrupados del usuario
  static Future<List<GroupedQR>> getGroupedQRs() async {
    try {
      // Usar Supabase como fuente principal
      final qrs = await SupabaseGroupedQRService.getGroupedQRs();
      
      print('🔍 DEBUG - QRs encontrados en Supabase: ${qrs.length}');
      
      return qrs;
    } catch (e) {
      print('❌ Error obteniendo QRs agrupados: $e');
      return [];
    }
  }

  // Eliminar QR agrupado
  static Future<void> deleteGroupedQR(String qrId) async {
    try {
      // Usar Supabase como fuente principal
      await SupabaseGroupedQRService.deleteGroupedQR(qrId);
      
      print('🔍 DEBUG - QR eliminado de Supabase: $qrId');
      
    } catch (e) {
      print('❌ Error eliminando QR agrupado: $e');
      throw Exception('Error eliminando QR agrupado: $e');
    }
  }

  // Obtener QR por ID
  static Future<GroupedQR?> getGroupedQRById(String qrId) async {
    try {
      // Usar Supabase como fuente principal
      return await SupabaseGroupedQRService.getGroupedQRById(qrId);
    } catch (e) {
      print('❌ Error obteniendo QR por ID: $e');
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
      // Usar Supabase como fuente principal
      await SupabaseGroupedQRService.updateGroupedQR(
        qrId: qrId,
        name: name,
        qrUrl: qrUrl,
        certificateIds: certificateIds,
        certificateTitles: certificateTitles,
      );
      
      print('🔍 DEBUG - QR actualizado en Supabase: $qrId');
      
    } catch (e) {
      print('❌ Error actualizando QR agrupado: $e');
      throw Exception('Error actualizando QR agrupado: $e');
    }
  }
}
