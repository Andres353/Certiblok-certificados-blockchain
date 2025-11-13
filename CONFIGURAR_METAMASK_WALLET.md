# 🔐 Configurar MetaMask como Wallet para Blockchain

## 📋 Pasos para Configurar MetaMask

### Paso 1: Exportar Clave Privada de MetaMask

1. **Abre MetaMask**
2. **Asegúrate de estar en Polygon Mainnet** (Chain ID: 137)
3. **Ve a Settings (Configuración)**:
   - Clic en el icono de 3 líneas (menú) en la esquina superior izquierda
   - O clic en tu avatar/icono de cuenta
4. **Ve a Security & Privacy** o **Seguridad y Privacidad**
5. **Busca "Export Private Key"** o **"Exportar clave privada"**
6. **Ingresa tu contraseña** de MetaMask
7. **Copia la clave privada**:
   - ⚠️ **NUNCA compartas esta clave**
   - ⚠️ **NO la subas a GitHub**
   - ⚠️ **Guárdala de forma segura**

### Paso 2: Configurar en la Aplicación

Tienes dos opciones:

#### Opción A: Desde el Código (Temporal - Solo para pruebas)

Crea un archivo temporal o agrega esto en algún lugar para ejecutarlo una vez:

```dart
import 'package:frontend_app/services/blockchain/blockchain_service.dart';

// Reemplaza 'TU_PRIVATE_KEY_AQUI' con la clave que copiaste de MetaMask
final blockchainService = BlockchainService();
await blockchainService.saveWalletPrivateKey('TU_PRIVATE_KEY_AQUI');

print('✅ Wallet de MetaMask configurada exitosamente');
```

#### Opción B: Crear Pantalla de Configuración (Recomendado)

Puedo crear una pantalla en tu app para configurar la wallet de forma segura.

### Paso 3: Verificar que Funciona

Después de configurar, verifica:

```dart
final blockchainService = BlockchainService();
final address = await blockchainService.getCurrentWalletAddress();
print('Dirección de wallet: $address');

// Verificar balance
final balance = await blockchainService.getBalance();
print('Balance: ${balance.getValueInUnit(EtherUnit.ether)} MATIC');
```

## ⚠️ IMPORTANTE: Seguridad

- **NUNCA** compartas tu clave privada
- **NUNCA** la subas a GitHub o repositorios públicos
- **SIEMPRE** usa variables de entorno para producción
- **GUARDA** una copia de seguridad segura

## ✅ Después de Configurar

1. ✅ La wallet está configurada
2. ✅ Asegúrate de tener MATIC en esa dirección de MetaMask
3. ✅ Emite un certificado y debería funcionar automáticamente

