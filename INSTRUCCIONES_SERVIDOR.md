# Instrucciones para Iniciar el Servidor Flutter

## Problema
Cuando cierras Cursor, el servidor Flutter se detiene y el puerto 8081 queda libre, causando el error "localhost rechazó la conexión".

## Soluciones

### Opción 1: Script Automático (Recomendado)
1. Ejecuta el archivo `start_flutter_server.bat` que está en la raíz del proyecto
2. Esto iniciará automáticamente el servidor Flutter en el puerto 8081
3. El servidor se mantendrá ejecutándose hasta que cierres la ventana

### Opción 2: Comando Manual
1. Abre una terminal en el directorio del proyecto:
   ```
   cd "C:\Users\msi\Documents\PROYECTO DE GRADO CARPETAS\PROYECTO_DE_GRADO_INICIO\frontend\frontend_app"
   ```
2. Ejecuta:
   ```
   flutter run -d web-server --web-port 8081
   ```

### Opción 3: Desde Cursor
1. Abre Cursor en el directorio del proyecto
2. Abre la terminal integrada (Ctrl + `)
3. Ejecuta: `flutter run -d web-server --web-port 8081`

## Detección Automática de Puerto
El sistema ahora detecta automáticamente el puerto correcto basado en la URL actual:
- Si estás en `localhost:8080`, los QR usarán el puerto 8080
- Si estás en `localhost:8081`, los QR usarán el puerto 8081
- Si estás en `localhost:8082`, los QR usarán el puerto 8082

## Verificación
Una vez que el servidor esté ejecutándose, deberías ver:
```
lib\main.dart is being served at http://localhost:8081
```

## Comandos Útiles

### Hot Reload (cuando el servidor ya está corriendo)
```bash
hot_reload.bat
```

### Comandos manuales en la terminal del servidor
- `r` - Hot reload
- `R` - Hot restart  
- `q` - Quit

## URLs de Prueba
- Servidor principal: `http://localhost:8081`
- Verificación de certificado: `http://localhost:8081/#/verify/certificate/[ID_DEL_CERTIFICADO]`
