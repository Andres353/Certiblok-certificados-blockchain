# ⚡ Resumen Rápido de Instalación - CertiBlock

Guía rápida para configurar el proyecto en una nueva laptop.

---

## 🚀 Instalación Rápida (5 pasos)

### 1. Instalar Herramientas
```bash
# Flutter (>= 3.1.0)
# Descargar desde: https://flutter.dev/docs/get-started/install

# Node.js (>= 16.0.0)
# Descargar desde: https://nodejs.org/

# Git
# Descargar desde: https://git-scm.com/download/win
```

### 2. Clonar y Configurar Proyecto
```bash
git clone [URL_DEL_REPOSITORIO]
cd frontend_app
flutter pub get
npm install
```

### 3. Configurar Firebase
- Descargar `google-services.json` desde Firebase Console
- Colocar en: `android/app/google-services.json`
- Credenciales ya están en: `lib/firebase_options.dart`

### 4. Configurar Supabase
- Credenciales ya están en: `lib/services/supabase/supabase_config.dart`
- Ejecutar scripts SQL en Supabase Dashboard (ver `GUIA_INSTALACION_COMPLETA.md`)

### 5. Ejecutar
```bash
flutter run -d chrome
```

---

## 🔑 Credenciales Rápidas

### Firebase
- **Project ID:** `certiblock-e7a7c`
- **Console:** https://console.firebase.google.com/project/certiblock-e7a7c

### Supabase
- **URL:** `https://ndddetlmqfyctapgvjnn.supabase.co`
- **Dashboard:** https://supabase.com/dashboard/project/ndddetlmqfyctapgvjnn

### EmailJS
- **Service ID:** `service_bdav8mg`
- **Template ID:** `template_2fs5k3c`
- **User ID:** `o1eUKl5D0Qq9fJ1Jv`

### Blockchain (Polygon Mainnet)
- **Contrato:** `0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504`
- **Chain ID:** `137`
- **Explorer:** https://polygonscan.com/address/0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504

---

## 📚 Documentación Completa

Para información detallada, ver:
- **`GUIA_INSTALACION_COMPLETA.md`** - Guía completa paso a paso
- **`CONFIGURACIONES_CREDENCIALES.md`** - Todas las credenciales y configuraciones

---

## ✅ Verificación Rápida

```bash
# Verificar Flutter
flutter doctor

# Verificar dependencias
flutter pub get
npm install

# Ejecutar aplicación
flutter run -d chrome
```

---

## 🆘 Problemas Comunes

### Error: "Flutter not found"
→ Agregar Flutter al PATH del sistema

### Error: "Firebase not initialized"
→ Verificar `lib/firebase_options.dart` y `android/app/google-services.json`

### Error: "Supabase connection failed"
→ Verificar credenciales en `lib/services/supabase/supabase_config.dart`

---

**Para más detalles, ver `GUIA_INSTALACION_COMPLETA.md`**
