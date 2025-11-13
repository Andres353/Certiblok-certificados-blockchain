# 📘 Guía Rápida: Desplegar Contrato en Polygon

## 🎯 Opción 1: Remix IDE (MÁS FÁCIL)

### Paso 1: Preparar Contrato
1. Ve a: https://remix.ethereum.org
2. Crea carpeta `contracts` si no existe
3. Crea archivo `CertificateRegistry.sol`
4. Copia el código de `contracts/CertificateRegistry.sol`

### Paso 2: Compilar
1. Pestaña "Solidity Compiler"
2. Versión: `0.8.19`
3. Clic "Compile CertificateRegistry.sol"
4. ✅ Debe aparecer marca verde

### Paso 3: Configurar MetaMask
1. Abre MetaMask
2. **Para Testnet**:
   - Settings > Networks > Add Network
   - Nombre: Polygon Mumbai
   - RPC: https://rpc-mumbai.maticvigil.com
   - Chain ID: 80001
   - Currency: MATIC
   - Explorer: https://mumbai.polygonscan.com
3. **Para Mainnet**:
   - Settings > Networks > Add Network
   - Nombre: Polygon Mainnet
   - RPC: https://polygon-rpc.com
   - Chain ID: 137
   - Currency: MATIC
   - Explorer: https://polygonscan.com

### Paso 4: Obtener MATIC
- **Testnet**: https://faucet.polygon.technology (GRATIS)
- **Mainnet**: Compra en exchange o bridge desde Ethereum

### Paso 5: Desplegar
1. Pestaña "Deploy & Run Transactions"
2. Environment: "Injected Provider - MetaMask"
3. Conecta MetaMask
4. Clic "Deploy"
5. Confirma en MetaMask
6. ✅ Copia la dirección del contrato

---

## 🎯 Opción 2: Hardhat (PARA DESARROLLADORES)

### Instalar Hardhat
```bash
npm install --save-dev hardhat
npx hardhat init
```

### Configurar hardhat.config.js
```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.19",
  networks: {
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: ["TU_PRIVATE_KEY_AQUI"]
    },
    polygon: {
      url: "https://polygon-rpc.com",
      accounts: ["TU_PRIVATE_KEY_AQUI"]
    }
  }
};
```

### Desplegar
```bash
npx hardhat run scripts/deploy.js --network mumbai
```

---

## 📝 Script de Deploy (Hardhat)

Crea `scripts/deploy.js`:

```javascript
async function main() {
  const CertificateRegistry = await ethers.getContractFactory("CertificateRegistry");
  const registry = await CertificateRegistry.deploy();
  
  await registry.deployed();
  
  console.log("Contrato desplegado en:", registry.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

---

## ✅ Verificar Despliegue

1. Ve a Polygonscan (Mumbai o Mainnet)
2. Busca la dirección del contrato
3. Debe mostrar el código del contrato
4. Verifica que las funciones estén disponibles

---

## 🔧 Configurar en la App

Edita `lib/services/blockchain/blockchain_config.dart`:

```dart
static const String testnetContractAddress = '0xTU_DIRECCION_AQUI';
static const String mainnetContractAddress = '0xTU_DIRECCION_AQUI';
```

---

## 🎉 ¡Listo!

El contrato está desplegado y listo para usar.

