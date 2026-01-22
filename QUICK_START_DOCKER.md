# 🚀 Inicio Rápido con Docker

## ⚠️ IMPORTANTE: Instalar Docker Primero

Si ves el error "docker no se reconoce", necesitas instalar Docker Desktop primero.

**Ver guía de instalación:** `INSTALAR_DOCKER_WINDOWS.md`

## Para Windows (PowerShell o CMD)

### 1. Construir la imagen
```powershell
docker-compose build
```

### 2. Ejecutar
```powershell
docker-compose up
```

### 3. Acceder
Abre tu navegador en: **http://localhost:8080**

## Comandos Rápidos

```powershell
# Construir y ejecutar
docker-compose up --build

# Ejecutar en segundo plano
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

## O usando los scripts

```powershell
# Construir
.\scripts\docker-build.bat

# Ejecutar
.\scripts\docker-run.bat

# Detener
.\scripts\docker-stop.bat
```

## ⚠️ Importante

- Asegúrate de tener Docker Desktop corriendo
- La primera vez puede tardar 5-10 minutos (descarga de imágenes)
- Necesitas conexión a internet (para Firebase y Supabase)

## 📚 Documentación Completa

Ver `README_DOCKER.md` para más detalles.

