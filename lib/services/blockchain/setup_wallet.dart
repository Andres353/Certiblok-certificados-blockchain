// lib/services/blockchain/setup_wallet.dart
// Utilidad para configurar la wallet blockchain

import 'package:flutter/material.dart';
import 'blockchain_service.dart';
import 'blockchain_config.dart';
import '../alert_service.dart';

class BlockchainWalletSetup {
  /// Configurar wallet automáticamente
  /// Genera una nueva wallet y la guarda
  static Future<Map<String, String>?> setupWallet(BuildContext context) async {
    try {
      final blockchainService = BlockchainService();
      
      // Generar nueva wallet
      final wallet = await blockchainService.generateNewWallet();
      
      final address = wallet['address']!;
      
      print('✅ Wallet generada exitosamente');
      print('   Dirección: $address');
      print('   ⚠️ IMPORTANTE: La clave privada se guardó automáticamente');
      
      // Mostrar alerta con información
      AlertService.showSuccess(
        context,
        'Wallet Configurada',
        'Wallet generada exitosamente.\n\nDirección: ${address.substring(0, 10)}...\n\nIMPORTANTE: Necesitas enviar MATIC a esta dirección desde MetaMask para poder emitir certificados en blockchain.',
      );
      
      return wallet;
    } catch (e) {
      print('❌ Error generando wallet: $e');
      AlertService.showError(
        context,
        'Error',
        'Error generando wallet: $e',
      );
      return null;
    }
  }
  
  /// Verificar si hay wallet configurada
  static Future<bool> hasWallet() async {
    try {
      final blockchainService = BlockchainService();
      final address = await blockchainService.getCurrentWalletAddress();
      return address != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Obtener dirección de la wallet actual
  static Future<String?> getWalletAddress() async {
    try {
      final blockchainService = BlockchainService();
      return await blockchainService.getCurrentWalletAddress();
    } catch (e) {
      return null;
    }
  }
  
  /// Verificar balance de la wallet
  static Future<String?> checkBalance() async {
    try {
      final blockchainService = BlockchainService();
      // Inicializar el servicio primero
      await blockchainService.initialize(BlockchainConfig.contractAddress);
      
      final balance = await blockchainService.getBalance();
      // Convertir de wei a ether manualmente
      final balanceInEther = balance.getInWei / BigInt.from(10).pow(18);
      return balanceInEther.toStringAsFixed(6);
    } catch (e) {
      return null;
    }
  }
  
  /// Importar wallet desde clave privada
  static Future<bool> importWallet(String privateKey) async {
    try {
      final blockchainService = BlockchainService();
      await blockchainService.saveWalletPrivateKey(privateKey);
      print('✅ Wallet importada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error importando wallet: $e');
      return false;
    }
  }
}

