// lib/services/blockchain/blockchain_service.dart
// Servicio para interactuar con blockchain (Polygon) para certificados

import 'dart:convert';
import 'dart:math';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blockchain_config.dart';
import '../supabase/supabase_config.dart';
import '../user_context_service.dart';

class BlockchainService {
  // Usar configuración centralizada
  static bool get useTestnet => BlockchainConfig.useTestnet;
  static String get rpcUrl => BlockchainConfig.rpcUrl;
  static int get chainId => BlockchainConfig.chainId;
  
  late Web3Client _client;
  late EthereumAddress _contractAddress;
  late DeployedContract _contract;
  late ContractFunction _issueCertificateFunction;
  late ContractFunction _verifyCertificateFunction;
  late ContractFunction _getCertificateFunction;
  late ContractFunction _revokeCertificateFunction;
  late ContractFunction _getTotalCertificatesFunction;
  
  // ABI del contrato (simplificado, debe coincidir con el contrato)
  static const String contractABI = '''
  [
    {
      "inputs": [
        {"internalType": "string", "name": "_certificateId", "type": "string"},
        {"internalType": "string", "name": "_studentId", "type": "string"},
        {"internalType": "string", "name": "_institutionId", "type": "string"},
        {"internalType": "string", "name": "_certificateHash", "type": "string"}
      ],
      "name": "issueCertificate",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string", "name": "_certificateHash", "type": "string"}],
      "name": "verifyCertificate",
      "outputs": [
        {"internalType": "bool", "name": "exists", "type": "bool"},
        {"internalType": "bool", "name": "revoked", "type": "bool"},
        {"internalType": "string", "name": "certificateId", "type": "string"},
        {"internalType": "uint256", "name": "issuedAt", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string", "name": "_certificateHash", "type": "string"}],
      "name": "getCertificate",
      "outputs": [
        {
          "components": [
            {"internalType": "string", "name": "certificateId", "type": "string"},
            {"internalType": "string", "name": "studentId", "type": "string"},
            {"internalType": "string", "name": "institutionId", "type": "string"},
            {"internalType": "string", "name": "certificateHash", "type": "string"},
            {"internalType": "uint256", "name": "issuedAt", "type": "uint256"},
            {"internalType": "address", "name": "issuedBy", "type": "address"},
            {"internalType": "bool", "name": "revoked", "type": "bool"}
          ],
          "internalType": "struct CertificateRegistry.Certificate",
          "name": "",
          "type": "tuple"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string", "name": "", "type": "string"}],
      "name": "certificateExists",
      "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string", "name": "_certificateHash", "type": "string"}],
      "name": "revokeCertificate",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getTotalCertificates",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';
  
  static BlockchainService? _instance;
  
  BlockchainService._internal();
  
  factory BlockchainService() {
    _instance ??= BlockchainService._internal();
    return _instance!;
  }
  
  /// Inicializar el servicio blockchain
  /// @param contractAddress Dirección del contrato desplegado
  Future<void> initialize(String contractAddress) async {
    try {
      _client = Web3Client(rpcUrl, Client());
      _contractAddress = EthereumAddress.fromHex(contractAddress);
      
      // Cargar el contrato
      final abi = jsonDecode(contractABI) as List<dynamic>;
      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(abi), 'CertificateRegistry'),
        _contractAddress,
      );
      
      // Obtener funciones del contrato
      _issueCertificateFunction = _contract.function('issueCertificate');
      _verifyCertificateFunction = _contract.function('verifyCertificate');
      _getCertificateFunction = _contract.function('getCertificate');
      _revokeCertificateFunction = _contract.function('revokeCertificate');
      _getTotalCertificatesFunction = _contract.function('getTotalCertificates');
      
      print('✅ BlockchainService inicializado correctamente');
      print('   Red: ${BlockchainConfig.useTestnet ? "Mumbai Testnet" : "Polygon Mainnet"}');
      print('   RPC: ${BlockchainConfig.rpcUrl}');
      print('   Chain ID: ${BlockchainConfig.chainId}');
      print('   Contrato: $contractAddress');
      print('   Explorador: ${BlockchainConfig.explorerUrl}');
    } catch (e) {
      print('❌ Error inicializando BlockchainService: $e');
      rethrow;
    }
  }
  
  /// Generar hash único del certificado
  static String generateCertificateHash({
    required String certificateId,
    required String studentId,
    required String institutionId,
    required DateTime issuedAt,
  }) {
    final data = '$certificateId|$studentId|$institutionId|${issuedAt.toIso8601String()}';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    final hashString = hash.toString();
    
    // Asegurar que el hash tenga exactamente 64 caracteres (SHA-256 siempre produce 64 caracteres hex)
    // Si por alguna razón tiene más, recortar; si tiene menos, es un error
    if (hashString.length > 64) {
      print('⚠️ ADVERTENCIA: Hash SHA-256 tiene ${hashString.length} caracteres, recortando a 64');
      return hashString.substring(0, 64);
    } else if (hashString.length < 64) {
      throw Exception('ERROR CRÍTICO: Hash SHA-256 tiene solo ${hashString.length} caracteres. Debe tener 64.');
    }
    
    // Validar que solo contenga caracteres hexadecimales
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hashString)) {
      throw Exception('ERROR CRÍTICO: Hash contiene caracteres no hexadecimales: $hashString');
    }
    
    print('✅ Hash generado correctamente: ${hashString.length} caracteres');
    return hashString;
  }
  
  /// Obtener la wallet privada (guardada en Supabase)
  /// Este método SIEMPRE intenta obtener desde Supabase primero, sin depender del usuario actual
  Future<Credentials?> getWalletCredentials() async {
    try {
      final supabase = SupabaseConfig.client;
      final network = BlockchainConfig.useTestnet ? 'polygon_testnet' : 'polygon_mainnet';
      
      print('🔍 Buscando wallet en Supabase para red: $network');
      
      // Obtener la configuración activa de blockchain desde Supabase
      // NO depende del usuario actual, busca cualquier configuración activa
      final response = await supabase
          .from('system_blockchain_config')
          .select('blockchain_private_key_encrypted, blockchain_wallet_address, configured_at')
          .eq('is_active', true)
          .eq('blockchain_network', network)
          .order('configured_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null || response.isEmpty) {
        print('⚠️ No se encontró wallet privada activa en Supabase para la red: $network');
        print('   Intentando buscar en SharedPreferences como fallback...');
        // Fallback a SharedPreferences para compatibilidad
        return await _getWalletFromSharedPreferences();
      }
      
      final privateKeyHex = response['blockchain_private_key_encrypted'] as String?;
      
      if (privateKeyHex == null || privateKeyHex.isEmpty) {
        print('⚠️ Clave privada vacía en Supabase');
        print('   Intentando buscar en SharedPreferences como fallback...');
        return await _getWalletFromSharedPreferences();
      }
      
      // Remover el prefijo "0x" si existe y espacios
      String cleanKey = privateKeyHex.trim();
      if (cleanKey.startsWith('0x')) {
        cleanKey = cleanKey.substring(2);
      }
      
      // Validar que la clave tenga exactamente 64 caracteres (32 bytes en hex)
      if (cleanKey.length != 64) {
        print('❌ Clave privada inválida: tiene ${cleanKey.length} caracteres, debe tener 64');
        print('   Intentando buscar en SharedPreferences como fallback...');
        return await _getWalletFromSharedPreferences();
      }
      
      // Validar que sea hexadecimal válido
      if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(cleanKey)) {
        print('❌ Clave privada contiene caracteres inválidos');
        print('   Intentando buscar en SharedPreferences como fallback...');
        return await _getWalletFromSharedPreferences();
      }
      
      // Intentar crear la clave privada
      final privateKey = EthPrivateKey.fromHex(cleanKey);
      
      // Verificar que la dirección coincida con la guardada
      final savedAddress = response['blockchain_wallet_address'] as String?;
      if (savedAddress != null) {
        final currentAddress = await privateKey.extractAddress();
        if (currentAddress.hex.toLowerCase() != savedAddress.toLowerCase()) {
          print('⚠️ La dirección de la wallet no coincide con la guardada');
          print('   Guardada: $savedAddress');
          print('   Actual: ${currentAddress.hex}');
          print('   Usando la dirección calculada de la clave privada...');
        }
      }
      
      final configuredAt = response['configured_at'] as String?;
      print('✅ Wallet privada cargada correctamente desde Supabase');
      print('   Dirección: ${savedAddress ?? 'N/A'}');
      print('   Red: $network');
      print('   Configurada en: ${configuredAt ?? 'N/A'}');
      return privateKey;
    } catch (e) {
      print('❌ Error obteniendo credenciales desde Supabase: $e');
      print('   Detalles del error: ${e.toString()}');
      print('   Intentando buscar en SharedPreferences como fallback...');
      // Fallback a SharedPreferences para compatibilidad
      return await _getWalletFromSharedPreferences();
    }
  }
  
  /// Fallback: Obtener wallet desde SharedPreferences (compatibilidad)
  Future<Credentials?> _getWalletFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final privateKeyHex = prefs.getString('blockchain_private_key');
      
      if (privateKeyHex == null || privateKeyHex.isEmpty) {
        return null;
      }
      
      String cleanKey = privateKeyHex.trim();
      if (cleanKey.startsWith('0x')) {
        cleanKey = cleanKey.substring(2);
      }
      
      if (cleanKey.length != 64 || !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(cleanKey)) {
        return null;
      }
      
      return EthPrivateKey.fromHex(cleanKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Guardar wallet privada (persistente en Supabase)
  Future<void> saveWalletPrivateKey(String privateKeyHex) async {
    // Limpiar la clave antes de guardar
    String cleanKey = privateKeyHex.trim();
    if (cleanKey.startsWith('0x')) {
      cleanKey = cleanKey.substring(2);
    }
    
    // Validar formato antes de guardar
    if (cleanKey.length != 64) {
      throw Exception('La clave privada debe tener exactamente 64 caracteres hexadecimales');
    }
    
    // Validar que sea hexadecimal válido
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(cleanKey)) {
      throw Exception('La clave privada contiene caracteres inválidos');
    }
    
    // Obtener la dirección de la wallet
    final tempKey = EthPrivateKey.fromHex(cleanKey);
    final address = await tempKey.extractAddress();
    final addressHex = address.hex;
    
    // SIEMPRE guardar en SharedPreferences primero (para persistencia inmediata)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('blockchain_private_key', cleanKey);
      await prefs.setString('blockchain_wallet_address', addressHex);
      await prefs.reload();
      print('✅ Wallet guardada en SharedPreferences');
    } catch (e) {
      print('❌ Error guardando en SharedPreferences: $e');
      throw Exception('Error guardando wallet: $e');
    }
    
    // SIEMPRE intentar guardar en Supabase (importante para persistencia)
    // Esto permite que cualquier usuario (admin, emisor) pueda usar la wallet
    try {
      final context = UserContextService.currentContext;
      final userId = context?.userId ?? 'system';
      final userName = context?.userName ?? 'Sistema';
      final network = BlockchainConfig.useTestnet ? 'polygon_testnet' : 'polygon_mainnet';
      
      // Guardar en Supabase
      final supabase = SupabaseConfig.client;
      
      try {
        // Primero, desactivar cualquier configuración activa de la misma red
        await supabase
            .from('system_blockchain_config')
            .update({'is_active': false})
            .eq('blockchain_network', network)
            .eq('is_active', true);
        
        // Insertar nueva configuración activa
        await supabase
            .from('system_blockchain_config')
            .insert({
              'blockchain_private_key_encrypted': cleanKey,
              'blockchain_wallet_address': addressHex,
              'blockchain_network': network,
              'configured_by': userId,
              'configured_by_name': userName,
              'is_active': true,
            });
        
        print('✅ Wallet privada guardada correctamente en Supabase');
        print('   Dirección: $addressHex');
        print('   Red: $network');
        print('   Configurado por: $userName ($userId)');
        print('   ✅ Ahora cualquier usuario (admin, emisor) puede emitir certificados');
      } catch (supabaseError) {
        // Si falla Supabase, es crítico pero no bloqueamos porque ya está en SharedPreferences
        print('❌ ERROR CRÍTICO: No se pudo guardar en Supabase: $supabaseError');
        print('   La wallet se guardó en SharedPreferences como backup');
        print('   ⚠️ IMPORTANTE: Sin Supabase, solo funcionará en este dispositivo');
        print('   Verifica que la tabla system_blockchain_config exista en Supabase');
        // No lanzamos excepción porque ya está guardado en SharedPreferences
      }
    } catch (e) {
      // Si falla Supabase, es crítico pero no bloqueamos porque ya está en SharedPreferences
      print('❌ ERROR CRÍTICO guardando en Supabase: $e');
      print('   La wallet se guardó en SharedPreferences como backup');
      print('   ⚠️ IMPORTANTE: Sin Supabase, solo funcionará en este dispositivo');
      // No lanzamos excepción porque ya está guardado en SharedPreferences
    }
  }
  
  /// Limpiar wallet guardada (útil si está corrupta)
  Future<void> clearWallet() async {
    try {
      // Verificar que el usuario sea super_admin
      final context = UserContextService.currentContext;
      if (context == null || !context.isSuperAdmin) {
        throw Exception('Solo el Super Admin puede limpiar la wallet blockchain');
      }
      
      final supabase = SupabaseConfig.client;
      final network = BlockchainConfig.useTestnet ? 'polygon_testnet' : 'polygon_mainnet';
      
      // Desactivar configuración activa
      await supabase
          .from('system_blockchain_config')
          .update({'is_active': false})
          .eq('blockchain_network', network)
          .eq('is_active', true);
      
      // También limpiar SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('blockchain_private_key');
        await prefs.remove('blockchain_wallet_address');
        await prefs.reload();
      } catch (e) {
        print('⚠️ Error limpiando SharedPreferences: $e');
      }
      
      print('✅ Wallet limpiada correctamente');
    } catch (e) {
      print('❌ Error limpiando wallet: $e');
      rethrow;
    }
  }
  
  /// Verificar si existe una wallet guardada
  Future<bool> hasWalletSaved() async {
    try {
      final supabase = SupabaseConfig.client;
      final network = BlockchainConfig.useTestnet ? 'polygon_testnet' : 'polygon_mainnet';
      
      final response = await supabase
          .from('system_blockchain_config')
          .select('id')
          .eq('is_active', true)
          .eq('blockchain_network', network)
          .limit(1)
          .maybeSingle();
      
      if (response != null && response.isNotEmpty) {
        return true;
      }
      
      // Fallback a SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final privateKeyHex = prefs.getString('blockchain_private_key');
      return privateKeyHex != null && privateKeyHex.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Obtener información de la wallet guardada (sin exponer la clave privada)
  Future<Map<String, String>?> getWalletInfo() async {
    try {
      final supabase = SupabaseConfig.client;
      final network = BlockchainConfig.useTestnet ? 'polygon_testnet' : 'polygon_mainnet';
      
      final response = await supabase
          .from('system_blockchain_config')
          .select('blockchain_wallet_address, configured_by_name, configured_at')
          .eq('is_active', true)
          .eq('blockchain_network', network)
          .order('configured_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response != null && response.isNotEmpty) {
        return {
          'address': response['blockchain_wallet_address'] as String,
          'configured_by': response['configured_by_name'] as String? ?? 'Super Admin',
          'configured_at': response['configured_at'] as String? ?? '',
        };
      }
      
      // Fallback a SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final address = prefs.getString('blockchain_wallet_address');
      
      if (address != null) {
        return {
          'address': address,
          'configured_by': 'Sistema',
          'configured_at': '',
        };
      }
      
      // Intentar obtener desde la clave privada
      final credentials = await getWalletCredentials();
      if (credentials != null) {
        final currentAddress = await credentials.extractAddress();
        await prefs.setString('blockchain_wallet_address', currentAddress.hex);
        return {
          'address': currentAddress.hex,
          'configured_by': 'Sistema',
          'configured_at': '',
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo información de wallet: $e');
      return null;
    }
  }
  
  /// Obtener o generar wallet automáticamente
  Future<Credentials> getOrCreateWalletCredentials({bool forceNew = false}) async {
    try {
      // Si no se fuerza nueva wallet, intentar obtener existente
      if (!forceNew) {
        final existing = await getWalletCredentials();
        if (existing != null) {
          print('✅ Usando wallet existente guardada');
          return existing;
        }
      } else {
        print('⚠️ Forzando generación de nueva wallet...');
        await clearWallet();
      }
      
      // Verificar una vez más si existe (por si se guardó entre llamadas)
      if (!forceNew) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final hasSaved = await hasWalletSaved();
        if (hasSaved) {
          final existing = await getWalletCredentials();
          if (existing != null) {
            print('✅ Wallet encontrada después de recargar');
            return existing;
          }
        }
      }
      
      // Si no existe, generar nueva
      print('⚠️ No hay wallet configurada, generando nueva...');
      final wallet = await generateNewWallet();
      print('✅ Nueva wallet generada: ${wallet['address']}');
      print('⚠️ IMPORTANTE: Esta wallet se guardó permanentemente.');
      print('   Dirección: ${wallet['address']}');
      print('   Envía MATIC a esta dirección desde MetaMask.');
      
      // Obtener credenciales de la nueva wallet
      final credentials = await getWalletCredentials();
      if (credentials == null) {
        throw Exception('Error generando wallet: no se pudo cargar después de guardar');
      }
      
      // Verificar que se guardó correctamente
      final savedAddress = await getCurrentWalletAddress();
      if (savedAddress != wallet['address']) {
        print('⚠️ Advertencia: La dirección guardada no coincide');
      }
      
      return credentials;
    } catch (e) {
      print('❌ Error obteniendo/creando wallet: $e');
      rethrow;
    }
  }
  
  /// Generar nueva wallet
  Future<Map<String, String>> generateNewWallet() async {
    try {
      final credentials = EthPrivateKey.createRandom(Random.secure());
      final address = await credentials.extractAddress();
      final privateKey = credentials.privateKey;
      
      // Convertir a hexadecimal correctamente (64 caracteres, sin 0x)
      final privateKeyHex = privateKey.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      
      // Guardar la wallet
      await saveWalletPrivateKey(privateKeyHex);
      
      return {
        'address': address.hex,
        'privateKey': privateKeyHex,
      };
    } catch (e) {
      print('❌ Error generando wallet: $e');
      rethrow;
    }
  }
  
  /// Obtener dirección de la wallet actual
  Future<String?> getCurrentWalletAddress() async {
    try {
      final credentials = await getWalletCredentials();
      if (credentials == null) return null;
      
      final address = await credentials.extractAddress();
      return address.hex;
    } catch (e) {
      print('❌ Error obteniendo dirección: $e');
      return null;
    }
  }
  
  /// Obtener balance de MATIC de la wallet
  Future<EtherAmount> getBalance() async {
    try {
      final credentials = await getWalletCredentials();
      if (credentials == null) {
        throw Exception('No hay wallet configurada');
      }
      
      final address = await credentials.extractAddress();
      final balance = await _client.getBalance(address);
      return balance;
    } catch (e) {
      print('❌ Error obteniendo balance: $e');
      rethrow;
    }
  }
  
  /// Emitir certificado en la blockchain
  Future<String> issueCertificate({
    required String certificateId,
    required String studentId,
    required String institutionId,
    required String certificateHash,
  }) async {
    try {
      // Obtener o crear wallet automáticamente
      final credentials = await getOrCreateWalletCredentials();
      
      // Verificar balance
      final balance = await getBalance();
      if (balance.getInWei < EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(10000000000000000)).getInWei) {
        throw Exception('Balance insuficiente. Necesitas al menos 0.01 MATIC para emitir certificados.');
      }
      
      // Obtener el nonce actual de la cuenta para evitar conflictos
      final address = await credentials.extractAddress();
      final nonce = await _client.getTransactionCount(address);
      
      // Obtener el gas price actual de la red y usar un 20% más para asegurar que se procese
      int gasPriceGwei = 50; // Valor base más alto
      try {
        final gasPrice = await _client.getGasPrice();
        // Convertir de wei a gwei: 1 gwei = 10^9 wei
        final gasPriceInWei = gasPrice.getInWei;
        final currentGasPriceGwei = (gasPriceInWei / BigInt.from(1000000000)).toInt();
        // Usar el mayor entre el gas price actual + 20% o 50 gwei mínimo
        gasPriceGwei = (currentGasPriceGwei * 1.2).round();
        if (gasPriceGwei < 50) gasPriceGwei = 50; // Mínimo 50 gwei
        print('💰 Gas price actual de la red: ${currentGasPriceGwei} gwei, usando: $gasPriceGwei gwei');
      } catch (e) {
        print('⚠️ No se pudo obtener gas price de la red, usando valor por defecto: $gasPriceGwei gwei');
      }
      
      // Llamar a la función del contrato
      final transaction = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: _issueCertificateFunction,
          parameters: [
            certificateId,
            studentId,
            institutionId,
            certificateHash,
          ],
          gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, BigInt.from(gasPriceGwei)),
          maxGas: 200000, // Gas limit
          nonce: nonce, // Usar el nonce actual
        ),
        chainId: chainId,
        fetchChainIdFromNetworkId: false,
      );
      
      // Limpiar el hash de transacción (eliminar espacios, saltos de línea, etc.)
      final cleanTransactionHash = transaction.toString().trim().replaceAll(RegExp(r'\s+'), '');
      
      print('✅ Certificado emitido en blockchain');
      print('   Hash de transacción: $cleanTransactionHash');
      print('   Verifica en: ${BlockchainConfig.explorerUrl}/tx/$cleanTransactionHash');
      
      return cleanTransactionHash;
    } catch (e) {
      print('❌ Error emitiendo certificado en blockchain: $e');
      rethrow;
    }
  }
  
  /// Verificar certificado en la blockchain
  Future<Map<String, dynamic>> verifyCertificate(String certificateHash) async {
    try {
      // Validar y limpiar el hash
      String cleanHash = certificateHash.trim();
      
      // Remover 0x si existe (no debería estar en el hash del certificado)
      if (cleanHash.startsWith('0x')) {
        cleanHash = cleanHash.substring(2);
        print('⚠️ Hash tenía prefijo 0x, removido: $cleanHash');
      }
      
      // Normalizar el hash a exactamente 64 caracteres
      if (cleanHash.length > 64) {
        print('⚠️ ADVERTENCIA: Hash tiene ${cleanHash.length} caracteres, recortando a 64');
        cleanHash = cleanHash.substring(0, 64);
      } else if (cleanHash.length < 64) {
        throw Exception('Hash inválido: debe tener 64 caracteres hexadecimales. Longitud actual: ${cleanHash.length}');
      }
      
      // Validar que solo contenga caracteres hexadecimales
      if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(cleanHash)) {
        throw Exception('Hash inválido: debe contener solo caracteres hexadecimales (0-9, a-f, A-F). Hash recibido: $cleanHash');
      }
      
      print('🔍 Verificando certificado con hash: $cleanHash');
      print('   Longitud: ${cleanHash.length} caracteres');
      print('   Tipo: ${cleanHash.runtimeType}');
      print('   Primeros 10 caracteres: ${cleanHash.substring(0, 10)}...');
      print('   Últimos 10 caracteres: ...${cleanHash.substring(cleanHash.length - 10)}');
      
      print('🔍 Llamando a verifyCertificate con hash: $cleanHash');
      print('   Tipo del hash antes de pasar: ${cleanHash.runtimeType}');
      
      // Intentar usar getCertificate primero para verificar si el problema es específico de verifyCertificate
      // Si getCertificate funciona, entonces el problema está en verifyCertificate
      print('🔍 Intentando usar getCertificate primero...');
      final certData = await getCertificate(cleanHash);
      if (certData != null) {
        print('✅ getCertificate funcionó, el certificado existe');
        return {
          'exists': true,
          'revoked': certData['revoked'] as bool,
          'certificateId': certData['certificateId'] as String,
          'issuedAt': certData['issuedAt'] as int,
          'valid': !(certData['revoked'] as bool),
        };
      }
      
      // Si getCertificate retornó null, intentar verifyCertificate
      print('⚠️ getCertificate retornó null, intentando verifyCertificate...');
      
      // El problema puede ser que web3dart está interpretando strings de 64 caracteres hex como bytes32
      // Solución: agregar un prefijo al hash para evitar que se interprete como bytes32
      // El contrato Solidity puede manejar el string con prefijo y seguir funcionando correctamente
      // ya que compara el string completo, no solo los últimos 64 caracteres
      final hashWithPrefix = 'cert_$cleanHash';
      
      print('   Hash con prefijo para evitar interpretación como bytes32: $hashWithPrefix');
      print('   Longitud del hash con prefijo: ${hashWithPrefix.length}');
      
      // NOTA: Esta solución requiere que el contrato también use el prefijo al guardar/verificar
      // Si el contrato no tiene el prefijo, esto no funcionará
      // Alternativa: usar el hash sin prefijo pero forzar que se codifique como string UTF-8
      final hashAsUtf8String = cleanHash; // Usar el hash original sin prefijo
      
      print('   Usando hash original: $hashAsUtf8String');
      
      // PROBLEMA CONOCIDO: web3dart tiene un bug al codificar strings de 64 caracteres hexadecimales
      // como parámetros en llamadas call(). El error "Invalid typed array length: 32" ocurre porque
      // web3dart intenta interpretar el string como bytes32.
      // 
      // SOLUCIÓN TEMPORAL: Usar certificateExists que es un mapping público y puede funcionar mejor
      print('⚠️ Usando workaround para evitar bug de web3dart con strings de 64 caracteres...');
      
      // Intentar usar certificateExists primero (mapping público, puede funcionar mejor)
      try {
        final existsResult = await _client.call(
          contract: _contract,
          function: _contract.function('certificateExists'),
          params: [hashAsUtf8String],
        );
        
        final exists = existsResult[0] as bool;
        if (!exists) {
          return {
            'exists': false,
            'revoked': false,
            'valid': false,
          };
        }
        
        print('✅ certificateExists funcionó, el certificado existe');
        // Si existe, intentar obtener más información usando getCertificate
        // (aunque también puede fallar con el mismo error)
      } catch (e) {
        print('⚠️ certificateExists también falló: $e');
      }
      
      // Intentar verifyCertificate (puede fallar con el mismo error)
      final result = await _client.call(
        contract: _contract,
        function: _verifyCertificateFunction,
        params: [hashAsUtf8String],
      );
      
      final exists = result[0] as bool;
      final revoked = result[1] as bool;
      final certificateId = result[2] as String;
      final issuedAt = (result[3] as BigInt).toInt();
      
      return {
        'exists': exists,
        'revoked': revoked,
        'certificateId': certificateId,
        'issuedAt': issuedAt,
        'valid': exists && !revoked,
      };
    } catch (e) {
      print('❌ Error verificando certificado: $e');
      print('   Hash recibido: ${certificateHash.length} caracteres');
      print('   Hash (primeros 20): ${certificateHash.substring(0, certificateHash.length > 20 ? 20 : certificateHash.length)}...');
      print('   Tipo de error: ${e.runtimeType}');
      return {
        'exists': false,
        'revoked': false,
        'valid': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Revocar certificado en la blockchain
  Future<String> revokeCertificate(String certificateHash) async {
    try {
      // Obtener o crear wallet automáticamente
      final credentials = await getOrCreateWalletCredentials();
      
      // Verificar balance
      final balance = await getBalance();
      if (balance.getInWei < EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(10000000000000000)).getInWei) {
        throw Exception('Balance insuficiente. Necesitas al menos 0.01 MATIC para revocar certificados.');
      }
      
      // Obtener el nonce actual de la cuenta para evitar conflictos
      final address = await credentials.extractAddress();
      final nonce = await _client.getTransactionCount(address);
      
      // Obtener el gas price actual de la red y usar un 20% más para asegurar que se procese
      int gasPriceGwei = 50; // Valor base más alto
      try {
        final gasPrice = await _client.getGasPrice();
        // Convertir de wei a gwei: 1 gwei = 10^9 wei
        final gasPriceInWei = gasPrice.getInWei;
        final currentGasPriceGwei = (gasPriceInWei / BigInt.from(1000000000)).toInt();
        // Usar el mayor entre el gas price actual + 20% o 50 gwei mínimo
        gasPriceGwei = (currentGasPriceGwei * 1.2).round();
        if (gasPriceGwei < 50) gasPriceGwei = 50; // Mínimo 50 gwei
        print('💰 Gas price actual de la red: ${currentGasPriceGwei} gwei, usando: $gasPriceGwei gwei');
      } catch (e) {
        print('⚠️ No se pudo obtener gas price de la red, usando valor por defecto: $gasPriceGwei gwei');
      }
      
      // Llamar a la función del contrato
      final transaction = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: _revokeCertificateFunction,
          parameters: [certificateHash],
          gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, BigInt.from(gasPriceGwei)),
          maxGas: 200000, // Gas limit
          nonce: nonce, // Usar el nonce actual
        ),
        chainId: chainId,
        fetchChainIdFromNetworkId: false,
      );
      
      // Limpiar el hash de transacción (eliminar espacios, saltos de línea, etc.)
      final cleanTransactionHash = transaction.toString().trim().replaceAll(RegExp(r'\s+'), '');
      
      print('✅ Certificado revocado en blockchain');
      print('   Hash de transacción: $cleanTransactionHash');
      print('   Verifica en: ${BlockchainConfig.explorerUrl}/tx/$cleanTransactionHash');
      
      return cleanTransactionHash;
    } catch (e) {
      print('❌ Error revocando certificado en blockchain: $e');
      rethrow;
    }
  }
  
  /// Obtener información completa del certificado
  Future<Map<String, dynamic>?> getCertificate(String certificateHash) async {
    try {
      // Normalizar el hash antes de pasarlo
      String cleanHash = certificateHash.trim();
      if (cleanHash.startsWith('0x')) {
        cleanHash = cleanHash.substring(2);
      }
      if (cleanHash.length > 64) {
        cleanHash = cleanHash.substring(0, 64);
      }
      
      // Forzar codificación UTF-8
      final hashBytes = utf8.encode(cleanHash);
      final hashAsUtf8String = utf8.decode(hashBytes);
      
      final result = await _client.call(
        contract: _contract,
        function: _getCertificateFunction,
        params: [hashAsUtf8String],
      );
      
      // El resultado es una tupla (struct)
      final certificateData = result[0] as List<dynamic>;
      
      return {
        'certificateId': certificateData[0] as String,
        'studentId': certificateData[1] as String,
        'institutionId': certificateData[2] as String,
        'certificateHash': certificateData[3] as String,
        'issuedAt': (certificateData[4] as BigInt).toInt(),
        'issuedBy': (certificateData[5] as EthereumAddress).hex,
        'revoked': certificateData[6] as bool,
      };
    } catch (e) {
      print('❌ Error obteniendo certificado: $e');
      return null;
    }
  }
  
  /// Obtener el total de certificados emitidos en blockchain
  Future<int> getTotalCertificates() async {
    try {
      final result = await _client.call(
        contract: _contract,
        function: _getTotalCertificatesFunction,
        params: [],
      );
      
      final total = result[0] as BigInt;
      return total.toInt();
    } catch (e) {
      print('❌ Error obteniendo total de certificados: $e');
      return 0;
    }
  }
  
  /// Cerrar conexión
  Future<void> dispose() async {
    await _client.dispose();
  }
}

