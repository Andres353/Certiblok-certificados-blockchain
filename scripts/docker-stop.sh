#!/bin/bash
# Script para detener el contenedor Docker

echo "🛑 Deteniendo contenedor Certiblock Frontend..."

docker stop certiblock-frontend

if [ $? -eq 0 ]; then
    echo "✅ Contenedor detenido"
    echo "🗑️  Para eliminar: docker rm certiblock-frontend"
else
    echo "⚠️  El contenedor no estaba corriendo o no existe"
fi

