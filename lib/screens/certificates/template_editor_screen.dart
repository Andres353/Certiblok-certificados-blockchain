// lib/screens/certificates/template_editor_screen.dart
// Editor de plantillas de certificados con vista previa

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/certificate_template_service.dart';
import '../../models/certificate_template.dart';
import 'template_preview_widget.dart';

class TemplateEditorScreen extends StatefulWidget {
  final CertificateTemplate? template;

  const TemplateEditorScreen({Key? key, this.template}) : super(key: key);

  @override
  _TemplateEditorScreenState createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _showPreview = true;

  late CertificateTemplate _currentTemplate;
  late TemplateDesign _currentDesign;
  late TemplateLayout _currentLayout;
  late List<TemplateField> _currentFields;

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
    _currentFields = List.from(widget.template?.fields ?? _getDefaultFields());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.template != null) {
        // Actualizar plantilla existente
        final updatedTemplate = _currentTemplate.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          design: _currentDesign,
          layout: _currentLayout,
          fields: _currentFields,
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
          fields: _currentFields,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.template != null ? 'Plantilla actualizada' : 'Plantilla creada'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando plantilla: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica
            _buildBasicInfoSection(),
            SizedBox(height: 24),
            
            // Diseño
            _buildDesignSection(),
            SizedBox(height: 24),
            
            // Layout
            _buildLayoutSection(),
            SizedBox(height: 24),
            
            // Campos
            _buildFieldsSection(),
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
            
            // Colores
            _buildColorPicker('Color Primario', _currentDesign.primaryColor, (color) {
              setState(() {
                _currentDesign = TemplateDesign(
                  primaryColor: color,
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
                );
              });
            }),
            
            _buildColorPicker('Color Secundario', _currentDesign.secondaryColor, (color) {
              setState(() {
                _currentDesign = TemplateDesign(
                  primaryColor: _currentDesign.primaryColor,
                  secondaryColor: color,
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
                );
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
            
            SizedBox(height: 16),
            
            // Tamaños de fuente
            _buildFontSizeSlider('Título', _currentDesign.titleFontSize, (size) {
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
          ],
        ),
      ),
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
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Campos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addField,
                  icon: Icon(Icons.add),
                  label: Text('Agregar Campo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Lista de campos
            ..._currentFields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              return _buildFieldCard(field, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(TemplateField field, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getFieldIcon(field.type)),
        title: Text(field.label),
        subtitle: Text('${field.type} - Orden: ${field.order}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editField(index),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _removeField(index),
            ),
          ],
        ),
        onTap: () => _editField(index),
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _parseColor(currentColor),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
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
              child: TemplatePreviewWidget(
                template: CertificateTemplate(
                  id: 'preview',
                  name: _nameController.text.isNotEmpty ? _nameController.text : 'Vista Previa',
                  description: _descriptionController.text,
                  institutionId: 'preview',
                  isDefault: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  createdBy: 'preview',
                  design: _currentDesign,
                  layout: _currentLayout,
                  fields: _currentFields,
                ),
              ),
            ),
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

  IconData _getFieldIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'qr':
        return Icons.qr_code;
      case 'signature':
        return Icons.draw;
      case 'date':
        return Icons.calendar_today;
      default:
        return Icons.widgets;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _addField() {
    // TODO: Implementar diálogo para agregar campo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Funcionalidad de agregar campo en desarrollo')),
    );
  }

  void _editField(int index) {
    // TODO: Implementar diálogo para editar campo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Funcionalidad de editar campo en desarrollo')),
    );
  }

  void _removeField(int index) {
    setState(() {
      _currentFields.removeAt(index);
    });
  }

  List<TemplateField> _getDefaultFields() {
    return [
      // Título del certificado
      TemplateField(
        id: 'certificate_title',
        type: 'text',
        label: 'Título del Certificado',
        value: 'CERTIFICADO',
        position: FieldPosition(x: 0, y: 50, width: 800, height: 60, alignment: 'center'),
        style: FieldStyle(
          fontSize: 32,
          fontWeight: 'bold',
          color: '#6C4DDC',
          textAlign: 'center',
          isBold: true,
        ),
        order: 1,
      ),
      // Nombre del estudiante
      TemplateField(
        id: 'student_name',
        type: 'text',
        label: 'Nombre del Estudiante',
        value: '{{studentName}}',
        position: FieldPosition(x: 0, y: 150, width: 800, height: 80, alignment: 'center'),
        style: FieldStyle(
          fontSize: 28,
          fontWeight: 'bold',
          color: '#000000',
          textAlign: 'center',
          isBold: true,
        ),
        order: 2,
      ),
      // Descripción
      TemplateField(
        id: 'certificate_description',
        type: 'text',
        label: 'Descripción',
        value: '{{description}}',
        position: FieldPosition(x: 50, y: 250, width: 700, height: 100, alignment: 'center'),
        style: FieldStyle(
          fontSize: 16,
          fontWeight: 'normal',
          color: '#000000',
          textAlign: 'center',
        ),
        order: 3,
      ),
      // Fecha de emisión
      TemplateField(
        id: 'issue_date',
        type: 'date',
        label: 'Fecha de Emisión',
        value: '{{issuedAt}}',
        position: FieldPosition(x: 500, y: 400, width: 200, height: 30, alignment: 'right'),
        style: FieldStyle(
          fontSize: 14,
          fontWeight: 'normal',
          color: '#666666',
          textAlign: 'right',
        ),
        order: 4,
      ),
      // Firma del emisor
      TemplateField(
        id: 'issuer_signature',
        type: 'signature',
        label: 'Firma del Emisor',
        value: '{{issuedByName}}',
        position: FieldPosition(x: 100, y: 450, width: 200, height: 50, alignment: 'left'),
        style: FieldStyle(
          fontSize: 14,
          fontWeight: 'normal',
          color: '#000000',
          textAlign: 'left',
        ),
        order: 5,
      ),
      // ID del certificado
      TemplateField(
        id: 'certificate_id',
        type: 'text',
        label: 'ID del Certificado',
        value: '{{id}}',
        position: FieldPosition(x: 0, y: 550, width: 800, height: 20, alignment: 'center'),
        style: FieldStyle(
          fontSize: 10,
          fontWeight: 'normal',
          color: '#999999',
          textAlign: 'center',
        ),
        order: 6,
      ),
    ];
  }
}
