// lib/screens/programs/application_form_screen.dart
// Pantalla de formulario de postulación

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/program_opportunity.dart';
import '../../services/application_service.dart';
import '../../services/image_upload_service.dart';

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
      _showErrorSnackBar('Error al cargar certificados: $e');
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
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('📄 Archivo seleccionado: ${file.name}');
        print('📊 Tamaño: ${file.size} bytes');
        print('📁 Ruta: ${file.path}');
        
        setState(() {
          _cvFilePath = file.path;
          _cvFileName = file.name;
        });
        
        _showInfoSnackBar('CV seleccionado exitosamente');
        print('✅ CV configurado correctamente');
      } else {
        print('❌ No se seleccionó ningún archivo');
      }
    } catch (e) {
      print('❌ Error al seleccionar CV: $e');
      _showErrorSnackBar('Error al seleccionar archivo: $e');
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
          // Usar el mismo método que para programas de pasantías
          final pdfData = await ImageUploadService.uploadPdfBytes(
            Uint8List.fromList(bytes),
            'motivation_letters/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
          );
          
          setState(() {
            _motivationPdfData = pdfData;
            _motivationPdfFileName = file.name;
            _isUploadingMotivationPdf = false;
          });
          
          _showInfoSnackBar('Carta de motivación subida exitosamente');
        } else {
          setState(() => _isUploadingMotivationPdf = false);
          _showErrorSnackBar('Error al leer el archivo PDF');
        }
      }
    } catch (e) {
      setState(() => _isUploadingMotivationPdf = false);
      _showErrorSnackBar('Error al subir carta de motivación: $e');
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

    if (_cvFilePath == null) {
      _showErrorSnackBar('Debes cargar tu CV');
      return;
    }

    if (_motivationPdfData == null) {
      _showErrorSnackBar('Debes subir tu carta de motivación en PDF');
      return;
    }

    if (_selectedCertificates.isEmpty) {
      _showErrorSnackBar('Debes seleccionar al menos un certificado');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApplicationService.createApplication(
        programId: widget.program.id,
        cvFilePath: _cvFilePath!,
        cvFileName: _cvFileName!,
        selectedCertificates: _selectedCertificates,
        motivationLetter: _motivationController.text,
        motivationPdfData: _motivationPdfData,
        motivationPdfFileName: _motivationPdfFileName,
      );

      _showSuccessDialog();
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Error al enviar postulación: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('¡Postulación Enviada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu postulación ha sido enviada exitosamente.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Recibirás una notificación cuando sea revisada.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar dialog
              Navigator.of(context).pop(); // Volver a la pantalla anterior
            },
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Postularse a ${widget.program.title}'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
    );
  }

  Widget _buildProgramInfo(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Programa',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            Text(
              widget.program.title,
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff6C4DDC),
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.program.institutionName,
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${widget.program.careerNames.join(', ')}',
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCVSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Curriculum Vitae *',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sube tu CV en formato PDF, DOC o DOCX',
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            
            // Sección de subida de CV
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  if (_cvFilePath == null) ...[
                    // Estado sin archivo
                    Icon(
                      Icons.description,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ningún archivo seleccionado',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sube tu CV en PDF, DOC o DOCX',
                      style: TextStyle(
                        fontSize: isWeb ? 12 : 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickCV,
                      icon: Icon(Icons.upload_file, size: 18),
                      label: Text('Seleccionar CV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Estado con archivo seleccionado
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Colors.green[600],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cvFileName ?? 'CV.pdf',
                                style: TextStyle(
                                  fontSize: isWeb ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Archivo seleccionado exitosamente',
                                style: TextStyle(
                                  fontSize: isWeb ? 12 : 10,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _cvFilePath = null;
                              _cvFileName = null;
                            });
                          },
                          icon: Icon(Icons.delete, color: Colors.red[600]),
                          tooltip: 'Eliminar archivo',
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

  Widget _buildCertificatesSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificados Relevantes *',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Selecciona los certificados que quieres incluir en tu postulación',
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            
            if (_availableCertificates.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.grey[600], size: 32),
                    SizedBox(height: 8),
                    Text(
                      'No tienes certificados disponibles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Necesitas tener certificados válidos para postularte',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._availableCertificates.map((cert) => _buildCertificateItem(cert, isWeb)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateItem(Map<String, dynamic> cert, bool isWeb) {
    final isSelected = _selectedCertificates.contains(cert['id']);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
        title: Text(
          cert['title'] ?? 'Certificado',
          style: TextStyle(
            fontSize: isWeb ? 14 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${cert['type'] ?? 'Tipo'} - ${cert['institutionName'] ?? 'Institución'}',
          style: TextStyle(
            fontSize: isWeb ? 12 : 11,
            color: Colors.grey[600],
          ),
        ),
        activeColor: Color(0xff6C4DDC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildMotivationSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carta de Motivación (PDF) *',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sube tu carta de motivación en formato PDF',
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            
            // Sección de subida de PDF
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  if (_motivationPdfData == null) ...[
                    // Estado sin archivo
                    Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ningún archivo seleccionado',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sube tu carta de motivación en PDF',
                      style: TextStyle(
                        fontSize: isWeb ? 12 : 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploadingMotivationPdf ? null : _uploadMotivationPdf,
                      icon: _isUploadingMotivationPdf 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.upload_file, size: 18),
                      label: Text(_isUploadingMotivationPdf ? 'Subiendo...' : 'Subir PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Estado con archivo subido
                    Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red[600],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _motivationPdfFileName ?? 'Carta de motivación.pdf',
                                style: TextStyle(
                                  fontSize: isWeb ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Archivo subido exitosamente',
                                style: TextStyle(
                                  fontSize: isWeb ? 12 : 10,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _removeMotivationPdf,
                          icon: Icon(Icons.delete, color: Colors.red[600]),
                          tooltip: 'Eliminar archivo',
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

  Widget _buildSubmitButton(bool isWeb) {
    return SizedBox(
      width: double.infinity,
      height: isWeb ? 56 : 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitApplication,
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.send, size: isWeb ? 20 : 18),
        label: Text(
          _isSubmitting ? 'Enviando...' : 'Enviar Postulación',
          style: TextStyle(
            fontSize: isWeb ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff6C4DDC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
