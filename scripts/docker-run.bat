@echo off
REM Script para ejecutar el contenedor Docker (Windows)

echo 🚀 Iniciando contenedor Certiblock Frontend...

REM Detener y eliminar contenedor existente si existe
docker stop certiblock-frontend 2>nul
docker rm certiblock-frontend 2>nul

REM Ejecutar el contenedor
docker run -d -p 8080:80 --name certiblock-frontend --restart unless-stopped certiblock-frontend:latest

if %errorlevel% equ 0 (
    echo ✅ Contenedor iniciado exitosamente
    echo 🌐 Aplicación disponible en: http://localhost:8080
    echo 📋 Ver logs: docker logs -f certiblock-frontend
) else (
    echo ❌ Error al iniciar el contenedor
    exit /b 1
)

