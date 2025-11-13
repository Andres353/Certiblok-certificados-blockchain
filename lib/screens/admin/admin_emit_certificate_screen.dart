import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import '../../services/alert_service.dart';
import '../../services/adapters/certificate_adapter.dart';
import '../../models/certificate_template.dart';
import '../../services/user_context_service.dart';
import '../../services/adapters/certificate_template_adapter.dart';

class AdminEmitCertificateScreen extends StatefulWidget {
  const AdminEmitCertificateScreen({super.key});

  @override
  _AdminEmitCertificateScreenState createState() => _AdminEmitCertificateScreenState();
}

class _AdminEmitCertificateScreenState extends State<AdminEmitCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCareerId;
  String? _selectedStudentId;
  bool _isLoading = false;
  bool _isLoadingStudents = false;
  bool _isEmitting = false; // Para el indicador de carga durante la emisión

  List<Map<String, dynamic>> _careers = [];
  List<Map<String, dynamic>> _students = [];
  List<CertificateTemplate> _templates = [];
  
  // Variables para el nuevo diseño
  String _selectedCertificateType = 'graduation';
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
    _loadCareers();
    _loadTemplates();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCareers() async {
    try {
      setState(() => _isLoading = true);
      
      final userContext = UserContextService.currentContext;
      if (userContext?.currentInstitution?.id == null) {
        AlertService.showError(context, 'Error', 'No se pudo obtener la institución actual');
        setState(() => _isLoading = false);
        return;
      }
      
      // Obtener solo las carreras de la institución actual del administrador
      final supabase = Supabase.instance.client;
      final programs = await supabase
          .from('programs')
          .select('*')
          .eq('institution_id', userContext!.currentInstitution!.id)
          .eq('status', 'active');
      
      setState(() {
        _careers = programs.map((program) => {
          'id': program['id'],
          'name': program['name'] ?? 'Sin nombre',
          'facultyName': program['faculty_name'] ?? 'Sin facultad',
          'code': program['program_code'] ?? '',
          'description': program['description'] ?? '',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AlertService.showError(context, 'Error', 'Error cargando carreras: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCareerId == null) return;
    
    try {
      setState(() => _isLoadingStudents = true);
      
      final userContext = UserContextService.currentContext;
      if (userContext?.currentInstitution?.id == null) {
        AlertService.showError(context, 'Error', 'No se pudo obtener la institución actual');
        setState(() => _isLoadingStudents = false);
        return;
      }
      
      print('🔍 Cargando estudiantes para carrera: $_selectedCareerId');
      print('🏫 Institución: ${userContext!.currentInstitution!.id}');
      
      // Buscar estudiantes que estén asociados a la institución y carrera del administrador
      final supabase = Supabase.instance.client;
      final students = await supabase
          .from('users')
          .select('*')
          .eq('role', 'student')
          .eq('institution_id', userContext.currentInstitution!.id)
          .eq('program_id', _selectedCareerId!);
      
      print('📊 Estudiantes encontrados: ${students.length}');
      
      // Debug adicional: mostrar todos los estudiantes de la institución para verificar
      final allStudents = await supabase
          .from('users')
          .select('*')
          .eq('role', 'student')
          .eq('institution_id', userContext.currentInstitution!.id);
      
      print('🔍 Todos los estudiantes de la institución: ${allStudents.length}');
      for (var student in allStudents) {
        print('👤 Estudiante: ${student['full_name']} - ProgramId: ${student['program_id']} - Program: ${student['program']}');
      }
      
      setState(() {
        _students = students.map((student) {
          print('👤 Estudiante: ${student['full_name']} - ${student['email']}');
          return {
            'id': student['id'],
            'name': student['full_name'] ?? 'Sin nombre',
            'email': student['email'] ?? 'Sin email',
            'studentId': student['student_id'] ?? 'Sin ID',
          };
        }).toList();
        _isLoadingStudents = false;
      });
      
      if (_students.isEmpty) {
        AlertService.showError(context, 'Información', 'No se encontraron estudiantes para esta carrera');
      }
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      print('❌ Error cargando estudiantes: $e');
      AlertService.showError(context, 'Error', 'Error cargando estudiantes: $e');
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await CertificateTemplateAdapter.getTemplates();
      setState(() {
        _templates = templates;
      });
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error cargando plantillas: $e');
    }
  }


  Future<void> _pickCustomCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          const int maxFileSize = 700000; // 700KB para base64
          if (file.bytes!.length > maxFileSize) {
            final double sizeInKB = file.bytes!.length / 1024;
            final double maxSizeInKB = maxFileSize / 1024;
            
            AlertService.showError(
              context, 
              'Archivo Demasiado Grande', 
              'El archivo seleccionado es demasiado grande (${sizeInKB.toStringAsFixed(1)}KB).\n\nEl límite máximo es ${maxSizeInKB.toStringAsFixed(1)}KB.\n\nPor favor, comprime el archivo manualmente o usa un archivo más pequeño.'
            );
            return;
          }
          
          final String extension = file.extension?.toLowerCase() ?? '';
          final bool isPdf = extension == 'pdf';
          
          setState(() {
            _customCertificateBytes = file.bytes;
            _customCertificateFileName = file.name;
            _customCertificateMimeType = isPdf ? 'application/pdf' : 'image/$extension';
            _isPdf = isPdf;
          });
          
          // Mostrar confirmación de carga exitosa
          final double sizeInKB = file.bytes!.length / 1024;
          AlertService.showSuccess(
            context, 
            isPdf ? 'PDF Cargado' : 'Imagen Cargada', 
            '${isPdf ? 'PDF' : 'Imagen'} cargada exitosamente (${sizeInKB.toStringAsFixed(1)}KB).\n\nEl archivo está listo para ser usado en el certificado.'
          );
        }
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error cargando archivo: $e');
    }
  }

  void _removeCustomCertificate() {
    setState(() {
      _customCertificateBytes = null;
      _customCertificateFileName = null;
      _customCertificateMimeType = null;
      _isPdf = false;
    });
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

  Widget _buildTemplatePreview() {
    if (_selectedTemplate == null || _selectedStudentId == null) {
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
    final selectedStudent = _students.firstWhere((s) => s['id'] == _selectedStudentId);
    
    // Usar EXACTAMENTE la misma lógica de renderizado que el editor de plantillas
    return _buildCertificatePreviewExact(template, selectedStudent);
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
                        student['name'] ?? 'Juan Pérez',
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
      case 'top-right':
        left = 500 - 80 - 20; // 500px - logo width - margin
        top = 20;
        break;
      case 'bottom-left':
        left = 20;
        top = 350 - 60 - 20; // 350px - logo height - margin
        break;
      case 'bottom-right':
        left = 500 - 80 - 20;
        top = 350 - 60 - 20;
        break;
      case 'center':
        left = (500 - 80) / 2;
        top = (350 - 60) / 2;
        break;
      default:
        left = 20;
        top = 20;
    }
    
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _buildInstitutionLogo(template.design.institutionLogoUrl),
        ),
      ),
    );
  }

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

    return TextStyle(
      fontFamily: googleFontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
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

  Future<void> _emitCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      AlertService.showError(context, 'Error', 'Debe seleccionar un estudiante');
      return;
    }

    // Obtener datos del estudiante y carrera para la confirmación
    final selectedStudent = _students.firstWhere((s) => s['id'] == _selectedStudentId);
    final selectedCareer = _careers.firstWhere((c) => c['id'] == _selectedCareerId);

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
                    _buildDetailRow('👤 Estudiante:', selectedStudent['name']),
                    _buildDetailRow('🎓 Carrera:', selectedCareer['name']),
                    _buildDetailRow('📜 Tipo:', _selectedCertificateType),
                    _buildDetailRow('📝 Título:', _titleController.text.trim()),
                    if (_descriptionController.text.trim().isNotEmpty)
                      _buildDetailRow('📄 Descripción:', _descriptionController.text.trim()),
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

    try {
      setState(() => _isEmitting = true);

      final userContext = UserContextService.currentContext;
      if (userContext == null) {
        setState(() => _isEmitting = false);
        AlertService.showError(context, 'Error', 'No se pudo obtener el contexto del usuario');
        return;
      }

      // Obtener datos del estudiante seleccionado
      final selectedStudent = _students.firstWhere((s) => s['id'] == _selectedStudentId);
      final selectedCareer = _careers.firstWhere((c) => c['id'] == _selectedCareerId);

      // Preparar datos del certificado
      Map<String, dynamic> certificateData = {
        'studentId': _selectedStudentId,
        'studentName': selectedStudent['name'],
        'studentEmail': selectedStudent['email'],
        'programName': selectedCareer['name'],
        'facultyName': selectedCareer['facultyName'] ?? 'Facultad',
        'institutionName': userContext.currentInstitution?.name ?? 'Institución',
        'issuerName': userContext.userName,
        'description': _descriptionController.text.trim(),
        'issuedBy': userContext.userId,
        'issuedByName': userContext.userName,
        'issuedAt': DateTime.now().toIso8601String(),
        'status': 'active',
        'type': _selectedCertificateType,
      };

      // Validar que se haya cargado un certificado personalizado
      if (_customCertificateBytes == null) {
        setState(() => _isEmitting = false);
        AlertService.showError(context, 'Error', 'Debes cargar un certificado personalizado');
        return;
      }

      // Procesar certificado personalizado (siempre se usa)
      final String base64Data = base64Encode(_customCertificateBytes!);
      certificateData['customCertificateData'] = base64Data;
      certificateData['customCertificateFileName'] = _customCertificateFileName;
      certificateData['customCertificateMimeType'] = _customCertificateMimeType;
      certificateData['isPdf'] = _isPdf;

      // Emitir certificado
      await CertificateAdapter.createCertificate(
        studentId: _selectedStudentId!,
        certificateType: _selectedCertificateType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        data: certificateData,
        institutionId: userContext.currentInstitution?.id,
      );

      setState(() => _isEmitting = false);
      
      // Limpiar formulario
      _clearForm();
      
      // Mostrar SweetAlert de éxito
      AlertService.showSuccess(context, 'Éxito', 'Certificado emitido exitosamente');
      
      // Volver atrás
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isEmitting = false);
      AlertService.showError(context, 'Error', 'Error emitiendo certificado: $e');
    }
  }

  void _clearForm() {
    // Limpiar controladores de texto
    _titleController.clear();
    _descriptionController.clear();
    
    // Limpiar selecciones
    setState(() {
      _selectedCareerId = null;
      _selectedStudentId = null;
      _selectedCertificateType = 'graduation';
      _selectedTemplate = null;
      _useTemplate = false;
      
      // Limpiar archivo de certificado personalizado
      _customCertificateBytes = null;
      _customCertificateFileName = null;
      _customCertificateMimeType = null;
      _isPdf = false;
      
      // Limpiar lista de estudiantes
      _students = [];
    });
    
    // Resetear formulario
    _formKey.currentState?.reset();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emitir Certificado - Administrador'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Contenido principal
          _isLoading && _careers.isEmpty
              ? Center(child: CircularProgressIndicator())
              : _careers.isEmpty
                  ? _buildNoCareersView()
                  : _buildEmitForm(),
          
          // Indicador de carga durante la emisión (centrado en la página)
          if (_isEmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Emitiendo certificado...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoCareersView() {
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
              'No hay carreras disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No hay carreras registradas en tu institución para emitir certificados.',
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
            // Información del administrador
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Administrador',
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
                          UserContextService.currentContext?.userName ?? 'Administrador',
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
                          UserContextService.currentContext?.currentInstitution?.name ?? 'Institución',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Selección de carrera
            Text(
              'Seleccionar Carrera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            _buildCareerSelector(),
            
            SizedBox(height: 24),
            
            // Selección de estudiante
            if (_selectedCareerId != null) ...[
              Text(
                'Seleccionar Estudiante',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 12),
              _buildStudentSelector(),
              SizedBox(height: 24),
            ],
            
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
            
            // Descripción (Opcional)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (Opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.description),
                hintText: 'Descripción detallada del certificado...',
              ),
              maxLines: 3,
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


  Widget _buildCareerSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCareerId,
      decoration: InputDecoration(
        labelText: 'Seleccionar Carrera *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.school),
      ),
      items: _careers.map((career) {
        return DropdownMenuItem<String>(
          value: career['id'],
          child: Text('${career['name']} - ${career['facultyName']}'),
        );
      }).toList(),
      onChanged: (value) {
        print('🎓 Carrera seleccionada: $value');
        setState(() {
          _selectedCareerId = value;
          _selectedStudentId = null;
          _students.clear();
        });
        if (value != null) {
          print('🔄 Iniciando carga de estudiantes...');
          _loadStudents();
        } else {
          print('❌ No se seleccionó carrera');
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Debe seleccionar una carrera';
        }
        return null;
      },
    );
  }

  Widget _buildStudentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedStudentId,
          decoration: InputDecoration(
            labelText: 'Seleccionar Estudiante *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
            helperText: _students.isEmpty && !_isLoadingStudents 
                ? 'No hay estudiantes en esta carrera' 
                : '${_students.length} estudiante(s) encontrado(s)',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          itemHeight: 50,
          menuMaxHeight: 300,
          items: _students.map((student) {
            return DropdownMenuItem<String>(
              value: student['id'],
              child: Text(
                '${student['name']} (${student['studentId']})',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: _isLoadingStudents ? null : (value) {
            setState(() {
              _selectedStudentId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Debe seleccionar un estudiante';
            }
            return null;
          },
          isExpanded: true,
        ),
        if (_isLoadingStudents)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator()),
                SizedBox(width: 8),
                Text('Cargando estudiantes...', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        if (_students.isEmpty && !_isLoadingStudents && _selectedCareerId != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se encontraron estudiantes para esta carrera. Verifica que haya estudiantes registrados en esta carrera.',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return DropdownButtonFormField<CertificateTemplate>(
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
    );
  }
}

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
        paint,
      );
    }
  }

  void _paintGeometry(Canvas canvas, Size size, Paint paint) {
    const double spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x + spacing / 2, y + spacing / 2)
          ..lineTo(x, y + spacing)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintWaves(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    const double amplitude = 10.0;
    const double frequency = 0.1;
    
    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x += 1) {
      final y = size.height / 2 + amplitude * math.sin(x * frequency);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }

  void _paintHexagons(Canvas canvas, Size size, Paint paint) {
    const double spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path();
        final center = Offset(x + spacing / 2, y + spacing / 2);
        final radius = spacing / 3;
        
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final point = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
