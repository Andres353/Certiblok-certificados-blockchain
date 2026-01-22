# ✅ Checklist Pre-Formateo - CertiBlock

Lista de verificación antes de formatear la laptop y subir a Git.

---

## 📋 Antes de Formatear

### 1. Verificar Archivos en Git
- [ ] Todos los archivos de código están en Git
- [ ] Archivos de configuración documentados están en Git
- [ ] Documentación completa está en Git
- [ ] `.gitignore` está configurado correctamente

### 2. Verificar que NO estén en Git (deben estar en .gitignore)
- [ ] `.env*` - NO deben estar
- [ ] `node_modules/` - NO debe estar
- [ ] `build/` - NO debe estar
- [ ] `.dart_tool/` - NO debe estar
- [ ] Claves privadas de blockchain - NO deben estar
- [ ] `google-services.json` - Verificar si debe estar o no

### 3. Documentación Creada
- [ ] `GUIA_INSTALACION_COMPLETA.md` - ✅ Creado
- [ ] `CONFIGURACIONES_CREDENCIALES.md` - ✅ Creado
- [ ] `RESUMEN_RAPIDO_INSTALACION.md` - ✅ Creado
- [ ] `CHECKLIST_PRE_FORMATEO.md` - ✅ Este archivo

### 4. Credenciales Documentadas
- [ ] Firebase - Credenciales documentadas
- [ ] Supabase - Credenciales documentadas
- [ ] EmailJS - Credenciales documentadas
- [ ] Blockchain - Configuración documentada
- [ ] Dirección del contrato - Documentada

### 5. Scripts SQL Documentados
- [ ] `supabase_migration.sql` - En Git
- [ ] `create_buckets.sql` - En Git
- [ ] `create_password_reset_codes_table.sql` - En Git
- [ ] `supabase_storage_policies.sql` - En Git

### 6. Archivos de Configuración
- [ ] `pubspec.yaml` - Dependencias Flutter
- [ ] `package.json` - Dependencias Node.js
- [ ] `firebase.json` - Configuración Firebase
- [ ] `docker-compose.yml` - Configuración Docker
- [ ] `Dockerfile` - Imagen Docker
- [ ] `nginx.conf` - Configuración Nginx

### 7. Scripts de Desarrollo
- [ ] `start_flutter_server.bat` - Script de inicio
- [ ] `hot_reload.bat` - Script de hot reload
- [ ] Scripts en `scripts/` - Scripts de Docker

---

## 🔐 Información Sensible a Guardar Fuera de Git

### Opción 1: Guardar en Lugar Seguro
- [ ] Credenciales de Firebase (si hay alguna adicional)
- [ ] Service Account Keys de Firebase (si existen)
- [ ] Claves privadas de blockchain (si se necesitan)
- [ ] Contraseñas de administrador (si se necesitan)

### Opción 2: Ya Están en Servicios Cloud
- [ ] Firebase - Credenciales en Firebase Console
- [ ] Supabase - Credenciales en Supabase Dashboard
- [ ] EmailJS - Credenciales en EmailJS Dashboard
- [ ] Blockchain - Wallet en Supabase (tabla `system_blockchain_config`)

---

## 📦 Verificar Estado del Repositorio

```bash
# Verificar estado
git status

# Verificar que no haya archivos sensibles
git ls-files | grep -E "\.env|google-services|GoogleService|private.*key"

# Verificar .gitignore
cat .gitignore
```

---

## 🚀 Comandos Finales Antes de Formatear

```bash
# 1. Asegurar que todo esté commiteado
git add .
git commit -m "Documentación completa pre-formateo"

# 2. Verificar que no haya cambios sin commitear
git status

# 3. Push a repositorio remoto
git push origin main
# O la rama que uses

# 4. Verificar que el push fue exitoso
git log --oneline -5
```

---

## 📝 Información Adicional a Guardar

### Si tienes datos locales importantes:
- [ ] Usuarios de prueba creados
- [ ] Certificados de prueba generados
- [ ] Configuraciones personalizadas adicionales
- [ ] Notas de desarrollo importantes

### Si usas herramientas adicionales:
- [ ] Configuración del IDE (VS Code, Android Studio, etc.)
- [ ] Extensiones recomendadas
- [ ] Configuraciones de debug

---

## ✅ Post-Formateo (En Nueva Laptop)

### Verificar que Funciona
1. [ ] Clonar repositorio
2. [ ] Seguir `GUIA_INSTALACION_COMPLETA.md`
3. [ ] Verificar que la aplicación ejecuta
4. [ ] Verificar login funciona
5. [ ] Verificar conexión a Firebase
6. [ ] Verificar conexión a Supabase
7. [ ] Verificar envío de emails
8. [ ] Verificar transacciones blockchain (si aplica)

---

## 🔗 Enlaces Rápidos

- **Firebase Console:** https://console.firebase.google.com/project/certiblock-e7a7c
- **Supabase Dashboard:** https://supabase.com/dashboard/project/ndddetlmqfyctapgvjnn
- **EmailJS Dashboard:** https://dashboard.emailjs.com/
- **Polygon Explorer:** https://polygonscan.com/address/0x92DCb57F0c42D31FE3FF8Cd4bD44C6689434D504

---

## 📚 Documentación de Referencia

1. **`GUIA_INSTALACION_COMPLETA.md`** - Guía completa paso a paso
2. **`CONFIGURACIONES_CREDENCIALES.md`** - Todas las credenciales
3. **`RESUMEN_RAPIDO_INSTALACION.md`** - Resumen rápido
4. **`README.md`** - Información general del proyecto
5. **`README_DOCKER.md`** - Guía de Docker
6. **`CONTROLES_AUTENTICACION.md`** - Controles de seguridad

---

## ⚠️ Recordatorios Importantes

1. **NO** subir claves privadas a Git
2. **SÍ** documentar todas las credenciales necesarias
3. **SÍ** incluir todos los scripts SQL necesarios
4. **SÍ** incluir archivos de configuración (sin datos sensibles)
5. **SÍ** incluir documentación completa

---

**Fecha de Checklist:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

**Estado:** ⬜ Pendiente / ✅ Completado

---

¡Con esta checklist deberías tener todo listo para formatear y continuar en otra laptop! 🚀
