# 🚀 Guía para Desplegar el Contrato en Polygon Mainnet

## ⚠️ IMPORTANTE: Verificar si el Contrato Está Desplegado

Si en Polygonscan **NO aparece la pestaña "Contract"**, significa que el contrato **NO está desplegado** y necesitas desplegarlo correctamente.

---

## 📋 Paso 1: Preparar Remix IDE

1. Ve a: https://remix.ethereum.org
2. Crea un nuevo archivo: `CertificateRegistry.sol`
3. Copia el código del contrato desde `contracts/CertificateRegistry.sol`

---

## 🔧 Paso 2: Compilar el Contrato

1. En Remix, ve a la pestaña **"Solidity Compiler"** (icono de compilador)
2. Selecciona la versión: **`0.8.19`** o superior (debe coincidir con `pragma solidity ^0.8.19`)
3. Haz clic en **"Compile CertificateRegistry.sol"**
4. ✅ Debe aparecer un check verde si compiló correctamente

---

## 💼 Paso 3: Conectar MetaMask a Polygon Mainnet

1. Abre MetaMask
2. Haz clic en el nombre de la red (arriba, ej: "Ethereum Mainnet")
3. Selecciona **"Add Network"** o **"Add a network manually"**
4. Ingresa estos datos:
   - **Network Name**: `Polygon Mainnet`
   - **RPC URL**: `https://polygon-rpc.com`
   - **Chain ID**: `137`
   - **Currency Symbol**: `MATIC`
   - **Block Explorer**: `https://polygonscan.com`
5. Haz clic en **"Save"**

---

## 💵 Paso 4: Obtener MATIC para Gas

Necesitas MATIC para pagar las tarifas de despliegue (~0.01-0.1 MATIC).

### Opción A: Comprar MATIC
1. Compra MATIC en un exchange (Binance, Coinbase, etc.)
2. Transfiere a tu wallet MetaMask

### Opción B: Bridge desde Ethereum
1. Ve a: https://portal.polygon.technology
2. Conecta tu wallet
3. Convierte ETH a MATIC

**Cantidad recomendada**: Mínimo 1 MATIC (~$0.50 USD)

---

## 🚀 Paso 5: Desplegar el Contrato

1. En Remix, ve a la pestaña **"Deploy & Run Transactions"** (icono de cohete)
2. **IMPORTANTE**: En "Environment", selecciona:
   - ✅ **"Injected Provider - MetaMask"** (NO "Remix VM")
3. Verifica que MetaMask esté conectado y en **Polygon Mainnet** (Chain ID 137)
4. Verifica que tengas MATIC en tu wallet
5. En "Contract", selecciona: **"CertificateRegistry"**
6. Haz clic en **"Deploy"**
7. MetaMask se abrirá:
   - Revisa el costo de gas
   - Haz clic en **"Confirm"**
8. Espera la confirmación (30-60 segundos)

---

## 📝 Paso 6: Copiar la Dirección del Contrato

Después del despliegue, en Remix verás:

```
✅ Deployed to: 0x1234567890abcdef1234567890abcdef12345678
```

**Copia esta dirección** (será diferente a `0xd9145CCE...`)

---

## ✅ Paso 7: Verificar en Polygonscan

1. Ve a: https://polygonscan.com
2. Pega la dirección del contrato en la búsqueda
3. Debe mostrar:
   - ✅ Balance de POL
   - ✅ Pestaña **"Contract"** (esto confirma que es un contrato)
   - ✅ Transacciones

---

## 🔍 Paso 8: Verificar el Código del Contrato (Opcional pero Recomendado)

Para que otros puedan ver el código fuente:

1. En Polygonscan, ve a la pestaña **"Contract"**
2. Haz clic en **"Verify and Publish"**
3. Completa el formulario:
   - **Compiler Type**: `Solidity (Single file)` o `Solidity (Standard JSON Input)`
   - **Compiler Version**: `v0.8.19+commit.7dd6d404` (o la versión que usaste)
   - **License**: `MIT`
   - **Optimization**: `No` (o `Yes` si compilaste con optimización)
4. Pega el código fuente completo de `CertificateRegistry.sol`
5. Haz clic en **"Verify and Publish"**
6. Espera la verificación (1-2 minutos)

---

## ⚙️ Paso 9: Actualizar la Configuración en la App

Edita `lib/services/blockchain/blockchain_config.dart`:

```dart
// Para mainnet:
static const String mainnetContractAddress = '0xTU_NUEVA_DIRECCION_AQUI';
```

**Ejemplo**:
```dart
static const String mainnetContractAddress = '0x1234567890abcdef1234567890abcdef12345678';
```

---

## 🧪 Paso 10: Probar el Contrato

1. Ejecuta la app
2. Intenta emitir un certificado de prueba
3. Verifica en Polygonscan que la transacción se ejecutó correctamente
4. Ve a la pestaña **"Contract"** → **"Read Contract"**
5. Prueba la función `getTotalCertificates()` (debe mostrar 1 o más)

---

## ❌ Solución de Problemas

### Error: "Insufficient funds"
- **Solución**: Asegúrate de tener suficiente MATIC en tu wallet (mínimo 0.1 MATIC)

### Error: "Contract deployment failed"
- **Solución**: Verifica que estés en Polygon Mainnet (Chain ID 137), no en testnet

### No aparece la pestaña "Contract" después del despliegue
- **Solución**: Espera 1-2 minutos y recarga la página. Si sigue sin aparecer, el contrato no se desplegó correctamente.

### Las transacciones fallan
- **Solución**: Verifica que la dirección del contrato en `blockchain_config.dart` sea correcta

---

## 📞 Verificación Final

Después de desplegar, verifica:

- ✅ La dirección del contrato aparece en Polygonscan
- ✅ Aparece la pestaña **"Contract"**
- ✅ Puedes ver las funciones en **"Read Contract"**
- ✅ La app puede emitir certificados sin errores
- ✅ Los certificados se pueden verificar en Polygonscan

---

## 🎉 ¡Listo!

Tu contrato está desplegado y funcionando en Polygon Mainnet. Ahora puedes:

- Emitir certificados reales
- Verificarlos en Polygonscan
- Usar "Read Contract" para consultar datos

---

## 💡 Nota Importante

**NO uses la dirección `0xd9145CCE52D386f254917e481eB44e9943F39138`** - Es una dirección de prueba de Remix, no un contrato real.

Siempre usa la dirección que te da Remix después de desplegar con **"Injected Provider - MetaMask"**.

