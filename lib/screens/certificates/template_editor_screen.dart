// lib/screens/certificates/template_editor_screen.dart
// Editor de plantillas de certificados con vista previa

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/adapters/certificate_template_adapter.dart';
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

        await CertificateTemplateAdapter.updateTemplate(
          _currentTemplate.id,
          updatedTemplate,
        );
      } else {
        // Crear nueva plantilla
        await CertificateTemplateAdapter.createTemplate(
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
              'Colores del Certificado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Paleta de colores predefinidos
            _buildColorPalette(),
            SizedBox(height: 20),
            
            // Colores principales
            Text(
              'Colores Principales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            
            _buildColorPicker('Color Principal', _currentDesign.primaryColor, (color) {
              setState(() {
                _currentDesign = _updateDesign(primaryColor: color);
              });
            }),
            
            _buildColorPicker('Color de Fondo', _currentDesign.backgroundColor, (color) {
              setState(() {
                _currentDesign = _updateDesign(backgroundColor: color);
              });
            }),
            
            _buildColorPicker('Color del Borde', _currentDesign.borderColor, (color) {
              setState(() {
                _currentDesign = _updateDesign(borderColor: color);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              // Muestra del color actual
              GestureDetector(
                onTap: () => _showColorPicker(currentColor, onChanged),
                child: Container(
                  width: 40,
                  height: 40,
            decoration: BoxDecoration(
              color: _parseColor(currentColor),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.color_lens,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Campo de texto para color personalizado
          Expanded(
            child: TextFormField(
              initialValue: currentColor,
              decoration: InputDecoration(
                    labelText: 'Código de color',
                    hintText: '#6C4DDC',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.palette, size: 20),
              ),
              onChanged: onChanged,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                        return 'Formato inválido (ej: #6C4DDC)';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Selector de colores visual
  void _showColorPicker(String currentColor, Function(String) onChanged) {
    final predefinedColors = [
      '#6C4DDC', '#4A90E2', '#50C878', '#F39C12', '#E74C3C',
      '#2C3E50', '#34495E', '#7F8C8D', '#95A5A6', '#BDC3C7',
      '#8E44AD', '#9B59B6', '#E67E22', '#D35400', '#C0392B',
      '#1ABC9C', '#16A085', '#27AE60', '#2ECC71', '#58D68D',
      '#3498DB', '#2980B9', '#5DADE2', '#85C1E9', '#AED6F1',
      '#F1C40F', '#F4D03F', '#F7DC6F', '#F9E79F', '#FCF3CF',
      '#E74C3C', '#C0392B', '#F1948A', '#F5B7B1', '#FADBD8',
      '#000000', '#2C3E50', '#34495E', '#7F8C8D', '#95A5A6',
      '#FFFFFF', '#F8F9FA', '#E9ECEF', '#DEE2E6', '#CED4DA',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar Color'),
        content: Container(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: predefinedColors.length,
            itemBuilder: (context, index) {
              final color = predefinedColors[index];
              final isSelected = color == currentColor;
              
              return GestureDetector(
                onTap: () {
                  onChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _parseColor(color),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
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
    final field = _currentFields[index];
    final TextEditingController valueController = TextEditingController(text: field.value);
    final TextEditingController colorController = TextEditingController(text: field.style.color);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar Contenido'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información del campo
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.text_fields, color: Color(0xff6C4DDC)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          field.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // Contenido del texto
                TextFormField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: 'Contenido del Certificado',
                    hintText: 'Ingresa el texto que aparecerá en el certificado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.edit),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El contenido no puede estar vacío';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                
                // Color del texto
                Text(
                  'Color del Texto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2E2F44),
                  ),
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    // Muestra del color actual
                    GestureDetector(
                      onTap: () => _showColorPicker(field.style.color, (color) {
                        colorController.text = color;
                        setDialogState(() {});
                      }),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _parseColor(field.style.color),
                          border: Border.all(color: Colors.grey[400]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.color_lens,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Campo de texto para color personalizado
                    Expanded(
                      child: TextFormField(
                        controller: colorController,
                        decoration: InputDecoration(
                          labelText: 'Código de color',
                          hintText: '#6C4DDC',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: Icon(Icons.palette, size: 20),
                        ),
                        onChanged: (value) {
                          setDialogState(() {});
                        },
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                              return 'Formato inválido (ej: #6C4DDC)';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Paleta de colores rápidos
                Text(
                  'Colores Rápidos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '#6C4DDC', '#2C3E50', '#E74C3C', '#27AE60', '#F39C12',
                    '#8E44AD', '#1ABC9C', '#34495E', '#E67E22', '#000000'
                  ].map((color) => GestureDetector(
                    onTap: () {
                      colorController.text = color;
                      setDialogState(() {});
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorController.text == color 
                              ? Colors.black 
                              : Colors.grey[300]!,
                          width: colorController.text == color ? 2 : 1,
                        ),
                      ),
                      child: colorController.text == color
                          ? Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (valueController.text.trim().isNotEmpty) {
                  setState(() {
                    _currentFields[index] = TemplateField(
                      id: field.id,
                      type: field.type,
                      label: field.label,
                      value: valueController.text.trim(),
                      position: field.position,
                      style: FieldStyle(
                        fontSize: field.style.fontSize,
                        fontWeight: field.style.fontWeight,
                        color: colorController.text.trim(),
                        textAlign: field.style.textAlign,
                        isBold: field.style.isBold,
                      ),
                      order: field.order,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
              ),
              child: Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeField(int index) {
    setState(() {
      _currentFields.removeAt(index);
    });
  }

  // Función auxiliar para actualizar el diseño
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
    );
  }

  // Paleta de colores predefinidos
  Widget _buildColorPalette() {
    final colorPalettes = <Map<String, dynamic>>[
      {
        'name': 'Clásico',
        'colors': ['#6C4DDC', '#4A90E2', '#50C878', '#F5F5F5', '#2E2F44'],
      },
      {
        'name': 'Profesional',
        'colors': ['#2C3E50', '#3498DB', '#E74C3C', '#FFFFFF', '#34495E'],
      },
      {
        'name': 'Elegante',
        'colors': ['#8E44AD', '#9B59B6', '#E67E22', '#F8F9FA', '#2C3E50'],
      },
      {
        'name': 'Moderno',
        'colors': ['#1ABC9C', '#16A085', '#F39C12', '#ECF0F1', '#2C3E50'],
      },
      {
        'name': 'Minimalista',
        'colors': ['#34495E', '#7F8C8D', '#95A5A6', '#FFFFFF', '#2C3E50'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paletas de Colores',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colorPalettes.map((palette) {
            final colors = palette['colors'] as List<String>;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentDesign = _updateDesign(
                    primaryColor: colors[0],
                    secondaryColor: colors[1],
                    backgroundColor: colors[3],
                    textColor: colors[4],
                    borderColor: colors[2],
                  );
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      palette['name'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: colors.map((color) {
                        return Container(
                          width: 20,
                          height: 20,
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _parseColor(color),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
