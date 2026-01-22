# 🚀 Guía Completa de Instalación y Configuración - CertiBlock

Esta guía contiene **TODA** la información necesaria para configurar el proyecto CertiBlock en una nueva laptop después de formatear.

---

## 📋 Índice

1. [Prerrequisitos del Sistema](#prerrequisitos-del-sistema)
2. [Instalación de Herramientas](#instalación-de-herramientas)
3. [Configuración del Proyecto](#configuración-del-proyecto)
4. [Configuración de Firebase](#configuración-de-firebase)
5. [Configuración de Supabase](#configuración-de-supabase)
6. [Configuración de EmailJS](#configuración-de-emailjs)
7. [Configuración de Blockchain](#configuración-de-blockchain)
8. [Configuración de Base de Datos](#configuración-de-base-de-datos)
9. [Scripts y Comandos Útiles](#scripts-y-comandos-útiles)
10. [Verificación de Instalación](#verificación-de-instalación)
11. [Solución de Problemas Comunes](#solución-de-problemas-comunes)

---

## 🔧 Prerrequisitos del Sistema

### Versiones Requeridas

- **Flutter SDK**: >= 3.1.0 < 4.0.0
- **Dart SDK**: Incluido con Flutter
- **Node.js**: >= 16.0.0 (para Hardhat y contratos inteligentes)
- **npm**: Incluido con Node.js
- **Git**: Cualquier versión reciente
- **Docker** (opcional): Para despliegue con contenedores

### Sistema Operativo

- Windows 10/11 (actualmente configurado)
- También compatible con macOS y Linux

---

## 🛠️ Instalación de Herramientas

### 1. Instalar Flutter

1. Descargar Flutter SDK desde: https://flutter.dev/docs/get-started/install
2. Extraer a una ubicación permanente (ej: `C:\src\flutter`)
3. Agregar Flutter al PATH:
   - Windows: Agregar `C:\src\flutter\bin` al PATH del sistema
4. Verificar instalación:
   ```bash
   flutter doctor
   ```
5. Instalar dependencias faltantes según `flutter doctor`

### 2. Instalar Node.js y npm

1. Descargar Node.js desde: https://nodejs.org/ (versión LTS)
2. Instalar con opciones por defecto
3. Verificar instalación:
   ```bash
   node --version
   npm --version
   ```

### 3. Instalar Git

1. Descargar desde: https://git-scm.com/download/win
2. Instalar con opciones por defecto
3. Verificar instalación:
   ```bash
   git --version
   ```

### 4. Instalar Docker (Opcional)

Si planeas usar Docker para despliegue:
1. Seguir guía: `INSTALAR_DOCKER_WINDOWS.md`
2. Verificar instalación:
   ```bash
   docker --version
   docker-compose --version
   ```

---

## 📦 Configuración del Proyecto

### 1. Clonar el Repositorio

```bash
git clone [URL_DEL_REPOSITORIO]
cd frontend_app
```

### 2. Instalar Dependencias de Flutter

```bash
flutter pub get
```

### 3. Instalar Dependencias de Node.js (para Hardhat)

```bash
npm install
```

### 4. Verificar Estructura del Proyecto

El proyecto debe tener esta estructura principal:

```
frontend_app/
├── lib/                          # Código fuente Dart
│   ├── main.dart                 # Punto de entrada
│   ├── firebase_options.dart     # Configuración Firebase
│   ├── screens/                  # Pantallas de la app
│   ├── services/                 # Servicios de la app
│   │   ├── blockchain/           # Servicios blockchain
│   │   └── supabase/             # Servicios Supabase
│   └── ...
├── assets/                       # Recursos estáticos
├── android/                      # Configuración Android
├── ios/                          # Configuración iOS
├── web/                          # Configuración Web
├── pubspec.yaml                  # Dependencias Flutter
├── package.json                  # Dependencias Node.js
├── docker-compose.yml            # Configuración Docker
├── Dockerfile                    # Imagen Docker
└── nginx.conf                    # Configuración Nginx
```

---

## 🔥 Configuración de Firebase

### 1. Credenciales de Firebase

Las credenciales están configuradas en `lib/firebase_options.dart`:

**Para Web:**
```dart
apiKey: 'AIzaSyB4PRuvfka3CUJkjb6xhR-HXq59YVu0RiQ'
appId: '1:471713232119:web:2524fbc98d7646788b8ff2'
messagingSenderId: '471713232119'
projectId: 'certiblock-e7a7c'
authDomain: 'certiblock-e7a7c.firebaseapp.com'
storageBucket: 'certiblock-e7a7c.firebasestorage.app'
measurementId: 'G-9KPEX7WP7Q'
```

**Para Android:**
```dart
apiKey: 'AIzaSyAfzmYGv4BfTech2UWGCjoYScpWyTPU4FA'
appId: '1:471713232119:android:1be4b226a041681a8b8ff2'
messagingSenderId: '471713232119'
projectId: 'certiblock-e7a7c'
storageBucket: 'certiblock-e7a7c.firebasestorage.app'
```

### 2. Archivos de Configuración Necesarios

**Para Android:**
- Archivo: `android/app/google-services.json`
- Descargar desde: Firebase Console > Project Settings > Your apps > Android app
- El archivo debe estar en: `android/app/google-services.json`

**Para iOS (si se necesita):**
- Archivo: `ios/Runner/GoogleService-Info.plist`
- Descargar desde: Firebase Console > Project Settings > Your apps > iOS app

### 3. Configurar Firebase en Firebase Console

1. Ir a: https://console.firebase.google.com/
2. Seleccionar proyecto: `certiblock-e7a7c`
3. Habilitar los siguientes servicios:
   - **Authentication**: Habilitar Email/Password
   - **Firestore Database**: Crear base de datos en modo producción o test
   - **Storage**: Habilitar Firebase Storage

### 4. Reglas de Firestore

Las reglas están en `firestore.rules`. Asegúrate de desplegarlas:

```bash
firebase deploy --only firestore:rules
```

### 5. Reglas de Storage

Las reglas están en `firebase_storage_rules.txt`. Configurarlas en Firebase Console.

---

## 🗄️ Configuración de Supabase

### 1. Credenciales de Supabase

Las credenciales están en `lib/services/supabase/supabase_config.dart`:

```dart
static const String supabaseUrl = 'https://ndddetlmqfyctapgvjnn.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kZGRldGxtcWZ5Y3RhcGd2am5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5NTY0NDAsImV4cCI6MjA3NTUzMjQ0MH0.ndB0VcFkA7Aj8LjKKLZAWxvBH1-Th_H1z-qF7S6-Cqs';
```

### 2. Configurar Base de Datos en Supabase

1. Ir a: https://supabase.com/dashboard
2. Seleccionar proyecto: `ndddetlmqfyctapgvjnn`
3. Ir a SQL Editor
4. Ejecutar los siguientes scripts SQL (en orden):

**a) Esquema principal:**
- Ver archivo: `lib/services/supabase/database_schema.sql`
- O usar: `supabase_migration.sql`

**b) Tablas adicionales:**
- `create_buckets.sql` - Para configurar buckets de almacenamiento
- `create_password_reset_codes_table.sql` - Para códigos de reset de contraseña
- `supabase_storage_policies.sql` - Para políticas de almacenamiento

### 3. Configurar Storage en Supabase

1. Ir a Storage en el dashboard de Supabase
2. Crear buckets necesarios (si no existen):
   - `certificates` - Para almacenar PDFs de certificados
   - `logos` - Para logos de instituciones
   - `documents` - Para documentos adicionales

3. Configurar políticas de acceso según `supabase_storage_policies.sql`

---

## 📧 Configuración de EmailJS

### 1. Credenciales de EmailJS

Las credenciales están configuradas en varios archivos:

**Service ID:** `service_bdav8mg`
**Template ID:** `template_2fs5k3c`
**User ID:** `o1eUKl5D0Qq9fJ1Jv`
**URL:** `https://api.emailjs.com/api/v1.0/email/send`

### 2. Archivos que Usan EmailJS

- `lib/services/email_notification_service.dart`
- `lib/services/emisor_notification_service.dart`
- `lib/services/password_reset_service.dart`
- `lib/services/certificate_notification_service.dart`

### 3. Verificar Configuración en EmailJS

1. Ir a: https://www.emailjs.com/
2. Iniciar sesión con la cuenta
3. Verificar que el servicio y template existan
4. Si es necesario, crear nuevos templates con los mismos parámetros:
   - `name`
   - `to_email`
   - `to_name`
   - `subject`
   - `message`

---

## ⛓️ Configuración de Blockchain

### 1. Configuración de Polygon

La configuración está en `lib/services/blockchain/blockchain_config.dart`:

**Polygon Mainnet (Producción):**
```dart
static const String polygonMainnetRpcUrl = 'https://polygon-rpc.com';
static const String polygonMainnetExplorer = 'https://polygonscan.com';
static const int polygonChainId = 137;
static const String mainnetContractAddress = '0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504';
```

**Polygon Mumbai Testnet (Desarrollo):**
```dart
static const String mumbaiTestnetRpcUrl = 'https://rpc-mumbai.maticvigil.com';
static const String mumbaiTestnetExplorer = 'https://mumbai.polygonscan.com';
static const int mumbaiChainId = 80001;
static const String testnetContractAddress = '0x0000000000000000000000000000000000000000';
```

**Configuración Actual:**
```dart
static const bool useTestnet = false; // USANDO MAINNET POLYGON
```

### 2. Contrato Inteligente

- **Dirección del Contrato (Mainnet):** `0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504`
- **Red:** Polygon Mainnet (Chain ID: 137)
- **Explorador:** https://polygonscan.com/address/0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504

### 3. Wallet y Claves Privadas

⚠️ **IMPORTANTE:** Las claves privadas de blockchain se almacenan en Supabase en la tabla `system_blockchain_config`.

**NO** se deben hardcodear en el código. El sistema las obtiene automáticamente desde Supabase.

### 4. Configurar Hardhat (para desarrollo de contratos)

Si necesitas trabajar con contratos inteligentes:

1. El proyecto ya tiene Hardhat configurado
2. Instalar dependencias:
   ```bash
   npm install
   ```
3. Verificar configuración en `hardhat.config.js` (si existe)

### 5. Obtener MATIC para Transacciones

- **Testnet:** Usar faucet: https://faucet.polygon.technology
- **Mainnet:** Comprar MATIC en un exchange (Binance, Coinbase, etc.)
- Ver guía: `COMPRAR_MATIC_BINANCE.md`

---

## 🗃️ Configuración de Base de Datos

### 1. Esquema de Base de Datos

El esquema completo está documentado en:
- `database_schema_for_drawio.sql`
- `lib/services/supabase/database_schema.sql`
- `database_diagram_dbml.dbml`

### 2. Tablas Principales

1. **institutions** - Instituciones académicas
2. **users** - Usuarios del sistema
3. **faculties** - Facultades
4. **programs** - Programas académicos
5. **certificates** - Certificados emitidos
6. **certificate_templates** - Plantillas de certificados
7. **system_blockchain_config** - Configuración de blockchain

### 3. Scripts SQL Importantes

Ejecutar en orden en Supabase SQL Editor:

1. `supabase_migration.sql` - Esquema principal
2. `create_buckets.sql` - Buckets de almacenamiento
3. `create_password_reset_codes_table.sql` - Tabla de reset
4. `supabase_storage_policies.sql` - Políticas de acceso

---

## 📜 Scripts y Comandos Útiles

### Scripts de Desarrollo

**Windows (PowerShell/Batch):**

1. **Iniciar servidor Flutter:**
   ```bash
   start_flutter_server.bat
   ```
   O manualmente:
   ```bash
   flutter run -d web-server --web-port 8081
   ```

2. **Hot Reload:**
   ```bash
   hot_reload.bat
   ```
   O presionar `r` en la terminal donde corre Flutter

### Scripts de Docker

Ver `scripts/` para scripts de Docker:
- `docker-build.bat` - Construir imagen
- `docker-run.bat` - Ejecutar contenedor
- `docker-stop.bat` - Detener contenedor
- `docker-update.bat` - Actualizar y reconstruir

### Comandos Flutter Comunes

```bash
# Instalar dependencias
flutter pub get

# Limpiar build
flutter clean

# Ejecutar en web
flutter run -d chrome

# Ejecutar en web con puerto específico
flutter run -d web-server --web-port 8081

# Build para web
flutter build web

# Verificar configuración
flutter doctor
```

### Comandos Docker

```bash
# Construir y ejecutar
docker-compose up --build -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down

# Reconstruir sin cache
docker-compose build --no-cache
```

---

## ✅ Verificación de Instalación

### 1. Verificar Flutter

```bash
flutter doctor -v
```

Debe mostrar:
- ✅ Flutter (Channel stable)
- ✅ Android toolchain (si se usa Android)
- ✅ Chrome (para desarrollo web)
- ✅ Visual Studio (para Windows)

### 2. Verificar Dependencias

```bash
# Flutter
flutter pub get

# Node.js
npm install
```

### 3. Verificar Configuraciones

**Firebase:**
- Verificar que `lib/firebase_options.dart` tenga las credenciales correctas
- Verificar que `android/app/google-services.json` exista (si se usa Android)

**Supabase:**
- Verificar que `lib/services/supabase/supabase_config.dart` tenga las credenciales correctas
- Probar conexión desde la app

**EmailJS:**
- Verificar que los servicios usen las credenciales correctas
- Probar envío de email de prueba

**Blockchain:**
- Verificar que `lib/services/blockchain/blockchain_config.dart` tenga la dirección del contrato correcta
- Verificar que la red esté configurada (testnet/mainnet)

### 4. Ejecutar la Aplicación

```bash
flutter run -d chrome
```

La aplicación debe:
- ✅ Iniciar sin errores
- ✅ Mostrar pantalla de login
- ✅ Conectarse a Firebase
- ✅ Conectarse a Supabase

---

## 🔍 Solución de Problemas Comunes

### Error: "Flutter not found"

**Solución:**
1. Verificar que Flutter esté en el PATH
2. Reiniciar terminal/IDE
3. Ejecutar: `flutter doctor`

### Error: "Firebase not initialized"

**Solución:**
1. Verificar `lib/firebase_options.dart`
2. Verificar que Firebase esté habilitado en Firebase Console
3. Verificar `android/app/google-services.json` (para Android)

### Error: "Supabase connection failed"

**Solución:**
1. Verificar credenciales en `lib/services/supabase/supabase_config.dart`
2. Verificar que el proyecto Supabase esté activo
3. Verificar conexión a internet

### Error: "EmailJS send failed"

**Solución:**
1. Verificar credenciales de EmailJS
2. Verificar que el template exista en EmailJS
3. Verificar límites de la cuenta EmailJS

### Error: "Blockchain transaction failed"

**Solución:**
1. Verificar que la wallet tenga MATIC suficiente
2. Verificar que la red esté correcta (testnet/mainnet)
3. Verificar que la dirección del contrato sea correcta
4. Verificar conexión a RPC de Polygon

### Error: "Dependencies not found"

**Solución:**
```bash
# Limpiar y reinstalar
flutter clean
flutter pub get
npm install
```

### Error: "Port already in use"

**Solución:**
```bash
# Cambiar puerto en start_flutter_server.bat
flutter run -d web-server --web-port 8082
```

---

## 📝 Notas Importantes

### Seguridad

⚠️ **NUNCA** subir a Git:
- Claves privadas de blockchain
- Archivos `.env` con credenciales
- `google-services.json` (ya está en .gitignore)
- `GoogleService-Info.plist` (ya está en .gitignore)

### Archivos en .gitignore

Los siguientes archivos NO deben estar en Git:
- `.env*`
- `node_modules/`
- `build/`
- `.dart_tool/`
- `android/app/google-services.json` (si contiene credenciales sensibles)
- `ios/Runner/GoogleService-Info.plist` (si contiene credenciales sensibles)

### Variables de Entorno

Actualmente el proyecto NO usa archivos `.env`. Las configuraciones están hardcodeadas en:
- `lib/firebase_options.dart` - Firebase
- `lib/services/supabase/supabase_config.dart` - Supabase
- `lib/services/blockchain/blockchain_config.dart` - Blockchain
- Varios archivos de servicios - EmailJS

### Documentación Adicional

- `README.md` - Información general del proyecto
- `README_DOCKER.md` - Guía de Docker
- `CONTROLES_AUTENTICACION.md` - Controles de seguridad
- `CONFIGURAR_POLYGON_MAINNET.md` - Configuración de blockchain
- `GUIA_BLOCKCHAIN_CERTIFICADOS.md` - Guía de blockchain
- `INSTALAR_DOCKER_WINDOWS.md` - Instalación de Docker

---

## 🆘 Contacto y Soporte

Si encuentras problemas no documentados:

1. Revisar logs de la aplicación
2. Revisar logs de Firebase Console
3. Revisar logs de Supabase Dashboard
4. Verificar documentación adicional en el proyecto

---

## ✅ Checklist Final

Antes de considerar la instalación completa, verificar:

- [ ] Flutter instalado y funcionando (`flutter doctor`)
- [ ] Node.js instalado (`node --version`)
- [ ] Git instalado (`git --version`)
- [ ] Dependencias de Flutter instaladas (`flutter pub get`)
- [ ] Dependencias de Node.js instaladas (`npm install`)
- [ ] Firebase configurado y funcionando
- [ ] Supabase configurado y base de datos creada
- [ ] EmailJS configurado y funcionando
- [ ] Blockchain configurado (contrato y wallet)
- [ ] Aplicación ejecuta sin errores
- [ ] Login funciona correctamente
- [ ] Conexión a Firebase funciona
- [ ] Conexión a Supabase funciona
- [ ] Envío de emails funciona
- [ ] Transacciones blockchain funcionan (si aplica)

---

**Última actualización:** $(Get-Date -Format "yyyy-MM-dd")

**Versión del Proyecto:** 1.0.0

---

¡Listo! Con esta guía deberías poder configurar el proyecto completamente en cualquier nueva laptop. 🚀
