# 🔐 Configuraciones y Credenciales - CertiBlock

⚠️ **IMPORTANTE:** Este archivo contiene información sensible. **NO** subir a repositorios públicos.

---

## 🔥 Firebase

### Proyecto
- **Project ID:** `certiblock-e7a7c`
- **Project Number:** `471713232119`
- **Console URL:** https://console.firebase.google.com/project/certiblock-e7a7c

### Web Configuration
```
apiKey: AIzaSyB4PRuvfka3CUJkjb6xhR-HXq59YVu0RiQ
appId: 1:471713232119:web:2524fbc98d7646788b8ff2
messagingSenderId: 471713232119
projectId: certiblock-e7a7c
authDomain: certiblock-e7a7c.firebaseapp.com
storageBucket: certiblock-e7a7c.firebasestorage.app
measurementId: G-9KPEX7WP7Q
```

### Android Configuration
```
apiKey: AIzaSyAfzmYGv4BfTech2UWGCjoYScpWyTPU4FA
appId: 1:471713232119:android:1be4b226a041681a8b8ff2
messagingSenderId: 471713232119
projectId: certiblock-e7a7c
storageBucket: certiblock-e7a7c.firebasestorage.app
```

### Archivos Necesarios
- **Android:** `android/app/google-services.json` (descargar desde Firebase Console)
- **iOS:** `ios/Runner/GoogleService-Info.plist` (si se necesita)

### Servicios Habilitados
- ✅ Authentication (Email/Password)
- ✅ Firestore Database
- ✅ Firebase Storage

---

## 🗄️ Supabase

### Proyecto
- **URL:** `https://ndddetlmqfyctapgvjnn.supabase.co`
- **Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kZGRldGxtcWZ5Y3RhcGd2am5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5NTY0NDAsImV4cCI6MjA3NTUzMjQ0MH0.ndB0VcFkA7Aj8LjKKLZAWxvBH1-Th_H1z-qF7S6-Cqs`
- **Dashboard:** https://supabase.com/dashboard/project/ndddetlmqfyctapgvjnn

### Configuración en Código
**Archivo:** `lib/services/supabase/supabase_config.dart`

```dart
static const String supabaseUrl = 'https://ndddetlmqfyctapgvjnn.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kZGRldGxtcWZ5Y3RhcGd2am5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5NTY0NDAsImV4cCI6MjA3NTUzMjQ0MH0.ndB0VcFkA7Aj8LjKKLZAWxvBH1-Th_H1z-qF7S6-Cqs';
```

### Scripts SQL a Ejecutar (en orden)
1. `supabase_migration.sql` - Esquema principal
2. `create_buckets.sql` - Buckets de almacenamiento
3. `create_password_reset_codes_table.sql` - Tabla de reset
4. `supabase_storage_policies.sql` - Políticas de acceso

### Buckets de Storage
- `certificates` - PDFs de certificados
- `logos` - Logos de instituciones
- `documents` - Documentos adicionales

---

## 📧 EmailJS

### Credenciales
- **Service ID:** `service_bdav8mg`
- **Template ID:** `template_2fs5k3c`
- **User ID:** `o1eUKl5D0Qq9fJ1Jv`
- **API URL:** `https://api.emailjs.com/api/v1.0/email/send`
- **Dashboard:** https://dashboard.emailjs.com/

### Archivos que Usan EmailJS
- `lib/services/email_notification_service.dart`
- `lib/services/emisor_notification_service.dart`
- `lib/services/password_reset_service.dart`
- `lib/services/certificate_notification_service.dart`

### Parámetros del Template
- `name` - Nombre del remitente
- `to_email` - Email del destinatario
- `to_name` - Nombre del destinatario
- `subject` - Asunto del email
- `message` - Contenido del mensaje

---

## ⛓️ Blockchain (Polygon)

### Polygon Mainnet (Producción Actual)
- **RPC URL:** `https://polygon-rpc.com`
- **Explorer:** `https://polygonscan.com`
- **Chain ID:** `137`
- **Contrato:** `0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504`
- **Explorador del Contrato:** https://polygonscan.com/address/0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504

### Polygon Mumbai Testnet (Desarrollo)
- **RPC URL:** `https://rpc-mumbai.maticvigil.com`
- **Explorer:** `https://mumbai.polygonscan.com`
- **Chain ID:** `80001`
- **Faucet:** `https://faucet.polygon.technology`
- **Contrato:** `0x0000000000000000000000000000000000000000` (no desplegado)

### Configuración Actual
```dart
static const bool useTestnet = false; // USANDO MAINNET
```

### Configuración de Gas
- **Gas Price:** 30 gwei
- **Gas Limit:** 500000
- **Costo Estimado por Certificado:** ~0.006 MATIC (~$0.004 USD)

### Wallet y Claves Privadas
⚠️ **IMPORTANTE:** Las claves privadas se almacenan en Supabase en la tabla `system_blockchain_config`.

**NO** están hardcodeadas en el código. El sistema las obtiene automáticamente desde Supabase.

### Obtener MATIC
- **Testnet:** https://faucet.polygon.technology
- **Mainnet:** Comprar en exchange (Binance, Coinbase, etc.)
- Ver guía: `COMPRAR_MATIC_BINANCE.md`

---

## 🗃️ Base de Datos

### Tablas Principales
1. `institutions` - Instituciones académicas
2. `users` - Usuarios del sistema
3. `faculties` - Facultades
4. `programs` - Programas académicos
5. `certificates` - Certificados emitidos
6. `certificate_templates` - Plantillas de certificados
7. `system_blockchain_config` - Configuración de blockchain
8. `password_reset_codes` - Códigos de reset de contraseña

### Esquema
Ver archivos:
- `database_schema_for_drawio.sql`
- `lib/services/supabase/database_schema.sql`
- `database_diagram_dbml.dbml`

---

## 🛠️ Herramientas y Versiones

### Flutter
- **SDK:** >= 3.1.0 < 4.0.0
- **Dart:** Incluido con Flutter
- **Descarga:** https://flutter.dev/docs/get-started/install

### Node.js
- **Versión:** >= 16.0.0 (LTS recomendado)
- **Descarga:** https://nodejs.org/

### Git
- **Descarga:** https://git-scm.com/download/win

### Docker (Opcional)
- **Descarga:** Ver `INSTALAR_DOCKER_WINDOWS.md`

---

## 📦 Dependencias Principales

### Flutter (pubspec.yaml)
- `flutter`: SDK
- `firebase_core`: ^2.27.0
- `firebase_auth`: ^4.17.0
- `cloud_firestore`: ^4.5.0
- `firebase_storage`: ^11.0.16
- `supabase_flutter`: ^2.3.4
- `web3dart`: ^2.7.3
- `http`: ^1.5.0
- Y más... (ver `pubspec.yaml`)

### Node.js (package.json)
- `hardhat`: ^2.27.1
- `@nomicfoundation/hardhat-toolbox`: ^3.0.0
- `ethers`: (incluido en hardhat)
- `dotenv`: ^17.2.3
- Y más... (ver `package.json`)

---

## 🚀 Comandos Rápidos

### Desarrollo
```bash
# Instalar dependencias
flutter pub get
npm install

# Ejecutar aplicación
flutter run -d chrome
# O con puerto específico
flutter run -d web-server --web-port 8081

# Limpiar build
flutter clean
```

### Docker
```bash
# Construir y ejecutar
docker-compose up --build -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

---

## 📝 Notas de Seguridad

### ⚠️ NO Subir a Git
- Claves privadas de blockchain
- Archivos `.env` con credenciales
- `google-services.json` (si contiene info sensible)
- `GoogleService-Info.plist` (si contiene info sensible)
- Cualquier archivo con tokens o API keys

### ✅ Ya en .gitignore
- `.env*`
- `node_modules/`
- `build/`
- `.dart_tool/`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## 🔗 Enlaces Útiles

### Firebase
- Console: https://console.firebase.google.com/project/certiblock-e7a7c
- Documentación: https://firebase.google.com/docs

### Supabase
- Dashboard: https://supabase.com/dashboard/project/ndddetlmqfyctapgvjnn
- Documentación: https://supabase.com/docs

### EmailJS
- Dashboard: https://dashboard.emailjs.com/
- Documentación: https://www.emailjs.com/docs/

### Polygon
- Explorer Mainnet: https://polygonscan.com
- Explorer Testnet: https://mumbai.polygonscan.com
- Faucet Testnet: https://faucet.polygon.technology
- Documentación: https://docs.polygon.technology/

### Flutter
- Documentación: https://flutter.dev/docs
- Pub.dev: https://pub.dev/

---

## ✅ Checklist de Configuración

- [ ] Firebase configurado y funcionando
- [ ] Supabase configurado y base de datos creada
- [ ] EmailJS configurado y funcionando
- [ ] Blockchain configurado (contrato y wallet)
- [ ] Archivos de configuración en su lugar
- [ ] Dependencias instaladas
- [ ] Aplicación ejecuta sin errores

---

**Última actualización:** $(Get-Date -Format "yyyy-MM-dd")

**⚠️ RECORDATORIO:** Este archivo contiene información sensible. Mantenerlo seguro y NO subirlo a repositorios públicos.
