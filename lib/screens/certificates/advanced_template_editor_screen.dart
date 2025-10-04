// lib/screens/certificates/advanced_template_editor_screen.dart
// Editor avanzado de plantillas de certificados

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import '../../services/certificate_template_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate_template.dart';

class AdvancedTemplateEditorScreen extends StatefulWidget {
  final CertificateTemplate? template;

  const AdvancedTemplateEditorScreen({Key? key, this.template}) : super(key: key);

  @override
  _AdvancedTemplateEditorScreenState createState() => _AdvancedTemplateEditorScreenState();
}

class _AdvancedTemplateEditorScreenState extends State<AdvancedTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Controllers para textos del certificado (solo los editables)
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionTextController = TextEditingController();
  final _issuerTitleController = TextEditingController();

  bool _isSaving = false;
  bool _showPreview = true;

  late CertificateTemplate _currentTemplate;
  late TemplateDesign _currentDesign;
  late TemplateLayout _currentLayout;
  
  // Variables para manejo de imágenes
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _institutionLogoBytes;
  Uint8List? _backgroundImageBytes;
  bool _isUploadingLogo = false;
  bool _isUploadingBackground = false;
  
  // Variables para posicionamiento libre de imágenes
  Offset _logoPosition = Offset(200, 50); // Posición inicial del logo
  Offset _backgroundImagePosition = Offset(0, 0); // Posición de la imagen de fondo
  bool _isDraggingLogo = false;
  bool _isDraggingBackground = false;
  double _logoSize = 80.0; // Tamaño del logo
  double _backgroundImageOpacity = 0.3; // Opacidad de la imagen de fondo
  
  // Lista de fuentes disponibles (fuentes del sistema de Flutter)
  final List<String> _availableFonts = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Georgia',
    'Verdana',
    'Helvetica',
    'Trebuchet MS',
    'Comic Sans MS',
    'Impact',
    'Palatino',
    'Garamond',
    'Bookman',
    'Avant Garde',
    'Century Gothic',
    'Lucida Console',
    'Monaco',
    'Consolas',
    'Courier',
    'serif',
    'sans-serif',
    'monospace',
  ];
  
  // Patrones de fondo abstractos
  final List<Map<String, dynamic>> _backgroundPatterns = [
    {'name': 'Ninguno', 'type': 'none'},
    {'name': 'Puntos', 'type': 'dots', 'color': '#E0E0E0'},
    {'name': 'Líneas', 'type': 'lines', 'color': '#E0E0E0'},
    {'name': 'Geometría', 'type': 'geometry', 'color': '#F0F0F0'},
    {'name': 'Ondas', 'type': 'waves', 'color': '#E8E8E8'},
    {'name': 'Hexágonos', 'type': 'hexagons', 'color': '#F5F5F5'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeTemplate();
  }

  void _initializeTemplate() {
    if (widget.template != null) {
      _currentTemplate = widget.template!;
      _nameController.text = _currentTemplate.name;
      _descriptionController.text = _currentTemplate.description;
    } else {
      _nameController.text = '';
      _descriptionController.text = '';
    }

    _currentDesign = widget.template?.design ?? TemplateDesign();
    _currentLayout = widget.template?.layout ?? TemplateLayout();
    
    // Inicializar textos con valores por defecto
    _titleController.text = 'CERTIFICADO';
    _subtitleController.text = 'DE GRADUACIÓN';
    _descriptionTextController.text = 'Por haber completado exitosamente el programa académico';
    _issuerTitleController.text = 'Emisor Autorizado';
  }

  // Helper function to create TemplateDesign with updated values
  TemplateDesign _updateDesign({
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? textColor,
    String? headerBackgroundColor,
    String? headerTextColor,
    String? borderColor,
    double? borderWidth,
    double? borderRadius,
    String? fontFamily,
    double? titleFontSize,
    double? subtitleFontSize,
    double? bodyFontSize,
    double? smallFontSize,
    String? logoUrl,
    String? backgroundImageUrl,
    double? backgroundOpacity,
    String? titleFontFamily,
    String? subtitleFontFamily,
    String? bodyFontFamily,
    String? smallFontFamily,
    String? institutionLogoUrl,
    String? certificateBackgroundUrl,
    double? logoOpacity,
    String? logoPosition,
    String? issuerSignatureLabel,
    String? issuerTitleLabel,
    String? dateLabel,
    String? issuerName,
  }) {
    return TemplateDesign(
      primaryColor: primaryColor ?? _currentDesign.primaryColor,
      secondaryColor: secondaryColor ?? _currentDesign.secondaryColor,
      backgroundColor: backgroundColor ?? _currentDesign.backgroundColor,
      textColor: textColor ?? _currentDesign.textColor,
      headerBackgroundColor: headerBackgroundColor ?? _currentDesign.headerBackgroundColor,
      headerTextColor: headerTextColor ?? _currentDesign.headerTextColor,
      borderColor: borderColor ?? _currentDesign.borderColor,
      borderWidth: borderWidth ?? _currentDesign.borderWidth,
      borderRadius: borderRadius ?? _currentDesign.borderRadius,
      fontFamily: fontFamily ?? _currentDesign.fontFamily,
      titleFontSize: titleFontSize ?? _currentDesign.titleFontSize,
      subtitleFontSize: subtitleFontSize ?? _currentDesign.subtitleFontSize,
      bodyFontSize: bodyFontSize ?? _currentDesign.bodyFontSize,
      smallFontSize: smallFontSize ?? _currentDesign.smallFontSize,
      logoUrl: logoUrl ?? _currentDesign.logoUrl,
      backgroundImageUrl: backgroundImageUrl ?? _currentDesign.backgroundImageUrl,
      backgroundOpacity: backgroundOpacity ?? _currentDesign.backgroundOpacity,
      titleFontFamily: titleFontFamily ?? _currentDesign.titleFontFamily,
      subtitleFontFamily: subtitleFontFamily ?? _currentDesign.subtitleFontFamily,
      bodyFontFamily: bodyFontFamily ?? _currentDesign.bodyFontFamily,
      smallFontFamily: smallFontFamily ?? _currentDesign.smallFontFamily,
      institutionLogoUrl: institutionLogoUrl ?? _currentDesign.institutionLogoUrl,
      certificateBackgroundUrl: certificateBackgroundUrl ?? _currentDesign.certificateBackgroundUrl,
      logoOpacity: logoOpacity ?? _currentDesign.logoOpacity,
      logoPosition: logoPosition ?? _currentDesign.logoPosition,
      issuerSignatureLabel: issuerSignatureLabel ?? _currentDesign.issuerSignatureLabel,
      issuerTitleLabel: issuerTitleLabel ?? _currentDesign.issuerTitleLabel,
      dateLabel: dateLabel ?? _currentDesign.dateLabel,
      issuerName: issuerName ?? _currentDesign.issuerName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionTextController.dispose();
    _issuerTitleController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Crear campos con los textos personalizados
      final fields = _createTemplateFields();

      if (widget.template != null) {
        // Actualizar plantilla existente
        final updatedTemplate = _currentTemplate.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          design: _currentDesign,
          layout: _currentLayout,
          fields: fields,
          updatedAt: DateTime.now(),
        );

        await CertificateTemplateService.updateTemplate(
          _currentTemplate.id,
          updatedTemplate,
        );
      } else {
        // Crear nueva plantilla
        await CertificateTemplateService.createTemplate(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          design: _currentDesign,
          layout: _currentLayout,
          fields: fields,
        );
      }

      AlertService.showSuccess(context, 'Éxito', widget.template != null ? 'Plantilla actualizada' : 'Plantilla creada');

      Navigator.pop(context, true);
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error guardando plantilla: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  List<TemplateField> _createTemplateFields() {
    return [
      // Título principal
      TemplateField(
        id: 'main_title',
        type: 'text',
        label: 'Título Principal',
        value: _titleController.text,
        position: FieldPosition(x: 0, y: 50, width: 800, height: 60, alignment: 'center'),
        style: FieldStyle(
          fontSize: _currentDesign.titleFontSize,
          fontWeight: 'bold',
          color: _currentDesign.primaryColor,
          textAlign: 'center',
          isBold: true,
        ),
        order: 1,
      ),
      // Subtítulo
      TemplateField(
        id: 'subtitle',
        type: 'text',
        label: 'Subtítulo',
        value: _subtitleController.text,
        position: FieldPosition(x: 0, y: 120, width: 800, height: 40, alignment: 'center'),
        style: FieldStyle(
          fontSize: _currentDesign.subtitleFontSize,
          fontWeight: 'normal',
          color: _currentDesign.textColor,
          textAlign: 'center',
        ),
        order: 2,
      ),
      // Nombre del estudiante (campo dinámico - no editable)
      TemplateField(
        id: 'student_name',
        type: 'text',
        label: 'Nombre del Estudiante',
        value: '{{studentName}}', // Valor fijo - se llena automáticamente
        position: FieldPosition(x: 0, y: 200, width: 800, height: 80, alignment: 'center'),
        style: FieldStyle(
          fontSize: _currentDesign.subtitleFontSize + 8,
          fontWeight: 'bold',
          color: _currentDesign.textColor,
          textAlign: 'center',
          isBold: true,
        ),
        order: 3,
      ),
      // Descripción
      TemplateField(
        id: 'description',
        type: 'text',
        label: 'Descripción',
        value: _descriptionTextController.text,
        position: FieldPosition(x: 50, y: 300, width: 700, height: 100, alignment: 'center'),
        style: FieldStyle(
          fontSize: _currentDesign.bodyFontSize,
          fontWeight: 'normal',
          color: _currentDesign.textColor,
          textAlign: 'center',
        ),
        order: 4,
      ),
      // Firma del emisor (campo dinámico - no editable)
      TemplateField(
        id: 'issuer_signature',
        type: 'signature',
        label: 'Firma del Emisor',
        value: '{{issuedByName}}', // Valor fijo - se llena automáticamente
        position: FieldPosition(x: 100, y: 450, width: 200, height: 50, alignment: 'left'),
        style: FieldStyle(
          fontSize: _currentDesign.smallFontSize + 2,
          fontWeight: 'normal',
          color: _currentDesign.textColor,
          textAlign: 'left',
        ),
        order: 5,
      ),
      // Título del emisor (editable)
      TemplateField(
        id: 'issuer_title',
        type: 'text',
        label: 'Título del Emisor',
        value: _issuerTitleController.text,
        position: FieldPosition(x: 100, y: 480, width: 200, height: 30, alignment: 'left'),
        style: FieldStyle(
          fontSize: _currentDesign.smallFontSize,
          fontWeight: 'normal',
          color: _currentDesign.textColor,
          textAlign: 'left',
        ),
        order: 6,
      ),
      // Fecha
      TemplateField(
        id: 'issue_date',
        type: 'date',
        label: 'Fecha de Emisión',
        value: '{{issuedAt}}',
        position: FieldPosition(x: 500, y: 450, width: 200, height: 30, alignment: 'right'),
        style: FieldStyle(
          fontSize: _currentDesign.smallFontSize,
          fontWeight: 'normal',
          color: _currentDesign.textColor,
          textAlign: 'right',
        ),
        order: 7,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Editar Plantilla' : 'Nueva Plantilla'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showPreview = !_showPreview),
            tooltip: _showPreview ? 'Ocultar Vista Previa' : 'Mostrar Vista Previa',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveTemplate,
            tooltip: 'Guardar Plantilla',
          ),
        ],
      ),
      body: _showPreview
          ? Row(
              children: [
                // Panel de edición
                Expanded(
                  flex: 1,
                  child: _buildEditorPanel(),
                ),
                // Vista previa
                Expanded(
                  flex: 1,
                  child: _buildPreviewPanel(),
                ),
              ],
            )
          : _buildEditorPanel(),
    );
  }

  Widget _buildEditorPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica
            _buildBasicInfoSection(),
            SizedBox(height: 24),
            
            // Textos del certificado
            _buildTextsSection(),
            SizedBox(height: 24),
            
            // Diseño
            _buildDesignSection(),
            SizedBox(height: 24),
            
            // Layout
            _buildLayoutSection(),
            SizedBox(height: 24),
            
            // Controles avanzados
            _buildAdvancedControlsSection(),
            SizedBox(height: 24),
            
            // Controles de imágenes
            _buildImageControlsSection(),
            SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Plantilla',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Ingresa un nombre' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Textos del Certificado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Información sobre campos dinámicos
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los campos de estudiante, emisor y fecha se llenan automáticamente al emitir el certificado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título Principal',
                border: OutlineInputBorder(),
                hintText: 'Ej: CERTIFICADO',
              ),
              onChanged: (value) => setState(() {}), // Actualizar vista previa
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _subtitleController,
              decoration: InputDecoration(
                labelText: 'Subtítulo',
                border: OutlineInputBorder(),
                hintText: 'Ej: DE GRADUACIÓN',
              ),
              onChanged: (value) => setState(() {}), // Actualizar vista previa
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionTextController,
              decoration: InputDecoration(
                labelText: 'Descripción del Certificado',
                border: OutlineInputBorder(),
                hintText: 'Ej: Por haber completado exitosamente...',
              ),
              maxLines: 3,
              onChanged: (value) => setState(() {}), // Actualizar vista previa
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _issuerTitleController,
              decoration: InputDecoration(
                labelText: 'Título del Emisor',
                border: OutlineInputBorder(),
                hintText: 'Ej: Emisor Autorizado',
              ),
              onChanged: (value) => setState(() {}), // Actualizar vista previa
            ),
            SizedBox(height: 16),
            
            // Campos dinámicos (solo informativos)
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
                  Text(
                    'Campos que se llenan automáticamente:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• Nombre del Estudiante: {{studentName}}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('• Nombre del Emisor: {{issuedByName}}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('• Fecha de Emisión: {{issuedAt}}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diseño',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Controles de fuentes individuales
            _buildIndividualFontControls(),
            SizedBox(height: 16),
            
            // Colores con selector visual
            _buildColorPicker('Color Primario', _currentDesign.primaryColor, (color) {
              setState(() {
                _currentDesign = _updateDesign(primaryColor: color);
              });
            }),
            
            _buildColorPicker('Color Secundario', _currentDesign.secondaryColor, (color) {
              setState(() {
                _currentDesign = _updateDesign(secondaryColor: color);
              });
            }),
            
            _buildColorPicker('Color de Fondo', _currentDesign.backgroundColor, (color) {
              setState(() {
                _currentDesign = TemplateDesign(
                  primaryColor: _currentDesign.primaryColor,
                  secondaryColor: _currentDesign.secondaryColor,
                  backgroundColor: color,
                  textColor: _currentDesign.textColor,
                  headerBackgroundColor: _currentDesign.headerBackgroundColor,
                  headerTextColor: _currentDesign.headerTextColor,
                  borderColor: _currentDesign.borderColor,
                  borderWidth: _currentDesign.borderWidth,
                  borderRadius: _currentDesign.borderRadius,
                  fontFamily: _currentDesign.fontFamily,
                  titleFontSize: _currentDesign.titleFontSize,
                  subtitleFontSize: _currentDesign.subtitleFontSize,
                  bodyFontSize: _currentDesign.bodyFontSize,
                  smallFontSize: _currentDesign.smallFontSize,
                  logoUrl: _currentDesign.logoUrl,
                  backgroundImageUrl: _currentDesign.backgroundImageUrl,
                  backgroundOpacity: _currentDesign.backgroundOpacity,
                );
              });
            }),
            
            _buildColorPicker('Color del Texto', _currentDesign.textColor, (color) {
              setState(() {
                _currentDesign = TemplateDesign(
                  primaryColor: _currentDesign.primaryColor,
                  secondaryColor: _currentDesign.secondaryColor,
                  backgroundColor: _currentDesign.backgroundColor,
                  textColor: color,
                  headerBackgroundColor: _currentDesign.headerBackgroundColor,
                  headerTextColor: _currentDesign.headerTextColor,
                  borderColor: _currentDesign.borderColor,
                  borderWidth: _currentDesign.borderWidth,
                  borderRadius: _currentDesign.borderRadius,
                  fontFamily: _currentDesign.fontFamily,
                  titleFontSize: _currentDesign.titleFontSize,
                  subtitleFontSize: _currentDesign.subtitleFontSize,
                  bodyFontSize: _currentDesign.bodyFontSize,
                  smallFontSize: _currentDesign.smallFontSize,
                  logoUrl: _currentDesign.logoUrl,
                  backgroundImageUrl: _currentDesign.backgroundImageUrl,
                  backgroundOpacity: _currentDesign.backgroundOpacity,
                );
              });
            }),
            
            SizedBox(height: 16),
            
            // Tamaños de fuente
            _buildFontSizeSlider('Título Principal', _currentDesign.titleFontSize, (size) {
              setState(() {
                _currentDesign = TemplateDesign(
                  primaryColor: _currentDesign.primaryColor,
                  secondaryColor: _currentDesign.secondaryColor,
                  backgroundColor: _currentDesign.backgroundColor,
                  textColor: _currentDesign.textColor,
                  headerBackgroundColor: _currentDesign.headerBackgroundColor,
                  headerTextColor: _currentDesign.headerTextColor,
                  borderColor: _currentDesign.borderColor,
                  borderWidth: _currentDesign.borderWidth,
                  borderRadius: _currentDesign.borderRadius,
                  fontFamily: _currentDesign.fontFamily,
                  titleFontSize: size,
                  subtitleFontSize: _currentDesign.subtitleFontSize,
                  bodyFontSize: _currentDesign.bodyFontSize,
                  smallFontSize: _currentDesign.smallFontSize,
                  logoUrl: _currentDesign.logoUrl,
                  backgroundImageUrl: _currentDesign.backgroundImageUrl,
                  backgroundOpacity: _currentDesign.backgroundOpacity,
                );
              });
            }),
            
            _buildFontSizeSlider('Subtítulo', _currentDesign.subtitleFontSize, (size) {
              setState(() {
                _currentDesign = TemplateDesign(
                  primaryColor: _currentDesign.primaryColor,
                  secondaryColor: _currentDesign.secondaryColor,
                  backgroundColor: _currentDesign.backgroundColor,
                  textColor: _currentDesign.textColor,
                  headerBackgroundColor: _currentDesign.headerBackgroundColor,
                  headerTextColor: _currentDesign.headerTextColor,
                  borderColor: _currentDesign.borderColor,
                  borderWidth: _currentDesign.borderWidth,
                  borderRadius: _currentDesign.borderRadius,
                  fontFamily: _currentDesign.fontFamily,
                  titleFontSize: _currentDesign.titleFontSize,
                  subtitleFontSize: size,
                  bodyFontSize: _currentDesign.bodyFontSize,
                  smallFontSize: _currentDesign.smallFontSize,
                  logoUrl: _currentDesign.logoUrl,
                  backgroundImageUrl: _currentDesign.backgroundImageUrl,
                  backgroundOpacity: _currentDesign.backgroundOpacity,
                );
              });
            }),
            
            _buildFontSizeSlider('Texto del Cuerpo', _currentDesign.bodyFontSize, (size) {
              setState(() {
                _currentDesign = TemplateDesign(
                  primaryColor: _currentDesign.primaryColor,
                  secondaryColor: _currentDesign.secondaryColor,
                  backgroundColor: _currentDesign.backgroundColor,
                  textColor: _currentDesign.textColor,
                  headerBackgroundColor: _currentDesign.headerBackgroundColor,
                  headerTextColor: _currentDesign.headerTextColor,
                  borderColor: _currentDesign.borderColor,
                  borderWidth: _currentDesign.borderWidth,
                  borderRadius: _currentDesign.borderRadius,
                  fontFamily: _currentDesign.fontFamily,
                  titleFontSize: _currentDesign.titleFontSize,
                  subtitleFontSize: _currentDesign.subtitleFontSize,
                  bodyFontSize: size,
                  smallFontSize: _currentDesign.smallFontSize,
                  logoUrl: _currentDesign.logoUrl,
                  backgroundImageUrl: _currentDesign.backgroundImageUrl,
                  backgroundOpacity: _currentDesign.backgroundOpacity,
                  titleFontFamily: _currentDesign.titleFontFamily,
                  subtitleFontFamily: _currentDesign.subtitleFontFamily,
                  bodyFontFamily: _currentDesign.bodyFontFamily,
                  smallFontFamily: _currentDesign.smallFontFamily,
                  institutionLogoUrl: _currentDesign.institutionLogoUrl,
                  certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
                  logoOpacity: _currentDesign.logoOpacity,
                  logoPosition: _currentDesign.logoPosition,
                  issuerSignatureLabel: _currentDesign.issuerSignatureLabel,
                  issuerTitleLabel: _currentDesign.issuerTitleLabel,
                  dateLabel: _currentDesign.dateLabel,
                );
              });
            }),
            
            SizedBox(height: 16),
            
            // Sección de firmas
            _buildSignatureSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Textos de Firmas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        
        // Texto de firma del emisor
        TextFormField(
          initialValue: _currentDesign.issuerSignatureLabel,
          decoration: InputDecoration(
            labelText: 'Texto de Firma del Emisor',
            hintText: 'Ej: Firma del Emisor, Director Académico',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              _currentDesign = TemplateDesign(
                primaryColor: _currentDesign.primaryColor,
                secondaryColor: _currentDesign.secondaryColor,
                backgroundColor: _currentDesign.backgroundColor,
                textColor: _currentDesign.textColor,
                headerBackgroundColor: _currentDesign.headerBackgroundColor,
                headerTextColor: _currentDesign.headerTextColor,
                borderColor: _currentDesign.borderColor,
                borderWidth: _currentDesign.borderWidth,
                borderRadius: _currentDesign.borderRadius,
                fontFamily: _currentDesign.fontFamily,
                titleFontSize: _currentDesign.titleFontSize,
                subtitleFontSize: _currentDesign.subtitleFontSize,
                bodyFontSize: _currentDesign.bodyFontSize,
                smallFontSize: _currentDesign.smallFontSize,
                logoUrl: _currentDesign.logoUrl,
                backgroundImageUrl: _currentDesign.backgroundImageUrl,
                backgroundOpacity: _currentDesign.backgroundOpacity,
                titleFontFamily: _currentDesign.titleFontFamily,
                subtitleFontFamily: _currentDesign.subtitleFontFamily,
                bodyFontFamily: _currentDesign.bodyFontFamily,
                smallFontFamily: _currentDesign.smallFontFamily,
                institutionLogoUrl: _currentDesign.institutionLogoUrl,
                certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
                logoOpacity: _currentDesign.logoOpacity,
                logoPosition: _currentDesign.logoPosition,
                issuerSignatureLabel: value,
                issuerTitleLabel: _currentDesign.issuerTitleLabel,
                dateLabel: _currentDesign.dateLabel,
              );
            });
          },
        ),
        
        SizedBox(height: 12),
        
        // Texto del título del emisor
        TextFormField(
          initialValue: _currentDesign.issuerTitleLabel,
          decoration: InputDecoration(
            labelText: 'Título del Emisor',
            hintText: 'Ej: Director, Rector, Decano',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              _currentDesign = TemplateDesign(
                primaryColor: _currentDesign.primaryColor,
                secondaryColor: _currentDesign.secondaryColor,
                backgroundColor: _currentDesign.backgroundColor,
                textColor: _currentDesign.textColor,
                headerBackgroundColor: _currentDesign.headerBackgroundColor,
                headerTextColor: _currentDesign.headerTextColor,
                borderColor: _currentDesign.borderColor,
                borderWidth: _currentDesign.borderWidth,
                borderRadius: _currentDesign.borderRadius,
                fontFamily: _currentDesign.fontFamily,
                titleFontSize: _currentDesign.titleFontSize,
                subtitleFontSize: _currentDesign.subtitleFontSize,
                bodyFontSize: _currentDesign.bodyFontSize,
                smallFontSize: _currentDesign.smallFontSize,
                logoUrl: _currentDesign.logoUrl,
                backgroundImageUrl: _currentDesign.backgroundImageUrl,
                backgroundOpacity: _currentDesign.backgroundOpacity,
                titleFontFamily: _currentDesign.titleFontFamily,
                subtitleFontFamily: _currentDesign.subtitleFontFamily,
                bodyFontFamily: _currentDesign.bodyFontFamily,
                smallFontFamily: _currentDesign.smallFontFamily,
                institutionLogoUrl: _currentDesign.institutionLogoUrl,
                certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
                logoOpacity: _currentDesign.logoOpacity,
                logoPosition: _currentDesign.logoPosition,
                issuerSignatureLabel: _currentDesign.issuerSignatureLabel,
                issuerTitleLabel: value,
                dateLabel: _currentDesign.dateLabel,
              );
            });
          },
        ),
        
        SizedBox(height: 12),
        
        // Texto de la fecha
        TextFormField(
          initialValue: _currentDesign.dateLabel,
          decoration: InputDecoration(
            labelText: 'Texto de la Fecha',
            hintText: 'Ej: Fecha, Fecha de Emisión',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              _currentDesign = TemplateDesign(
                primaryColor: _currentDesign.primaryColor,
                secondaryColor: _currentDesign.secondaryColor,
                backgroundColor: _currentDesign.backgroundColor,
                textColor: _currentDesign.textColor,
                headerBackgroundColor: _currentDesign.headerBackgroundColor,
                headerTextColor: _currentDesign.headerTextColor,
                borderColor: _currentDesign.borderColor,
                borderWidth: _currentDesign.borderWidth,
                borderRadius: _currentDesign.borderRadius,
                fontFamily: _currentDesign.fontFamily,
                titleFontSize: _currentDesign.titleFontSize,
                subtitleFontSize: _currentDesign.subtitleFontSize,
                bodyFontSize: _currentDesign.bodyFontSize,
                smallFontSize: _currentDesign.smallFontSize,
                logoUrl: _currentDesign.logoUrl,
                backgroundImageUrl: _currentDesign.backgroundImageUrl,
                backgroundOpacity: _currentDesign.backgroundOpacity,
                titleFontFamily: _currentDesign.titleFontFamily,
                subtitleFontFamily: _currentDesign.subtitleFontFamily,
                bodyFontFamily: _currentDesign.bodyFontFamily,
                smallFontFamily: _currentDesign.smallFontFamily,
                institutionLogoUrl: _currentDesign.institutionLogoUrl,
                certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
                logoOpacity: _currentDesign.logoOpacity,
                logoPosition: _currentDesign.logoPosition,
                issuerSignatureLabel: _currentDesign.issuerSignatureLabel,
                issuerTitleLabel: _currentDesign.issuerTitleLabel,
                dateLabel: value,
                issuerName: _currentDesign.issuerName,
              );
            });
          },
        ),
        
        SizedBox(height: 12),
        
        // Nombre del emisor
        TextFormField(
          initialValue: _currentDesign.issuerName,
          decoration: InputDecoration(
            labelText: 'Nombre del Emisor',
            hintText: 'Ej: Dr. María González, Lic. Juan Pérez',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              _currentDesign = TemplateDesign(
                primaryColor: _currentDesign.primaryColor,
                secondaryColor: _currentDesign.secondaryColor,
                backgroundColor: _currentDesign.backgroundColor,
                textColor: _currentDesign.textColor,
                headerBackgroundColor: _currentDesign.headerBackgroundColor,
                headerTextColor: _currentDesign.headerTextColor,
                borderColor: _currentDesign.borderColor,
                borderWidth: _currentDesign.borderWidth,
                borderRadius: _currentDesign.borderRadius,
                fontFamily: _currentDesign.fontFamily,
                titleFontSize: _currentDesign.titleFontSize,
                subtitleFontSize: _currentDesign.subtitleFontSize,
                bodyFontSize: _currentDesign.bodyFontSize,
                smallFontSize: _currentDesign.smallFontSize,
                logoUrl: _currentDesign.logoUrl,
                backgroundImageUrl: _currentDesign.backgroundImageUrl,
                backgroundOpacity: _currentDesign.backgroundOpacity,
                titleFontFamily: _currentDesign.titleFontFamily,
                subtitleFontFamily: _currentDesign.subtitleFontFamily,
                bodyFontFamily: _currentDesign.bodyFontFamily,
                smallFontFamily: _currentDesign.smallFontFamily,
                institutionLogoUrl: _currentDesign.institutionLogoUrl,
                certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
                logoOpacity: _currentDesign.logoOpacity,
                logoPosition: _currentDesign.logoPosition,
                issuerSignatureLabel: _currentDesign.issuerSignatureLabel,
                issuerTitleLabel: _currentDesign.issuerTitleLabel,
                dateLabel: _currentDesign.dateLabel,
                issuerName: value,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildLayoutSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Orientación
            Row(
              children: [
                Text('Orientación: '),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Vertical'),
                    value: 'portrait',
                    groupValue: _currentLayout.orientation,
                    onChanged: (value) {
                      setState(() {
                        _currentLayout = TemplateLayout(
                          orientation: value!,
                          width: _currentLayout.width,
                          height: _currentLayout.height,
                          padding: _currentLayout.padding,
                          margin: _currentLayout.margin,
                          alignment: _currentLayout.alignment,
                          showHeader: _currentLayout.showHeader,
                          showFooter: _currentLayout.showFooter,
                          showBorder: _currentLayout.showBorder,
                          showBackground: _currentLayout.showBackground,
                          backgroundPattern: _currentLayout.backgroundPattern,
                          patternColor: _currentLayout.patternColor,
                          patternOpacity: _currentLayout.patternOpacity,
                          showShadow: _currentLayout.showShadow,
                          shadowBlur: _currentLayout.shadowBlur,
                          shadowOffset: _currentLayout.shadowOffset,
                          shadowColor: _currentLayout.shadowColor,
                        );
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Horizontal'),
                    value: 'landscape',
                    groupValue: _currentLayout.orientation,
                    onChanged: (value) {
                      setState(() {
                        _currentLayout = TemplateLayout(
                          orientation: value!,
                          width: _currentLayout.width,
                          height: _currentLayout.height,
                          padding: _currentLayout.padding,
                          margin: _currentLayout.margin,
                          alignment: _currentLayout.alignment,
                          showHeader: _currentLayout.showHeader,
                          showFooter: _currentLayout.showFooter,
                          showBorder: _currentLayout.showBorder,
                          showBackground: _currentLayout.showBackground,
                          backgroundPattern: _currentLayout.backgroundPattern,
                          patternColor: _currentLayout.patternColor,
                          patternOpacity: _currentLayout.patternOpacity,
                          showShadow: _currentLayout.showShadow,
                          shadowBlur: _currentLayout.shadowBlur,
                          shadowOffset: _currentLayout.shadowOffset,
                          shadowColor: _currentLayout.shadowColor,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
            
            // Opciones de visualización
            CheckboxListTile(
              title: Text('Mostrar Header'),
              value: _currentLayout.showHeader,
              onChanged: (value) {
                setState(() {
                  _currentLayout = TemplateLayout(
                    orientation: _currentLayout.orientation,
                    width: _currentLayout.width,
                    height: _currentLayout.height,
                    padding: _currentLayout.padding,
                    margin: _currentLayout.margin,
                    alignment: _currentLayout.alignment,
                    showHeader: value!,
                    showFooter: _currentLayout.showFooter,
                    showBorder: _currentLayout.showBorder,
                    showBackground: _currentLayout.showBackground,
                    backgroundPattern: _currentLayout.backgroundPattern,
                    patternColor: _currentLayout.patternColor,
                    patternOpacity: _currentLayout.patternOpacity,
                    showShadow: _currentLayout.showShadow,
                    shadowBlur: _currentLayout.shadowBlur,
                    shadowOffset: _currentLayout.shadowOffset,
                    shadowColor: _currentLayout.shadowColor,
                  );
                });
              },
            ),
            
            CheckboxListTile(
              title: Text('Mostrar Footer'),
              value: _currentLayout.showFooter,
              onChanged: (value) {
                setState(() {
                  _currentLayout = TemplateLayout(
                    orientation: _currentLayout.orientation,
                    width: _currentLayout.width,
                    height: _currentLayout.height,
                    padding: _currentLayout.padding,
                    margin: _currentLayout.margin,
                    alignment: _currentLayout.alignment,
                    showHeader: _currentLayout.showHeader,
                    showFooter: value!,
                    showBorder: _currentLayout.showBorder,
                    showBackground: _currentLayout.showBackground,
                    backgroundPattern: _currentLayout.backgroundPattern,
                    patternColor: _currentLayout.patternColor,
                    patternOpacity: _currentLayout.patternOpacity,
                    showShadow: _currentLayout.showShadow,
                    shadowBlur: _currentLayout.shadowBlur,
                    shadowOffset: _currentLayout.shadowOffset,
                    shadowColor: _currentLayout.shadowColor,
                  );
                });
              },
            ),
            
            CheckboxListTile(
              title: Text('Mostrar Borde'),
              value: _currentLayout.showBorder,
              onChanged: (value) {
                setState(() {
                  _currentLayout = TemplateLayout(
                    orientation: _currentLayout.orientation,
                    width: _currentLayout.width,
                    height: _currentLayout.height,
                    padding: _currentLayout.padding,
                    margin: _currentLayout.margin,
                    alignment: _currentLayout.alignment,
                    showHeader: _currentLayout.showHeader,
                    showFooter: _currentLayout.showFooter,
                    showBorder: value!,
                    showBackground: _currentLayout.showBackground,
                    backgroundPattern: _currentLayout.backgroundPattern,
                    patternColor: _currentLayout.patternColor,
                    patternOpacity: _currentLayout.patternOpacity,
                    showShadow: _currentLayout.showShadow,
                    shadowBlur: _currentLayout.shadowBlur,
                    shadowOffset: _currentLayout.shadowOffset,
                    shadowColor: _currentLayout.shadowColor,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualFontControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuentes por Elemento',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),
        
        // Fuente del título
        _buildFontSelector('Título Principal', _currentDesign.titleFontFamily, (font) {
          setState(() {
            _currentDesign = TemplateDesign(
              primaryColor: _currentDesign.primaryColor,
              secondaryColor: _currentDesign.secondaryColor,
              backgroundColor: _currentDesign.backgroundColor,
              textColor: _currentDesign.textColor,
              headerBackgroundColor: _currentDesign.headerBackgroundColor,
              headerTextColor: _currentDesign.headerTextColor,
              borderColor: _currentDesign.borderColor,
              borderWidth: _currentDesign.borderWidth,
              borderRadius: _currentDesign.borderRadius,
              fontFamily: _currentDesign.fontFamily,
              titleFontSize: _currentDesign.titleFontSize,
              subtitleFontSize: _currentDesign.subtitleFontSize,
              bodyFontSize: _currentDesign.bodyFontSize,
              smallFontSize: _currentDesign.smallFontSize,
              logoUrl: _currentDesign.logoUrl,
              backgroundImageUrl: _currentDesign.backgroundImageUrl,
              backgroundOpacity: _currentDesign.backgroundOpacity,
              titleFontFamily: font,
              subtitleFontFamily: _currentDesign.subtitleFontFamily,
              bodyFontFamily: _currentDesign.bodyFontFamily,
              smallFontFamily: _currentDesign.smallFontFamily,
              institutionLogoUrl: _currentDesign.institutionLogoUrl,
              certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
              logoOpacity: _currentDesign.logoOpacity,
              logoPosition: _currentDesign.logoPosition,
            );
          });
        }),
        
        // Fuente del subtítulo
        _buildFontSelector('Subtítulo', _currentDesign.subtitleFontFamily, (font) {
          setState(() {
            _currentDesign = TemplateDesign(
              primaryColor: _currentDesign.primaryColor,
              secondaryColor: _currentDesign.secondaryColor,
              backgroundColor: _currentDesign.backgroundColor,
              textColor: _currentDesign.textColor,
              headerBackgroundColor: _currentDesign.headerBackgroundColor,
              headerTextColor: _currentDesign.headerTextColor,
              borderColor: _currentDesign.borderColor,
              borderWidth: _currentDesign.borderWidth,
              borderRadius: _currentDesign.borderRadius,
              fontFamily: _currentDesign.fontFamily,
              titleFontSize: _currentDesign.titleFontSize,
              subtitleFontSize: _currentDesign.subtitleFontSize,
              bodyFontSize: _currentDesign.bodyFontSize,
              smallFontSize: _currentDesign.smallFontSize,
              logoUrl: _currentDesign.logoUrl,
              backgroundImageUrl: _currentDesign.backgroundImageUrl,
              backgroundOpacity: _currentDesign.backgroundOpacity,
              titleFontFamily: _currentDesign.titleFontFamily,
              subtitleFontFamily: font,
              bodyFontFamily: _currentDesign.bodyFontFamily,
              smallFontFamily: _currentDesign.smallFontFamily,
              institutionLogoUrl: _currentDesign.institutionLogoUrl,
              certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
              logoOpacity: _currentDesign.logoOpacity,
              logoPosition: _currentDesign.logoPosition,
            );
          });
        }),
        
        // Fuente del cuerpo
        _buildFontSelector('Descripción', _currentDesign.bodyFontFamily, (font) {
          setState(() {
            _currentDesign = TemplateDesign(
              primaryColor: _currentDesign.primaryColor,
              secondaryColor: _currentDesign.secondaryColor,
              backgroundColor: _currentDesign.backgroundColor,
              textColor: _currentDesign.textColor,
              headerBackgroundColor: _currentDesign.headerBackgroundColor,
              headerTextColor: _currentDesign.headerTextColor,
              borderColor: _currentDesign.borderColor,
              borderWidth: _currentDesign.borderWidth,
              borderRadius: _currentDesign.borderRadius,
              fontFamily: _currentDesign.fontFamily,
              titleFontSize: _currentDesign.titleFontSize,
              subtitleFontSize: _currentDesign.subtitleFontSize,
              bodyFontSize: _currentDesign.bodyFontSize,
              smallFontSize: _currentDesign.smallFontSize,
              logoUrl: _currentDesign.logoUrl,
              backgroundImageUrl: _currentDesign.backgroundImageUrl,
              backgroundOpacity: _currentDesign.backgroundOpacity,
              titleFontFamily: _currentDesign.titleFontFamily,
              subtitleFontFamily: _currentDesign.subtitleFontFamily,
              bodyFontFamily: font,
              smallFontFamily: _currentDesign.smallFontFamily,
              institutionLogoUrl: _currentDesign.institutionLogoUrl,
              certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
              logoOpacity: _currentDesign.logoOpacity,
              logoPosition: _currentDesign.logoPosition,
            );
          });
        }),
        
        // Fuente pequeña
        _buildFontSelector('Texto Pequeño', _currentDesign.smallFontFamily, (font) {
          setState(() {
            _currentDesign = TemplateDesign(
              primaryColor: _currentDesign.primaryColor,
              secondaryColor: _currentDesign.secondaryColor,
              backgroundColor: _currentDesign.backgroundColor,
              textColor: _currentDesign.textColor,
              headerBackgroundColor: _currentDesign.headerBackgroundColor,
              headerTextColor: _currentDesign.headerTextColor,
              borderColor: _currentDesign.borderColor,
              borderWidth: _currentDesign.borderWidth,
              borderRadius: _currentDesign.borderRadius,
              fontFamily: _currentDesign.fontFamily,
              titleFontSize: _currentDesign.titleFontSize,
              subtitleFontSize: _currentDesign.subtitleFontSize,
              bodyFontSize: _currentDesign.bodyFontSize,
              smallFontSize: _currentDesign.smallFontSize,
              logoUrl: _currentDesign.logoUrl,
              backgroundImageUrl: _currentDesign.backgroundImageUrl,
              backgroundOpacity: _currentDesign.backgroundOpacity,
              titleFontFamily: _currentDesign.titleFontFamily,
              subtitleFontFamily: _currentDesign.subtitleFontFamily,
              bodyFontFamily: _currentDesign.bodyFontFamily,
              smallFontFamily: font,
              institutionLogoUrl: _currentDesign.institutionLogoUrl,
              certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
              logoOpacity: _currentDesign.logoOpacity,
              logoPosition: _currentDesign.logoPosition,
            );
          });
        }),
      ],
    );
  }

  Widget _buildFontSelector(String label, String currentFont, Function(String) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: currentFont,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
              items: _availableFonts.map((font) {
                return DropdownMenuItem<String>(
                  value: font,
                  child: Text(
                    font,
                    style: TextStyle(fontFamily: font, fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedControlsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controles Avanzados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Patrones de fondo
            _buildBackgroundPatternSelector(),
            SizedBox(height: 16),
            
            // Controles de márgenes
            _buildMarginControls(),
            SizedBox(height: 16),
            
            // Efectos visuales
            _buildVisualEffectsControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPatternSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patrón de Fondo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _backgroundPatterns.map((pattern) {
            final isSelected = _currentLayout.backgroundPattern == pattern['type'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentLayout = TemplateLayout(
                    orientation: _currentLayout.orientation,
                    width: _currentLayout.width,
                    height: _currentLayout.height,
                    padding: _currentLayout.padding,
                    margin: _currentLayout.margin,
                    alignment: _currentLayout.alignment,
                    showHeader: _currentLayout.showHeader,
                    showFooter: _currentLayout.showFooter,
                    showBorder: _currentLayout.showBorder,
                    showBackground: _currentLayout.showBackground,
                    backgroundPattern: pattern['type'],
                    patternColor: pattern['color'] ?? '#E0E0E0',
                    patternOpacity: _currentLayout.patternOpacity,
                    showShadow: _currentLayout.showShadow,
                    shadowBlur: _currentLayout.shadowBlur,
                    shadowOffset: _currentLayout.shadowOffset,
                    shadowColor: _currentLayout.shadowColor,
                  );
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xff6C4DDC) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Color(0xff6C4DDC) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Text(
                  pattern['name'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMarginControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Márgenes y Espaciado',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        
        // Padding superior
        _buildMarginSlider('Padding Superior', _currentLayout.padding.top, (value) {
          setState(() {
            _currentLayout = TemplateLayout(
              orientation: _currentLayout.orientation,
              width: _currentLayout.width,
              height: _currentLayout.height,
              padding: EdgeInsetsData(
                top: value,
                bottom: _currentLayout.padding.bottom,
                left: _currentLayout.padding.left,
                right: _currentLayout.padding.right,
              ),
              margin: _currentLayout.margin,
              alignment: _currentLayout.alignment,
              showHeader: _currentLayout.showHeader,
              showFooter: _currentLayout.showFooter,
              showBorder: _currentLayout.showBorder,
              showBackground: _currentLayout.showBackground,
              backgroundPattern: _currentLayout.backgroundPattern,
              patternColor: _currentLayout.patternColor,
              patternOpacity: _currentLayout.patternOpacity,
              showShadow: _currentLayout.showShadow,
              shadowBlur: _currentLayout.shadowBlur,
              shadowOffset: _currentLayout.shadowOffset,
              shadowColor: _currentLayout.shadowColor,
            );
          });
        }),
        
        // Padding inferior
        _buildMarginSlider('Padding Inferior', _currentLayout.padding.bottom, (value) {
          setState(() {
            _currentLayout = TemplateLayout(
              orientation: _currentLayout.orientation,
              width: _currentLayout.width,
              height: _currentLayout.height,
              padding: EdgeInsetsData(
                top: _currentLayout.padding.top,
                bottom: value,
                left: _currentLayout.padding.left,
                right: _currentLayout.padding.right,
              ),
              margin: _currentLayout.margin,
              alignment: _currentLayout.alignment,
              showHeader: _currentLayout.showHeader,
              showFooter: _currentLayout.showFooter,
              showBorder: _currentLayout.showBorder,
              showBackground: _currentLayout.showBackground,
              backgroundPattern: _currentLayout.backgroundPattern,
              patternColor: _currentLayout.patternColor,
              patternOpacity: _currentLayout.patternOpacity,
              showShadow: _currentLayout.showShadow,
              shadowBlur: _currentLayout.shadowBlur,
              shadowOffset: _currentLayout.shadowOffset,
              shadowColor: _currentLayout.shadowColor,
            );
          });
        }),
      ],
    );
  }

  Widget _buildVisualEffectsControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Efectos Visuales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        
        // Sombra
        CheckboxListTile(
          title: Text('Mostrar Sombra'),
          value: _currentLayout.showShadow,
          onChanged: (value) {
            setState(() {
              _currentLayout = TemplateLayout(
                orientation: _currentLayout.orientation,
                width: _currentLayout.width,
                height: _currentLayout.height,
                padding: _currentLayout.padding,
                margin: _currentLayout.margin,
                alignment: _currentLayout.alignment,
                showHeader: _currentLayout.showHeader,
                showFooter: _currentLayout.showFooter,
                showBorder: _currentLayout.showBorder,
                showBackground: _currentLayout.showBackground,
                backgroundPattern: _currentLayout.backgroundPattern,
                patternColor: _currentLayout.patternColor,
                patternOpacity: _currentLayout.patternOpacity,
                showShadow: value!,
                shadowBlur: _currentLayout.shadowBlur,
                shadowOffset: _currentLayout.shadowOffset,
                shadowColor: _currentLayout.shadowColor,
              );
            });
          },
        ),
        
        if (_currentLayout.showShadow) ...[
          _buildMarginSlider('Desenfoque de Sombra', _currentLayout.shadowBlur, (value) {
            setState(() {
              _currentLayout = TemplateLayout(
                orientation: _currentLayout.orientation,
                width: _currentLayout.width,
                height: _currentLayout.height,
                padding: _currentLayout.padding,
                margin: _currentLayout.margin,
                alignment: _currentLayout.alignment,
                showHeader: _currentLayout.showHeader,
                showFooter: _currentLayout.showFooter,
                showBorder: _currentLayout.showBorder,
                showBackground: _currentLayout.showBackground,
                backgroundPattern: _currentLayout.backgroundPattern,
                patternColor: _currentLayout.patternColor,
                patternOpacity: _currentLayout.patternOpacity,
                showShadow: _currentLayout.showShadow,
                shadowBlur: value,
                shadowOffset: _currentLayout.shadowOffset,
                shadowColor: _currentLayout.shadowColor,
              );
            });
          }),
        ],
      ],
    );
  }

  Widget _buildMarginSlider(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${value.round()}px'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageControlsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imágenes y Logos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Logo de la institución
            _buildImageUploader(
              'Logo de la Institución',
              _currentDesign.institutionLogoUrl,
              (url) {
                setState(() {
                  _currentDesign = TemplateDesign(
                    primaryColor: _currentDesign.primaryColor,
                    secondaryColor: _currentDesign.secondaryColor,
                    backgroundColor: _currentDesign.backgroundColor,
                    textColor: _currentDesign.textColor,
                    headerBackgroundColor: _currentDesign.headerBackgroundColor,
                    headerTextColor: _currentDesign.headerTextColor,
                    borderColor: _currentDesign.borderColor,
                    borderWidth: _currentDesign.borderWidth,
                    borderRadius: _currentDesign.borderRadius,
                    fontFamily: _currentDesign.fontFamily,
                    titleFontSize: _currentDesign.titleFontSize,
                    subtitleFontSize: _currentDesign.subtitleFontSize,
                    bodyFontSize: _currentDesign.bodyFontSize,
                    smallFontSize: _currentDesign.smallFontSize,
                    logoUrl: _currentDesign.logoUrl,
                    backgroundImageUrl: _currentDesign.backgroundImageUrl,
                    backgroundOpacity: _currentDesign.backgroundOpacity,
                    titleFontFamily: _currentDesign.titleFontFamily,
                    subtitleFontFamily: _currentDesign.subtitleFontFamily,
                    bodyFontFamily: _currentDesign.bodyFontFamily,
                    smallFontFamily: _currentDesign.smallFontFamily,
                    institutionLogoUrl: url,
                    certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
                    logoOpacity: _currentDesign.logoOpacity,
                    logoPosition: _currentDesign.logoPosition,
                  );
                });
              },
              isLogo: true,
            ),
            
            SizedBox(height: 16),
            
            // Opacidad del logo
            _buildLogoOpacitySlider(),
            
            SizedBox(height: 16),
            
            // Tamaño del logo
            _buildLogoSizeSlider(),
            
            SizedBox(height: 16),
            
            // Imagen de fondo del certificado
            _buildImageUploader(
              'Imagen de Fondo',
              _currentDesign.certificateBackgroundUrl,
              (url) {
                setState(() {
                  _currentDesign = TemplateDesign(
                    primaryColor: _currentDesign.primaryColor,
                    secondaryColor: _currentDesign.secondaryColor,
                    backgroundColor: _currentDesign.backgroundColor,
                    textColor: _currentDesign.textColor,
                    headerBackgroundColor: _currentDesign.headerBackgroundColor,
                    headerTextColor: _currentDesign.headerTextColor,
                    borderColor: _currentDesign.borderColor,
                    borderWidth: _currentDesign.borderWidth,
                    borderRadius: _currentDesign.borderRadius,
                    fontFamily: _currentDesign.fontFamily,
                    titleFontSize: _currentDesign.titleFontSize,
                    subtitleFontSize: _currentDesign.subtitleFontSize,
                    bodyFontSize: _currentDesign.bodyFontSize,
                    smallFontSize: _currentDesign.smallFontSize,
                    logoUrl: _currentDesign.logoUrl,
                    backgroundImageUrl: _currentDesign.backgroundImageUrl,
                    backgroundOpacity: _currentDesign.backgroundOpacity,
                    titleFontFamily: _currentDesign.titleFontFamily,
                    subtitleFontFamily: _currentDesign.subtitleFontFamily,
                    bodyFontFamily: _currentDesign.bodyFontFamily,
                    smallFontFamily: _currentDesign.smallFontFamily,
                    institutionLogoUrl: _currentDesign.institutionLogoUrl,
                    certificateBackgroundUrl: url,
                    logoOpacity: _currentDesign.logoOpacity,
                    logoPosition: _currentDesign.logoPosition,
                  );
                });
              },
              isLogo: false,
            ),
            
            SizedBox(height: 16),
            
            // Opacidad de la imagen de fondo
            _buildBackgroundImageOpacitySlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tamaño del Logo: ${_logoSize.round()}px',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Slider(
          value: _logoSize,
          min: 40.0,
          max: 200.0,
          divisions: 16,
          onChanged: (value) {
            setState(() {
              _logoSize = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundImageOpacitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opacidad de Imagen de Fondo: ${(_backgroundImageOpacity * 100).round()}%',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Slider(
          value: _backgroundImageOpacity,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) {
            setState(() {
              _backgroundImageOpacity = value;
            });
          },
        ),
      ],
    );
  }


  Widget _buildImageUploader(String label, String currentUrl, Function(String) onChanged, {required bool isLogo}) {
    final selectedBytes = isLogo ? _institutionLogoBytes : _backgroundImageBytes;
    final isUploading = isLogo ? _isUploadingLogo : _isUploadingBackground;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : () => _pickImageFromGallery(isLogo),
                icon: isUploading ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : Icon(Icons.photo_library),
                label: Text(isUploading ? 'Subiendo...' : 'Seleccionar Imagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : () => _pickImageFromCamera(isLogo),
                icon: Icon(Icons.camera_alt),
                label: Text('Tomar Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        if (selectedBytes != null || currentUrl.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: selectedBytes != null
                  ? Image.memory(
                      selectedBytes,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      currentUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              Text('Error cargando imagen', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
            ),
          ),
          SizedBox(height: 8),
          // Mostrar botones siempre que haya una imagen (nueva o existente)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedBytes != null ? Colors.orange[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedBytes != null ? Colors.orange[200]! : Colors.blue[200]!,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      selectedBytes != null ? Icons.info : Icons.image,
                      color: selectedBytes != null ? Colors.orange[600] : Colors.blue[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedBytes != null
                            ? (isLogo 
                                ? 'Logo seleccionado. Arrastra en la vista previa para posicionarlo.'
                                : 'Imagen de fondo seleccionada. Arrastra en la vista previa para posicionarla.')
                            : (isLogo 
                                ? 'Logo guardado en la plantilla. Arrastra en la vista previa para posicionarlo.'
                                : 'Imagen de fondo guardada en la plantilla. Arrastra en la vista previa para posicionarla.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedBytes != null ? Colors.orange[700] : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isUploading ? null : () => _uploadImage(isLogo),
                        icon: isUploading ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ) : Icon(Icons.save),
                        label: Text(isUploading ? 'Guardando...' : 'Guardar Permanente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _removeSelectedImage(isLogo),
                        icon: Icon(Icons.delete),
                        label: Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  selectedBytes != null
                      ? (isLogo 
                          ? '💡 El logo ya está visible en la vista previa. "Guardar Permanente" lo guarda en la plantilla.'
                          : '💡 La imagen ya está visible en la vista previa. "Guardar Permanente" la guarda en la plantilla.')
                      : (isLogo 
                          ? '💡 El logo ya está guardado en la plantilla. "Guardar Permanente" lo actualiza.'
                          : '💡 La imagen ya está guardada en la plantilla. "Guardar Permanente" la actualiza.'),
                  style: TextStyle(
                    fontSize: 11,
                    color: selectedBytes != null ? Colors.orange[600] : Colors.blue[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildLogoOpacitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opacidad del Logo: ${(_currentDesign.logoOpacity * 100).round()}%',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Slider(
          value: _currentDesign.logoOpacity,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) {
            setState(() {
              _currentDesign = TemplateDesign(
                primaryColor: _currentDesign.primaryColor,
                secondaryColor: _currentDesign.secondaryColor,
                backgroundColor: _currentDesign.backgroundColor,
                textColor: _currentDesign.textColor,
                headerBackgroundColor: _currentDesign.headerBackgroundColor,
                headerTextColor: _currentDesign.headerTextColor,
                borderColor: _currentDesign.borderColor,
                borderWidth: _currentDesign.borderWidth,
                borderRadius: _currentDesign.borderRadius,
                fontFamily: _currentDesign.fontFamily,
                titleFontSize: _currentDesign.titleFontSize,
                subtitleFontSize: _currentDesign.subtitleFontSize,
                bodyFontSize: _currentDesign.bodyFontSize,
                smallFontSize: _currentDesign.smallFontSize,
                logoUrl: _currentDesign.logoUrl,
                backgroundImageUrl: _currentDesign.backgroundImageUrl,
                backgroundOpacity: _currentDesign.backgroundOpacity,
                titleFontFamily: _currentDesign.titleFontFamily,
                subtitleFontFamily: _currentDesign.subtitleFontFamily,
                bodyFontFamily: _currentDesign.bodyFontFamily,
                smallFontFamily: _currentDesign.smallFontFamily,
                institutionLogoUrl: _currentDesign.institutionLogoUrl,
                certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
                logoOpacity: value,
                logoPosition: _currentDesign.logoPosition,
              );
            });
          },
        ),
      ],
    );
  }


  Widget _buildPreviewPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility),
                SizedBox(width: 8),
                Text('Vista Previa', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: _buildPreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _parseColor(_currentDesign.backgroundColor),
        borderRadius: BorderRadius.circular(_currentDesign.borderRadius),
        border: _currentLayout.showBorder
            ? Border.all(
                color: _parseColor(_currentDesign.borderColor),
                width: _currentDesign.borderWidth,
              )
            : null,
        boxShadow: _currentLayout.showShadow
            ? [
                BoxShadow(
                  color: _parseColor(_currentLayout.shadowColor).withOpacity(0.3),
                  blurRadius: _currentLayout.shadowBlur,
                  offset: Offset(0, _currentLayout.shadowOffset),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Imagen de fondo del certificado
          if (_currentDesign.certificateBackgroundUrl.isNotEmpty || _backgroundImageBytes != null)
            _buildBackgroundImage(),
          
          // Patrón de fondo
          if (_currentLayout.backgroundPattern != 'none')
            _buildBackgroundPattern(),
          
          // Logo de la institución
          _buildInstitutionLogo(),
          
          // Contenido del certificado
          Column(
            children: [
              // Header
              if (_currentLayout.showHeader)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _parseColor(_currentDesign.primaryColor),
                    _parseColor(_currentDesign.secondaryColor),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_currentDesign.borderRadius),
                  topRight: Radius.circular(_currentDesign.borderRadius),
                ),
              ),
              child: Text(
                _titleController.text,
                style: _getTextStyle(
                  _currentDesign.titleFontFamily,
                  _currentDesign.titleFontSize,
                  _parseColor(_currentDesign.headerTextColor),
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
                  _parseColor(_currentDesign.primaryColor),
                  _parseColor(_currentDesign.secondaryColor),
                ],
              ),
            ),
          ),
          
          // Contenido
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                // Subtítulo
                Text(
                  _subtitleController.text,
                  style: _getTextStyle(
                    _currentDesign.subtitleFontFamily,
                    _currentDesign.subtitleFontSize,
                    _parseColor(_currentDesign.textColor),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 40),
                
                // Nombre del estudiante (campo dinámico)
                Text(
                  'Juan Pérez', // Datos de ejemplo para vista previa
                  style: _getTextStyle(
                    _currentDesign.titleFontFamily,
                    _currentDesign.subtitleFontSize + 8,
                    _parseColor(_currentDesign.textColor),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 40),
                
                // Descripción
                Text(
                  _descriptionTextController.text,
                  style: _getTextStyle(
                    _currentDesign.bodyFontFamily,
                    _currentDesign.bodyFontSize,
                    _parseColor(_currentDesign.textColor),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 60),
                
                // Firmas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 200,
                          height: 1,
                          color: _parseColor(_currentDesign.textColor),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _currentDesign.issuerName, // Nombre personalizable del emisor
                          style: _getTextStyle(
                            _currentDesign.smallFontFamily,
                            _currentDesign.smallFontSize + 2,
                            _parseColor(_currentDesign.textColor),
                          ),
                        ),
                        Text(
                          _currentDesign.issuerTitleLabel,
                          style: _getTextStyle(
                            _currentDesign.smallFontFamily,
                            _currentDesign.smallFontSize,
                            _parseColor(_currentDesign.textColor),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_currentDesign.dateLabel}: {{issuedAt}}',
                          style: _getTextStyle(
                            _currentDesign.smallFontFamily,
                            _currentDesign.smallFontSize,
                            _parseColor(_currentDesign.textColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Footer
          if (_currentLayout.showFooter)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_currentDesign.borderRadius),
                  bottomRight: Radius.circular(_currentDesign.borderRadius),
                ),
              ),
              child: Text(
                'Para verificar este certificado, visite: certiblock.com/validate',
                style: _getTextStyle(
                  _currentDesign.smallFontFamily,
                  _currentDesign.smallFontSize,
                  Colors.grey[500]!,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_currentDesign.borderRadius),
        ),
        child: CustomPaint(
          painter: BackgroundPatternPainter(
            patternType: _currentLayout.backgroundPattern,
            color: _parseColor(_currentLayout.patternColor),
            opacity: _currentLayout.patternOpacity,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(String label, String currentColor, Function(String) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text('$label: '),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showColorPicker(label, currentColor, onChanged),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(currentColor),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.color_lens,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: currentColor,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toInt()}px'),
          Slider(
            value: value,
            min: 8,
            max: 72,
            divisions: 64,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Guardar'),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(String title, String currentColor, Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar $title'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _parseColor(currentColor),
            onColorChanged: (color) {
              onChanged('#${color.value.toRadixString(16).substring(2).toUpperCase()}');
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Seleccionar'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
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
      case 'courier new':
        googleFontFamily = 'Source Code Pro';
        break;
      case 'georgia':
        googleFontFamily = 'Merriweather';
        break;
      case 'verdana':
        googleFontFamily = 'Nunito';
        break;
      case 'helvetica':
        googleFontFamily = 'Inter';
        break;
      case 'trebuchet ms':
        googleFontFamily = 'Poppins';
        break;
      case 'comic sans ms':
        googleFontFamily = 'Kalam';
        break;
      case 'impact':
        googleFontFamily = 'Oswald';
        break;
      case 'palatino':
        googleFontFamily = 'Lora';
        break;
      case 'garamond':
        googleFontFamily = 'Crimson Text';
        break;
      case 'bookman':
        googleFontFamily = 'Libre Baskerville';
        break;
      case 'avant garde':
        googleFontFamily = 'Montserrat';
        break;
      case 'century gothic':
        googleFontFamily = 'Raleway';
        break;
      case 'lucida console':
        googleFontFamily = 'Fira Code';
        break;
      case 'monaco':
        googleFontFamily = 'JetBrains Mono';
        break;
      case 'consolas':
        googleFontFamily = 'Inconsolata';
        break;
      case 'courier':
        googleFontFamily = 'Space Mono';
        break;
      case 'serif':
        googleFontFamily = 'Crimson Text';
        break;
      case 'sans-serif':
        googleFontFamily = 'Open Sans';
        break;
      case 'monospace':
        googleFontFamily = 'Source Code Pro';
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

  Future<void> _pickImageFromGallery(bool isLogo) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        print('Imagen seleccionada desde galería: ${image.path}');
        print('Bytes cargados: ${bytes.length} bytes');
        setState(() {
          if (isLogo) {
            _institutionLogoBytes = bytes;
            print('Logo bytes guardados: ${_institutionLogoBytes?.length} bytes');
          } else {
            _backgroundImageBytes = bytes;
            print('Background bytes guardados: ${_backgroundImageBytes?.length} bytes');
          }
        });
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickImageFromCamera(bool isLogo) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        print('Imagen tomada con cámara: ${image.path}');
        print('Bytes cargados: ${bytes.length} bytes');
        setState(() {
          if (isLogo) {
            _institutionLogoBytes = bytes;
            print('Logo bytes guardados: ${_institutionLogoBytes?.length} bytes');
          } else {
            _backgroundImageBytes = bytes;
            print('Background bytes guardados: ${_backgroundImageBytes?.length} bytes');
          }
        });
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      _showErrorSnackBar('Error al tomar foto: $e');
    }
  }

  Future<void> _uploadImage(bool isLogo) async {
    final bytes = isLogo ? _institutionLogoBytes : _backgroundImageBytes;
    if (bytes == null) {
      _showErrorSnackBar('No hay imagen seleccionada para subir');
      return;
    }

    setState(() {
      if (isLogo) {
        _isUploadingLogo = true;
      } else {
        _isUploadingBackground = true;
      }
    });

    try {
      // SOLUCIÓN MEJORADA: Usar data URL con base64 para desarrollo
      // Esto evita problemas de CORS y funciona perfectamente en localhost
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      
      // Simular delay de subida
      await Future.delayed(Duration(seconds: 2));
      
      // Usar data URL en lugar de URL simulada
      final downloadUrl = dataUrl;
      
      print('DEBUG: Generando Data URL para ${isLogo ? 'logo' : 'background'}');
      print('DEBUG: Data URL generada: ${downloadUrl.substring(0, 50)}...');
      
      // Actualizar el diseño con la nueva URL y limpiar los bytes
      setState(() {
        _currentDesign = TemplateDesign(
          primaryColor: _currentDesign.primaryColor,
          secondaryColor: _currentDesign.secondaryColor,
          backgroundColor: _currentDesign.backgroundColor,
          textColor: _currentDesign.textColor,
          headerBackgroundColor: _currentDesign.headerBackgroundColor,
          headerTextColor: _currentDesign.headerTextColor,
          borderColor: _currentDesign.borderColor,
          borderWidth: _currentDesign.borderWidth,
          borderRadius: _currentDesign.borderRadius,
          fontFamily: _currentDesign.fontFamily,
          titleFontSize: _currentDesign.titleFontSize,
          subtitleFontSize: _currentDesign.subtitleFontSize,
          bodyFontSize: _currentDesign.bodyFontSize,
          smallFontSize: _currentDesign.smallFontSize,
          logoUrl: _currentDesign.logoUrl,
          backgroundImageUrl: _currentDesign.backgroundImageUrl,
          backgroundOpacity: _currentDesign.backgroundOpacity,
          titleFontFamily: _currentDesign.titleFontFamily,
          subtitleFontFamily: _currentDesign.subtitleFontFamily,
          bodyFontFamily: _currentDesign.bodyFontFamily,
          smallFontFamily: _currentDesign.smallFontFamily,
          institutionLogoUrl: isLogo ? downloadUrl : _currentDesign.institutionLogoUrl,
          certificateBackgroundUrl: isLogo ? _currentDesign.certificateBackgroundUrl : downloadUrl,
          logoOpacity: _currentDesign.logoOpacity,
          logoPosition: _currentDesign.logoPosition,
        );
        
        // Limpiar los bytes después de subir exitosamente
        if (isLogo) {
          _institutionLogoBytes = null;
        } else {
          _backgroundImageBytes = null;
        }
      });

      _showSuccessSnackBar('Imagen subida exitosamente');
      
    } catch (e) {
      _showErrorSnackBar('Error al subir imagen: $e');
    } finally {
      setState(() {
        if (isLogo) {
          _isUploadingLogo = false;
        } else {
          _isUploadingBackground = false;
        }
      });
    }
  }

  void _removeSelectedImage(bool isLogo) {
    setState(() {
      if (isLogo) {
        _institutionLogoBytes = null;
        // También limpiar la URL guardada
        _currentDesign = TemplateDesign(
          primaryColor: _currentDesign.primaryColor,
          secondaryColor: _currentDesign.secondaryColor,
          backgroundColor: _currentDesign.backgroundColor,
          textColor: _currentDesign.textColor,
          headerBackgroundColor: _currentDesign.headerBackgroundColor,
          headerTextColor: _currentDesign.headerTextColor,
          borderColor: _currentDesign.borderColor,
          borderWidth: _currentDesign.borderWidth,
          borderRadius: _currentDesign.borderRadius,
          fontFamily: _currentDesign.fontFamily,
          titleFontSize: _currentDesign.titleFontSize,
          subtitleFontSize: _currentDesign.subtitleFontSize,
          bodyFontSize: _currentDesign.bodyFontSize,
          smallFontSize: _currentDesign.smallFontSize,
          logoUrl: _currentDesign.logoUrl,
          backgroundImageUrl: _currentDesign.backgroundImageUrl,
          backgroundOpacity: _currentDesign.backgroundOpacity,
          titleFontFamily: _currentDesign.titleFontFamily,
          subtitleFontFamily: _currentDesign.subtitleFontFamily,
          bodyFontFamily: _currentDesign.bodyFontFamily,
          smallFontFamily: _currentDesign.smallFontFamily,
          institutionLogoUrl: '', // Limpiar URL del logo
          certificateBackgroundUrl: _currentDesign.certificateBackgroundUrl,
          logoOpacity: _currentDesign.logoOpacity,
          logoPosition: _currentDesign.logoPosition,
        );
      } else {
        _backgroundImageBytes = null;
        // También limpiar la URL guardada
        _currentDesign = TemplateDesign(
          primaryColor: _currentDesign.primaryColor,
          secondaryColor: _currentDesign.secondaryColor,
          backgroundColor: _currentDesign.backgroundColor,
          textColor: _currentDesign.textColor,
          headerBackgroundColor: _currentDesign.headerBackgroundColor,
          headerTextColor: _currentDesign.headerTextColor,
          borderColor: _currentDesign.borderColor,
          borderWidth: _currentDesign.borderWidth,
          borderRadius: _currentDesign.borderRadius,
          fontFamily: _currentDesign.fontFamily,
          titleFontSize: _currentDesign.titleFontSize,
          subtitleFontSize: _currentDesign.subtitleFontSize,
          bodyFontSize: _currentDesign.bodyFontSize,
          smallFontSize: _currentDesign.smallFontSize,
          logoUrl: _currentDesign.logoUrl,
          backgroundImageUrl: _currentDesign.backgroundImageUrl,
          backgroundOpacity: _currentDesign.backgroundOpacity,
          titleFontFamily: _currentDesign.titleFontFamily,
          subtitleFontFamily: _currentDesign.subtitleFontFamily,
          bodyFontFamily: _currentDesign.bodyFontFamily,
          smallFontFamily: _currentDesign.smallFontFamily,
          institutionLogoUrl: _currentDesign.institutionLogoUrl,
          certificateBackgroundUrl: '', // Limpiar URL de la imagen de fondo
          logoOpacity: _currentDesign.logoOpacity,
          logoPosition: _currentDesign.logoPosition,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    AlertService.showError(context, 'Error', message);
  }

  void _showSuccessSnackBar(String message) {
    AlertService.showSuccess(context, 'Éxito', message);
  }

  Widget _buildBackgroundImage() {
    // Mostrar imagen de fondo si hay bytes seleccionados (vista previa) o URL guardada
    final hasBackgroundImage = _backgroundImageBytes != null || _currentDesign.certificateBackgroundUrl.isNotEmpty;
    print('_buildBackgroundImage: hasBackgroundImage=$hasBackgroundImage, bytes=${_backgroundImageBytes?.length}, url=${_currentDesign.certificateBackgroundUrl}');
    if (!hasBackgroundImage) return Container();
    
    return Positioned.fill(
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDraggingBackground = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _backgroundImagePosition = Offset(
              (_backgroundImagePosition.dx + details.delta.dx).clamp(-100.0, 100.0),
              (_backgroundImagePosition.dy + details.delta.dy).clamp(-100.0, 100.0),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDraggingBackground = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: _isDraggingBackground ? Border.all(color: Colors.green, width: 2) : null,
            borderRadius: BorderRadius.circular(_currentDesign.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_currentDesign.borderRadius),
            child: Transform.translate(
              offset: _backgroundImagePosition,
              child: Opacity(
                opacity: _backgroundImageOpacity,
                child: _backgroundImageBytes != null
                    ? Image.memory(
                        _backgroundImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : _currentDesign.certificateBackgroundUrl.startsWith('data:')
                        ? Image.network(
                            _currentDesign.certificateBackgroundUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.memory(
                            Uint8List(0), // Imagen vacía si no es Data URL
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(); // Fallback silencioso
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionLogo() {
    // Mostrar logo si hay bytes seleccionados (vista previa) o URL guardada
    final hasLogo = _institutionLogoBytes != null || _currentDesign.institutionLogoUrl.isNotEmpty;
    print('_buildInstitutionLogo: hasLogo=$hasLogo, bytes=${_institutionLogoBytes?.length}, url=${_currentDesign.institutionLogoUrl}');
    print('_buildInstitutionLogo: logoPosition=${_logoPosition}, logoSize=${_logoSize}');
    if (!hasLogo) {
      print('_buildInstitutionLogo: No hay logo, retornando Container vacío');
      return Container();
    }
    
    print('_buildInstitutionLogo: Construyendo widget del logo');
    return Positioned(
      left: _logoPosition.dx,
      top: _logoPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDraggingLogo = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _logoPosition = Offset(
              (_logoPosition.dx + details.delta.dx).clamp(0.0, 320.0), // Limitar dentro del certificado
              (_logoPosition.dy + details.delta.dy).clamp(0.0, 520.0),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDraggingLogo = false;
          });
        },
        child: Container(
          width: _logoSize,
          height: _logoSize,
          decoration: BoxDecoration(
            border: _isDraggingLogo ? Border.all(color: Colors.blue, width: 2) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Opacity(
            opacity: _currentDesign.logoOpacity,
            child: _institutionLogoBytes != null
                ? Image.memory(
                    _institutionLogoBytes!,
                    fit: BoxFit.contain,
                  )
                : _currentDesign.institutionLogoUrl.startsWith('data:')
                    ? Image.network(
                        _currentDesign.institutionLogoUrl,
                        fit: BoxFit.contain,
                      )
                    : Image.memory(
                        Uint8List(0), // Imagen vacía si no es Data URL
                        fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final String patternType;
  final Color color;
  final double opacity;

  BackgroundPatternPainter({
    required this.patternType,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    switch (patternType) {
      case 'dots':
        _drawDots(canvas, size, paint);
        break;
      case 'lines':
        _drawLines(canvas, size, paint);
        break;
      case 'geometry':
        _drawGeometry(canvas, size, paint);
        break;
      case 'waves':
        _drawWaves(canvas, size, paint);
        break;
      case 'hexagons':
        _drawHexagons(canvas, size, paint);
        break;
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    final spacing = 20.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    final spacing = 30.0;
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

  void _drawGeometry(Canvas canvas, Size size, Paint paint) {
    final spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x + spacing / 2, y + spacing / 2)
          ..lineTo(x, y + spacing)
          ..lineTo(x - spacing / 2, y + spacing / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final waveHeight = 20.0;
    final waveLength = 100.0;
    
    path.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x += 5) {
      final y = size.height / 2 + waveHeight * math.sin(x * 2 * math.pi / waveLength);
      path.lineTo(x, y);
    }
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint) {
    final radius = 15.0;
    final spacing = radius * 2;
    
    for (double x = 0; x < size.width + spacing; x += spacing * 0.75) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final offsetX = (y / spacing).floor() % 2 == 0 ? 0 : spacing * 0.375;
        _drawHexagon(canvas, Offset(x + offsetX, y), radius, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
