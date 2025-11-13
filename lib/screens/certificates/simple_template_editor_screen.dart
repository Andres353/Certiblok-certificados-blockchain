// lib/screens/certificates/simple_template_editor_screen.dart
// Editor de plantillas simple con vista previa y PDF idénticos

import 'package:flutter/material.dart';
import '../../services/pdf_generator_service.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate_template.dart';

class SimpleTemplateEditorScreen extends StatefulWidget {
  final CertificateTemplate? template;

  const SimpleTemplateEditorScreen({Key? key, this.template}) : super(key: key);

  @override
  _SimpleTemplateEditorScreenState createState() => _SimpleTemplateEditorScreenState();
}

class _SimpleTemplateEditorScreenState extends State<SimpleTemplateEditorScreen> {
  bool _isLoading = false;
  bool _showPreview = true;
  
  // Controladores de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Datos de muestra para vista previa y PDF
  Map<String, dynamic> _sampleData = {
    'studentName': 'Juan Pérez',
    'studentId': '2024001',
    'programName': 'Ingeniería de Sistemas',
    'institutionName': 'Universidad Ejemplo',
    'certificateTitle': 'Certificado de Graduación',
    'issuedBy': 'Dr. María González',
    'issuedDate': '18/09/2025',
  };

  // Diseño actual
  late TemplateDesign _currentDesign;
  late TemplateLayout _currentLayout;
  List<TemplateField> _currentFields = [];

  @override
  void initState() {
    super.initState();
    _initializeTemplate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeTemplate() {
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _descriptionController.text = widget.template!.description;
      _currentDesign = widget.template!.design;
      _currentLayout = widget.template!.layout;
      _currentFields = List<TemplateField>.from(widget.template!.fields);
    } else {
      _createDefaultTemplate();
    }
  }

  void _createDefaultTemplate() {
    _currentDesign = TemplateDesign(
      primaryColor: '#6C4DDC',
      secondaryColor: '#9C27B0',
      backgroundColor: '#FFFFFF',
      textColor: '#000000',
      headerBackgroundColor: '#6C4DDC',
      headerTextColor: '#FFFFFF',
      borderColor: '#E0E0E0',
      borderWidth: 2.0,
      borderRadius: 8.0,
      fontFamily: 'Arial',
      titleFontSize: 24.0,
      subtitleFontSize: 18.0,
      bodyFontSize: 14.0,
      smallFontSize: 12.0,
      logoUrl: '',
      backgroundImageUrl: '',
      backgroundOpacity: 1.0,
      titleFontFamily: 'Arial',
      subtitleFontFamily: 'Arial',
      bodyFontFamily: 'Arial',
      smallFontFamily: 'Arial',
      institutionLogoUrl: '',
      certificateBackgroundUrl: '',
      logoOpacity: 1.0,
      logoPosition: 'top-left',
    );

    _currentLayout = TemplateLayout(
      showHeader: true,
      showFooter: true,
      showBorder: true,
      padding: EdgeInsetsData(left: 20, top: 20, right: 20, bottom: 20),
    );

    _currentFields = [
      TemplateField(
        id: 'title',
        type: 'text',
        label: 'Título',
        value: 'CERTIFICADO',
        order: 1,
        isVisible: true,
        position: FieldPosition(x: 0, y: 50, width: 400, height: 40),
        style: FieldStyle(
          fontSize: 28.0,
          color: '#6C4DDC',
          isBold: true,
          textAlign: 'center',
        ),
      ),
      TemplateField(
        id: 'subtitle',
        type: 'text',
        label: 'Subtítulo',
        value: 'DE GRADUACIÓN',
        order: 2,
        isVisible: true,
        position: FieldPosition(x: 0, y: 100, width: 400, height: 30),
        style: FieldStyle(
          fontSize: 18.0,
          color: '#000000',
          isBold: true,
          textAlign: 'center',
        ),
      ),
      TemplateField(
        id: 'student_name',
        type: 'text',
        label: 'Nombre del Estudiante',
        value: '{{studentName}}',
        order: 3,
        isVisible: true,
        position: FieldPosition(x: 0, y: 200, width: 400, height: 50),
        style: FieldStyle(
          fontSize: 22.0,
          color: '#000000',
          isBold: true,
          textAlign: 'center',
        ),
      ),
      TemplateField(
        id: 'description',
        type: 'text',
        label: 'Descripción',
        value: 'Por haber completado exitosamente el programa académico',
        order: 4,
        isVisible: true,
        position: FieldPosition(x: 0, y: 250, width: 400, height: 30),
        style: FieldStyle(
          fontSize: 14.0,
          color: '#666666',
          textAlign: 'center',
        ),
      ),
      TemplateField(
        id: 'signature',
        type: 'signature',
        label: 'Firma',
        value: '{{issuedByName}}\nDirector Académico',
        order: 5,
        isVisible: true,
        position: FieldPosition(x: 50, y: 350, width: 150, height: 60),
        style: FieldStyle(
          fontSize: 12.0,
          color: '#000000',
          textAlign: 'left',
        ),
      ),
      TemplateField(
        id: 'date',
        type: 'date',
        label: 'Fecha',
        value: 'Fecha: {{issuedAt}}',
        order: 6,
        isVisible: true,
        position: FieldPosition(x: 250, y: 350, width: 150, height: 30),
        style: FieldStyle(
          fontSize: 12.0,
          color: '#000000',
          textAlign: 'right',
        ),
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
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'Generar PDF',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTemplate,
            tooltip: 'Guardar Plantilla',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Panel de edición
                Expanded(
                  flex: _showPreview ? 1 : 2,
                  child: _buildEditorPanel(),
                ),
                // Vista previa
                if (_showPreview)
                  Expanded(
                    flex: 1,
                    child: _buildPreviewPanel(),
                  ),
              ],
            ),
    );
  }

  Widget _buildEditorPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfo(),
          SizedBox(height: 20),
          _buildDesignSettings(),
          SizedBox(height: 20),
          _buildFieldsEditor(),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información Básica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                label: Text('Nombre de la plantilla'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                label: Text('Descripción'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuración de Diseño', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildColorPicker('Color Primario', _currentDesign.primaryColor, (color) {
                    setState(() {
                      _currentDesign = _createNewDesign(primaryColor: color);
                    });
                  }),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildColorPicker('Color Secundario', _currentDesign.secondaryColor, (color) {
                    setState(() {
                      _currentDesign = _createNewDesign(secondaryColor: color);
                    });
                  }),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSlider('Tamaño de Título', _currentDesign.titleFontSize, 12.0, 36.0, (value) {
                    setState(() {
                      _currentDesign = _createNewDesign(titleFontSize: value);
                    });
                  }),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSlider('Tamaño Pequeño', _currentDesign.smallFontSize, 8.0, 20.0, (value) {
                    setState(() {
                      _currentDesign = _createNewDesign(smallFontSize: value);
                    });
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsEditor() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campos de la Plantilla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ..._currentFields.map((field) => _buildFieldEditor(field)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldEditor(TemplateField field) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${field.type.toUpperCase()}: ${field.value}', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Switch(
                  value: field.isVisible,
                  onChanged: (value) {
                    setState(() {
                      final index = _currentFields.indexWhere((f) => f.id == field.id);
                      if (index != -1) {
                        _currentFields[index] = TemplateField(
                          id: field.id,
                          type: field.type,
                          label: field.label,
                          value: field.value,
                          order: field.order,
                          isVisible: value,
                          position: field.position,
                          style: field.style,
                        );
                      }
                    });
                  },
                ),
                Text('Visible'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('Posición: (${field.position.x}, ${field.position.y})'),
                SizedBox(width: 16),
                Text('Tamaño: ${field.position.width}x${field.position.height}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(String label, String currentColor, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 8),
        InkWell(
          onTap: () => _showColorPicker(currentColor, onChanged),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _parseColor(currentColor),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(currentColor, style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          label: '$label: ${value.toStringAsFixed(1)}',
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
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _generatePDF,
                  icon: Icon(Icons.picture_as_pdf, size: 16),
                  label: Text('Generar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: _buildCertificatePreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatePreview() {
    return Container(
      width: 400, // Ancho fijo para vista previa
      decoration: BoxDecoration(
        color: _parseColor(_currentDesign.backgroundColor),
        borderRadius: BorderRadius.circular(_currentDesign.borderRadius),
        border: _currentLayout.showBorder
            ? Border.all(
                color: _parseColor(_currentDesign.borderColor),
                width: _currentDesign.borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          if (_currentLayout.showHeader) _buildPreviewHeader(),
          
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
          
          // Contenido principal
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20), // Usar EdgeInsets normal
              child: _buildPreviewContent(),
            ),
          ),
          
          // Footer
          if (_currentLayout.showFooter) _buildPreviewFooter(),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseColor(_currentDesign.headerBackgroundColor),
            _parseColor(_currentDesign.secondaryColor),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_currentDesign.borderRadius),
          topRight: Radius.circular(_currentDesign.borderRadius),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'LOGO',
                style: TextStyle(
                  fontSize: 12,
                  color: _parseColor(_currentDesign.primaryColor),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sampleData['institutionName'],
                  style: TextStyle(
                    color: _parseColor(_currentDesign.headerTextColor),
                    fontSize: _currentDesign.titleFontSize * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Código: UNIVAL',
                  style: TextStyle(
                    color: _parseColor(_currentDesign.headerTextColor),
                    fontSize: _currentDesign.smallFontSize,
                  ),
                ),
              ],
            ),
          ),
          // Estado del certificado
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VÁLIDO',
              style: TextStyle(
                color: Colors.white,
                fontSize: _currentDesign.smallFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Column(
      children: _currentFields.map((field) {
        if (!field.isVisible) return SizedBox.shrink();
        
        return Container(
          margin: EdgeInsets.only(
            top: field.position.y,
            left: field.position.x,
            right: 0,
            bottom: 8,
          ),
          width: field.position.width,
          height: field.position.height,
          child: _buildPreviewField(field),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewField(TemplateField field) {
    final style = field.style;
    
    Widget content;
    
    switch (field.type) {
      case 'text':
        content = Text(
          _getFieldValue(field),
          style: TextStyle(
            fontSize: style.fontSize,
            fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
            color: _parseColor(style.color),
            decoration: style.isUnderline ? TextDecoration.underline : null,
          ),
          textAlign: _getTextAlign(style.textAlign),
        );
        break;
      case 'date':
        content = Text(
          _getFieldValue(field),
          style: TextStyle(
            fontSize: style.fontSize,
            fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
            color: _parseColor(style.color),
          ),
          textAlign: _getTextAlign(style.textAlign),
        );
        break;
      case 'image':
        content = Container(
          width: style.fontSize * 2,
          height: style.fontSize * 2,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              Icons.image,
              size: style.fontSize,
              color: _parseColor(style.color),
            ),
          ),
        );
        break;
      case 'qr':
        content = Container(
          width: style.fontSize * 2,
          height: style.fontSize * 2,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _parseColor(style.color)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code,
              size: style.fontSize,
              color: _parseColor(style.color),
            ),
          ),
        );
        break;
      case 'signature':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: field.position.width,
              height: 1,
              color: _parseColor(style.color),
            ),
            SizedBox(height: 4),
            Text(
              _getFieldValue(field),
              style: TextStyle(
                fontSize: style.fontSize,
                fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
                color: _parseColor(style.color),
              ),
              textAlign: _getTextAlign(style.textAlign),
            ),
          ],
        );
        break;
      default:
        content = Text(
          _getFieldValue(field),
          style: TextStyle(
            fontSize: style.fontSize,
            color: _parseColor(style.color),
          ),
          textAlign: _getTextAlign(style.textAlign),
        );
    }

    return Container(
      decoration: BoxDecoration(
        color: style.backgroundColor != 'transparent' 
            ? _parseColor(style.backgroundColor) 
            : null,
        borderRadius: BorderRadius.circular(style.borderRadius),
      ),
      child: content,
    );
  }

  Widget _buildPreviewFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_currentDesign.borderRadius),
          bottomRight: Radius.circular(_currentDesign.borderRadius),
        ),
      ),
      child: Column(
        children: [
          Text(
            'VERIFICACIÓN',
            style: TextStyle(
              fontSize: _currentDesign.smallFontSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ID del certificado
              Column(
                children: [
                  Text(
                    'ID del Certificado',
                    style: TextStyle(
                      fontSize: _currentDesign.smallFontSize * 0.8,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'ABC123...',
                      style: TextStyle(
                        fontSize: _currentDesign.smallFontSize * 0.8,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // QR Code
              Column(
                children: [
                  Text(
                    'Código QR',
                    style: TextStyle(
                      fontSize: _currentDesign.smallFontSize * 0.8,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.qr_code,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Para verificar este certificado, visite: certiblock.com/validate',
            style: TextStyle(
              fontSize: _currentDesign.smallFontSize * 0.8,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getFieldValue(TemplateField field) {
    String value = field.value;
    
    // Variables comunes
    value = value.replaceAll('{{studentName}}', _sampleData['studentName']);
    value = value.replaceAll('{{description}}', 'Por haber completado exitosamente el programa académico');
    value = value.replaceAll('{{issuedAt}}', _sampleData['issuedDate']);
    value = value.replaceAll('{{issuedByName}}', _sampleData['issuedBy']);
    value = value.replaceAll('{{id}}', 'CERT-123456');
    value = value.replaceAll('{{institutionName}}', _sampleData['institutionName']);
    value = value.replaceAll('{{programName}}', _sampleData['programName']);
    value = value.replaceAll('{{facultyName}}', 'Facultad de Ingeniería');
    
    return value;
  }

  TextAlign _getTextAlign(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  TemplateDesign _createNewDesign({
    String? primaryColor,
    String? secondaryColor,
    double? titleFontSize,
    double? smallFontSize,
  }) {
    return TemplateDesign(
      primaryColor: primaryColor ?? _currentDesign.primaryColor,
      secondaryColor: secondaryColor ?? _currentDesign.secondaryColor,
      backgroundColor: _currentDesign.backgroundColor,
      textColor: _currentDesign.textColor,
      headerBackgroundColor: _currentDesign.headerBackgroundColor,
      headerTextColor: _currentDesign.headerTextColor,
      borderColor: _currentDesign.borderColor,
      borderWidth: _currentDesign.borderWidth,
      borderRadius: _currentDesign.borderRadius,
      fontFamily: _currentDesign.fontFamily,
      titleFontSize: titleFontSize ?? _currentDesign.titleFontSize,
      subtitleFontSize: _currentDesign.subtitleFontSize,
      bodyFontSize: _currentDesign.bodyFontSize,
      smallFontSize: smallFontSize ?? _currentDesign.smallFontSize,
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
    );
  }

  void _showColorPicker(String currentColor, Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar Color'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildColorOption('#6C4DDC', 'Morado', currentColor, onChanged),
              _buildColorOption('#9C27B0', 'Púrpura', currentColor, onChanged),
              _buildColorOption('#2196F3', 'Azul', currentColor, onChanged),
              _buildColorOption('#4CAF50', 'Verde', currentColor, onChanged),
              _buildColorOption('#FF9800', 'Naranja', currentColor, onChanged),
              _buildColorOption('#F44336', 'Rojo', currentColor, onChanged),
              _buildColorOption('#000000', 'Negro', currentColor, onChanged),
              _buildColorOption('#666666', 'Gris', currentColor, onChanged),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(String color, String name, String currentColor, Function(String) onChanged) {
    final isSelected = color == currentColor;
    return ListTile(
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _parseColor(color),
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
      ),
      title: Text(name),
      onTap: () {
        onChanged(color);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _generatePDF() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Generando PDF...'),
            ],
          ),
        ),
      );

      // Crear plantilla temporal para PDF
      final template = CertificateTemplate(
        id: 'temp',
        name: _nameController.text.isNotEmpty ? _nameController.text : 'Plantilla',
        description: _descriptionController.text,
        institutionId: UserContextService.currentContext?.institutionId ?? 'temp',
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: UserContextService.currentContext?.userId ?? 'temp',
        design: _currentDesign,
        layout: _currentLayout,
        fields: _currentFields,
      );

      // Generar PDF usando la misma lógica que la vista previa
      final pdfBytes = await PDFGeneratorService.generatePDFFromTemplate(
        template: template,
        sampleData: _sampleData,
      );

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Descargar PDF
      final fileName = PDFGeneratorService.generateFileName(template);
      PDFGeneratorService.downloadPDF(pdfBytes, fileName);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generado y descargado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      print('❌ Error generando PDF: $e');
      AlertService.showError(context, 'Error', 'Error generando PDF: $e');
    }
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.isEmpty) {
      AlertService.showError(context, 'Error', 'El nombre de la plantilla es requerido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear nueva plantilla (por ahora solo mostramos mensaje de éxito)
      // TODO: Implementar guardado real en base de datos

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plantilla guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error guardando plantilla: $e');
      AlertService.showError(context, 'Error', 'Error guardando plantilla: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
