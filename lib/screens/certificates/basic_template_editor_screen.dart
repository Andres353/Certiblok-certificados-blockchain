import 'package:flutter/material.dart';
import 'package:frontend_app/models/certificate_template.dart';
import 'package:frontend_app/services/pdf_generator_service.dart';
import 'package:frontend_app/services/user_context_service.dart';
import 'package:frontend_app/services/image_upload_service.dart';
import 'package:file_picker/file_picker.dart';

class BasicTemplateEditorScreen extends StatefulWidget {
  final CertificateTemplate? template;

  const BasicTemplateEditorScreen({Key? key, this.template}) : super(key: key);

  @override
  _BasicTemplateEditorScreenState createState() => _BasicTemplateEditorScreenState();
}

class _BasicTemplateEditorScreenState extends State<BasicTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late TemplateDesign _currentDesign;
  late TemplateLayout _currentLayout;
  late List<TemplateField> _currentFields;

  // URL de la imagen del logo
  String? _logoImageUrl;

  final Map<String, dynamic> _sampleData = {
    'studentName': 'Juan Pérez',
    'institutionName': 'Universidad Ejemplo',
    'programName': 'Ingeniería de Sistemas',
    'completionDate': '18/09/2025',
    'signatureName': 'Dr. María González',
  };

  @override
  void initState() {
    super.initState();
    _initializeTemplate();
  }

  void _initializeTemplate() {
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _descriptionController.text = widget.template!.description;
      _currentDesign = widget.template!.design;
      _currentLayout = widget.template!.layout;
      _currentFields = List.from(widget.template!.fields);
    } else {
      _nameController.text = '';
      _descriptionController.text = '';
      _currentDesign = TemplateDesign(
        backgroundColor: '#FFFFFF',
        primaryColor: '#6C4DDC',
        secondaryColor: '#8B5CF6',
        headerBackgroundColor: '#6C4DDC',
        headerTextColor: '#FFFFFF',
        titleFontSize: 24.0,
        bodyFontSize: 14.0,
        borderRadius: 12.0,
        borderColor: '#E5E7EB',
        borderWidth: 1.0,
      );
      _currentLayout = TemplateLayout(
        showHeader: true,
        showFooter: true,
        showBorder: true,
        padding: EdgeInsetsData(top: 20, left: 20, right: 20, bottom: 20),
      );
      _currentFields = [
        TemplateField(
          id: 'title',
          type: 'text',
          label: 'Título',
          value: 'CERTIFICADO',
          order: 1,
          isVisible: true,
          position: FieldPosition(x: 200, y: 50, width: 400, height: 60),
          style: FieldStyle(
            fontSize: 32.0,
            color: '#6C4DDC',
            isBold: true,
            textAlign: 'center',
            backgroundColor: 'transparent',
            borderRadius: 0.0,
            isItalic: false,
            isUnderline: false,
          ),
        ),
        TemplateField(
          id: 'studentName',
          type: 'text',
          label: 'Nombre del Estudiante',
          value: 'Juan Pérez',
          order: 2,
          isVisible: true,
          position: FieldPosition(x: 200, y: 120, width: 400, height: 50),
          style: FieldStyle(
            fontSize: 24.0,
            color: '#000000',
            isBold: true,
            textAlign: 'center',
            backgroundColor: 'transparent',
            borderRadius: 0.0,
            isItalic: false,
            isUnderline: false,
          ),
        ),
        TemplateField(
          id: 'description',
          type: 'text',
          label: 'Descripción',
          value: 'Por haber completado exitosamente el programa académico',
          order: 3,
          isVisible: true,
          position: FieldPosition(x: 200, y: 180, width: 400, height: 40),
          style: FieldStyle(
            fontSize: 16.0,
            color: '#6B7280',
            isBold: false,
            textAlign: 'center',
            backgroundColor: 'transparent',
            borderRadius: 0.0,
            isItalic: false,
            isUnderline: false,
          ),
        ),
        TemplateField(
          id: 'institution',
          type: 'text',
          label: 'Institución',
          value: 'Universidad Ejemplo',
          order: 4,
          isVisible: true,
          position: FieldPosition(x: 200, y: 230, width: 400, height: 40),
          style: FieldStyle(
            fontSize: 18.0,
            color: '#6C4DDC',
            isBold: true,
            textAlign: 'center',
            backgroundColor: 'transparent',
            borderRadius: 0.0,
            isItalic: false,
            isUnderline: false,
          ),
        ),
        TemplateField(
          id: 'program',
          type: 'text',
          label: 'Programa',
          value: 'Ingeniería de Sistemas',
          order: 5,
          isVisible: true,
          position: FieldPosition(x: 200, y: 280, width: 400, height: 40),
          style: FieldStyle(
            fontSize: 16.0,
            color: '#000000',
            isBold: false,
            textAlign: 'center',
            backgroundColor: 'transparent',
            borderRadius: 0.0,
            isItalic: false,
            isUnderline: false,
          ),
        ),
        TemplateField(
          id: 'date',
          type: 'date',
          label: 'Fecha',
          value: 'Fecha: 18/09/2025',
          order: 6,
          isVisible: true,
          position: FieldPosition(x: 50, y: 350, width: 200, height: 30),
          style: FieldStyle(
            fontSize: 14.0,
            color: '#6B7280',
            isBold: false,
            textAlign: 'left',
            backgroundColor: 'transparent',
            borderRadius: 0.0,
            isItalic: false,
            isUnderline: false,
          ),
        ),
        TemplateField(
          id: 'signature',
          type: 'signature',
          label: 'Firma',
          value: 'Dr. María González',
          order: 7,
          isVisible: true,
          position: FieldPosition(x: 550, y: 350, width: 200, height: 30),
          style: FieldStyle(
            fontSize: 14.0,
            color: '#6B7280',
            isBold: false,
            textAlign: 'right',
            backgroundColor: 'transparent',
            borderRadius: 0.0,
            isItalic: false,
            isUnderline: false,
          ),
          signatureImageUrl: null,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Editar Plantilla' : 'Nueva Plantilla'),
        backgroundColor: Color(0xFF6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Panel de edición
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfo(),
                    SizedBox(height: 20),
                    _buildDesignSettings(),
                    SizedBox(height: 20),
                    _buildFieldsList(),
                    SizedBox(height: 20),
                    _buildPreviewButton(),
                  ],
                ),
              ),
            ),
          ),
          
          // Vista previa
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(20),
              child: _buildCertificatePreview(),
            ),
          ),
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
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

  Widget _buildDesignSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración del Certificado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C4DDC),
              ),
            ),
            SizedBox(height: 16),
            
            // Layout settings
            Text(
              'Diseño del Certificado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            
            // Mostrar header
            SwitchListTile(
              title: Text('Mostrar Header'),
              subtitle: Text('Incluir información de la institución'),
              value: _currentLayout.showHeader,
              onChanged: (value) {
                setState(() {
                  _currentLayout = TemplateLayout(
                    showHeader: value,
                    showFooter: _currentLayout.showFooter,
                    showBorder: _currentLayout.showBorder,
                    padding: _currentLayout.padding,
                  );
                });
              },
            ),
            
            // Mostrar footer
            SwitchListTile(
              title: Text('Mostrar Footer'),
              subtitle: Text('Incluir sección de verificación'),
              value: _currentLayout.showFooter,
              onChanged: (value) {
                setState(() {
                  _currentLayout = TemplateLayout(
                    showHeader: _currentLayout.showHeader,
                    showFooter: value,
                    showBorder: _currentLayout.showBorder,
                    padding: _currentLayout.padding,
                  );
                });
              },
            ),
            
            // Mostrar borde
            SwitchListTile(
              title: Text('Mostrar Borde'),
              subtitle: Text('Incluir borde decorativo'),
              value: _currentLayout.showBorder,
              onChanged: (value) {
                setState(() {
                  _currentLayout = TemplateLayout(
                    showHeader: _currentLayout.showHeader,
                    showFooter: _currentLayout.showFooter,
                    showBorder: value,
                    padding: _currentLayout.padding,
                  );
                });
              },
            ),
            
            SizedBox(height: 20),
            
            // Colores
            Text(
              'Colores del Certificado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            
            // Color primario
            _buildColorSelector(
              'Color Primario',
              _currentDesign.primaryColor,
              (color) {
                setState(() {
                  _currentDesign = TemplateDesign(
                    primaryColor: color,
                    secondaryColor: _currentDesign.secondaryColor,
                    backgroundColor: _currentDesign.backgroundColor,
                    borderColor: _currentDesign.borderColor,
                    titleFontSize: _currentDesign.titleFontSize,
                    bodyFontSize: _currentDesign.bodyFontSize,
                    borderRadius: _currentDesign.borderRadius,
                    borderWidth: _currentDesign.borderWidth,
                    headerBackgroundColor: _currentDesign.headerBackgroundColor,
                    headerTextColor: _currentDesign.headerTextColor,
                  );
                });
              },
            ),
            
            // Color de fondo
            _buildColorSelector(
              'Color de Fondo',
              _currentDesign.backgroundColor,
              (color) {
                setState(() {
                  _currentDesign = TemplateDesign(
                    primaryColor: _currentDesign.primaryColor,
                    secondaryColor: _currentDesign.secondaryColor,
                    backgroundColor: color,
                    borderColor: _currentDesign.borderColor,
                    titleFontSize: _currentDesign.titleFontSize,
                    bodyFontSize: _currentDesign.bodyFontSize,
                    borderRadius: _currentDesign.borderRadius,
                    borderWidth: _currentDesign.borderWidth,
                    headerBackgroundColor: _currentDesign.headerBackgroundColor,
                    headerTextColor: _currentDesign.headerTextColor,
                  );
                });
              },
            ),
            
            // Color del borde
            _buildColorSelector(
              'Color del Borde',
              _currentDesign.borderColor,
              (color) {
                setState(() {
                  _currentDesign = TemplateDesign(
                    primaryColor: _currentDesign.primaryColor,
                    secondaryColor: _currentDesign.secondaryColor,
                    backgroundColor: _currentDesign.backgroundColor,
                    borderColor: color,
                    titleFontSize: _currentDesign.titleFontSize,
                    bodyFontSize: _currentDesign.bodyFontSize,
                    borderRadius: _currentDesign.borderRadius,
                    borderWidth: _currentDesign.borderWidth,
                    headerBackgroundColor: _currentDesign.headerBackgroundColor,
                    headerTextColor: _currentDesign.headerTextColor,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget para selector de color
  Widget _buildColorSelector(String label, String currentColor, Function(String) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text('$label: '),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showColorPicker(currentColor, onChanged),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _parseColor(currentColor),
                border: Border.all(color: Colors.grey[400]!, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.color_lens,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: currentColor,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                labelText: 'Código de color',
                hintText: '#6C4DDC',
                hintStyle: TextStyle(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campos de la Plantilla',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...(_currentFields.map((field) => _buildFieldItem(field)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldItem(TemplateField field) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del campo
            Row(
              children: [
                Icon(
                  _getFieldIcon(field.type),
                  color: Color(0xFF6C4DDC),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
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
                          signatureImageUrl: field.signatureImageUrl,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            
              // Contenido editable
              TextFormField(
                initialValue: field.value,
                decoration: InputDecoration(
                  labelText: _getFieldLabelText(field.type),
                  hintText: _getFieldHintText(field.type),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: _getFieldMaxLines(field.type),
                onChanged: (value) {
                  setState(() {
                    final index = _currentFields.indexWhere((f) => f.id == field.id);
                    if (index != -1) {
                      _currentFields[index] = TemplateField(
                        id: field.id,
                        type: field.type,
                        label: field.label,
                        value: value,
                        order: field.order,
                        isVisible: field.isVisible,
                        position: field.position,
                        style: field.style,
                        signatureImageUrl: field.signatureImageUrl,
                      );
                    }
                  });
                },
              ),
            // Opción para subir imagen de firma digital (solo para tipo signature)
            if (field.type == 'signature') ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, size: 16, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Firma Digital',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (field.signatureImageUrl != null && field.signatureImageUrl!.isNotEmpty) ...[
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.network(
                          field.signatureImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.broken_image, color: Colors.grey[600]),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _uploadSignatureImage(field),
                            icon: Icon(Icons.upload, size: 16),
                            label: Text(field.signatureImageUrl != null ? 'Cambiar Imagen' : 'Subir Imagen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        if (field.signatureImageUrl != null && field.signatureImageUrl!.isNotEmpty) ...[
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeSignatureImage(field),
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar imagen',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 12),
            
            // Color del texto
            Row(
              children: [
                Text(
                  'Color: ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 8),
                // Muestra del color actual
                GestureDetector(
                  onTap: () => _showColorPicker(field.style.color, (color) {
                    setState(() {
                      final index = _currentFields.indexWhere((f) => f.id == field.id);
                      if (index != -1) {
                        _currentFields[index] = TemplateField(
                          id: field.id,
                          type: field.type,
                          label: field.label,
                          value: field.value,
                          order: field.order,
                          isVisible: field.isVisible,
                          position: field.position,
                          style: FieldStyle(
                            fontSize: field.style.fontSize,
                            color: color,
                            isBold: field.style.isBold,
                            textAlign: field.style.textAlign,
                            backgroundColor: field.style.backgroundColor,
                            borderRadius: field.style.borderRadius,
                            isItalic: field.style.isItalic,
                            isUnderline: field.style.isUnderline,
                          ),
                          signatureImageUrl: field.signatureImageUrl,
                        );
                      }
                    });
                  }),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _parseColor(field.style.color),
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.color_lens,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Campo de texto para color personalizado
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: field.style.color,
                    style: TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      labelText: 'Código de color',
                      hintText: '#6C4DDC',
                      hintStyle: TextStyle(fontSize: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
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
                            isVisible: field.isVisible,
                            position: field.position,
                            style: FieldStyle(
                              fontSize: field.style.fontSize,
                              color: value,
                              isBold: field.style.isBold,
                              textAlign: field.style.textAlign,
                              backgroundColor: field.style.backgroundColor,
                              borderRadius: field.style.borderRadius,
                              isItalic: field.style.isItalic,
                              isUnderline: field.style.isUnderline,
                            ),
                            signatureImageUrl: field.signatureImageUrl,
                          );
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Función para obtener el icono del tipo de campo
  IconData _getFieldIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'date':
        return Icons.calendar_today;
      case 'signature':
        return Icons.draw;
      case 'title':
        return Icons.title;
      case 'image':
        return Icons.image;
      case 'qr':
        return Icons.qr_code;
      default:
        return Icons.text_fields;
    }
  }

  // Función para parsear colores
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.black;
    }
  }

  // Función para obtener el texto del label según el tipo de campo
  String _getFieldLabelText(String type) {
    switch (type) {
      case 'text':
        return 'Contenido del Certificado';
      case 'date':
        return 'Fecha del Certificado';
      case 'signature':
        return 'Nombre de la Firma';
      case 'title':
        return 'Título del Certificado';
      case 'image':
        return 'URL de la Imagen';
      case 'qr':
        return 'Contenido del QR';
      default:
        return 'Contenido del Campo';
    }
  }

  // Función para obtener el hint text según el tipo de campo
  String _getFieldHintText(String type) {
    switch (type) {
      case 'text':
        return 'Ingresa el texto que aparecerá en el certificado';
      case 'date':
        return 'Ej: Fecha: 18/09/2025';
      case 'signature':
        return 'Ej: Dr. María González';
      case 'title':
        return 'Ej: CERTIFICADO';
      case 'image':
        return 'https://ejemplo.com/imagen.png';
      case 'qr':
        return 'Contenido para el código QR';
      default:
        return 'Ingresa el contenido del campo';
    }
  }

  // Función para obtener el número de líneas según el tipo de campo
  int _getFieldMaxLines(String type) {
    switch (type) {
      case 'signature':
        return 1;
      case 'text':
      case 'title':
      case 'date':
        return 2;
      case 'image':
      case 'qr':
        return 1;
      default:
        return 2;
    }
  }

  // Selector de colores visual
  void _showColorPicker(String currentColor, Function(String) onChanged) {
    final predefinedColors = [
      '#6C4DDC', '#2C3E50', '#E74C3C', '#27AE60', '#F39C12',
      '#8E44AD', '#1ABC9C', '#34495E', '#E67E22', '#000000',
      '#4A90E2', '#50C878', '#F1C40F', '#E67E22', '#8B5CF6',
      '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#06B6D4',
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
              crossAxisCount: 5,
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

  Widget _buildPreviewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generatePDF,
        icon: Icon(Icons.picture_as_pdf),
        label: Text('Generar PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCertificatePreview() {
    return Center(
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          color: _parseColor(_currentDesign.backgroundColor),
          borderRadius: BorderRadius.circular(12),
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
            // Header (igual que en el PDF)
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
              child: Container(
                padding: EdgeInsets.all(20),
                child: _buildPreviewContent(),
              ),
            ),
            
            // Footer (igual que en el PDF)
            if (_currentLayout.showFooter) _buildPreviewFooter(),
          ],
        ),
      ),
    );
  }

  // Header de la vista previa (igual que en el PDF)
  Widget _buildPreviewHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
          // Logo a la izquierda
          GestureDetector(
            onTap: _selectLogoImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _logoImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _logoImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: _parseColor(_currentDesign.primaryColor),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 30,
                            color: _parseColor(_currentDesign.primaryColor),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'LOGO',
                            style: TextStyle(
                              fontSize: 12,
                              color: _parseColor(_currentDesign.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          SizedBox(width: 20),
          // Nombre de institución centrado
          Expanded(
            child: Center(
              child: Text(
                'Universidad Ejemplo',
                style: TextStyle(
                  color: _parseColor(_currentDesign.headerTextColor),
                  fontSize: _currentDesign.titleFontSize * 0.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Badge VÁLIDO a la derecha
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VÁLIDO',
              style: TextStyle(
                color: Colors.white,
                fontSize: _currentDesign.smallFontSize * 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Contenido principal de la vista previa
  Widget _buildPreviewContent() {
    return Stack(
      children: _currentFields
          .where((field) => field.isVisible)
          .map((field) => _buildPositionedField(field))
          .toList(),
    );
  }

  // Footer de la vista previa (igual que en el PDF)
  Widget _buildPreviewFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_currentDesign.borderRadius),
          bottomRight: Radius.circular(_currentDesign.borderRadius),
        ),
      ),
      child: Container(),
    );
  }

  Widget _buildPositionedField(TemplateField field) {
    // Calcular altura del contenedor y posición
    double containerHeight = field.position.height;
    double topPosition = field.position.y;
    
    if (field.type == 'signature' && field.signatureImageUrl != null && field.signatureImageUrl!.isNotEmpty) {
      // Aumentar altura para incluir la imagen (80px imagen + 15px espacio + altura original)
      containerHeight = 80 + 15 + field.position.height;
      // Mover el contenedor hacia arriba para que la imagen quede más arriba
      topPosition = field.position.y - 80; // Mover 80px hacia arriba
    }
    
    return Positioned(
      left: field.position.x,
      top: topPosition,
      width: field.position.width,
      child: Container(
        width: field.position.width,
        height: containerHeight,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: field.style.backgroundColor != 'transparent' 
              ? _parseColor(field.style.backgroundColor) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(field.style.borderRadius),
        ),
        child: _buildFieldContent(field),
      ),
    );
  }

  // Construir el contenido del campo según su tipo
  Widget _buildFieldContent(TemplateField field) {
    switch (field.type) {
      case 'signature':
        // Usar Column normal con la imagen arriba y la línea abajo
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: field.style.textAlign == 'right' 
              ? CrossAxisAlignment.end 
              : field.style.textAlign == 'left' 
                  ? CrossAxisAlignment.start 
                  : CrossAxisAlignment.center,
          children: [
            // Imagen de firma digital posicionada arriba (si existe)
            if (field.signatureImageUrl != null && field.signatureImageUrl!.isNotEmpty) ...[
              Transform.translate(
                offset: Offset(-10, 0), // Mover 10px a la izquierda (reducido de 20 para moverla más a la derecha)
                child: Align(
                  alignment: Alignment.centerLeft, // Alinear a la izquierda
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: field.position.width,
                      maxHeight: 80,
                    ),
                    margin: EdgeInsets.only(bottom: 15), // Más abajo (reducido de 25 a 15 para acercarla a la línea)
                    child: Image.network(
                      field.signatureImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: field.position.width,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Icon(Icons.broken_image, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            // Línea de firma - posición fija (no se mueve)
            Container(
              width: field.position.width,
              height: 1,
              color: _parseColor(field.style.color),
            ),
            SizedBox(height: 4),
            // Texto de la firma
            Text(
              field.value,
              style: TextStyle(
                fontSize: field.style.fontSize,
                fontWeight: field.style.isBold ? FontWeight.bold : FontWeight.normal,
                color: _parseColor(field.style.color),
                fontStyle: field.style.isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: field.style.isUnderline ? TextDecoration.underline : TextDecoration.none,
                letterSpacing: 0.5,
                height: 1.2,
              ),
              textAlign: _getTextAlign(field.style.textAlign),
              overflow: TextOverflow.visible,
              maxLines: null,
            ),
          ],
        );
      case 'image':
        return Container(
          width: field.position.width,
          height: field.position.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _parseColor(field.style.color)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: field.style.fontSize,
                  color: _parseColor(field.style.color),
                ),
                SizedBox(height: 4),
                Text(
                  'IMG',
                  style: TextStyle(
                    fontSize: field.style.fontSize * 0.6,
                    color: _parseColor(field.style.color),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'qr':
        return Container(
          width: field.position.width,
          height: field.position.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _parseColor(field.style.color)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code,
                  size: field.style.fontSize,
                  color: _parseColor(field.style.color),
                ),
                SizedBox(height: 4),
                Text(
                  'QR',
                  style: TextStyle(
                    fontSize: field.style.fontSize * 0.6,
                    color: _parseColor(field.style.color),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Text(
          field.value,
          style: TextStyle(
            fontSize: field.style.fontSize,
            fontWeight: field.style.isBold ? FontWeight.bold : FontWeight.normal,
            color: _parseColor(field.style.color),
            fontStyle: field.style.isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: field.style.isUnderline ? TextDecoration.underline : TextDecoration.none,
            letterSpacing: 0.5,
            height: 1.2,
          ),
          textAlign: _getTextAlign(field.style.textAlign),
          overflow: TextOverflow.visible,
          maxLines: null,
        );
    }
  }

  TextAlign _getTextAlign(String textAlign) {
    switch (textAlign) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      default:
        return TextAlign.left;
    }
  }

  // Función para seleccionar imagen del logo
  void _selectLogoImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seleccionar Logo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Subir desde PC'),
              subtitle: Text('Seleccionar imagen desde tu computadora'),
              onTap: () {
                Navigator.pop(context);
                _pickLogoFromPC();
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Ingresar URL'),
              subtitle: Text('Pegar URL de imagen'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
            if (_logoImageUrl != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar Logo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    _logoImageUrl = null;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Función para seleccionar imagen desde la PC
  void _pickLogoFromPC() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Leer los bytes del archivo
        final bytes = file.bytes;
        if (bytes != null) {
          // Subir a Supabase Storage
          final url = await ImageUploadService.uploadImageBytes(
            bytes,
            'certificate_logos/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
          );
          
          setState(() {
            _logoImageUrl = url;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logo subido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para mostrar diálogo de entrada de URL
  void _showUrlInputDialog() {
    final urlController = TextEditingController(text: _logoImageUrl ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingresar URL del Logo'),
        content: TextFormField(
          controller: urlController,
          decoration: InputDecoration(
            labelText: 'URL de la Imagen',
            hintText: 'https://ejemplo.com/logo.png',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _logoImageUrl = urlController.text.isNotEmpty ? urlController.text : null;
              });
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _generatePDF() async {
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

      final template = CertificateTemplate(
        id: widget.template?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        institutionId: await _getCurrentInstitutionId(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: await _getCurrentUserId(),
        design: _currentDesign,
        layout: _currentLayout,
        fields: _currentFields,
      );

      // Generar PDF - incluir logo si existe
      final pdfSampleData = Map<String, dynamic>.from(_sampleData);
      if (_logoImageUrl != null && _logoImageUrl!.isNotEmpty) {
        pdfSampleData['logoUrl'] = _logoImageUrl;
      }
      
      final pdfBytes = await PDFGeneratorService.generatePDFFromTemplate(
        template: template, 
        sampleData: pdfSampleData
      );
      
      // Cerrar diálogo de carga
      Navigator.pop(context);
      
      // Descargar PDF
      final fileName = PDFGeneratorService.generateFileName(template);
      PDFGeneratorService.downloadPDF(pdfBytes, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generado y descargado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _getCurrentUserId() async {
    final userContext = await UserContextService.loadUserContext();
    return userContext?.userId ?? '';
  }

  Future<String> _getCurrentInstitutionId() async {
    final userContext = await UserContextService.loadUserContext();
    return userContext?.institutionId ?? '';
  }

  void _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final template = CertificateTemplate(
        id: widget.template?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        institutionId: await _getCurrentInstitutionId(),
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: await _getCurrentUserId(),
        design: _currentDesign,
        layout: _currentLayout,
        fields: _currentFields,
      );

      // Simular guardado (sin adapter por ahora)
      print('Template creado: ${template.name}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plantilla guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para subir imagen de firma digital
  Future<void> _uploadSignatureImage(TemplateField field) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Leer los bytes del archivo
        final bytes = file.bytes;
        if (bytes != null) {
          // Subir a Supabase Storage
          final url = await ImageUploadService.uploadImageBytes(
            bytes,
            'certificate_signatures/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
          );
          
          setState(() {
            final index = _currentFields.indexWhere((f) => f.id == field.id);
            if (index != -1) {
              _currentFields[index] = TemplateField(
                id: field.id,
                type: field.type,
                label: field.label,
                value: field.value,
                order: field.order,
                isVisible: field.isVisible,
                position: field.position,
                style: field.style,
                signatureImageUrl: url,
              );
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imagen de firma subida exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen de firma: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para eliminar imagen de firma digital
  void _removeSignatureImage(TemplateField field) {
    setState(() {
      final index = _currentFields.indexWhere((f) => f.id == field.id);
      if (index != -1) {
        _currentFields[index] = TemplateField(
          id: field.id,
          type: field.type,
          label: field.label,
          value: field.value,
          order: field.order,
          isVisible: field.isVisible,
          position: field.position,
          style: field.style,
          signatureImageUrl: null,
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imagen de firma eliminada'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}