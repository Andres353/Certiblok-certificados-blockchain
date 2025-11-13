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
import '../../services/adapters/certificate_adapter.dart';
import '../../services/emisor_permission_service.dart';
import '../../services/user_context_service.dart';
import '../../services/adapters/certificate_template_adapter.dart';
import '../../services/certificate_notification_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate_template.dart';

class EmitCertificateScreen extends StatefulWidget {
  final String? studentId; // Opcional para preseleccionar un estudiante
  
  const EmitCertificateScreen({Key? key, this.studentId}) : super(key: key);

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
  bool _useCustomCertificate = true; // Siempre usar certificado personalizado
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
    // Ya no se cargan plantillas, siempre se usa certificado personalizado
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

      // Si se proporcionó un studentId, preseleccionar ese estudiante
      Map<String, dynamic>? studentToSelect;
      if (widget.studentId != null) {
        studentToSelect = students.firstWhere(
          (student) => student['id'] == widget.studentId,
          orElse: () => {},
        );
        if (studentToSelect.isEmpty) {
          print('⚠️ No se encontró el estudiante con ID: ${widget.studentId}');
        }
      }

      setState(() {
        _students = students;
        _selectedStudent = studentToSelect?.isNotEmpty == true ? studentToSelect : null;
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

      final templates = await CertificateTemplateAdapter.getTemplates(
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
        
        // Validar tamaño de la imagen (mismo límite que PDFs)
        const int maxImageSize = 700000; // 700KB para base64
        if (bytes.length > maxImageSize) {
          final double sizeInKB = bytes.length / 1024;
          final double maxSizeInKB = maxImageSize / 1024;
          
          AlertService.showError(
            context, 
            'Imagen Demasiado Grande', 
            'La imagen seleccionada es demasiado grande (${sizeInKB.toStringAsFixed(1)}KB).\n\nEl límite máximo es ${maxSizeInKB.toStringAsFixed(1)}KB.\n\nPor favor, comprime la imagen o usa una más pequeña.'
          );
          return;
        }
        
        setState(() {
          _customCertificateBytes = bytes;
          _customCertificateFileName = image.name;
          _customCertificateMimeType = 'image/jpeg';
          _isPdf = false;
          _useCustomCertificate = true;
        });
        
        // Mostrar confirmación de carga exitosa
        final double sizeInKB = bytes.length / 1024;
        AlertService.showSuccess(
          context, 
          'Imagen Cargada', 
          'Imagen cargada exitosamente (${sizeInKB.toStringAsFixed(1)}KB).\n\nLa imagen está lista para ser usada en el certificado.'
        );
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
          // Validar tamaño del PDF (mismo límite que programas)
          const int maxPdfSize = 700000; // 700KB para base64
          if (file.bytes!.length > maxPdfSize) {
            final double sizeInKB = file.bytes!.length / 1024;
            final double maxSizeInKB = maxPdfSize / 1024;
            
            AlertService.showError(
              context, 
              'PDF Demasiado Grande', 
              'El PDF seleccionado es demasiado grande (${sizeInKB.toStringAsFixed(1)}KB).\n\nEl límite máximo es ${maxSizeInKB.toStringAsFixed(1)}KB.\n\nPor favor, comprime el PDF manualmente o usa un archivo más pequeño.\n\nHerramientas recomendadas:\n• SmallPDF.com\n• ILovePDF.com\n• Adobe Acrobat'
            );
            return;
          }
          
          setState(() {
            _customCertificateBytes = file.bytes;
            _customCertificateFileName = file.name;
            _customCertificateMimeType = 'application/pdf';
            _isPdf = true;
            _useCustomCertificate = true;
            _useTemplate = false;
          });
          
          // Mostrar confirmación de carga exitosa
          final double sizeInKB = file.bytes!.length / 1024;
          AlertService.showSuccess(
            context, 
            'PDF Cargado', 
            'PDF cargado exitosamente (${sizeInKB.toStringAsFixed(1)}KB).\n\nEl archivo está listo para ser usado en el certificado.'
          );
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
      _useCustomCertificate = true; // Mantener siempre activo
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
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff6C4DDC),
                Color(0xff8B5CF6),
              ],
            ),
          ),
        ),
      ),
      body: (_isLoadingStudents || _isLoadingTemplates)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando información...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _students.isEmpty
              ? _buildNoStudentsView()
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xff6C4DDC).withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: _buildEmitForm(),
                ),
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
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del emisor - Card mejorada
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff6C4DDC),
                    Color(0xff8B5CF6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff6C4DDC).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                                'Emisor',
                      style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                        Text(
                          UserContextService.currentContext?.userName ?? 'Emisor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                        ),
                      ],
                    ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Institución',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                        Text(
                          UserContextService.currentContext?.institutionName ?? 'Institución',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
            
            // Selección de estudiante - Card mejorada
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xff6C4DDC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: Color(0xff6C4DDC),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
            Text(
              'Seleccionar Estudiante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
                    ],
                  ),
                  SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedStudent,
              decoration: InputDecoration(
                labelText: 'Estudiante',
                      hintText: 'Selecciona un estudiante',
                border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(Icons.person, color: Color(0xff6C4DDC)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    itemHeight: 60,
                    menuMaxHeight: 300,
              items: _students.map((student) {
                return DropdownMenuItem(
                  value: student,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              student['fullName'] ?? 'Sin nombre',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                            ),
                            SizedBox(height: 2),
                            Text(
                              student['program'] ?? 'Sin programa',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                  ),
                );
              }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return _students.map((student) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            student['fullName'] ?? 'Sin nombre',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();
                    },
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
                    isExpanded: true,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Sección de certificado personalizado (siempre visible) - Card mejorada
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Row(
              children: [
                      Container(
                        padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                          color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                        child: Icon(
                          Icons.description_outlined,
                          color: Color(0xff6C4DDC),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Certificado Personalizado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                  ),
                ),
              ],
                  ),
                  SizedBox(height: 20),
            
                    if (_customCertificateBytes == null) ...[
                      // Área de carga mejorada
              Container(
                decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xff6C4DDC).withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: Color(0xff6C4DDC).withOpacity(0.05),
                        ),
                        child: InkWell(
                          onTap: _pickCustomCertificate,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Color(0xff6C4DDC).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 48,
                                    color: Color(0xff6C4DDC),
                                  ),
                                ),
                                SizedBox(height: 16),
                    Text(
                                  'Cargar Certificado',
                      style: TextStyle(
                                    fontSize: 18,
                        fontWeight: FontWeight.bold,
                                    color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                                  'Haz clic para seleccionar un archivo',
                        style: TextStyle(
                                    fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                                SizedBox(height: 12),
                      Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                                    _buildFormatChip('PDF', Icons.picture_as_pdf, Colors.red),
                                    SizedBox(width: 8),
                                    _buildFormatChip('JPG', Icons.image, Colors.blue),
                                    SizedBox(width: 8),
                                    _buildFormatChip('PNG', Icons.image, Colors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Mostrar certificado cargado - Card mejorada
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                            _isPdf ? Icons.picture_as_pdf : Icons.image,
                                color: Colors.green[700],
                                size: 28,
                          ),
                            ),
                            SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _customCertificateFileName ?? 'Archivo cargado',
                                  style: TextStyle(
                                      color: Colors.green[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green[700],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _isPdf ? 'Documento PDF' : 'Imagen cargada',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                      SizedBox(width: 8),
                                Text(
                                        '• ${(_customCertificateBytes!.length / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                      ),
                                    ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeCustomCertificate,
                              icon: Icon(Icons.close, color: Colors.red[700]),
                            tooltip: 'Eliminar certificado',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                padding: EdgeInsets.all(8),
                              ),
                          ),
                        ],
                      ),
                      ),
                      SizedBox(height: 16),
                      
                      // Vista previa del certificado personalizado mejorada
                      Container(
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          ),
                          child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
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
            
            SizedBox(height: 24),
            
            // Tipo de certificado - Card mejorada
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xff6C4DDC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xff6C4DDC),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
            Text(
              'Tipo de Certificado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
                    ],
                  ),
                  SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCertificateType,
              decoration: InputDecoration(
                labelText: 'Tipo',
                      hintText: 'Selecciona el tipo de certificado',
                border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(Icons.workspace_premium, color: Color(0xff6C4DDC)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _certificateTypes.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                        child: Text(
                          type['label']!,
                          style: TextStyle(fontSize: 15),
                        ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCertificateType = value!;
                });
              },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Información del certificado - Card mejorada
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xff6C4DDC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Color(0xff6C4DDC),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Información del Certificado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
            
            // Título del certificado
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del Certificado',
                      hintText: 'Ej: Certificado de Graduación en Ingeniería de Sistemas',
                border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(Icons.title, color: Color(0xff6C4DDC)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el título del certificado';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Descripción (Opcional)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (Opcional)',
                      hintText: 'Descripción detallada del certificado...',
                border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(Icons.description_outlined, color: Color(0xff6C4DDC)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 3,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Botón de emisión mejorado
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff6C4DDC).withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: SizedBox(
              width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _emitCertificate,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.send, size: 22),
                  label: Text(
                    _isLoading ? 'Emitiendo...' : 'Emitir Certificado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                    elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                  ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                ),
                      ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar chips de formato
  Widget _buildFormatChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
              // Header - Siempre mostrar
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
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
                    template.design.titleFontSize, // Usar tamaño completo
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
                          template.design.subtitleFontSize, // Usar tamaño completo
                          _parseColor(template.design.textColor),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Nombre del estudiante (campo dinámico)
                      Text(
                        student['fullName'] ?? 'Juan Pérez',
                        style: _getTextStyle(
                          template.design.titleFontFamily,
                          template.design.subtitleFontSize + 8, // Usar tamaño completo
                          _parseColor(template.design.textColor),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Descripción
                      Text(
                        'Ha completado exitosamente el programa de estudios',
                        style: _getTextStyle(
                          template.design.bodyFontFamily,
                          template.design.bodyFontSize, // Usar tamaño completo
                          _parseColor(template.design.textColor),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
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
                                  template.design.smallFontSize + 2, // Usar tamaño completo
                                  _parseColor(template.design.textColor),
                                ),
                              ),
                              Text(
                                template.design.issuerTitleLabel,
                                style: _getTextStyle(
                                  template.design.smallFontFamily,
                                  template.design.smallFontSize, // Usar tamaño completo
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
                                  template.design.smallFontSize, // Usar tamaño completo
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
      // Validar que se haya cargado un certificado personalizado
      if (_customCertificateBytes == null) {
        AlertService.showError(context, 'Error', 'Debes cargar un certificado personalizado');
        setState(() => _isLoading = false);
        return;
      }
      
      print('  - Usar certificado personalizado: true');
      
      // Preparar datos del certificado
      Map<String, dynamic> certificateData = {
        'studentIdInInstitution': _selectedStudent!['studentIdInInstitution'],
        'program': _selectedStudent!['program'],
        'faculty': _selectedStudent!['faculty'],
        'issuedByRole': 'emisor',
        'useTemplate': false,
        'useCustomCertificate': true,
      };
      
      // Agregar datos de certificado personalizado (siempre se usa)
      if (_customCertificateBytes != null) {
        // Convertir bytes a base64 para almacenar
        String base64Data = base64Encode(_customCertificateBytes!);
        certificateData['customCertificateData'] = {
          'fileData': base64Data,
          'mimeType': _customCertificateMimeType ?? 'application/pdf',
          'fileName': _customCertificateFileName ?? 'certificate',
          'isPdf': _isPdf,
        };
      }
      
      final certificateId = await CertificateAdapter.createCertificate(
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
        _useCustomCertificate = true; // Mantener siempre activo
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
