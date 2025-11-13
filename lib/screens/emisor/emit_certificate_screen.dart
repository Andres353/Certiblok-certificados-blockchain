// lib/screens/emisor/emit_certificate_screen.dart
// Pantalla para emitir certificados con control de permisos

import 'package:flutter/material.dart';
import '../../services/emisor_permission_service.dart';
import '../../services/adapters/certificate_adapter.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';

class EmitCertificateScreen extends StatefulWidget {
  final String? studentId; // Opcional para emisión masiva
  final String institutionId;

  const EmitCertificateScreen({
    Key? key,
    this.studentId,
    required this.institutionId,
  }) : super(key: key);

  @override
  _EmitCertificateScreenState createState() => _EmitCertificateScreenState();
}

class _EmitCertificateScreenState extends State<EmitCertificateScreen> {
  bool _isLoading = true;
  bool _canEmit = false;
  String _permissionReason = '';
  Map<String, dynamic> _studentInfo = {};
  
  // Variables para modo de emisión
  String _emissionMode = 'individual'; // 'individual' o 'masiva'
  
  // Variables para emisión individual
  String _selectedCertificateType = 'graduation';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Variables para emisión masiva
  List<Map<String, dynamic>> _students = [];
  List<String> _selectedStudentIds = [];
  bool _isEmitting = false;
  
  // Variables para diseño de PDF personalizado (para futuras implementaciones)
  // bool _useCustomCertificate = false;
  // bool _useTemplate = true;
  // Map<String, Map<String, dynamic>> _studentCustomCertificates = {};
  
  final List<Map<String, String>> _certificateTypes = [
    {'value': 'graduation', 'label': 'Certificado de Graduación'},
    {'value': 'constancy', 'label': 'Constancia de Estudios'},
    {'value': 'achievement', 'label': 'Certificado de Logro'},
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Si es emisión individual, verificar permisos para el estudiante específico
      if (widget.studentId != null) {
        final canEmit = await EmisorPermissionService.canEmitForStudent(
          studentId: widget.studentId!,
          institutionId: widget.institutionId,
        );

        if (canEmit) {
          // Obtener información del estudiante
          final students = await EmisorPermissionService.getStudentsForEmisor(
            institutionId: widget.institutionId,
          );
          
          final student = students.firstWhere(
            (s) => s['id'] == widget.studentId,
            orElse: () => {},
          );

          setState(() {
            _canEmit = true;
            _studentInfo = student;
            _emissionMode = 'individual';
          });
        } else {
          setState(() {
            _canEmit = false;
            _permissionReason = 'No tienes permisos para emitir certificados para este estudiante';
          });
        }
      } else {
        // Emisión masiva - verificar permisos generales
        final permissions = await EmisorPermissionService.getEmisorPermissions();
        if (permissions['canEmit'] == true) {
          // Cargar lista de estudiantes
          final students = await EmisorPermissionService.getStudentsForEmisor(
            institutionId: widget.institutionId,
          );
          
          setState(() {
            _canEmit = true;
            _students = students;
            _emissionMode = 'masiva';
          });
        } else {
          setState(() {
            _canEmit = false;
            _permissionReason = permissions['reason'] ?? 'No tienes permisos para emitir certificados';
          });
        }
      }
    } catch (e) {
      setState(() {
        _canEmit = false;
        _permissionReason = 'Error verificando permisos: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_emissionMode == 'individual' ? 'Emitir Certificado' : 'Emisión Masiva'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _canEmit
              ? _buildContent()
              : _buildPermissionDenied(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Selector de modo de emisión (solo si no hay studentId específico)
        if (widget.studentId == null) _buildModeSelector(),
        
        // Contenido según el modo
        Expanded(
          child: _emissionMode == 'individual' 
              ? _buildIndividualEmission()
              : _buildMassiveEmission(),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
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
            'Modo de Emisión',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Individual'),
                  subtitle: Text('Emitir a un estudiante'),
                  value: 'individual',
                  groupValue: _emissionMode,
                  onChanged: (value) {
                    setState(() {
                      _emissionMode = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Masiva'),
                  subtitle: Text('Emitir a múltiples estudiantes'),
                  value: 'masiva',
                  groupValue: _emissionMode,
                  onChanged: (value) {
                    setState(() {
                      _emissionMode = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualEmission() {
    return _buildEmitForm();
  }

  Widget _buildMassiveEmission() {
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

  Widget _buildEmitForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del estudiante
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Estudiante',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
                        child: Text(
                          _studentInfo['fullName']?.substring(0, 1).toUpperCase() ?? 'S',
                          style: TextStyle(
                            color: Color(0xff6C4DDC),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _studentInfo['fullName'] ?? 'Estudiante',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ID: ${_studentInfo['studentIdInInstitution'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (_studentInfo['program'] != null) ...[
                              SizedBox(height: 2),
                              Text(
                                'Programa: ${_studentInfo['program']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (_studentInfo['faculty'] != null) ...[
                              SizedBox(height: 2),
                              Text(
                                'Facultad: ${_studentInfo['faculty']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Formulario de emisión
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos del Certificado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tipo de Certificado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                    initialValue: 'Certificado de Estudios',
                  ),
                  
                  SizedBox(height: 16),
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Fecha de Emisión',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    initialValue: DateTime.now().toString().split(' ')[0],
                  ),
                  
                  SizedBox(height: 16),
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Observaciones (Opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  
                  SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _emitCertificate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Emitir Certificado',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Colors.red[300],
            ),
            SizedBox(height: 24),
            Text(
              'Acceso Denegado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _permissionReason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _emitCertificate() async {
    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Confirmar Emisión'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Está seguro de que desea emitir este certificado?',
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
                    Text('📋 Detalles del Certificado:', 
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 8),
                    _buildDetailRow('👤 Estudiante:', _studentInfo['name'] ?? 'N/A'),
                    _buildDetailRow('📧 Email:', _studentInfo['email'] ?? 'N/A'),
                    _buildDetailRow('🎓 Carrera:', _studentInfo['programName'] ?? 'N/A'),
                    _buildDetailRow('🏫 Institución:', _studentInfo['institutionName'] ?? 'N/A'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
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
                        'Esta acción no se puede deshacer. Verifique que los datos sean correctos.',
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
              child: Text('Emitir Certificado'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Aquí se implementaría la lógica real de emisión de certificados
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Certificado emitido exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS PARA EMISIÓN MASIVA ==========

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
          
          // Título
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título del Certificado *',
              border: OutlineInputBorder(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Descripción
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripción *',
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
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) => _toggleStudentSelection(student['id']),
                  title: Text(
                    student['fullName'] ?? 'N/A',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📧 ${student['email'] ?? 'N/A'}'),
                      Text('🎓 ${student['program'] ?? 'N/A'}'),
                    ],
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: isSelected ? Color(0xff6C4DDC) : Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
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

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _selectAllStudents() {
    setState(() {
      _selectedStudentIds = _students.map((s) => s['id'] as String).toList();
    });
  }

  bool _canEmitCertificates() {
    if (_isEmitting) return false;
    if (_selectedStudentIds.isEmpty) return false;
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  String _getEmitButtonText() {
    if (_selectedStudentIds.isEmpty) {
      return 'Seleccionar Estudiantes';
    }
    return 'Emitir ${_selectedStudentIds.length} Certificados';
  }

  Future<void> _emitBulkCertificates() async {
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
      List<String> errors = [];

      // Emitir certificados uno por uno
      for (String studentId in _selectedStudentIds) {
        final student = _students.firstWhere((s) => s['id'] == studentId);
        
        try {
          // Crear datos del certificado
          final certificateData = {
            'studentId': studentId,
            'studentName': student['fullName'],
            'studentEmail': student['email'],
            'programName': student['program'],
            'institutionName': student['faculty'],
            'certificateType': _selectedCertificateType,
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'issuedAt': DateTime.now().toIso8601String(),
            'issuedBy': userContext!.userId,
            'issuedByName': userContext.userName,
            'issuedByRole': userContext.userRole,
          };

          // Emitir certificado usando el adapter
          await CertificateAdapter.createCertificate(
            studentId: studentId,
            certificateType: _selectedCertificateType,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            data: certificateData,
            institutionId: userContext.institutionId,
          );

          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('${student['fullName']}: $e');
        }
      }

      setState(() => _isEmitting = false);

      // Mostrar resultado
      if (successCount > 0) {
        AlertService.showSuccess(
          context, 
          'Éxito', 
          'Se emitieron $successCount certificados exitosamente${errorCount > 0 ? ' ($errorCount fallaron)' : ''}'
        );
        
        if (errorCount > 0) {
          _showErrorDetails(errors);
        }
        
        // Limpiar formulario
        _titleController.clear();
        _descriptionController.clear();
        _selectedStudentIds.clear();
      } else {
        AlertService.showError(
          context, 
          'Error', 
          'No se pudo emitir ningún certificado'
        );
        if (errors.isNotEmpty) {
          _showErrorDetails(errors);
        }
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
                    Text('📋 Detalles del Certificado:', 
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

}
