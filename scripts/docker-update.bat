@echo off
REM Script para actualizar Docker después de cambios en el código (Windows)

echo 🔄 Actualizando Docker con los últimos cambios...
echo.

REM Detener contenedor si está corriendo
echo 📦 Deteniendo contenedor actual...
docker-compose down

echo.
echo 🔨 Reconstruyendo imagen con los cambios...
echo ⏳ Esto puede tardar 2-5 minutos...
echo.

REM Reconstruir y ejecutar
docker-compose up --build -d

if %errorlevel% equ 0 (
    echo.
    echo ✅ Docker actualizado exitosamente!
    echo 🌐 La aplicación está disponible en: http://localhost:8081
    echo.
    echo 📊 Para ver los logs: docker-compose logs -f
) else (
    echo.
    echo ❌ Error al actualizar Docker
    exit /b 1
)

