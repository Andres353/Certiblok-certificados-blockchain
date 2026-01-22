@echo off
REM Script para construir la imagen Docker (Windows)

echo 🔨 Construyendo imagen Docker para Certiblock Frontend...

REM Construir la imagen
docker build -t certiblock-frontend:latest .

if %errorlevel% equ 0 (
    echo ✅ Imagen construida exitosamente
    echo 📦 Para ejecutar: docker run -d -p 8080:80 --name certiblock-frontend certiblock-frontend:latest
) else (
    echo ❌ Error al construir la imagen
    exit /b 1
)

