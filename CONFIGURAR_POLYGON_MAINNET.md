# 🚀 Configuración para Polygon Mainnet

## ✅ Configuración Actualizada

Ya está configurado para usar **Polygon Mainnet**. Los cambios realizados:

1. ✅ `blockchain_config.dart`: `useTestnet = false`
2. ✅ `blockchain_service.dart`: Usa configuración de mainnet

---

## 📋 Pasos para Usar Polygon Mainnet

### 1️⃣ Obtener MATIC (Fondos Reales)

Necesitas MATIC real para pagar las transacciones. Opciones:

#### Opción A: Comprar MATIC en Exchange
1. **Binance**:
   - Compra MATIC con tarjeta o transferencia
   - Transfiere a tu wallet MetaMask

2. **Coinbase**:
   - Compra MATIC directamente
   - Envía a MetaMask

3. **Cantidad recomendada**:
   - **Mínimo**: 1 MATIC (~$0.50 USD)
   - **Recomendado**: 5-10 MATIC (~$2.50-5 USD)
   - Esto permite emitir ~800-1600 certificados

#### Opción B: Bridge desde Ethereum
1. Ve a: https://portal.polygon.technology
2. Conecta tu wallet
3. Convierte ETH a MATIC (Polygon)
4. Espera confirmación (~10-30 minutos)

#### Opción C: Cambiar ETH por MATIC
1. Usa Uniswap o 1inch
2. Cambia ETH → MATIC (Polygon)
3. Envía a tu wallet

---

### 2️⃣ Configurar MetaMask para Polygon Mainnet

Si no lo tienes configurado:

1. **Abrir MetaMask**
2. **Settings > Networks > Add Network**
3. **Configuración**:
   ```
   Network Name: Polygon Mainnet
   RPC URL: https://polygon-rpc.com
   Chain ID: 137
   Currency Symbol: MATIC
   Block Explorer URL: https://polygonscan.com
   ```
4. **Save**

---

### 3️⃣ Desplegar Contrato en Polygon Mainnet

#### Usando Remix IDE:

1. **Ve a**: https://remix.ethereum.org

2. **Crea el archivo**:
   - Carpeta `contracts`
   - Archivo `CertificateRegistry.sol`
   - Copia el código de `contracts/CertificateRegistry.sol`

3. **Compila**:
   - Pestaña "Solidity Compiler"
   - Versión: `0.8.19`
   - Clic "Compile"

4. **Despliega**:
   - Pestaña "Deploy & Run Transactions"
   - Environment: **"Injected Provider - MetaMask"**
   - **IMPORTANTE**: Asegúrate de estar en **Polygon Mainnet** (Chain ID 137)
   - Verifica que tengas MATIC en tu wallet
   - Clic "Deploy"
   - Confirma en MetaMask
   - **Costo**: ~0.001-0.01 MATIC (~$0.001-0.01 USD)

5. **Copia la dirección del contrato**:
   - Después del deploy verás: `0x1234...`
   - Copia esta dirección

---

### 4️⃣ Configurar Contrato en la App

Edita `lib/services/blockchain/blockchain_config.dart`:

```dart
// Para mainnet:
static const String mainnetContractAddress = '0xTU_DIRECCION_DEL_CONTRATO_AQUI';
```

**Ejemplo**:
```dart
static const String mainnetContractAddress = '0x1234567890abcdef1234567890abcdef12345678';
```

---

### 5️⃣ Configurar Wallet en la App

#### Opción A: Generar nueva wallet (Recomendado)

La app generará automáticamente una wallet la primera vez. Necesitas cargarle MATIC:

1. Genera la wallet desde la app
2. Copia la dirección de la wallet
3. Envía MATIC desde MetaMask a esa dirección

#### Opción B: Usar wallet existente (MetaMask)

1. Exporta la clave privada de MetaMask:
   - MetaMask > Settings > Security > Export Private Key
   - ⚠️ **NUNCA compartas esta clave**

2. Usa el servicio:
```dart
final blockchainService = BlockchainService();
await blockchainService.saveWalletPrivateKey('TU_PRIVATE_KEY_AQUI');
```

---

### 6️⃣ Verificar Configuración

Ejecuta esto para verificar:

```dart
final blockchainService = BlockchainService();

// Verificar configuración
print('Red: ${BlockchainConfig.useTestnet ? "Testnet" : "Mainnet"}');
print('RPC: ${BlockchainConfig.rpcUrl}');
print('Chain ID: ${BlockchainConfig.chainId}');
print('Contrato: ${BlockchainConfig.contractAddress}');

// Inicializar
await blockchainService.initialize(BlockchainConfig.contractAddress);

// Verificar balance
final balance = await blockchainService.getBalance();
print('Balance: ${balance.getValueInUnit(EtherUnit.ether)} MATIC');
```

---

## 💰 Costos Reales en Polygon Mainnet

### Por Certificado:
- **Gas**: ~200,000 unidades
- **Gas Price**: ~30 gwei
- **Costo**: ~0.006 MATIC
- **USD**: ~$0.003-0.004 USD

### Ejemplos:
- **10 certificados**: ~0.06 MATIC (~$0.03 USD)
- **100 certificados**: ~0.6 MATIC (~$0.30 USD)
- **1,000 certificados**: ~6 MATIC (~$3 USD)

### Comparación:
- **Ethereum Mainnet**: ~$5-50 por certificado ❌
- **Polygon Mainnet**: ~$0.004 por certificado ✅
- **Ahorro**: ~99.9% más barato

---

## 🔍 Verificar Transacciones

### Explorador de Polygon:
- **URL**: https://polygonscan.com
- Busca tu dirección de contrato o hash de transacción
- Todas las transacciones son públicas y verificables

### Ejemplo de URL:
```
https://polygonscan.com/tx/0x1234567890abcdef...
https://polygonscan.com/address/0xTU_CONTRATO
```

---

## ⚠️ IMPORTANTE: Seguridad

### ⚠️ NUNCA:
- ❌ Compartas tu clave privada
- ❌ Envíes la clave por email/mensaje
- ❌ Hardcodees la clave en el código
- ❌ Subas la clave a GitHub

### ✅ SÍ:
- ✅ Usa variables de entorno para claves
- ✅ Guarda backups seguros de la wallet
- ✅ Usa wallet de hardware para producción
- ✅ Verifica siempre las direcciones antes de enviar

---

## 🧪 Prueba de Emisión

### 1. Emitir certificado de prueba:

```dart
final blockchainService = BlockchainService();
await blockchainService.initialize(BlockchainConfig.contractAddress);

final txHash = await blockchainService.issueCertificate(
  certificateId: 'test-cert-001',
  studentId: 'student-123',
  institutionId: 'inst-456',
  certificateHash: 'hash-abc123',
);

print('✅ Certificado emitido: $txHash');
print('Verifica en: ${BlockchainConfig.explorerUrl}/tx/$txHash');
```

### 2. Verificar certificado:

```dart
final verification = await blockchainService.verifyCertificate('hash-abc123');
print('Válido: ${verification['valid']}');
print('Existe: ${verification['exists']}');
print('Revocado: ${verification['revoked']}');
```

---

## 📊 Monitoreo de Costos

### Ver cuánto has gastado:

1. Ve a Polygonscan
2. Busca tu dirección de wallet
3. Ve a "Token Transfers"
4. Verás todas las transacciones y costos

### Calcular costos futuros:

```dart
// Costo estimado para N certificados
int numCertificates = 100;
double costMATIC = numCertificates * BlockchainConfig.estimatedCostPerCertificate;
print('Costo estimado: $costMATIC MATIC');
```

---

## 🎯 Checklist para Mainnet

- [ ] Wallet configurada con MATIC (mínimo 1 MATIC)
- [ ] MetaMask configurado para Polygon Mainnet
- [ ] Contrato desplegado en Polygon Mainnet
- [ ] Dirección del contrato configurada en `blockchain_config.dart`
- [ ] Wallet configurada en la app
- [ ] Balance verificado (tiene MATIC suficiente)
- [ ] Prueba de emisión exitosa
- [ ] Transacción verificada en Polygonscan

---

## 🆘 Solución de Problemas

### Error: "Insufficient funds"
- **Solución**: Carga más MATIC a tu wallet
- **Mínimo recomendado**: 1 MATIC

### Error: "Contract not found"
- **Solución**: Verifica que la dirección del contrato sea correcta
- Asegúrate de que el contrato esté desplegado en Mainnet

### Error: "Transaction failed"
- **Solución**: Verifica que tienes suficiente MATIC para gas
- Aumenta el gas limit si es necesario

### Error: "Wrong network"
- **Solución**: Asegúrate de estar en Polygon Mainnet (Chain ID: 137)
- Verifica en MetaMask

---

## ✅ Estado Actual

- ✅ Configurado para **Polygon Mainnet**
- ✅ Chain ID: **137**
- ✅ RPC: **https://polygon-rpc.com**
- ✅ Explorador: **https://polygonscan.com**

---

## 🎉 ¡Listo!

Ya tienes todo configurado para usar **Polygon Mainnet**. Solo necesitas:

1. ✅ Desplegar el contrato
2. ✅ Configurar la dirección del contrato
3. ✅ Cargar MATIC a tu wallet
4. ✅ ¡Emitir certificados!

---

## 📞 Recursos

- **Polygon Docs**: https://docs.polygon.technology
- **Polygonscan**: https://polygonscan.com
- **Remix IDE**: https://remix.ethereum.org
- **Polygon Bridge**: https://portal.polygon.technology

¡Éxito con tu proyecto! 🚀

