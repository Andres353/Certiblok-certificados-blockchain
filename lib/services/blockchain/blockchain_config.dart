// lib/services/blockchain/blockchain_config.dart
// Configuración de blockchain

class BlockchainConfig {
  // Configuración de Polygon Mumbai Testnet (GRATIS para desarrollo)
  static const String mumbaiTestnetRpcUrl = 'https://rpc-mumbai.maticvigil.com';
  static const String mumbaiTestnetExplorer = 'https://mumbai.polygonscan.com';
  static const int mumbaiChainId = 80001;
  
  // Configuración de Polygon Mainnet (MUY BARATO para producción)
  static const String polygonMainnetRpcUrl = 'https://polygon-rpc.com';
  static const String polygonMainnetExplorer = 'https://polygonscan.com';
  static const int polygonChainId = 137;
  
  // Faucet para obtener MATIC gratis en testnet
  static const String mumbaiFaucetUrl = 'https://faucet.polygon.technology';
  
  // ¿Usar testnet o mainnet?
  // Para desarrollo: true (gratis)
  // Para producción/demo: false (muy barato, ~$0.001-0.01 por certificado)
  static const bool useTestnet = false; // USANDO MAINNET POLYGON
  
  // Dirección del contrato desplegado
  // Debes reemplazar esto con la dirección real después de desplegar el contrato
  // Para testnet:
  static const String testnetContractAddress = '0x0000000000000000000000000000000000000000'; // CAMBIAR ESTO
  
  // Para mainnet:
  static const String mainnetContractAddress = '0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504'; // Contrato desplegado en Polygon Mainnet
  
  static String get rpcUrl => useTestnet ? mumbaiTestnetRpcUrl : polygonMainnetRpcUrl;
  static String get explorerUrl => useTestnet ? mumbaiTestnetExplorer : polygonMainnetExplorer;
  static int get chainId => useTestnet ? mumbaiChainId : polygonChainId;
  static String get contractAddress => useTestnet ? testnetContractAddress : mainnetContractAddress;
  
  // Precio estimado de gas (en gwei)
  static const int gasPrice = 30; // 30 gwei es razonable para Polygon
  
  // Gas limit estimado por transacción
  static const int gasLimit = 500000; // Aumentado para evitar "out of gas"
  
  // Costo estimado por certificado (en MATIC)
  // Gas limit * Gas price = ~200,000 * 30 gwei = 0.006 MATIC (~$0.004 USD)
  static const double estimatedCostPerCertificate = 0.006;
}

