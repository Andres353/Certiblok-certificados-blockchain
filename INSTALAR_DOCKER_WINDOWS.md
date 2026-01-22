# 🐳 Instalación de Docker en Windows

## 📋 Requisitos del Sistema

- Windows 10 64-bit: Pro, Enterprise, o Education (Build 19041 o superior)
- Windows 11 64-bit: Home o Pro (Build 22000 o superior)
- Habilitar WSL 2 (Windows Subsystem for Linux 2)
- Virtualización habilitada en BIOS

## 🚀 Pasos de Instalación

### Paso 1: Verificar Requisitos

#### Verificar versión de Windows
1. Presiona `Win + R`
2. Escribe `winver` y presiona Enter
3. Verifica que tengas Windows 10 (19041+) o Windows 11

#### Verificar si WSL 2 está instalado
Abre PowerShell como **Administrador** y ejecuta:
```powershell
wsl --version
```

Si no está instalado o la versión es antigua, continúa con el Paso 2.

### Paso 2: Instalar WSL 2

Abre PowerShell como **Administrador** y ejecuta:

```powershell
# Habilitar características de Windows necesarias
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Reiniciar el equipo (IMPORTANTE)
# Después del reinicio, continúa con:
wsl --set-default-version 2
```

### Paso 3: Instalar Docker Desktop

1. **Descargar Docker Desktop**
   - Ve a: https://www.docker.com/products/docker-desktop/
   - O descarga directo: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe

2. **Ejecutar el instalador**
   - Ejecuta `Docker Desktop Installer.exe`
   - Acepta los términos y condiciones
   - Marca la opción "Use WSL 2 instead of Hyper-V" (si está disponible)
   - Haz clic en "Install"

3. **Reiniciar** (si se solicita)

4. **Iniciar Docker Desktop**
   - Busca "Docker Desktop" en el menú de inicio
   - Ejecútalo y espera a que inicie (puede tardar 1-2 minutos)
   - Verás el ícono de Docker en la bandeja del sistema

### Paso 4: Verificar Instalación

Abre PowerShell (normal, no como administrador) y ejecuta:

```powershell
# Verificar Docker
docker --version

# Verificar Docker Compose
docker-compose --version

# O en versiones nuevas de Docker Desktop:
docker compose version
```

Deberías ver algo como:
```
Docker version 24.0.0, build ...
Docker Compose version v2.20.0
```

### Paso 5: Probar Docker

```powershell
# Ejecutar un contenedor de prueba
docker run hello-world
```

Si ves "Hello from Docker!", ¡está funcionando correctamente!

## ⚠️ Solución de Problemas

### Error: "WSL 2 installation is incomplete"

1. Abre PowerShell como Administrador
2. Ejecuta:
```powershell
wsl --update
wsl --set-default-version 2
```

### Error: "Virtualization is not enabled"

1. Reinicia tu PC
2. Entra al BIOS/UEFI (generalmente F2, F10, F12 o Del al iniciar)
3. Busca "Virtualization Technology" o "Intel VT-x" o "AMD-V"
4. Habilítalo
5. Guarda y reinicia

### Docker Desktop no inicia

1. Verifica que WSL 2 esté funcionando:
```powershell
wsl --status
```

2. Reinicia Docker Desktop desde el menú de inicio

3. Si persiste, desinstala y reinstala Docker Desktop

### Comando 'docker' no reconocido

1. Cierra y vuelve a abrir PowerShell/Terminal
2. Verifica que Docker Desktop esté corriendo (ícono en bandeja del sistema)
3. Reinicia Docker Desktop

## ✅ Después de Instalar

Una vez instalado Docker, puedes usar tu aplicación:

```powershell
# Ir a la carpeta del proyecto
cd "C:\Users\msi\Documents\PROYECTO DE GRADO CARPETAS\PROYECTO_DE_GRADO_INICIO\frontend\frontend_app"

# Construir y ejecutar
docker-compose up --build
```

## 📚 Recursos

- [Documentación oficial de Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)
- [Guía de WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install)
- [Troubleshooting Docker Desktop](https://docs.docker.com/desktop/troubleshoot/overview/)

## 🎯 Próximos Pasos

1. Instala Docker Desktop siguiendo los pasos arriba
2. Verifica la instalación con `docker --version`
3. Vuelve a `QUICK_START_DOCKER.md` para ejecutar tu aplicación

---

**¿Necesitas ayuda?** Revisa la sección de troubleshooting o consulta la documentación oficial.

