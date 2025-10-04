// lib/screens/certificates/emit_certificate_screen.dart
// Pantalla para emitir certificados (Emisores)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:pdf_render/pdf_render.dart'; // Comentado temporalmente por compatibilidad con Web
import '../../services/certificate_service.dart';
import '../../services/emisor_permission_service.dart';
import '../../services/user_context_service.dart';
import '../../services/certificate_template_service.dart';
import '../../services/certificate_notification_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate_template.dart';

class EmitCertificateScreen extends StatefulWidget {
  const EmitCertificateScreen({Key? key}) : super(key: key);

  @override
  _EmitCertificateScreenState createState() => _EmitCertificateScreenState();
}

class _EmitCertificateScreenState extends State<EmitCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingStudents = true;
  bool _isLoadingTemplates = true;
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;
  String _selectedCertificateType = 'graduation';
  List<CertificateTemplate> _templates = [];
  CertificateTemplate? _selectedTemplate;
  bool _useTemplate = false;
  bool _useCustomCertificate = false;
  Uint8List? _customCertificateBytes;
  String? _customCertificateFileName;
  String? _customCertificateMimeType;
  bool _isPdf = false;
  
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
    _loadTemplates();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('No se pudo obtener la información de la institución');
      }

      final students = await EmisorPermissionService.getStudentsForEmisor(
        institutionId: userContext!.institutionId!,
      );

      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      AlertService.showError(context, 'Error', 'Error cargando estudiantes: $e');
    }
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoadingTemplates = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('No se pudo obtener la información de la institución');
      }

      final templates = await CertificateTemplateService.getTemplates(
        institutionId: userContext!.institutionId!,
      );

      setState(() {
        _templates = templates;
        _isLoadingTemplates = false;
      });
    } catch (e) {
      setState(() => _isLoadingTemplates = false);
      AlertService.showError(context, 'Error', 'Error cargando plantillas: $e');
    }
  }

  Future<void> _pickCustomCertificate() async {
    try {
      // Mostrar opciones de selección
      final String? selectedType = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Seleccionar tipo de archivo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.image, color: Colors.blue),
                  title: Text('Imagen'),
                  subtitle: Text('JPG, PNG, etc.'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('PDF'),
                  subtitle: Text('Documento PDF'),
                  onTap: () => Navigator.pop(context, 'pdf'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
            ],
          );
        },
      );

      if (selectedType == null) return;

      if (selectedType == 'image') {
        await _pickImage();
      } else if (selectedType == 'pdf') {
        await _pickPdf();
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error cargando certificado: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _customCertificateBytes = bytes;
          _customCertificateFileName = image.name;
          _customCertificateMimeType = 'image/jpeg';
          _isPdf = false;
          _useCustomCertificate = true;
          _useTemplate = false;
        });
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error cargando imagen: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _customCertificateBytes = file.bytes;
            _customCertificateFileName = file.name;
            _customCertificateMimeType = 'application/pdf';
            _isPdf = true;
            _useCustomCertificate = true;
            _useTemplate = false;
          });
        }
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error cargando PDF: $e');
    }
  }

  void _removeCustomCertificate() {
    setState(() {
      _customCertificateBytes = null;
      _customCertificateFileName = null;
      _customCertificateMimeType = null;
      _isPdf = false;
      _useCustomCertificate = false;
    });
  }

  Widget _buildPdfPreview() {
    if (_customCertificateBytes == null) {
      return Center(
        child: Text('No hay datos de PDF'),
      );
    }
    
    // Vista previa simple para PDF sin renderizado
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 48,
            color: Colors.red,
          ),
          SizedBox(height: 8),
          Text(
            'Documento PDF',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            _customCertificateFileName ?? 'Archivo PDF',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Tamaño: ${(_customCertificateBytes!.length / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emitir Certificado'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: (_isLoadingStudents || _isLoadingTemplates)
          ? Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildNoStudentsView()
              : _buildEmitForm(),
    );
  }

  Widget _buildNoStudentsView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No hay estudiantes disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No tienes estudiantes asignados para emitir certificados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
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

  Widget _buildEmitForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del emisor
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Emisor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E2F44),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person, color: Color(0xff6C4DDC)),
                        SizedBox(width: 8),
                        Text(
                          UserContextService.currentContext?.userName ?? 'Emisor',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.school, color: Color(0xff6C4DDC)),
                        SizedBox(width: 8),
                        Text(
                          UserContextService.currentContext?.institutionName ?? 'Institución',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Selección de estudiante
            Text(
              'Seleccionar Estudiante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedStudent,
              decoration: InputDecoration(
                labelText: 'Estudiante',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.person),
              ),
              items: _students.map((student) {
                return DropdownMenuItem(
                  value: student,
                  child: Text(
                    '${student['fullName'] ?? 'Sin nombre'} (${student['program'] ?? 'Sin programa'})',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStudent = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un estudiante';
                }
                return null;
              },
            ),
            
            SizedBox(height: 24),
            
            // Selección de plantilla
            Text(
              'Plantilla del Certificado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            
            // Checkbox para usar plantilla
            Row(
              children: [
                Checkbox(
                  value: _useTemplate,
                  onChanged: (value) {
                    setState(() {
                      _useTemplate = value ?? false;
                      if (!_useTemplate) {
                        _selectedTemplate = null;
                      }
                      if (_useTemplate) {
                        _useCustomCertificate = false; // Desactivar certificado personalizado
                        _customCertificateBytes = null;
                      }
                    });
                  },
                ),
                Text('Usar plantilla personalizada'),
              ],
            ),
            
            // Checkbox para usar certificado personalizado
            Row(
              children: [
                Checkbox(
                  value: _useCustomCertificate,
                  onChanged: (value) {
                    setState(() {
                      _useCustomCertificate = value ?? false;
                      if (!_useCustomCertificate) {
                        _customCertificateBytes = null;
                        _customCertificateFileName = null;
                        _customCertificateMimeType = null;
                        _isPdf = false;
                      }
                      if (_useCustomCertificate) {
                        _useTemplate = false; // Desactivar plantilla
                        _selectedTemplate = null;
                      }
                    });
                  },
                ),
                Text('Usar certificado personalizado'),
              ],
            ),
            
            // Selector de plantilla (solo si está habilitado)
            if (_useTemplate) ...[
              SizedBox(height: 12),
              DropdownButtonFormField<CertificateTemplate>(
                value: _selectedTemplate,
                decoration: InputDecoration(
                  labelText: 'Plantilla',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
                items: _templates.map((template) {
                  return DropdownMenuItem(
                    value: template,
                    child: Text(
                      template.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTemplate = value;
                  });
                },
                validator: (value) {
                  if (_useTemplate && value == null) {
                    return 'Selecciona una plantilla';
                  }
                  return null;
                },
              ),
              
              // Vista previa de la plantilla
              if (_selectedTemplate != null) ...[
                SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 500, // Ancho más realista para certificado
                    height: 350, // Proporción más natural (5:3.5)
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildTemplatePreview(),
                    ),
                  ),
                ),
              ],
            ],
            
            // Sección de certificado personalizado
            if (_useCustomCertificate) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificado Personalizado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    if (_customCertificateBytes == null) ...[
                      // Botón para cargar certificado
                      ElevatedButton.icon(
                        onPressed: _pickCustomCertificate,
                        icon: Icon(Icons.upload_file),
                        label: Text('Cargar Certificado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Formatos soportados: JPG, PNG, PDF',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      // Mostrar certificado cargado
                      Row(
                        children: [
                          Icon(
                            _isPdf ? Icons.picture_as_pdf : Icons.image,
                            color: _isPdf ? Colors.red : Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _customCertificateFileName ?? 'Archivo cargado',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _isPdf ? 'Documento PDF' : 'Imagen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeCustomCertificate,
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar certificado',
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Vista previa del certificado personalizado
                      Center(
                        child: Container(
                          width: 300,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _isPdf 
                                ? _buildPdfPreview()
                                : Image.memory(
                                    _customCertificateBytes!,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 24),
            
            // Tipo de certificado
            Text(
              'Tipo de Certificado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCertificateType,
              decoration: InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.workspace_premium),
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
            
            SizedBox(height: 24),
            
            // Título del certificado
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del Certificado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.title),
                hintText: 'Ej: Certificado de Graduación en Ingeniería de Sistemas',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el título del certificado';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.description),
                hintText: 'Descripción detallada del certificado...',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),
            
            SizedBox(height: 32),
            
            // Botón de emisión
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _emitCertificate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Emitir Certificado',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview() {
    if (_selectedTemplate == null || _selectedStudent == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 48, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'Selecciona una plantilla y estudiante',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final template = _selectedTemplate!;
    final student = _selectedStudent!;
    
    // Usar EXACTAMENTE la misma lógica de renderizado que el editor de plantillas
    return _buildCertificatePreviewExact(template, student);
  }

  Widget _buildCertificatePreviewExact(CertificateTemplate template, Map<String, dynamic> student) {
    return Container(
      decoration: BoxDecoration(
        color: _parseColor(template.design.backgroundColor),
        borderRadius: BorderRadius.circular(template.design.borderRadius),
        border: Border.all(
          color: _parseColor(template.design.borderColor),
          width: template.design.borderWidth,
        ),
      ),
      child: Stack(
        children: [
          // Imagen de fondo del certificado
          if (template.design.certificateBackgroundUrl.isNotEmpty)
            _buildBackgroundImagePreview(template.design.certificateBackgroundUrl),
          
          // Patrón de fondo
          if (template.layout.backgroundPattern != 'none')
            _buildBackgroundPatternPreview(template),
          
          // Logo de la institución
          _buildInstitutionLogoPreview(template),
          
          // Contenido del certificado
          Column(
            children: [
              // Header
              if (template.layout.showHeader)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16), // Reducir padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _parseColor(template.design.primaryColor),
                        _parseColor(template.design.secondaryColor),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(template.design.borderRadius),
                      topRight: Radius.circular(template.design.borderRadius),
                    ),
                  ),
                  child: Text(
                    'CERTIFICADO',
                    style: _getTextStyle(
                      template.design.titleFontFamily,
                      template.design.titleFontSize * 0.9, // Aumentar un poco para 500px
                      _parseColor(template.design.headerTextColor),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Línea decorativa
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _parseColor(template.design.primaryColor),
                      _parseColor(template.design.secondaryColor),
                    ],
                  ),
                ),
              ),
              
              // Contenido
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16), // Reducir padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Subtítulo
                      Text(
                        'Se certifica que',
                        style: _getTextStyle(
                          template.design.subtitleFontFamily,
                          template.design.subtitleFontSize * 0.9, // Aumentar un poco para 500px
                          _parseColor(template.design.textColor),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 25), // Aumentar espaciado
                      
                      // Nombre del estudiante (campo dinámico)
                      Text(
                        student['fullName'] ?? 'Juan Pérez',
                        style: _getTextStyle(
                          template.design.titleFontFamily,
                          (template.design.subtitleFontSize + 8) * 0.9, // Aumentar un poco
                          _parseColor(template.design.textColor),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2, // Limitar líneas
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 25), // Aumentar espaciado
                      
                      // Descripción
                      Text(
                        'Ha completado exitosamente el programa de estudios',
                        style: _getTextStyle(
                          template.design.bodyFontFamily,
                          template.design.bodyFontSize * 0.9, // Aumentar un poco
                          _parseColor(template.design.textColor),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2, // Limitar líneas
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 30), // Reducir espaciado
                      
                      // Firmas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.design.issuerName,
                                style: _getTextStyle(
                                  template.design.smallFontFamily,
                                  (template.design.smallFontSize + 2) * 0.8, // Reducir tamaño
                                  _parseColor(template.design.textColor),
                                ),
                              ),
                              Text(
                                template.design.issuerTitleLabel,
                                style: _getTextStyle(
                                  template.design.smallFontFamily,
                                  template.design.smallFontSize * 0.8, // Reducir tamaño
                                  _parseColor(template.design.textColor),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                template.design.dateLabel,
                                style: _getTextStyle(
                                  template.design.smallFontFamily,
                                  template.design.smallFontSize * 0.8, // Reducir tamaño
                                  _parseColor(template.design.textColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImagePreview(String imageUrl) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildBackgroundImage(imageUrl),
        ),
      ),
    );
  }

  Widget _buildBackgroundPatternPreview(CertificateTemplate template) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPatternPainter(
          pattern: template.layout.backgroundPattern,
          color: _parseColor(template.layout.patternColor),
          opacity: template.layout.patternOpacity,
        ),
      ),
    );
  }

  Widget _buildInstitutionLogoPreview(CertificateTemplate template) {
    if (template.design.institutionLogoUrl.isEmpty) return Container();
    
    // Calcular posición basada en la configuración de la plantilla
    // Ajustado para el ancho fijo de 500px
    double left = 20;
    double top = 20;
    
    // Mapear posiciones de texto a coordenadas (ajustado para 500px de ancho)
    switch (template.design.logoPosition) {
      case 'top-left':
        left = 20;
        top = 20;
        break;
      case 'top-center':
        left = 220; // Centro de 500px (250 - 30)
        top = 20;
        break;
      case 'top-right':
        left = 420; // Derecha de 500px (500 - 80)
        top = 20;
        break;
      case 'bottom-left':
        left = 20;
        top = 250;
        break;
      case 'bottom-center':
        left = 220;
        top = 250;
        break;
      case 'bottom-right':
        left = 420;
        top = 250;
        break;
      default:
        left = 20;
        top = 20;
    }
    
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 80, // Tamaño más apropiado para 500px de ancho
        height: 80,
        child: _buildInstitutionLogo(template.design.institutionLogoUrl),
      ),
    );
  }

  // Función idéntica a la del editor de plantillas
  TextStyle _getTextStyle(String fontFamily, double fontSize, Color color, {FontWeight? fontWeight}) {
    // Mapeo de fuentes del sistema a Google Fonts
    String googleFontFamily;
    switch (fontFamily.toLowerCase()) {
      case 'roboto':
        googleFontFamily = 'Roboto';
        break;
      case 'arial':
        googleFontFamily = 'Open Sans';
        break;
      case 'times new roman':
        googleFontFamily = 'Playfair Display';
        break;
      case 'helvetica':
        googleFontFamily = 'Lato';
        break;
      case 'courier':
        googleFontFamily = 'Source Code Pro';
        break;
      case 'georgia':
        googleFontFamily = 'Merriweather';
        break;
      case 'verdana':
        googleFontFamily = 'Nunito';
        break;
      case 'comic sans':
      case 'comic sans ms':
        googleFontFamily = 'Comic Neue';
        break;
      case 'impact':
        googleFontFamily = 'Oswald'; // Impact -> Oswald
        break;
      case 'trebuchet':
        googleFontFamily = 'Ubuntu';
        break;
      case 'bookman':
        googleFontFamily = 'Merriweather'; // Bookman -> Merriweather
        break;
      case 'avant garde':
        googleFontFamily = 'Montserrat'; // Avant Garde -> Montserrat
        break;
      case 'palatino':
        googleFontFamily = 'Playfair Display'; // Palatino -> Playfair Display
        break;
      case 'comic neue':
        googleFontFamily = 'Comic Neue';
        break;
      case 'oswald':
        googleFontFamily = 'Oswald';
        break;
      case 'montserrat':
        googleFontFamily = 'Montserrat';
        break;
      case 'merriweather':
        googleFontFamily = 'Merriweather';
        break;
      case 'playfair display':
        googleFontFamily = 'Playfair Display';
        break;
      case 'open sans':
        googleFontFamily = 'Open Sans';
        break;
      case 'lato':
        googleFontFamily = 'Lato';
        break;
      case 'source code pro':
        googleFontFamily = 'Source Code Pro';
        break;
      case 'nunito':
        googleFontFamily = 'Nunito';
        break;
      case 'ubuntu':
        googleFontFamily = 'Ubuntu';
        break;
      case 'garamond':
        googleFontFamily = 'Crimson Text'; // Garamond -> Crimson Text
        break;
      default:
        googleFontFamily = 'Roboto';
    }

    return GoogleFonts.getFont(
      googleFontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Remover el # si existe
      String cleanColor = colorString.replaceAll('#', '');
      // Agregar FF para alpha si no existe
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }
      return Color(int.parse(cleanColor, radix: 16));
    } catch (e) {
      return Colors.grey; // Color por defecto si hay error
    }
  }

  Widget _buildBackgroundImage(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container();
        },
      );
    }
    return Container();
  }

  Widget _buildInstitutionLogo(String logoUrl) {
    if (logoUrl.startsWith('data:')) {
      return Image.network(
        logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container();
        },
      );
    }
    return Container();
  }

  Future<void> _emitCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      AlertService.showError(context, 'Error', 'Selecciona un estudiante');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🚀 Iniciando emisión de certificado...');
      print('  - Estudiante seleccionado: ${_selectedStudent!['fullName']} (${_selectedStudent!['id']})');
      print('  - Tipo de certificado: $_selectedCertificateType');
      print('  - Título: ${_titleController.text.trim()}');
      print('  - Descripción: ${_descriptionController.text.trim()}');
      print('  - Usar plantilla: $_useTemplate');
      print('  - Usar certificado personalizado: $_useCustomCertificate');
      
      // Preparar datos del certificado
      Map<String, dynamic> certificateData = {
        'studentIdInInstitution': _selectedStudent!['studentIdInInstitution'],
        'program': _selectedStudent!['program'],
        'faculty': _selectedStudent!['faculty'],
        'issuedByRole': 'emisor',
        'useTemplate': _useTemplate,
        'useCustomCertificate': _useCustomCertificate,
      };
      
      // Agregar datos de plantilla si se usa
      if (_useTemplate && _selectedTemplate != null) {
        certificateData['templateId'] = _selectedTemplate!.id;
        certificateData['templateData'] = {
          'name': _selectedTemplate!.name,
          'design': _selectedTemplate!.design.toMap(),
          'layout': _selectedTemplate!.layout.toMap(),
        };
      }
      
      // Agregar datos de certificado personalizado si se usa
      if (_useCustomCertificate && _customCertificateBytes != null) {
        // Convertir bytes a base64 para almacenar
        String base64Data = base64Encode(_customCertificateBytes!);
        certificateData['customCertificateData'] = {
          'fileData': base64Data,
          'mimeType': _customCertificateMimeType ?? 'application/pdf',
          'fileName': _customCertificateFileName ?? 'certificate',
          'isPdf': _isPdf,
        };
      }
      
      final certificateId = await CertificateService.createCertificate(
        studentId: _selectedStudent!['id'],
        certificateType: _selectedCertificateType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        data: certificateData,
      );
      
      print('✅ Certificado emitido exitosamente con ID: $certificateId');

      // Notificar al estudiante
      try {
        final notificationResult = await CertificateNotificationService.notifyCertificateIssued(
          studentEmail: _selectedStudent!['email'] ?? 'email@ejemplo.com',
          studentName: _selectedStudent!['fullName'],
          certificateTitle: _titleController.text.trim(),
          certificateType: _selectedCertificateType,
          institutionName: UserContextService.currentContext?.institutionName ?? 'Tu Institución',
          certificateId: certificateId,
          description: _descriptionController.text.trim(),
        );
        
        if (notificationResult['success']) {
          print('📧 Notificación enviada al estudiante exitosamente');
        } else {
          print('⚠️ Error enviando notificación: ${notificationResult['message']}');
        }
      } catch (e) {
        print('⚠️ Error enviando notificación: $e');
        // No interrumpimos el flujo si fallan las notificaciones
      }

      // Limpiar formulario
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedStudent = null;
        _selectedCertificateType = 'graduation';
        _useTemplate = false;
        _selectedTemplate = null;
        _useCustomCertificate = false;
        _customCertificateBytes = null;
        _customCertificateFileName = null;
        _customCertificateMimeType = null;
        _isPdf = false;
      });

      AlertService.showSuccess(context, 'Éxito', 'Certificado emitido exitosamente. El estudiante ha sido notificado por email.');

      // Mostrar información del certificado
      _showCertificateInfo(certificateId);
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error al emitir certificado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCertificateInfo(String certificateId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Certificado Emitido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El certificado ha sido emitido exitosamente.'),
            SizedBox(height: 16),
            Text('ID del Certificado:'),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                certificateId,
                style: TextStyle(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('El estudiante recibirá una notificación por email.'),
          ],
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

// Clase para pintar patrones de fondo (idéntica a la del editor)
class _BackgroundPatternPainter extends CustomPainter {
  final String pattern;
  final Color color;
  final double opacity;

  _BackgroundPatternPainter({
    required this.pattern,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    switch (pattern) {
      case 'dots':
        _paintDots(canvas, size, paint);
        break;
      case 'lines':
        _paintLines(canvas, size, paint);
        break;
      case 'geometry':
        _paintGeometry(canvas, size, paint);
        break;
      case 'waves':
        _paintWaves(canvas, size, paint);
        break;
      case 'hexagons':
        _paintHexagons(canvas, size, paint);
        break;
    }
  }

  void _paintDots(Canvas canvas, Size size, Paint paint) {
    const double spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  void _paintLines(Canvas canvas, Size size, Paint paint) {
    const double spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint..strokeWidth = 1,
      );
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint..strokeWidth = 1,
      );
    }
  }

  void _paintGeometry(Canvas canvas, Size size, Paint paint) {
    const double spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x + 10, y)
          ..lineTo(x + 5, y + 10)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintWaves(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    const double amplitude = 10.0;
    const double frequency = 0.02;
    
    path.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height / 2 + amplitude * math.sin(x * frequency);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  void _paintHexagons(Canvas canvas, Size size, Paint paint) {
    const double spacing = 30.0;
    const double radius = 10.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final dx = x + radius * math.cos(angle);
          final dy = y + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(dx, dy);
          } else {
            path.lineTo(dx, dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = 1);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
