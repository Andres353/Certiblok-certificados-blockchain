// lib/screens/emisor/bulk_emit_certificates_screen.dart
// Pantalla para emitir múltiples certificados a la vez

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../services/emisor_permission_service.dart';
import '../../services/adapters/certificate_adapter.dart';
import '../../services/alert_service.dart';
import '../../services/user_context_service.dart';
import '../../services/certificate_notification_service.dart';

class BulkEmitCertificatesScreen extends StatefulWidget {
  const BulkEmitCertificatesScreen({Key? key}) : super(key: key);

  @override
  _BulkEmitCertificatesScreenState createState() => _BulkEmitCertificatesScreenState();
}

class _BulkEmitCertificatesScreenState extends State<BulkEmitCertificatesScreen> {
  bool _isLoading = true;
  bool _isEmitting = false;
  List<Map<String, dynamic>> _students = [];
  List<String> _selectedStudentIds = [];
  String _selectedCertificateType = 'graduation';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Variables para diseño de PDF personalizado
  Map<String, Map<String, dynamic>> _studentCustomCertificates = {}; // studentId -> certificateData
  
  final List<Map<String, String>> _certificateTypes = [
    {'value': 'graduation', 'label': 'Certificado de Graduación'},
    {'value': 'constancy', 'label': 'Constancia de Estudios'},
    {'value': 'achievement', 'label': 'Certificado de Logro'},
    {'value': 'participation', 'label': 'Certificado de Participación'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario no autenticado o sin institución');
      }

      final students = await EmisorPermissionService.getStudentsForEmisor(
        institutionId: userContext!.institutionId!,
      );

      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AlertService.showError(context, 'Error', 'Error cargando estudiantes: $e');
    }
  }

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
        // Limpiar certificado personalizado si existe
        _studentCustomCertificates.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  // Método para cargar PDF personalizado para un estudiante específico
  Future<void> _pickCustomCertificateForStudent(String studentId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // Validar tamaño del PDF
          const int maxPdfSize = 700000; // 700KB para base64
          if (file.bytes!.length > maxPdfSize) {
            final double sizeInKB = file.bytes!.length / 1024;
            final double maxSizeInKB = maxPdfSize / 1024;
            
            AlertService.showError(
              context, 
              'PDF Demasiado Grande', 
              'El PDF seleccionado es demasiado grande (${sizeInKB.toStringAsFixed(1)}KB).\n\nEl límite máximo es ${maxSizeInKB.toStringAsFixed(1)}KB.\n\nPor favor, comprime el PDF manualmente o usa un archivo más pequeño.'
            );
            return;
          }
          
          // Convertir a base64
          final String base64Data = base64Encode(file.bytes!);
          
          setState(() {
            _studentCustomCertificates[studentId] = {
              'isPdf': true,
              'fileData': base64Data,
              'fileName': file.name,
              'mimeType': 'application/pdf',
            };
          });
          
          // Mostrar confirmación
          final double sizeInKB = file.bytes!.length / 1024;
          AlertService.showSuccess(
            context, 
            'PDF Cargado', 
            'PDF cargado exitosamente para este estudiante (${sizeInKB.toStringAsFixed(1)}KB).'
          );
        }
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error cargando PDF: $e');
    }
  }

  // Método para remover PDF personalizado de un estudiante
  void _removeCustomCertificateForStudent(String studentId) {
    setState(() {
      _studentCustomCertificates.remove(studentId);
    });
  }

  // Método para verificar si un estudiante tiene PDF personalizado
  bool _hasCustomCertificate(String studentId) {
    return _studentCustomCertificates.containsKey(studentId);
  }

  // Método para validar si se pueden emitir certificados
  bool _canEmitCertificates() {
    // Verificar que no esté emitiendo
    if (_isEmitting) return false;
    
    // Verificar que haya estudiantes seleccionados
    if (_selectedStudentIds.isEmpty) return false;
    
    // Verificar que el campo obligatorio (título) esté lleno
    if (_titleController.text.trim().isEmpty) {
      return false;
    }
    
    // Verificar que todos los estudiantes seleccionados tengan PDF
      for (String studentId in _selectedStudentIds) {
        if (!_hasCustomCertificate(studentId)) {
          return false;
      }
    }
    
    return true;
  }

  // Método para obtener el texto del botón de emisión
  String _getEmitButtonText() {
    if (_selectedStudentIds.isEmpty) {
      return 'Seleccionar Estudiantes';
    }
    
    // Verificar campo obligatorio (título)
    if (_titleController.text.trim().isEmpty) {
      return 'Completar Título';
    }
    
    // Verificar PDFs
      int studentsWithPdf = 0;
      for (String studentId in _selectedStudentIds) {
        if (_hasCustomCertificate(studentId)) {
          studentsWithPdf++;
        }
      }
      
      if (studentsWithPdf == _selectedStudentIds.length) {
      return 'Emitir ${_selectedStudentIds.length} Certificado${_selectedStudentIds.length > 1 ? 's' : ''}';
      } else {
      return 'Cargar PDFs faltantes (${studentsWithPdf}/${_selectedStudentIds.length})';
    }
  }

  void _selectAllStudents() {
    setState(() {
      _selectedStudentIds = _students.map((s) => s['id'] as String).toList();
    });
  }

  void _deselectAllStudents() {
    setState(() {
      _selectedStudentIds.clear();
    });
  }

  Future<void> _emitBulkCertificates() async {
    if (_selectedStudentIds.isEmpty) {
      AlertService.showError(context, 'Error', 'Selecciona al menos un estudiante');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      AlertService.showError(context, 'Error', 'El título es obligatorio');
      return;
    }

    // Mostrar diálogo de confirmación
    final bool? confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isEmitting = true);

    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario no autenticado');
      }

      int successCount = 0;
      int errorCount = 0;
      int emailSentCount = 0;
      int emailErrorCount = 0;
      List<String> errors = [];

      // Emitir certificados uno por uno
      for (String studentId in _selectedStudentIds) {
        final student = _students.firstWhere((s) => s['id'] == studentId);
        String? certificateId;
        
        try {
          // Crear datos del certificado
          final certificateData = {
            'studentId': studentId,
            'studentName': student['fullName'],
            'studentEmail': student['email'],
            'programName': student['program'],
            'institutionName': student['faculty'], // Usar faculty como institución por ahora
            'certificateType': _selectedCertificateType,
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
            'issuedAt': DateTime.now().toIso8601String(),
            'issuedBy': userContext!.userId,
            'issuedByName': userContext.userName,
            'issuedByRole': userContext.userRole,
            'useCustomCertificate': true,
            'useTemplate': false,
            // Incluir datos del PDF personalizado (obligatorio)
              'customCertificateData': _studentCustomCertificates[studentId],
          };

          // Emitir certificado usando el adapter
          certificateId = await CertificateAdapter.createCertificate(
            studentId: studentId,
            certificateType: _selectedCertificateType,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            data: certificateData,
            institutionId: userContext.institutionId,
          );

          successCount++;

          // Enviar email de notificación al estudiante
          try {
            final notificationResult = await CertificateNotificationService.notifyCertificateIssued(
              studentEmail: student['email'] ?? '',
              studentName: student['fullName'] ?? 'Estudiante',
              certificateTitle: _titleController.text.trim(),
              certificateType: _selectedCertificateType,
              institutionName: userContext.institutionName ?? userContext.institution ?? 'Tu Institución',
              certificateId: certificateId,
              description: _descriptionController.text.trim(),
            );
            
            if (notificationResult['success']) {
              emailSentCount++;
              print('📧 Email enviado exitosamente a: ${student['email']}');
            } else {
              emailErrorCount++;
              print('⚠️ Error enviando email a ${student['email']}: ${notificationResult['message']}');
            }
          } catch (emailError) {
            emailErrorCount++;
            print('⚠️ Error enviando email a ${student['email']} (no crítico): $emailError');
            // No interrumpir el flujo si falla el email
          }
        } catch (e) {
          errorCount++;
          errors.add('${student['fullName']}: $e');
        }
      }

      setState(() => _isEmitting = false);

      // Mostrar resultado
      if (successCount > 0) {
        String resultMessage = 'Se emitieron $successCount certificados exitosamente';
        if (errorCount > 0) {
          resultMessage += ' ($errorCount fallaron)';
        }
        if (emailSentCount > 0) {
          resultMessage += '\n\n📧 Emails enviados: $emailSentCount';
        }
        if (emailErrorCount > 0) {
          resultMessage += '\n⚠️ Emails no enviados: $emailErrorCount';
        }
        
        AlertService.showSuccess(
          context, 
          'Éxito', 
          resultMessage
        );
        
        // Limpiar formulario
        _titleController.clear();
        _descriptionController.clear();
        _selectedStudentIds.clear();
      } else {
        AlertService.showError(context, 'Error', 'No se pudo emitir ningún certificado');
      }

      if (errors.isNotEmpty) {
        // Mostrar errores detallados
        _showErrorDetails(errors);
      }

    } catch (e) {
      setState(() => _isEmitting = false);
      AlertService.showError(context, 'Error', 'Error emitiendo certificados: $e');
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Confirmar Emisión Masiva'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Está seguro de que desea emitir certificados para ${_selectedStudentIds.length} estudiantes?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Detalles de la Emisión:', 
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 8),
                    _buildDetailRow('🎓 Tipo:', _getCertificateTypeLabel(_selectedCertificateType)),
                    _buildDetailRow('📝 Título:', _titleController.text.trim()),
                    _buildDetailRow('👥 Estudiantes:', '${_selectedStudentIds.length} seleccionados'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer. Se emitirán certificados para todos los estudiantes seleccionados.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
              ),
              child: Text('Emitir ${_selectedStudentIds.length} Certificados'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDetails(List<String> errors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Errores Detallados'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: errors.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${errors[index]}',
                    style: TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String _getCertificateTypeLabel(String type) {
    return _certificateTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => {'label': type},
    )['label']!;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emisión Masiva de Certificados'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedStudentIds.isNotEmpty)
            TextButton(
              onPressed: _deselectAllStudents,
              child: Text('Deseleccionar Todo', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Formulario de certificado
        _buildCertificateForm(),
        
        // Lista de estudiantes
        Expanded(child: _buildStudentsList()),
        
        // Botón de emisión
        _buildEmitButton(),
      ],
    );
  }

  Widget _buildCertificateForm() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración del Certificado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          // Tipo de certificado
          DropdownButtonFormField<String>(
            value: _selectedCertificateType,
            decoration: InputDecoration(
              labelText: 'Tipo de Certificado',
              border: OutlineInputBorder(),
            ),
            items: _certificateTypes.map((type) {
              return DropdownMenuItem(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCertificateType = value!;
              });
            },
          ),
          
          SizedBox(height: 16),
          
          // Información sobre PDF personalizado (siempre requerido)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                    'Para emitir certificados, deberás cargar un archivo PDF para cada estudiante seleccionado en la lista de abajo. Formatos soportados: PDF (máx. 700KB).',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 16),
          
          // Título
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título del Certificado *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es obligatorio';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16),
          
          // Descripción (opcional)
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return Column(
      children: [
        // Header con controles
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Text(
                'Seleccionar Estudiantes (${_selectedStudentIds.length}/${_students.length})',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: _selectAllStudents,
                icon: Icon(Icons.select_all, size: 16),
                label: Text('Seleccionar Todo'),
              ),
            ],
          ),
        ),
        
        // Lista de estudiantes
        Expanded(
          child: ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final isSelected = _selectedStudentIds.contains(student['id']);
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primera fila: Checkbox, información del estudiante y avatar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) => _toggleStudentSelection(student['id']),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['fullName'] ?? 'N/A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xff2E2F44),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        student['email'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.school, size: 14, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        student['program'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isSelected ? Color(0xff6C4DDC) : Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      
                      // Segunda fila: Sección de PDF (si está seleccionado)
                      if (isSelected) ...[
                        SizedBox(height: 12),
                        Divider(height: 1),
                        SizedBox(height: 12),
                        Row(
                            children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 20,
                              color: Color(0xff6C4DDC),
                            ),
                            SizedBox(width: 8),
                              Text(
                              'PDF del Certificado',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xff2E2F44),
                              ),
                            ),
                          ],
                              ),
                              SizedBox(height: 8),
                              
                              if (_hasCustomCertificate(student['id'])) ...[
                                // Mostrar información del PDF cargado
                                Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                SizedBox(width: 12),
                                      Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          _studentCustomCertificates[student['id']]!['fileName'] ?? 'PDF cargado',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'PDF listo para emitir',
                                        style: TextStyle(
                                          color: Colors.green[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeCustomCertificateForStudent(student['id']),
                                  icon: Icon(Icons.close, color: Colors.red[600], size: 20),
                                  tooltip: 'Remover PDF',
                                        padding: EdgeInsets.all(4),
                                  constraints: BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Botón para cargar PDF
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                                  onPressed: () => _pickCustomCertificateForStudent(student['id']),
                              icon: Icon(Icons.upload_file, size: 18),
                                  label: Text('Cargar PDF'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xff6C4DDC),
                                side: BorderSide(color: Color(0xff6C4DDC)),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Formatos soportados: PDF (máx. 700KB)',
                                  style: TextStyle(
                              fontSize: 11,
                                    color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                                  ),
                            textAlign: TextAlign.center,
                                ),
                              ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmitButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _canEmitCertificates() ? _emitBulkCertificates : null,
              icon: _isEmitting 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.send),
              label: Text(_isEmitting 
                  ? 'Emitiendo...' 
                  : _getEmitButtonText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
