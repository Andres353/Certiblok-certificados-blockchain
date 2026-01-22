#!/bin/bash
# scripts/run_stress_tests.sh
# Script para ejecutar todas las pruebas de estrés

echo "🧪 ========================================="
echo "🧪 CertiBlock - Pruebas de Estrés"
echo "🧪 ========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mostrar resultados
show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Contador de pruebas
PASSED=0
FAILED=0

echo "📊 1. Ejecutando Pruebas de Importación CSV..."
echo "----------------------------------------"
if flutter test test/stress_test_csv_import.dart; then
    show_result 0 "Pruebas de Importación CSV"
    ((PASSED++))
else
    show_result 1 "Pruebas de Importación CSV"
    ((FAILED++))
fi
echo ""

echo "⚡ 2. Ejecutando Benchmarks de Rendimiento..."
echo "----------------------------------------"
if flutter test test/performance_benchmark.dart; then
    show_result 0 "Benchmarks de Rendimiento"
    ((PASSED++))
else
    show_result 1 "Benchmarks de Rendimiento"
    ((FAILED++))
fi
echo ""

echo "🔄 3. Ejecutando Pruebas de Concurrencia..."
echo "----------------------------------------"
if flutter test test/concurrency_test.dart; then
    show_result 0 "Pruebas de Concurrencia"
    ((PASSED++))
else
    show_result 1 "Pruebas de Concurrencia"
    ((FAILED++))
fi
echo ""

# Resumen
echo "🧪 ========================================="
echo "📊 RESUMEN DE PRUEBAS"
echo "🧪 ========================================="
echo -e "${GREEN}✅ Pruebas exitosas: $PASSED${NC}"
echo -e "${RED}❌ Pruebas fallidas: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡Todas las pruebas pasaron exitosamente!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Algunas pruebas fallaron. Revisa los resultados arriba.${NC}"
    exit 1
fi
