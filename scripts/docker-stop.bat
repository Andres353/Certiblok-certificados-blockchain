@echo off
REM Script para detener el contenedor Docker (Windows)

echo 🛑 Deteniendo contenedor Certiblock Frontend...

docker stop certiblock-frontend

if %errorlevel% equ 0 (
    echo ✅ Contenedor detenido
    echo 🗑️  Para eliminar: docker rm certiblock-frontend
) else (
    echo ⚠️  El contenedor no estaba corriendo o no existe
)

