// lib/screens/admin/blockchain_wallet_setup_screen.dart
// Pantalla para configurar la wallet blockchain (MetaMask)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/blockchain/blockchain_service.dart';
import '../../services/blockchain/blockchain_config.dart';
import '../../services/alert_service.dart';
import 'package:web3dart/web3dart.dart';

class BlockchainWalletSetupScreen extends StatefulWidget {
  @override
  _BlockchainWalletSetupScreenState createState() => _BlockchainWalletSetupScreenState();
}

class _BlockchainWalletSetupScreenState extends State<BlockchainWalletSetupScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePrivateKey = true;
  String? _currentWalletAddress;
  String? _currentBalance;

  @override
  void initState() {
    super.initState();
    _loadWalletInfo();
  }

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletInfo() async {
    setState(() => _isLoading = true);
    try {
      final blockchainService = BlockchainService();
      
      // Primero verificar si existe una wallet guardada
      final hasWallet = await blockchainService.hasWalletSaved();
      print('🔍 Wallet guardada: $hasWallet');
      
      if (hasWallet) {
        // Intentar obtener información de la wallet guardada
        final walletInfo = await blockchainService.getWalletInfo();
        if (walletInfo != null && walletInfo['address'] != null) {
          setState(() => _currentWalletAddress = walletInfo['address']);
          print('✅ Wallet encontrada: ${walletInfo['address']}');
        } else {
          // Si no se pudo obtener info, intentar con getCurrentWalletAddress
          final address = await blockchainService.getCurrentWalletAddress();
          if (address != null) {
            setState(() => _currentWalletAddress = address);
            print('✅ Wallet encontrada (método alternativo): $address');
          }
        }
      } else {
        print('⚠️ No hay wallet guardada');
        setState(() => _currentWalletAddress = null);
      }
      
      // Si tenemos dirección, intentar obtener balance
      if (_currentWalletAddress != null) {
        try {
          // Inicializar servicio si el contrato está configurado
          final contractAddress = BlockchainConfig.contractAddress;
          if (contractAddress != '0x0000000000000000000000000000000000000000') {
            await blockchainService.initialize(contractAddress);
            final balance = await blockchainService.getBalance();
            final balanceInEther = balance.getValueInUnit(EtherUnit.ether);
            setState(() => _currentBalance = balanceInEther.toStringAsFixed(6));
            print('✅ Balance obtenido: $_currentBalance MATIC');
          } else {
            print('⚠️ Contrato no configurado, no se puede obtener balance');
          }
        } catch (e) {
          print('⚠️ Error obteniendo balance: $e');
          // No es crítico, continuar sin balance
        }
      }
    } catch (e) {
      print('❌ Error cargando información de wallet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importWallet() async {
    if (_privateKeyController.text.trim().isEmpty) {
      AlertService.showWarning(
        context,
        'Campo Requerido',
        'Por favor ingresa la clave privada de MetaMask',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final blockchainService = BlockchainService();
      await blockchainService.saveWalletPrivateKey(_privateKeyController.text.trim());
      
      AlertService.showSuccess(
        context,
        'Wallet Configurada',
        'La wallet de MetaMask ha sido configurada exitosamente',
        onOk: () {
          _privateKeyController.clear();
          _loadWalletInfo();
        },
      );
    } catch (e) {
      print('❌ Error detallado al importar wallet: $e');
      AlertService.showError(
        context,
        'Error',
        'Error configurando wallet: ${e.toString()}\n\nVerifica:\n1. Que la clave privada tenga 64 caracteres\n2. Que estés logueado como Super Admin\n3. Revisa la consola para más detalles',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateNewWallet() async {
    AlertService.showConfirmation(
      context,
      'Generar Nueva Wallet',
      'Se generará una nueva wallet. Si ya tienes una configurada, será reemplazada. ¿Continuar?',
      confirmText: 'Generar',
      cancelText: 'Cancelar',
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          final blockchainService = BlockchainService();
          final wallet = await blockchainService.generateNewWallet();
          final address = wallet['address'];
          final privateKey = wallet['privateKey'];
          
          AlertService.showSuccess(
            context,
            'Wallet Generada',
            'Nueva wallet generada exitosamente.\n\nDirección: $address\n\n⚠️ IMPORTANTE: Guarda la clave privada de forma segura. Necesitas enviar MATIC a esta dirección para poder emitir certificados.',
            onOk: () {
              _privateKeyController.text = privateKey ?? '';
              _loadWalletInfo();
            },
          );
        } catch (e) {
          AlertService.showError(
            context,
            'Error',
            'Error generando wallet: $e',
          );
        } finally {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AlertService.showInfo(
      context,
      'Copiado',
      '$label copiado al portapapeles',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de Wallet Blockchain'),
        backgroundColor: Color(0xff6C4DDC),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff6C4DDC).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWeb ? 40 : 20),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la red
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Información de Red',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow('Red', BlockchainConfig.useTestnet ? 'Mumbai Testnet' : 'Polygon Mainnet'),
                          _buildInfoRow('RPC', BlockchainConfig.rpcUrl),
                          _buildInfoRow('Chain ID', BlockchainConfig.chainId.toString()),
                          _buildInfoRow('Contrato', BlockchainConfig.contractAddress),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Wallet actual
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Color(0xff6C4DDC)),
                              SizedBox(width: 12),
                              Text(
                                'Wallet Actual',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          if (_isLoading)
                            Center(child: CircularProgressIndicator())
                          else if (_currentWalletAddress != null) ...[
                            _buildInfoRow('Dirección', _currentWalletAddress!),
                            if (_currentBalance != null)
                              _buildInfoRow('Balance', '$_currentBalance MATIC'),
                            if (_currentBalance == null || (double.tryParse(_currentBalance ?? '0') ?? 0) < 0.01)
                              Container(
                                margin: EdgeInsets.only(top: 12),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Balance insuficiente. Envía MATIC a esta dirección para poder emitir certificados.',
                                        style: TextStyle(color: Colors.orange[900]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _copyToClipboard(_currentWalletAddress!, 'Dirección'),
                                    icon: Icon(Icons.copy, size: 18),
                                    label: Text('Copiar Dirección'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _loadWalletInfo,
                                    icon: Icon(Icons.refresh, size: 18),
                                    label: Text('Actualizar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No hay wallet configurada',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Configura una wallet usando las opciones de abajo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Configurar wallet
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Color(0xff6C4DDC)),
                              SizedBox(width: 12),
                              Text(
                                'Configurar Wallet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          // Opción 1: Importar desde MetaMask
                          Text(
                            'Opción 1: Importar desde MetaMask',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Abre MetaMask\n2. Settings > Security > Export Private Key\n3. Copia la clave privada\n4. Pégala abajo',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: _privateKeyController,
                            obscureText: _obscurePrivateKey,
                            decoration: InputDecoration(
                              labelText: 'Clave Privada de MetaMask',
                              hintText: '0x...',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePrivateKey ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() => _obscurePrivateKey = !_obscurePrivateKey);
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _importWallet,
                              icon: Icon(Icons.import_export),
                              label: Text('Importar Wallet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff6C4DDC),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Opción 2: Generar nueva
                          Text(
                            'Opción 2: Generar Nueva Wallet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Se generará una nueva wallet. Luego necesitarás enviar MATIC a esa dirección.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _generateNewWallet,
                              icon: Icon(Icons.add_circle_outline),
                              label: Text('Generar Nueva Wallet'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xff6C4DDC),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Advertencia de seguridad
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠️ ADVERTENCIA DE SEGURIDAD',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[900],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• NUNCA compartas tu clave privada\n'
                                '• NUNCA la subas a GitHub\n'
                                '• SIEMPRE guárdala de forma segura\n'
                                '• Si pierdes la clave, pierdes acceso a los fondos',
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

