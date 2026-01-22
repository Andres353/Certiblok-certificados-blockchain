#!/bin/bash
# Script para actualizar Docker después de cambios en el código (Linux/Mac)

echo "🔄 Actualizando Docker con los últimos cambios..."
echo ""

# Detener contenedor si está corriendo
echo "📦 Deteniendo contenedor actual..."
docker-compose down

echo ""
echo "🔨 Reconstruyendo imagen con los cambios..."
echo "⏳ Esto puede tardar 2-5 minutos..."
echo ""

# Reconstruir y ejecutar
docker-compose up --build -d

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker actualizado exitosamente!"
    echo "🌐 La aplicación está disponible en: http://localhost:8081"
    echo ""
    echo "📊 Para ver los logs: docker-compose logs -f"
else
    echo ""
    echo "❌ Error al actualizar Docker"
    exit 1
fi

