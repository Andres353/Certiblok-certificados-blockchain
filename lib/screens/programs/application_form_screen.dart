// lib/screens/programs/application_form_screen.dart
// Pantalla de formulario de postulación

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/program_opportunity.dart';
import '../../services/application_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/alert_service.dart';

class ApplicationFormScreen extends StatefulWidget {
  final ProgramOpportunity program;

  const ApplicationFormScreen({Key? key, required this.program}) : super(key: key);

  @override
  _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivationController = TextEditingController();
  
  List<Map<String, dynamic>> _availableCertificates = [];
  List<String> _selectedCertificates = [];
  String? _cvFilePath;
  String? _cvFileName;
  Uint8List? _cvFileBytes; // Bytes del CV para web
  String? _motivationPdfData; // Base64 del PDF de carta de motivación
  String? _motivationPdfFileName;
  bool _isUploadingMotivationPdf = false;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoading = true);
    
    try {
      final certificates = await ApplicationService.getStudentCertificates();
      setState(() {
        _availableCertificates = certificates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = 'No se pudieron cargar tus certificados.';
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('conexión') || errorStr.contains('network') || errorStr.contains('timeout')) {
        errorMsg = 'Error de conexión. Verifica tu internet.';
      } else if (errorStr.contains('autenticado') || errorStr.contains('auth')) {
        errorMsg = 'Sesión expirada. Inicia sesión nuevamente.';
      }
      AlertService.showError(
        context,
        'Error',
        errorMsg,
      );
    }
  }

  Future<void> _pickCV() async {
    try {
      print('🔄 Iniciando selección de CV...');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
        allowCompression: true,
        withData: true, // Cargar bytes para web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('📄 Archivo seleccionado: ${file.name}');
        print('📊 Tamaño: ${file.size} bytes');
        
        // Manejar path de forma segura para web
        String? filePath;
        try {
          // Intentar acceder al path
          final path = file.path;
          if (path != null && path.isNotEmpty) {
            filePath = path;
          }
        } catch (e) {
          // En web, path no está disponible, esto es normal
          print('ℹ️ Path no disponible (web), usando bytes en su lugar');
        }
        
        setState(() {
          _cvFilePath = filePath;
          _cvFileName = file.name;
          _cvFileBytes = file.bytes; // Importante para web
        });
        
        print('✅ CV configurado correctamente');
      } else {
        print('❌ No se seleccionó ningún archivo');
      }
    } catch (e) {
      print('❌ Error al seleccionar CV: $e');
      String errorMsg = 'No se pudo seleccionar el archivo.';
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('formato') || errorStr.contains('extensión') || errorStr.contains('tipo')) {
        errorMsg = 'Formato de archivo no válido. Usa PDF, DOC o DOCX.';
      } else if (errorStr.contains('tamaño') || errorStr.contains('size') || errorStr.contains('grande')) {
        errorMsg = 'El archivo es demasiado grande.';
      }
      AlertService.showError(
        context,
        'Error',
        errorMsg,
      );
    }
  }

  Future<void> _uploadMotivationPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingMotivationPdf = true);
        
        final file = result.files.first;
        final bytes = file.bytes;
        
        if (bytes != null) {
          // Subir PDF a Supabase Storage
          final pdfUrl = await ImageUploadService.uploadPdfBytes(
            Uint8List.fromList(bytes),
            'motivation_letters/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
          );
          
          setState(() {
            _motivationPdfData = pdfUrl; // Almacenar URL de Supabase Storage
            _motivationPdfFileName = file.name;
            _isUploadingMotivationPdf = false;
          });
        } else {
          setState(() => _isUploadingMotivationPdf = false);
          AlertService.showError(
            context,
            'Error',
            'No se pudo leer el archivo PDF. Verifica que el archivo no esté dañado.',
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingMotivationPdf = false);
      String errorMsg = 'No se pudo subir la carta de motivación.';
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('tamaño') || errorStr.contains('size') || errorStr.contains('grande') || errorStr.contains('demasiado')) {
        errorMsg = 'El PDF es demasiado grande. El límite es 700KB. Comprime el archivo.';
      } else if (errorStr.contains('formato') || errorStr.contains('válido') || errorStr.contains('invalid')) {
        errorMsg = 'Formato de archivo no válido. Solo se aceptan PDFs.';
      } else if (errorStr.contains('conexión') || errorStr.contains('network') || errorStr.contains('timeout')) {
        errorMsg = 'Error de conexión. Verifica tu internet.';
      }
      AlertService.showError(
        context,
        'Error',
        errorMsg,
      );
    }
  }

  void _removeMotivationPdf() {
    setState(() {
      _motivationPdfData = null;
      _motivationPdfFileName = null;
    });
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cvFileBytes == null && _cvFilePath == null) {
      AlertService.showError(
        context,
        'CV Requerido',
        'Debes cargar tu CV para continuar.',
      );
      return;
    }

    if (_motivationPdfData == null) {
      AlertService.showError(
        context,
        'Carta de Motivación Requerida',
        'Debes subir tu carta de motivación en PDF.',
      );
      return;
    }

    // Los certificados son opcionales, no validar

    setState(() => _isSubmitting = true);

    try {
      await ApplicationService.createApplication(
        programId: widget.program.id,
        cvFilePath: _cvFilePath,
        cvFileName: _cvFileName!,
        cvFileBytes: _cvFileBytes, // Agregar bytes para web
        selectedCertificates: _selectedCertificates,
        motivationLetter: _motivationController.text,
        motivationPdfData: _motivationPdfData,
        motivationPdfFileName: _motivationPdfFileName,
      );

      AlertService.showSuccess(
        context,
        '¡Postulación Enviada!',
        'Tu postulación ha sido enviada exitosamente.\n\nRecibirás una notificación cuando sea revisada.',
        onOk: () {
          Navigator.of(context).pop(); // Volver a la pantalla anterior
        },
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      String errorMsg = 'No se pudo enviar tu postulación.';
      final errorStr = e.toString().toLowerCase();
      
      // Errores de tamaño de archivo
      if (errorStr.contains('tamaño') || errorStr.contains('size') || errorStr.contains('grande') || errorStr.contains('demasiado') || errorStr.contains('límite es')) {
        if (errorStr.contains('cv')) {
          errorMsg = 'El CV es demasiado grande. El límite es 700KB. Comprime el archivo.';
        } else if (errorStr.contains('pdf') || errorStr.contains('motivación')) {
          errorMsg = 'La carta de motivación es demasiado grande. El límite es 700KB. Comprime el PDF.';
        } else {
          errorMsg = 'Uno de los archivos es demasiado grande. El límite es 700KB.';
        }
      }
      // Errores de conexión
      else if (errorStr.contains('conexión') || errorStr.contains('network') || errorStr.contains('timeout') || errorStr.contains('connection')) {
        errorMsg = 'Error de conexión. Verifica tu internet.';
      }
      // Errores de cupos
      else if (errorStr.contains('cupos') || errorStr.contains('cupo') || errorStr.contains('no hay cupos')) {
        errorMsg = 'No hay cupos disponibles para este programa.';
      }
      // Errores de fecha límite
      else if (errorStr.contains('fecha') || errorStr.contains('deadline') || errorStr.contains('límite') || errorStr.contains('pasado')) {
        errorMsg = 'La fecha límite de postulación ha pasado.';
      }
      // Errores de postulación duplicada
      else if (errorStr.contains('ya aplicó') || errorStr.contains('ya se postuló') || errorStr.contains('ya te postulaste')) {
        errorMsg = 'Ya te postulaste a este programa.';
      }
      // Errores de autenticación
      else if (errorStr.contains('autenticado') || errorStr.contains('auth') || errorStr.contains('sesión') || errorStr.contains('login')) {
        errorMsg = 'Sesión expirada. Inicia sesión nuevamente.';
      }
      // Errores de permisos
      else if (errorStr.contains('estudiante') || errorStr.contains('student') || errorStr.contains('permisos') || errorStr.contains('permission')) {
        errorMsg = 'Solo los estudiantes pueden postularse.';
      }
      // Errores de programa no encontrado
      else if (errorStr.contains('programa no encontrado') || errorStr.contains('program not found')) {
        errorMsg = 'El programa no existe o fue eliminado.';
      }
      // Errores de datos incompletos
      else if (errorStr.contains('incompletos') || errorStr.contains('incomplete') || errorStr.contains('datos del usuario')) {
        errorMsg = 'Datos incompletos. Cierra sesión y vuelve a iniciar.';
      }
      // Errores de programa no activo o no abierto
      else if (errorStr.contains('no está activo') || errorStr.contains('no está abierto')) {
        errorMsg = 'El programa no está disponible para postulaciones.';
      }
      // Errores de formato de archivo
      else if (errorStr.contains('formato') || errorStr.contains('format') || errorStr.contains('válido') || errorStr.contains('invalid file')) {
        errorMsg = 'Formato de archivo no válido. Verifica los archivos.';
      }
      // Errores de base de datos
      else if (errorStr.contains('foreign key') || errorStr.contains('constraint') || errorStr.contains('database') || errorStr.contains('supabase')) {
        errorMsg = 'Error en la base de datos. Intenta nuevamente.';
      }
      // Si no se detecta un error específico, extraer el mensaje del error
      else {
        // Extraer el mensaje real del error, removiendo "Exception:" y otros prefijos
        String cleanError = errorStr;
        if (cleanError.contains('exception:')) {
          cleanError = cleanError.split('exception:').last.trim();
        }
        if (cleanError.contains('error al crear postulación:')) {
          cleanError = cleanError.split('error al crear postulación:').last.trim();
        }
        if (cleanError.contains('error')) {
          final parts = cleanError.split('error');
          if (parts.length > 1) {
            cleanError = parts.last.trim();
            if (cleanError.startsWith(':')) {
              cleanError = cleanError.substring(1).trim();
            }
          }
        }
        // Si el mensaje limpio es muy largo o contiene detalles técnicos, usar mensaje genérico
        if (cleanError.length > 100 || cleanError.contains('stack') || cleanError.contains('trace') || cleanError.contains('at ') || cleanError.contains('package:')) {
          errorMsg = 'Error al enviar la postulación. Verifica tu conexión e intenta nuevamente.';
        } else if (cleanError.isNotEmpty && cleanError != errorStr) {
          // Usar el mensaje limpio si es razonable
          errorMsg = cleanError.substring(0, cleanError.length > 150 ? 150 : cleanError.length);
        }
      }
      
      AlertService.showError(
        context,
        'Error',
        errorMsg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Postularse a Pasantía'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isWeb ? 24 : 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del programa
                        _buildProgramInfo(isWeb),
                        
                        SizedBox(height: 24),
                        
                        // Carga de CV
                        _buildCVSection(isWeb),
                        
                        SizedBox(height: 24),
                        
                        // Selección de certificados
                        _buildCertificatesSection(isWeb),
                        
                        SizedBox(height: 24),
                        
                        // Carta de motivación
                        _buildMotivationSection(isWeb),
                        
                        SizedBox(height: 32),
                        
                        // Botón de envío
                        _buildSubmitButton(isWeb),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProgramInfo(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
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
                  child: Icon(Icons.work_outline, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Programa',
                        style: TextStyle(
                          fontSize: isWeb ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.program.title,
                        style: TextStyle(
                          fontSize: isWeb ? 22 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.program.institutionName,
                          style: TextStyle(
                            fontSize: isWeb ? 16 : 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.program.careerNames.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.book, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: widget.program.careerNames.map((career) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  career,
                                  style: TextStyle(
                                    fontSize: isWeb ? 13 : 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCVSection(bool isWeb) {
    return Card(
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.description, color: Color(0xff6C4DDC), size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Curriculum Vitae *',
                          style: TextStyle(
                            fontSize: isWeb ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sube tu CV en formato PDF, DOC o DOCX',
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Sección de subida de CV
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: (_cvFilePath == null && _cvFileName == null && _cvFileBytes == null)
                        ? [Colors.blue[50]!, Colors.blue[100]!]
                        : [Colors.green[50]!, Colors.green[100]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_cvFilePath == null && _cvFileName == null && _cvFileBytes == null)
                        ? Colors.blue[200]!
                        : Colors.green[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ((_cvFilePath == null && _cvFileName == null && _cvFileBytes == null) ? Colors.blue : Colors.green).withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_cvFilePath == null && _cvFileName == null && _cvFileBytes == null) ...[
                      // Estado sin archivo
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 56,
                          color: Colors.blue[400],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Ningún archivo seleccionado',
                        style: TextStyle(
                          fontSize: isWeb ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Formatos aceptados: PDF, DOC, DOCX',
                        style: TextStyle(
                          fontSize: isWeb ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pickCV,
                        icon: Icon(Icons.upload_file, size: 20),
                        label: Text(
                          'Seleccionar CV',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ] else ...[
                      // Estado con archivo seleccionado (igual que PDF de motivación)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
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
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _cvFileName ?? 'CV.pdf',
                                    style: TextStyle(
                                      fontSize: isWeb ? 16 : 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff2E2F44),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Archivo seleccionado exitosamente',
                                        style: TextStyle(
                                          fontSize: isWeb ? 13 : 12,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _cvFilePath = null;
                                  _cvFileName = null;
                                  _cvFileBytes = null;
                                });
                              },
                              icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 24),
                              tooltip: 'Eliminar archivo',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificatesSection(bool isWeb) {
    return Card(
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.verified, color: Color(0xff6C4DDC), size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificados Relevantes (Opcional)',
                          style: TextStyle(
                            fontSize: isWeb ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Selecciona los certificados que quieres incluir (opcional)',
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              if (_availableCertificates.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[600], size: 40),
                      SizedBox(height: 12),
                      Text(
                        'No tienes certificados disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Necesitas tener certificados válidos para postularte',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                // Contador de certificados seleccionados
                if (_selectedCertificates.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${_selectedCertificates.length} certificado${_selectedCertificates.length > 1 ? 's' : ''} seleccionado${_selectedCertificates.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Contenedor con altura máxima y scrollbar
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 350, // Altura máxima
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        children: _availableCertificates
                            .map((cert) => _buildCertificateItem(cert, isWeb))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateItem(Map<String, dynamic> cert, bool isWeb) {
    final isSelected = _selectedCertificates.contains(cert['id']);
    
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xff6C4DDC).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Color(0xff6C4DDC) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ] : null,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedCertificates.add(cert['id']);
            } else {
              _selectedCertificates.remove(cert['id']);
            }
          });
        },
        activeColor: Color(0xff6C4DDC),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xff6C4DDC) : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.verified,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                cert['title'] ?? 'Certificado',
                style: TextStyle(
                  fontSize: isWeb ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Color(0xff6C4DDC) : Color(0xff2E2F44),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(left: 42, top: 4),
          child: Text(
            '${cert['type'] ?? 'Tipo'} - ${cert['institutionName'] ?? 'Institución'}',
            style: TextStyle(
              fontSize: isWeb ? 13 : 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationSection(bool isWeb) {
    return Card(
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.picture_as_pdf, color: Color(0xff6C4DDC), size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carta de Motivación (PDF) *',
                          style: TextStyle(
                            fontSize: isWeb ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sube tu carta de motivación en formato PDF',
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Sección de subida de PDF
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _motivationPdfData == null 
                        ? [Colors.red[50]!, Colors.red[100]!]
                        : [Colors.green[50]!, Colors.green[100]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _motivationPdfData == null 
                        ? Colors.red[200]!
                        : Colors.green[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_motivationPdfData == null ? Colors.red : Colors.green).withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_motivationPdfData == null) ...[
                      // Estado sin archivo
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 56,
                          color: Colors.red[400],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Ningún archivo seleccionado',
                        style: TextStyle(
                          fontSize: isWeb ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Formato requerido: PDF',
                        style: TextStyle(
                          fontSize: isWeb ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isUploadingMotivationPdf ? null : _uploadMotivationPdf,
                        icon: _isUploadingMotivationPdf 
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.upload_file, size: 20),
                        label: Text(
                          _isUploadingMotivationPdf ? 'Subiendo...' : 'Subir PDF',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ] else ...[
                      // Estado con archivo subido
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
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
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _motivationPdfFileName ?? 'Carta de motivación.pdf',
                                    style: TextStyle(
                                      fontSize: isWeb ? 16 : 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff2E2F44),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Archivo subido exitosamente',
                                        style: TextStyle(
                                          fontSize: isWeb ? 13 : 12,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _removeMotivationPdf,
                              icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 24),
                              tooltip: 'Eliminar archivo',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: isWeb ? 60 : 56,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitApplication,
          icon: _isSubmitting
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.send_rounded, size: isWeb ? 22 : 20),
          label: Text(
            _isSubmitting ? 'Enviando Postulación...' : 'Enviar Postulación',
            style: TextStyle(
              fontSize: isWeb ? 18 : 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

}
