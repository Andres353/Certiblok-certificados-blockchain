#!/bin/bash
# Script para ejecutar el contenedor Docker

echo "🚀 Iniciando contenedor Certiblock Frontend..."

# Detener y eliminar contenedor existente si existe
docker stop certiblock-frontend 2>/dev/null
docker rm certiblock-frontend 2>/dev/null

# Ejecutar el contenedor
docker run -d \
  -p 8080:80 \
  --name certiblock-frontend \
  --restart unless-stopped \
  certiblock-frontend:latest

if [ $? -eq 0 ]; then
    echo "✅ Contenedor iniciado exitosamente"
    echo "🌐 Aplicación disponible en: http://localhost:8080"
    echo "📋 Ver logs: docker logs -f certiblock-frontend"
else
    echo "❌ Error al iniciar el contenedor"
    exit 1
fi

