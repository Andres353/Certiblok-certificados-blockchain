# 🧪 Guía de Pruebas de Estrés - CertiBlock

Esta guía te ayudará a realizar pruebas de estrés en tu aplicación CertiBlock para validar su rendimiento, estabilidad y capacidad de manejar cargas altas.

## 📋 Índice

1. [Pruebas de Importación CSV](#pruebas-de-importación-csv)
2. [Pruebas de Rendimiento](#pruebas-de-rendimiento)
3. [Pruebas de Memoria](#pruebas-de-memoria)
4. [Pruebas de Concurrencia](#pruebas-de-concurrencia)
5. [Herramientas Recomendadas](#herramientas-recomendadas)
6. [Métricas a Monitorear](#métricas-a-monitorear)

---

## 1. Pruebas de Importación CSV

### Ejecutar Pruebas Automatizadas

```bash
# Ejecutar todas las pruebas de estrés de CSV
flutter test test/stress_test_csv_import.dart

# Ejecutar una prueba específica
flutter test test/stress_test_csv_import.dart --name "Test 1: Importar 10 estudiantes"

# Ejecutar con verbose para ver más detalles
flutter test test/stress_test_csv_import.dart -v
```

### Pruebas Incluidas

- ✅ **10 estudiantes**: Prueba básica
- ✅ **50 estudiantes**: Prueba media
- ✅ **100 estudiantes**: Prueba estándar
- ✅ **500 estudiantes**: Prueba de carga
- ✅ **1000 estudiantes**: Prueba de estrés
- ✅ **Caracteres especiales**: Validación de codificación
- ✅ **Datos inválidos**: Validación de errores
- ✅ **Archivo grande (10MB)**: Límite de capacidad

### Resultados Esperados

```
🧪 Iniciando prueba: 100 estudiantes
⏱️  Tiempo de generación: 5ms
📊 Tamaño del archivo: 8.5 KB
✅ CSV parseado exitosamente
⏱️  Tiempo de parseo: 45ms
📊 Estudiantes parseados: 100
⚡ Velocidad: 2222.22 estudiantes/segundo
```

---

## 2. Pruebas de Rendimiento

### Ejecutar Benchmarks

```bash
# Ejecutar benchmarks de rendimiento
flutter test test/performance_benchmark.dart

# Ejecutar con reporte detallado
flutter test test/performance_benchmark.dart --reporter expanded
```

### Benchmarks Incluidos

- ✅ **Codificación UTF-8**: Velocidad de encoding/decoding
- ✅ **Parseo CSV**: Velocidad de procesamiento
- ✅ **Validación de datos**: Eficiencia de regex
- ✅ **Generación de contraseñas**: Velocidad de creación

---

## 3. Pruebas de Memoria

### Usar Flutter DevTools

```bash
# Iniciar la aplicación con profiling
flutter run --profile

# Abrir DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Monitorear Memoria

1. Abre DevTools en el navegador
2. Ve a la pestaña "Memory"
3. Realiza la importación de estudiantes
4. Observa el uso de memoria
5. Busca fugas de memoria (memory leaks)

### Prueba Manual de Memoria

```dart
// Agregar en tu código de prueba
import 'dart:developer' as developer;

void testMemoryUsage() {
  developer.log('Memoria antes: ${_getMemoryUsage()}');
  
  // Realizar operación
  await importarEstudiantes(1000);
  
  developer.log('Memoria después: ${_getMemoryUsage()}');
}

String _getMemoryUsage() {
  // En web, usar performance.memory
  // En mobile, usar herramientas nativas
  return 'N/A';
}
```

---

## 4. Pruebas de Concurrencia

### Simular Múltiples Usuarios

Crea un script para simular múltiples importaciones simultáneas:

```dart
// test/concurrency_test.dart
import 'dart:async';
import 'package:frontend_app/services/csv_student_import_service.dart';

Future<void> testConcurrentImports() async {
  print('🧪 Iniciando prueba de concurrencia...');
  
  final futures = <Future>[];
  final stopwatch = Stopwatch()..start();
  
  // Simular 10 importaciones simultáneas de 100 estudiantes cada una
  for (int i = 0; i < 10; i++) {
    futures.add(_importStudents(100, i));
  }
  
  await Future.wait(futures);
  
  stopwatch.stop();
  print('⏱️  Tiempo total: ${stopwatch.elapsedMilliseconds}ms');
  print('⚡ Velocidad promedio: ${(1000 / (stopwatch.elapsedMilliseconds / 10)).toStringAsFixed(2)} importaciones/segundo');
}

Future<void> _importStudents(int count, int batchId) async {
  // Generar y parsear CSV
  final csvContent = _generateTestCsv(count);
  final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
  
  try {
    final students = await CsvStudentImportService.parseCsv(csvBytes);
    print('✅ Lote $batchId: ${students.length} estudiantes procesados');
  } catch (e) {
    print('❌ Lote $batchId: Error - $e');
  }
}
```

---

## 5. Herramientas Recomendadas

### Flutter DevTools

```bash
# Instalar
flutter pub global activate devtools

# Ejecutar
flutter pub global run devtools
```

**Características:**
- Profiling de CPU
- Análisis de memoria
- Network inspector
- Performance overlay

### Dart Observatory (Deprecated, usar DevTools)

Para versiones antiguas de Flutter, usar:
```bash
flutter run --observatory-port=8888
```

### Herramientas de Terceros

1. **Apache JMeter**: Para pruebas de carga HTTP
2. **Postman**: Para pruebas de API
3. **K6**: Para pruebas de carga modernas
4. **Gatling**: Para pruebas de estrés avanzadas

---

## 6. Métricas a Monitorear

### Métricas de Rendimiento

| Métrica | Objetivo | Crítico |
|---------|----------|---------|
| Tiempo de parseo (100 estudiantes) | < 100ms | > 500ms |
| Tiempo de parseo (1000 estudiantes) | < 1s | > 5s |
| Velocidad de parseo | > 1000 est/s | < 100 est/s |
| Uso de memoria (1000 estudiantes) | < 50MB | > 200MB |
| Tiempo de respuesta API | < 200ms | > 1s |

### Métricas de Estabilidad

- ✅ **Tasa de éxito**: > 99%
- ✅ **Tasa de error**: < 1%
- ✅ **Tiempo de recuperación**: < 5s
- ✅ **Fugas de memoria**: 0

### Métricas de Escalabilidad

- ✅ **Capacidad máxima**: > 10,000 estudiantes
- ✅ **Concurrencia**: > 50 usuarios simultáneos
- ✅ **Throughput**: > 5000 operaciones/minuto

---

## 7. Script de Prueba Completo

Crea un script que ejecute todas las pruebas:

```bash
#!/bin/bash
# test/run_all_stress_tests.sh

echo "🧪 Iniciando pruebas de estrés completas..."

echo "📊 1. Pruebas de Importación CSV"
flutter test test/stress_test_csv_import.dart

echo "⚡ 2. Benchmarks de Rendimiento"
flutter test test/performance_benchmark.dart

echo "🔄 3. Pruebas de Concurrencia"
flutter test test/concurrency_test.dart

echo "✅ Todas las pruebas completadas"
```

---

## 8. Interpretación de Resultados

### Resultados Normales

- ✅ Tiempo de parseo < 1s para 1000 estudiantes
- ✅ Uso de memoria estable
- ✅ Sin errores de codificación
- ✅ Todas las validaciones pasan

### Señales de Problemas

- ⚠️ Tiempo de parseo > 5s para 1000 estudiantes
- ⚠️ Uso de memoria creciente (fuga de memoria)
- ⚠️ Errores de codificación frecuentes
- ⚠️ Validaciones fallando

### Acciones Correctivas

1. **Optimizar parseo**: Usar streams para archivos grandes
2. **Limpiar memoria**: Implementar dispose() correctamente
3. **Mejorar codificación**: Manejar diferentes charsets
4. **Validar datos**: Mejorar mensajes de error

---

## 9. Pruebas en Producción

### Monitoreo Continuo

1. **Logs**: Revisar logs de errores diariamente
2. **Métricas**: Monitorear tiempos de respuesta
3. **Alertas**: Configurar alertas para errores críticos
4. **Reportes**: Generar reportes semanales de rendimiento

### Pruebas Periódicas

- **Diarias**: Pruebas básicas de funcionalidad
- **Semanales**: Pruebas de carga media
- **Mensuales**: Pruebas de estrés completas
- **Trimestrales**: Auditoría de seguridad y rendimiento

---

## 10. Mejores Prácticas

1. ✅ **Ejecutar pruebas regularmente**
2. ✅ **Documentar resultados**
3. ✅ **Comparar con benchmarks anteriores**
4. ✅ **Optimizar basándose en resultados**
5. ✅ **Mantener pruebas actualizadas**

---

## 📞 Soporte

Si encuentras problemas durante las pruebas:

1. Revisa los logs de error
2. Verifica la configuración del entorno
3. Consulta la documentación de Flutter
4. Revisa los issues conocidos en GitHub

---

**Última actualización**: $(date)
**Versión**: 1.0.0
