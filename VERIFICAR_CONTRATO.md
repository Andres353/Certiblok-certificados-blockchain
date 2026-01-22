# 🔍 Cómo Verificar el Contrato en Polygonscan

## ⚠️ Problema: Bytecode no coincide

Si obtienes el error "Unable to find matching Contract Bytecode", significa que la configuración de compilación no coincide.

## ✅ Solución: Usar Standard JSON Input

### Paso 1: Obtener el JSON de compilación desde Remix

1. Ve a Remix: https://remix.ethereum.org
2. Abre el contrato `CertificateRegistry.sol`
3. Ve a la pestaña **"Solidity Compiler"**
4. Asegúrate de que la versión sea **`0.8.19`**
5. **IMPORTANTE**: Verifica la configuración:
   - **Optimization**: `No` (o el mismo que usaste al desplegar)
   - **Runs**: `200` (si usaste optimización)
6. Haz clic en **"Compile CertificateRegistry.sol"**
7. Abre el panel de detalles (icono "i" o "Details" debajo del botón Compile)
8. Busca **"Standard JSON Input"**
9. **Copia TODO el contenido** del JSON

### Paso 2: Verificar en Polygonscan

1. Ve a: https://polygonscan.com/address/0x382aEEd42A584AaD1235aCDEC251177627453BF4
2. Pestaña **"Contract"** → **"Verify and Publish"**
3. Selecciona: **"Via Standard JSON Input"**
4. Pega el JSON completo que copiaste de Remix
5. Haz clic en **"Verify and Publish"**
6. Espera 1-2 minutos

---

## 🔄 Alternativa: Recompilar en Remix con la misma configuración

Si no tienes el JSON, puedes:

1. En Remix, verifica la configuración exacta que usaste al desplegar:
   - Versión del compilador
   - Optimization: Sí/No
   - Runs: (si usaste optimización)

2. Compila de nuevo con la MISMA configuración

3. Usa el código fuente directamente en Polygonscan:
   - Selecciona "Solidity (Single file)"
   - Pega el código fuente
   - Usa la MISMA versión y configuración

---

## ⚡ Solución Rápida: No verificar (por ahora)

**El contrato funciona sin verificación**. Puedes:
- ✅ Emitir certificados
- ✅ Verificarlos desde la app
- ✅ Usar todas las funciones

Solo no podrás:
- ❌ Ver el código fuente en Polygonscan
- ❌ Usar "Read Contract" con interfaz visual

**Puedes verificar después** cuando tengas más tiempo.

---

## 📝 Nota para la Defensa

Si te preguntan sobre la verificación:
- "El contrato está desplegado y funcionando correctamente"
- "La verificación del código fuente es opcional y se puede hacer después"
- "El bytecode está en la blockchain y es inmutable"

