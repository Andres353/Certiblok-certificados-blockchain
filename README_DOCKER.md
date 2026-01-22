# 🐳 Docker Setup - Certiblock Frontend

Guía para ejecutar la aplicación Flutter Web usando Docker.

## 📋 Requisitos Previos

- **Docker Desktop instalado** (versión 20.10 o superior)
  - ⚠️ Si no lo tienes, ve a `INSTALAR_DOCKER_WINDOWS.md`
- Docker Compose (incluido en Docker Desktop)
- Al menos 4GB de RAM disponible
- Conexión a internet (para Firebase y Supabase)
- WSL 2 habilitado (requisito de Docker Desktop en Windows)

## 🚀 Inicio Rápido

### Opción 1: Usando Docker Compose (Recomendado)

```bash
# Construir y ejecutar
docker-compose up --build

# O en modo detached (segundo plano)
docker-compose up -d --build
```

### Opción 1.5: Usando Scripts (Más fácil)

**Windows:**
```powershell
# Actualizar después de cambios
.\scripts\docker-update.bat
```

**Linux/Mac:**
```bash
# Dar permisos de ejecución (solo la primera vez)
chmod +x scripts/docker-update.sh

# Actualizar después de cambios
./scripts/docker-update.sh
```

La aplicación estará disponible en: **http://localhost:8081**

### Opción 2: Usando Docker directamente

```bash
# Construir la imagen
docker build -t certiblock-frontend .

# Ejecutar el contenedor
docker run -d -p 8081:80 --name certiblock-frontend certiblock-frontend
```

## 📝 Comandos Útiles

### Ver logs
```bash
docker-compose logs -f
# O con Docker directo
docker logs -f certiblock-frontend
```

### Detener la aplicación
```bash
docker-compose down
# O con Docker directo
docker stop certiblock-frontend
docker rm certiblock-frontend
```

### 🔄 Actualizar Docker después de cambios en el código

**⚠️ Importante:** Docker no tiene hot reload. Cada vez que hagas cambios en el código, necesitas reconstruir la imagen.

#### Proceso completo de actualización:

```powershell
# 1. Detener el contenedor actual
docker-compose down

# 2. Reconstruir la imagen con los cambios y ejecutar
docker-compose up --build -d

# O en un solo comando (recomendado):
docker-compose up --build -d
```

#### Proceso rápido (sin detener primero):

```powershell
# Reconstruir y reiniciar automáticamente
docker-compose up --build -d
```

#### Si solo cambiaste archivos estáticos (sin cambios en código Dart):

```powershell
# Detener, reconstruir y ejecutar
docker-compose down
docker-compose up --build -d
```

**Tiempo estimado:**
- Primera vez: ~5-10 minutos
- Reconstrucciones subsecuentes: ~2-5 minutos (usa cache cuando es posible)

**Nota:** Durante el desarrollo, es más rápido usar `flutter run -d chrome` para tener hot reload. Usa Docker solo para probar el build de producción.

### Acceder al contenedor
```bash
docker exec -it certiblock-frontend sh
```

## 🔧 Configuración

### Variables de Entorno

Puedes agregar variables de entorno en `docker-compose.yml`:

```yaml
environment:
  - FLUTTER_WEB_USE_SKIA=false
  - SUPABASE_URL=tu_url
  - SUPABASE_ANON_KEY=tu_key
```

### Cambiar Puerto

Edita `docker-compose.yml` y cambia:
```yaml
ports:
  - "3000:80"  # Cambia 3000 por el puerto que quieras
```

## 🏗️ Estructura de Archivos Docker

```
.
├── Dockerfile              # Configuración de la imagen
├── docker-compose.yml      # Orquestación de contenedores
├── .dockerignore          # Archivos a excluir
├── nginx.conf             # Configuración del servidor web
└── README_DOCKER.md       # Esta documentación
```

## 📦 Proceso de Build

El Dockerfile usa **multi-stage build**:

1. **Stage 1 (build)**: Compila la aplicación Flutter Web
2. **Stage 2 (production)**: Crea imagen ligera con nginx para servir los archivos estáticos

### Tamaño de la Imagen

- Imagen final: ~50-70MB (nginx alpine + archivos compilados)
- Tiempo de build: ~5-10 minutos (primera vez)
- Tiempo de build subsecuente: ~2-5 minutos (con cache)

## 🌐 Despliegue en Producción

### Opción 1: Docker Hub

```bash
# Tag de la imagen
docker tag certiblock-frontend tu-usuario/certiblock-frontend:latest

# Push a Docker Hub
docker push tu-usuario/certiblock-frontend:latest
```

### Opción 2: Servidor propio

```bash
# En el servidor
docker pull tu-usuario/certiblock-frontend:latest
docker run -d -p 80:80 --name certiblock-frontend tu-usuario/certiblock-frontend:latest
```

### Opción 3: Con docker-compose en servidor

```bash
# Copiar archivos al servidor
scp docker-compose.yml nginx.conf .dockerignore Dockerfile usuario@servidor:/ruta/app/

# En el servidor
docker-compose up -d
```

## 🔍 Troubleshooting

### Error: "Cannot connect to Docker daemon" o "The system cannot find the file specified" (Windows)

**En Windows:**
Este error indica que **Docker Desktop no está corriendo**.

1. **Abre Docker Desktop** desde el menú de inicio o la bandeja del sistema
2. Espera a que Docker Desktop inicie completamente (verás el ícono de Docker en la bandeja del sistema)
3. Verifica que esté corriendo:
   ```powershell
   docker ps
   ```
4. Si Docker Desktop no está instalado, sigue las instrucciones en `INSTALAR_DOCKER_WINDOWS.md`

**En Linux/Mac:**
```bash
# Verificar que Docker esté corriendo
sudo systemctl status docker
sudo systemctl start docker
```

### Error: "401 Unauthorized: email must be verified" o problemas de autenticación con Docker Hub

Este error ocurre cuando Docker intenta autenticarse con Docker Hub pero hay credenciales inválidas o un email no verificado.

**Solución:**

1. **Cerrar sesión de Docker Hub** (si hay credenciales guardadas):
   ```powershell
   docker logout
   ```

2. **Si necesitas hacer login** (solo para imágenes privadas):
   ```powershell
   docker login
   ```
   Asegúrate de que el email de tu cuenta esté verificado en Docker Hub.

3. **Para imágenes públicas** (como `nginx:alpine` y `flutter:stable`), no necesitas autenticación. Simplemente ejecuta:
   ```powershell
   docker-compose up --build
   ```

**Nota:** Las imágenes usadas en este proyecto (`nginx:alpine` y `ghcr.io/cirruslabs/flutter:stable`) son públicas, por lo que normalmente no requieren autenticación.

### Error: "Could not find an option named '--web-renderer'"

Este error ocurre en versiones recientes de Flutter donde el flag `--web-renderer` fue eliminado.

**Solución:** El Dockerfile ya está actualizado. Si tienes una versión antigua, cambia:
```dockerfile
RUN flutter build web --release --web-renderer html
```
Por:
```dockerfile
RUN flutter build web --release
```

### Error: "Port already in use"
```bash
# Cambiar el puerto en docker-compose.yml
# O detener el proceso que usa el puerto
```

### La aplicación no carga
```bash
# Verificar logs
docker-compose logs frontend

# Verificar que el build fue exitoso
docker images | grep certiblock-frontend
```

### Reconstruir desde cero
```bash
# Eliminar contenedores e imágenes
docker-compose down --rmi all

# Limpiar cache de Docker
docker system prune -a

# Reconstruir
docker-compose up --build
```

## 📊 Monitoreo

### Ver uso de recursos
```bash
docker stats certiblock-frontend
```

### Ver información del contenedor
```bash
docker inspect certiblock-frontend
```

## 🔐 Seguridad

- La imagen usa nginx:alpine (ligera y segura)
- Headers de seguridad configurados en nginx.conf
- No se exponen puertos innecesarios
- Variables sensibles se pasan como environment variables

## 📚 Recursos Adicionales

- [Documentación de Docker](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Flutter Web](https://flutter.dev/web)
- [Nginx](https://nginx.org/en/docs/)

## ⚠️ Notas Importantes

1. **Firebase y Supabase**: La aplicación necesita conexión a internet para funcionar
2. **Credenciales**: Asegúrate de tener `firebase_options.dart` con las credenciales correctas
3. **Primera ejecución**: El build puede tardar varios minutos
4. **Hot Reload**: No está disponible en Docker (solo en desarrollo local)
5. **Volúmenes**: Si necesitas persistencia, agrega volúmenes en docker-compose.yml

## 🎯 Próximos Pasos

1. Construir la imagen: `docker-compose build`
2. Ejecutar: `docker-compose up`
3. Acceder: http://localhost:8081
4. Verificar que todo funcione correctamente

---

**¿Problemas?** Revisa los logs con `docker-compose logs` o crea un issue.

