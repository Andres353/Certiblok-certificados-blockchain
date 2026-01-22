// lib/screens/admin/csv_import_students_screen.dart
// Pantalla para importar estudiantes desde archivos CSV

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../../services/csv_student_import_service.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';

// Importar dart:html solo para web (se usa condicionalmente)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show AnchorElement, Blob, Url, document;

class CsvImportStudentsScreen extends StatefulWidget {
  @override
  _CsvImportStudentsScreenState createState() => _CsvImportStudentsScreenState();
}

class _CsvImportStudentsScreenState extends State<CsvImportStudentsScreen> {
  Uint8List? _csvBytes;
  String? _fileName;
  List<Map<String, dynamic>>? _parsedStudents;
  bool _isImporting = false;
  int _currentProgress = 0;
  int _totalProgress = 0;
  Map<String, dynamic>? _importResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Importar Estudiantes desde CSV'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instrucciones
            _buildInstructionsCard(),
            SizedBox(height: 24),
            
            // Selector de archivo
            _buildFileSelector(),
            SizedBox(height: 24),
            
            // Vista previa
            if (_parsedStudents != null) ...[
              _buildPreviewSection(),
              SizedBox(height: 24),
            ],
            
            // Botón de importar
            if (_parsedStudents != null && !_isImporting) ...[
              _buildImportButton(),
              SizedBox(height: 24),
            ],
            
            // Progreso de importación
            if (_isImporting) ...[
              _buildProgressSection(),
              SizedBox(height: 24),
            ],
            
            // Resultados
            if (_importResults != null) ...[
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xff6C4DDC)),
                SizedBox(width: 8),
                Text(
                  'Formato del CSV',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IMPORTANTE:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• El CSV debe tener los datos en UNA SOLA COLUMNA separados por comas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                    ),
                  ),
                  Text(
                    '• El archivo debe estar guardado en formato UTF-8',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                    ),
                  ),
                  Text(
                    '• En Excel: Guardar como > CSV UTF-8 (delimitado por comas)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'El archivo CSV debe tener el siguiente formato:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opción 1: Con encabezados (recomendado)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primera fila (encabezados):',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Filas siguientes (datos):',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Opción 2: Sin encabezados (los datos deben estar en el mismo orden)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'juan.perez@example.com,Juan Pérez,2024001,1234567890,Ingeniería de Sistemas,SISTEMAS-001',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'maria.garcia@example.com,María García,2024002,0987654321,Ingeniería Industrial,INDUSTRIAL-001',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xff6C4DDC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Color(0xff6C4DDC), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Todos los campos son obligatorios:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff6C4DDC),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildColumnInfo('correo', 'Obligatorio', true),
                  _buildColumnInfo('nombre completo', 'Obligatorio', true),
                  _buildColumnInfo('codigo estudiante', 'Obligatorio', true),
                  _buildColumnInfo('telefono', 'Obligatorio', true),
                  _buildColumnInfo('nombre programa', 'Obligatorio', true),
                  _buildColumnInfo('codigo programa', 'Obligatorio', true),
                ],
              ),
            ),
            SizedBox(height: 12),
            TextButton.icon(
              onPressed: _downloadTemplate,
              icon: Icon(Icons.download),
              label: Text('Descargar plantilla CSV'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xff6C4DDC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnInfo(String column, String label, bool required) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: required ? Colors.red : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$column',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '($label)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar archivo CSV',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            if (_fileName != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fileName!,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _csvBytes = null;
                          _fileName = null;
                          _parsedStudents = null;
                          _importResults = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _pickCsvFile,
                icon: Icon(Icons.upload_file),
                label: Text('Seleccionar archivo CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Color(0xff6C4DDC)),
                SizedBox(width: 8),
                Text(
                  'Vista Previa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Se encontraron ${_parsedStudents!.length} estudiantes para importar',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: _parsedStudents!.length > 5 ? 5 : _parsedStudents!.length,
                itemBuilder: (context, index) {
                  final student = _parsedStudents![index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
                      child: Icon(Icons.person, color: Color(0xff6C4DDC)),
                    ),
                    title: Text(student['full_name'] ?? 'Sin nombre'),
                    subtitle: Text(student['email'] ?? 'Sin email'),
                    trailing: student['program_name'] != null
                        ? Chip(
                            label: Text(
                              student['program_name'],
                              style: TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
                          )
                        : null,
                  );
                },
              ),
            ),
            if (_parsedStudents!.length > 5)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '... y ${_parsedStudents!.length - 5} más',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _importStudents,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff6C4DDC),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Importar ${_parsedStudents!.length} Estudiantes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Importando estudiantes...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _totalProgress > 0 ? _currentProgress / _totalProgress : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
            ),
            SizedBox(height: 8),
            Text(
              'Progreso: $_currentProgress / $_totalProgress',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final successful = _importResults!['successful'] as List;
    final failed = _importResults!['failed'] as List;
    final emailsSent = successful.where((s) => s['emailSent'] == true).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Resultados de la Importación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    'Exitosos',
                    successful.length,
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildResultCard(
                    'Fallidos',
                    failed.length,
                    Colors.red,
                    Icons.error,
                  ),
                ),
              ],
            ),
            if (successful.isNotEmpty) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildResultCard(
                      'Correos Enviados',
                      emailsSent,
                      emailsSent == successful.length ? Colors.blue : Colors.orange,
                      Icons.email,
                    ),
                  ),
                ],
              ),
            ],
            if (successful.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.green[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Contraseñas Enviadas por Correo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Las contraseñas temporales han sido enviadas automáticamente al correo electrónico de cada estudiante. Los estudiantes deben cambiar su contraseña en el primer inicio de sesión.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showPasswords(successful),
                            icon: Icon(Icons.visibility, size: 18),
                            label: Text('Ver Contraseñas'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              side: BorderSide(color: Colors.green[300]!),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _downloadPasswordsCsv(successful),
                            icon: Icon(Icons.download, size: 18),
                            label: Text('Descargar CSV'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              side: BorderSide(color: Colors.green[300]!),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nota: Puedes ver o descargar las contraseñas si necesitas compartirlas manualmente.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (failed.isNotEmpty) ...[
              SizedBox(height: 16),
              ExpansionTile(
                title: Text('Ver errores (${failed.length})'),
                leading: Icon(Icons.error_outline, color: Colors.red),
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: failed.length,
                      itemBuilder: (context, index) {
                        final error = failed[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            error['email'] ?? 'Desconocido',
                            style: TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            error['message'] ?? 'Error desconocido',
                            style: TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _csvBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
          _parsedStudents = null;
          _importResults = null;
        });

        // Parsear CSV
        try {
          final students = await CsvStudentImportService.parseCsv(_csvBytes!);
          setState(() {
            _parsedStudents = students;
          });
        } catch (e) {
          // Extraer el mensaje de error de forma más clara
          String errorMessage = e.toString();
          
          // Remover "Exception: " del inicio si está presente
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }
          
          AlertService.showError(
            context,
            'Error al procesar el archivo CSV',
            errorMessage,
          );
          setState(() {
            _csvBytes = null;
            _fileName = null;
          });
        }
      }
    } catch (e) {
      AlertService.showError(
        context,
        'Error',
        'No se pudo seleccionar el archivo: $e',
      );
    }
  }

  Future<void> _importStudents() async {
    if (_parsedStudents == null || _parsedStudents!.isEmpty) {
      AlertService.showError(
        context,
        'Error',
        'No hay estudiantes para importar',
      );
      return;
    }

    final userContext = UserContextService.currentContext;
    if (userContext?.institutionId == null) {
      AlertService.showError(
        context,
        'Error',
        'No se pudo obtener la información de la institución',
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _currentProgress = 0;
      _totalProgress = _parsedStudents!.length;
      _importResults = null;
    });

    try {
      final results = await CsvStudentImportService.importStudents(
        studentsData: _parsedStudents!,
        institutionId: userContext!.institutionId!,
        institutionName: userContext.currentInstitution?.name ?? 'Institución',
        onProgress: (current, total) {
          setState(() {
            _currentProgress = current;
            _totalProgress = total;
          });
        },
      );

      setState(() {
        _isImporting = false;
        _importResults = results;
      });

      final successful = results['successful'] as List;
      final failed = results['failed'] as List;

      if (failed.isEmpty) {
        AlertService.showSuccess(
          context,
          'Importación Exitosa',
          'Se importaron ${successful.length} estudiantes exitosamente.\n\nLas contraseñas temporales han sido enviadas automáticamente al correo electrónico de cada estudiante.',
        );
      } else {
        final emailsSent = successful.where((s) => s['emailSent'] == true).length;
        AlertService.showError(
          context,
          'Importación Parcial',
          'Se importaron ${successful.length} estudiantes. ${failed.length} fallaron.\n\nContraseñas enviadas por correo: $emailsSent de ${successful.length}',
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      AlertService.showError(
        context,
        'Error',
        'Error al importar estudiantes: $e',
      );
    }
  }

  void _downloadTemplate() {
    // Crear contenido del template CSV solo con encabezados (sin ejemplos)
    // Usar formato CSV estándar con nueva línea al final
    const csvContent = 'correo,nombre completo,codigo estudiante,telefono,nombre programa,codigo programa\n';

    if (kIsWeb) {
      // Para web: descargar directamente el archivo usando data URL
      try {
        // Codificar el contenido en base64 para data URL
        final base64Content = base64Encode(utf8.encode(csvContent));
        final dataUrl = 'data:text/csv;charset=utf-8;base64,$base64Content';
        
        // Crear elemento anchor para descarga
        final anchor = html.AnchorElement(href: dataUrl);
        anchor.download = 'plantilla_estudiantes.csv';
        anchor.style.display = 'none';
        
        // Agregar al DOM temporalmente
        html.document.body?.children.add(anchor);
        
        // Simular click para iniciar descarga
        anchor.click();
        
        // Limpiar después de un breve delay
        Future.delayed(Duration(milliseconds: 200), () {
          html.document.body?.children.remove(anchor);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plantilla CSV descargada exitosamente. Ábrela con Excel o Google Sheets.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        AlertService.showError(
          context,
          'Error',
          'No se pudo descargar la plantilla: $e',
        );
      }
    } else {
      // Para mobile/desktop: mostrar contenido para copiar
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Plantilla CSV'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copia este contenido y guárdalo como archivo CSV:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    csvContent,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  void _showPasswords(List successful) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Color(0xff6C4DDC)),
            SizedBox(width: 8),
            Text('Contraseñas de Estudiantes'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estas son las contraseñas temporales generadas. Los estudiantes deben cambiarlas en el primer inicio de sesión.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                ...successful.map<Widget>((result) {
                  final email = result['email'] ?? 'Sin email';
                  final password = result['tempPassword'] ?? 'No generada';
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                password,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, size: 18),
                              onPressed: () {
                                // Copiar al portapapeles
                                // En web esto requiere usar dart:html
                                if (kIsWeb) {
                                  // Implementar copia al portapapeles para web
                                }
                              },
                              tooltip: 'Copiar',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadPasswordsCsv(successful);
            },
            icon: Icon(Icons.download, size: 18),
            label: Text('Descargar CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadPasswordsCsv(List successful) {
    // Crear contenido CSV con email y contraseña
    final csvLines = <String>['correo,contraseña'];
    for (final result in successful) {
      final email = result['email'] ?? '';
      final password = result['tempPassword'] ?? '';
      csvLines.add('$email,$password');
    }
    final csvContent = csvLines.join('\n');

    if (kIsWeb) {
      try {
        final base64Content = base64Encode(utf8.encode(csvContent));
        final dataUrl = 'data:text/csv;charset=utf-8;base64,$base64Content';
        
        final anchor = html.AnchorElement(href: dataUrl);
        anchor.download = 'contraseñas_estudiantes_${DateTime.now().millisecondsSinceEpoch}.csv';
        anchor.style.display = 'none';
        
        html.document.body?.children.add(anchor);
        anchor.click();
        
        Future.delayed(Duration(milliseconds: 200), () {
          html.document.body?.children.remove(anchor);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo CSV con contraseñas descargado exitosamente.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        AlertService.showError(
          context,
          'Error',
          'No se pudo descargar el archivo: $e',
        );
      }
    } else {
      // Para mobile/desktop: mostrar contenido para copiar
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Contraseñas CSV'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copia este contenido y guárdalo como archivo CSV:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    csvContent,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }
}
