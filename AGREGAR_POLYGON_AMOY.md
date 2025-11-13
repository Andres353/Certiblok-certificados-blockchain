# 🚀 Agregar Polygon Amoy Testnet (Nueva Testnet de Polygon)

## ⚠️ IMPORTANTE
**Polygon Mumbai está en desuso**. Ahora debes usar **Polygon Amoy** como testnet.

## 📋 Configuración de Polygon Amoy

### Chain ID: **80002** (NO 80001)
### Currency: **MATIC**
### Explorador: https://amoy.polygonscan.com

## ✅ Método 1: Usar Chainlist (RECOMENDADO)

1. Ve a: https://chainlist.org/
2. Busca: **"Amoy"** o filtra por Chain ID: **80002**
3. Conecta MetaMask
4. Clic en **"Add to MetaMask"** en la red que diga:
   - Network: **Amoy**
   - Chain ID: **80002**
   - Currency: **MATIC**

## ✅ Método 2: Agregar Manualmente

1. Abre MetaMask
2. Clic en la red actual → **"Add Network"** → **"Add a network manually"**
3. Completa estos datos **exactos**:

```
Network Name: Polygon Amoy Testnet
New RPC URL: https://rpc.ankr.com/polygon_amoy
Chain ID: 80002
Currency Symbol: MATIC
Block Explorer URL: https://amoy.polygonscan.com
```

4. **Guardar**
5. Cambiar a "Polygon Amoy Testnet"

## 🔄 URLs RPC Alternativas para Amoy

Si una no funciona, prueba estas:

1. `https://rpc.ankr.com/polygon_amoy` ✅ (Más confiable)
2. `https://polygon-amoy.blockpi.network/v1/rpc/public`
3. `https://rpc-amoy.polygon.technology`

## 💧 Obtener MATIC de Prueba (Faucet)

1. Ve a: https://faucet.polygon.technology/
2. Selecciona **"Polygon Amoy"** (NO Mumbai)
3. Pega tu dirección de wallet
4. Solicita MATIC de prueba

## 📝 Desplegar Contrato en Amoy

Una vez configurada la red, despliega usando:

```bash
npx hardhat run scripts/deploy.js --network amoy
```

## ⚠️ Cambios Importantes

- ✅ **Chain ID**: 80002 (antes era 80001)
- ✅ **Nombre**: Amoy (antes Mumbai)
- ✅ **Explorador**: https://amoy.polygonscan.com
- ❌ **Mumbai está deprecado** - No lo uses

## ✅ Verificación

Cuando agregues correctamente, deberías ver:
- Red "Polygon Amoy Testnet" en MetaMask
- Chain ID: 80002
- Puedes solicitar MATIC del faucet
- Funciona sin errores

