# 🔧 Solución: Error al Conectarse a Red Personalizada

## Problema Común
MetaMask muestra "Error al conectarse a la red personalizada" al agregar Polygon Mumbai.

## ✅ Soluciones

### Opción 1: Usar URL RPC Alternativa

Si la URL `https://rpc-mumbai.maticvigil.com` no funciona, prueba estas alternativas:

**URLs RPC de Polygon Mumbai (elige una):**

1. **Alchemy** (Recomendado):
   ```
   https://polygon-mumbai.g.alchemy.com/v2/YOUR-API-KEY
   ```
   O sin API key (puede tener límites):
   ```
   https://polygon-mumbai.g.alchemy.com/v2/demo
   ```

2. **QuickNode**:
   ```
   https://polygon-mumbai.blockpi.network/v1/rpc/public
   ```

3. **Infura**:
   ```
   https://polygon-mumbai.infura.io/v3/YOUR-PROJECT-ID
   ```

4. **Public RPC** (Más confiable):
   ```
   https://matic-mumbai.chainstacklabs.com
   ```

5. **Another Public RPC**:
   ```
   https://rpc.ankr.com/polygon_mumbai
   ```

### Opción 2: Agregar Manualmente con URL Alternativa

1. Abre MetaMask
2. Clic en la red actual → "Add Network" → "Add a network manually"
3. Usa estos datos con una URL alternativa:

```
Network Name: Polygon Mumbai Testnet
New RPC URL: https://rpc.ankr.com/polygon_mumbai
Chain ID: 80001
Currency Symbol: MATIC
Block Explorer URL: https://mumbai.polygonscan.com
```

### Opción 3: Usar Chainlist (Más Confiable)

1. Ve a: https://chainlist.org/
2. Busca: "Mumbai" o filtra por Chain ID: 80001
3. Conecta MetaMask
4. Clic en "Add to MetaMask"
5. Chainlist usa URLs actualizadas y verificadas

### Opción 4: Verificar Chain ID

Asegúrate de que el Chain ID sea exactamente: **80001**

### Opción 5: Limpiar y Reintentar

1. En MetaMask, ve a Settings → Networks
2. Elimina cualquier red "Polygon Mumbai" que hayas intentado agregar antes
3. Vuelve a agregar con una URL RPC diferente

## 🔍 URLs RPC Verificadas que Funcionan (Nov 2024)

```
https://rpc.ankr.com/polygon_mumbai
https://polygon-mumbai.blockpi.network/v1/rpc/public
https://matic-mumbai.chainstacklabs.com
```

## ⚠️ Si Nada Funciona

1. **Verifica tu conexión a internet**
2. **Actualiza MetaMask** a la última versión
3. **Prueba en otro navegador** (Chrome, Firefox, Brave)
4. **Usa la extensión de escritorio** en lugar de móvil

## 📝 Configuración Final Correcta

Cuando agregues manualmente, debe quedar así:

```
✅ Network Name: Polygon Mumbai Testnet
✅ New RPC URL: https://rpc.ankr.com/polygon_mumbai (o cualquiera de las listadas)
✅ Chain ID: 80001
✅ Currency Symbol: MATIC
✅ Block Explorer URL: https://mumbai.polygonscan.com
```

