// lib/services/supabase/test_grouped_qr_service.dart
// Script de prueba para el servicio de QRs agrupados

import 'package:frontend_app/services/supabase/supabase_grouped_qr_service.dart';
import 'package:frontend_app/services/user_context_service.dart';

class TestGroupedQRService {
  static Future<void> runTests() async {
    print('🧪 Iniciando pruebas del servicio de QRs agrupados...');
    
    try {
      // Simular contexto de usuario (esto debería estar configurado en la app real)
      final testContext = UserContext(
        userId: 'test-user-id',
        userName: 'Usuario de Prueba',
        userEmail: 'test@example.com',
        userRole: 'student',
        institutionId: 'test-institution-id',
        institutionName: 'Institución de Prueba',
        mustChangePassword: false,
        isTemporaryPassword: false,
      );
      
      await UserContextService.setUserContext(testContext);
      
      // Test 1: Guardar QR agrupado
      print('📝 Test 1: Guardando QR agrupado...');
      final qrId = await SupabaseGroupedQRService.saveGroupedQR(
        name: 'QR de Prueba',
        qrUrl: 'http://localhost:8081/#/verify/certificates/cert1,cert2,cert3',
        certificateIds: ['cert1', 'cert2', 'cert3'],
        certificateTitles: ['Certificado 1', 'Certificado 2', 'Certificado 3'],
      );
      print('✅ QR guardado con ID: $qrId');
      
      // Test 2: Obtener QRs agrupados
      print('📝 Test 2: Obteniendo QRs agrupados...');
      final qrs = await SupabaseGroupedQRService.getGroupedQRs();
      print('✅ QRs obtenidos: ${qrs.length}');
      
      // Test 3: Obtener QR por ID
      print('📝 Test 3: Obteniendo QR por ID...');
      final qr = await SupabaseGroupedQRService.getGroupedQRById(qrId);
      if (qr != null) {
        print('✅ QR encontrado: ${qr.name}');
      } else {
        print('❌ QR no encontrado');
      }
      
      // Test 4: Actualizar QR
      print('📝 Test 4: Actualizando QR...');
      await SupabaseGroupedQRService.updateGroupedQR(
        qrId: qrId,
        name: 'QR de Prueba Actualizado',
        qrUrl: 'http://localhost:8081/#/verify/certificates/cert1,cert2,cert3,cert4',
        certificateIds: ['cert1', 'cert2', 'cert3', 'cert4'],
        certificateTitles: ['Certificado 1', 'Certificado 2', 'Certificado 3', 'Certificado 4'],
      );
      print('✅ QR actualizado');
      
      // Test 5: Eliminar QR
      print('📝 Test 5: Eliminando QR...');
      await SupabaseGroupedQRService.deleteGroupedQR(qrId);
      print('✅ QR eliminado');
      
      print('🎉 Todas las pruebas completadas exitosamente!');
      
    } catch (e) {
      print('❌ Error en las pruebas: $e');
    }
  }
}
