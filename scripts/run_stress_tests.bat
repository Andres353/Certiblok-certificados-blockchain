@echo off
REM scripts/run_stress_tests.bat
REM Script para ejecutar todas las pruebas de estrés en Windows

echo.
echo ========================================
echo CertiBlock - Pruebas de Estres
echo ========================================
echo.

set PASSED=0
set FAILED=0

echo 1. Ejecutando Pruebas de Importacion CSV...
echo ----------------------------------------
flutter test test/stress_test_csv_import.dart
if %ERRORLEVEL% EQU 0 (
    echo [OK] Pruebas de Importacion CSV
    set /a PASSED+=1
) else (
    echo [ERROR] Pruebas de Importacion CSV
    set /a FAILED+=1
)
echo.

echo 2. Ejecutando Benchmarks de Rendimiento...
echo ----------------------------------------
flutter test test/performance_benchmark.dart
if %ERRORLEVEL% EQU 0 (
    echo [OK] Benchmarks de Rendimiento
    set /a PASSED+=1
) else (
    echo [ERROR] Benchmarks de Rendimiento
    set /a FAILED+=1
)
echo.

echo 3. Ejecutando Pruebas de Concurrencia...
echo ----------------------------------------
flutter test test/concurrency_test.dart
if %ERRORLEVEL% EQU 0 (
    echo [OK] Pruebas de Concurrencia
    set /a PASSED+=1
) else (
    echo [ERROR] Pruebas de Concurrencia
    set /a FAILED+=1
)
echo.

echo ========================================
echo RESUMEN DE PRUEBAS
echo ========================================
echo Pruebas exitosas: %PASSED%
echo Pruebas fallidas: %FAILED%
echo.

if %FAILED% EQU 0 (
    echo [OK] Todas las pruebas pasaron exitosamente!
    exit /b 0
) else (
    echo [ERROR] Algunas pruebas fallaron. Revisa los resultados arriba.
    exit /b 1
)
