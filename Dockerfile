# Dockerfile para Flutter Web Application
# Multi-stage build para optimizar el tamaño de la imagen

# ============================================
# Stage 1: Build - Compilar la aplicación
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Configurar directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración
COPY pubspec.yaml ./
COPY pubspec.lock* ./

# Instalar dependencias
RUN flutter pub get

# Copiar código fuente
COPY . .

# Compilar para web en modo release
RUN flutter build web --release

# ============================================
# Stage 2: Production - Servir con nginx
# ============================================
FROM nginx:alpine

# Copiar archivos compilados desde el stage de build
COPY --from=build /app/build/web /usr/share/nginx/html

# Copiar configuración personalizada de nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer puerto 80
EXPOSE 80

# Comando para iniciar nginx
CMD ["nginx", "-g", "daemon off;"]

