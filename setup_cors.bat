@echo off
echo Configurando CORS para Firebase Storage...
echo.

echo Instalando Google Cloud SDK si no está instalado...
where gsutil >nul 2>nul
if %errorlevel% neq 0 (
    echo Google Cloud SDK no encontrado. Por favor instálalo desde:
    echo https://cloud.google.com/sdk/docs/install
    pause
    exit /b 1
)

echo.
echo Configurando CORS...
gsutil cors set cors_config.json gs://certiblock-e7a7c.appspot.com

if %errorlevel% equ 0 (
    echo.
    echo ✅ CORS configurado exitosamente!
    echo.
    echo Ahora puedes subir imágenes desde Flutter web.
) else (
    echo.
    echo ❌ Error al configurar CORS.
    echo Verifica que tengas permisos de administrador en el proyecto Firebase.
)

echo.
pause
