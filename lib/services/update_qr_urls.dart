// lib/services/update_qr_urls.dart
// Script para actualizar URLs de QR en certificados existentes

import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateQRUrls {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'certificates';

  // Actualizar todas las URLs de QR de certificados existentes
  static Future<void> updateAllQRUrls() async {
    try {
      print('🔄 Actualizando URLs de QR en certificados existentes...');
      
      // Obtener todos los certificados
      final querySnapshot = await _firestore.collection(_collection).get();
      
      print('📋 Encontrados ${querySnapshot.docs.length} certificados');
      
      int updatedCount = 0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final certificateId = doc.id;
        
        // Generar nueva URL de QR
        final newQRUrl = 'http://localhost:8081/#/verify/certificate/$certificateId';
        
        // Actualizar solo si la URL es diferente
        if (data['qrCode'] != newQRUrl) {
          await doc.reference.update({
            'qrCode': newQRUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          updatedCount++;
          print('✅ Actualizado certificado: $certificateId');
        }
      }
      
      print('🎉 Actualización completada: $updatedCount certificados actualizados');
      
    } catch (e) {
      print('❌ Error actualizando URLs de QR: $e');
    }
  }
}
