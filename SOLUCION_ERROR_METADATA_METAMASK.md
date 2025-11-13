# 🔧 Solución: Error "Cannot read properties of undefined (reading 'metadata')" en MetaMask

## ⚠️ Causa
MetaMask no puede obtener los metadatos de la red personalizada. Esto suele pasar cuando:
- La URL RPC no responde correctamente
- Faltan campos en la configuración de la red
- La extensión necesita actualizarse

## ✅ Solución Paso a Paso

### Paso 1: Eliminar la Red Problemática

1. Abre MetaMask
2. Ve a **Settings** (⚙️) → **Networks** o **Redes**
3. Busca "Polygon Mumbai" o "Mumbai Testnet"
4. **Elimínala** (clic en los 3 puntos → Delete)

### Paso 2: Actualizar MetaMask

1. Ve a Chrome Web Store
2. Busca "MetaMask"
3. Si hay actualización disponible, **actualiza**
4. O ve a: chrome://extensions/
5. Busca MetaMask y haz clic en "Actualizar"

### Paso 3: Agregar la Red de Nuevo (Usando Chainlist - RECOMENDADO)

**Esta es la forma más confiable:**

1. Ve a: https://chainlist.org/
2. **Conecta MetaMask** (botón arriba a la derecha)
3. Busca: **"Mumbai"** o filtra por Chain ID: **80001**
4. Busca la entrada que diga:
   - Network: **Mumbai**
   - Chain ID: **80001**
   - Currency: **MATIC**
5. Clic en **"Add to MetaMask"**
6. Acepta en MetaMask

**Chainlist agrega automáticamente todos los metadatos necesarios.**

### Paso 4: Si Prefieres Agregar Manualmente

Si quieres agregar manualmente, asegúrate de completar **TODOS** estos campos exactamente:

```
Network Name: Polygon Mumbai Testnet
New RPC URL: https://rpc.ankr.com/polygon_mumbai
Chain ID: 80001
Currency Symbol: MATIC
Block Explorer URL: https://mumbai.polygonscan.com
```

**IMPORTANTE:**
- No dejes ningún campo vacío
- El Chain ID debe ser exactamente: **80001** (sin espacios)
- El Currency Symbol debe ser: **MATIC** (mayúsculas)

### Paso 5: Verificar que Funciona

1. Cambia a la red "Polygon Mumbai Testnet"
2. Deberías ver el saldo (si tienes MATIC) o "0 MATIC"
3. Si aparece el error, prueba con otra URL RPC

## 🔄 URLs RPC Alternativas para Probar

Si una URL no funciona, prueba estas en orden:

1. `https://rpc.ankr.com/polygon_mumbai` ✅ (Más confiable)
2. `https://polygon-mumbai.blockpi.network/v1/rpc/public`
3. `https://matic-mumbai.chainstacklabs.com`
4. `https://rpc-mumbai.maticvigil.com`

## 🚨 Si el Error Persiste

1. **Cierra y vuelve a abrir MetaMask**
2. **Reinicia el navegador** (Chrome/Edge)
3. **Prueba en modo incógnito** (para descartar extensiones conflictivas)
4. **Reinstala MetaMask** (última opción - asegúrate de tener tu frase de recuperación)

## ✅ Verificación Final

Cuando agregues la red correctamente, deberías ver:
- ✅ Red "Polygon Mumbai Testnet" en la lista
- ✅ Puedes cambiar a esa red sin errores
- ✅ Muestra saldo (0 MATIC si no tienes fondos)
- ✅ Puedes solicitar MATIC del faucet

## 💡 Recomendación

**Usa Chainlist** - Es más rápido, confiable y agrega automáticamente todos los metadatos necesarios. Es la forma recomendada por MetaMask.

