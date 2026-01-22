#!/bin/bash
# Script para construir la imagen Docker

echo "🔨 Construyendo imagen Docker para Certiblock Frontend..."

# Construir la imagen
docker build -t certiblock-frontend:latest .

if [ $? -eq 0 ]; then
    echo "✅ Imagen construida exitosamente"
    echo "📦 Para ejecutar: docker run -d -p 8080:80 --name certiblock-frontend certiblock-frontend:latest"
else
    echo "❌ Error al construir la imagen"
    exit 1
fi

