// lib/screens/certificates/template_pdf_management_screen.dart
// Pantalla de gestión de plantillas con funcionalidad de PDF

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/adapters/certificate_template_adapter.dart';
import '../../services/pdf_generator_service.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate_template.dart';
import 'advanced_template_editor_screen.dart';

class TemplatePDFManagementScreen extends StatefulWidget {
  @override
  _TemplatePDFManagementScreenState createState() => _TemplatePDFManagementScreenState();
}

class _TemplatePDFManagementScreenState extends State<TemplatePDFManagementScreen> {
  bool _isLoading = true;
  List<CertificateTemplate> _templates = [];
  CertificateTemplate? _defaultTemplate;
  Map<String, TextEditingController> _sampleDataControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeAndLoadTemplates();
  }

  @override
  void dispose() {
    _sampleDataControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _initializeAndLoadTemplates() async {
    await UserContextService.loadUserContext();
    await _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Cargando plantillas...');
      
      final userContext = UserContextService.currentContext;
      _templates = await CertificateTemplateAdapter.getTemplates();
      
      // Filtrar solo plantillas de la institución actual
      final currentInstitutionId = userContext?.institutionId;
      if (currentInstitutionId != null) {
        _templates = _templates.where((template) => template.institutionId == currentInstitutionId).toList();
      }
      
      _defaultTemplate = await CertificateTemplateAdapter.getDefaultTemplate();
      
      // Crear controladores para datos de muestra
      _createSampleDataControllers();
      
      // Si no hay plantillas, crear una por defecto
      if (_templates.isEmpty) {
        try {
          await CertificateTemplateAdapter.createDefaultTemplate(
            UserContextService.currentContext?.institutionId ?? 'default'
          );
          _templates = await CertificateTemplateAdapter.getTemplates();
          _defaultTemplate = await CertificateTemplateAdapter.getDefaultTemplate();
          _createSampleDataControllers();
        } catch (e) {
          print('❌ Error creando plantilla por defecto: $e');
        }
      }
    } catch (e) {
      print('❌ Error cargando plantillas: $e');
      AlertService.showError(context, 'Error', 'Error cargando plantillas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _createSampleDataControllers() {
    for (var template in _templates) {
      if (!_sampleDataControllers.containsKey(template.id)) {
        _sampleDataControllers[template.id] = TextEditingController(
          text: '${template.name} - Muestra'
        );
      }
    }
  }

  void _createNewTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedTemplateEditorScreen(),
      ),
    ).then((_) => _loadTemplates());
  }

  void _editTemplate(CertificateTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedTemplateEditorScreen(template: template),
      ),
    ).then((_) => _loadTemplates());
  }

  Future<void> _generateAndDownloadPDF(CertificateTemplate template) async {
    try {
      // Mostrar diálogo para datos de muestra
      final sampleData = await _showSampleDataDialog(template);
      if (sampleData == null) return;

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

      // Generar PDF
      final pdfBytes = await PDFGeneratorService.generatePDFFromTemplate(
        template: template,
        sampleData: sampleData,
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

  Future<Map<String, dynamic>?> _showSampleDataDialog(CertificateTemplate template) async {
    final studentNameController = TextEditingController(text: 'Juan Pérez');
    final studentIdController = TextEditingController(text: '2024001');
    final programNameController = TextEditingController(text: 'Ingeniería de Sistemas');
    final institutionNameController = TextEditingController(text: 'Universidad Ejemplo');
    final certificateTitleController = TextEditingController(text: template.name);
    final issuedByController = TextEditingController(text: 'Director Académico');

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Datos de Muestra para PDF'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Estudiante',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: studentIdController,
                decoration: InputDecoration(
                  labelText: 'ID del Estudiante',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: programNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Programa',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: institutionNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Institución',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: certificateTitleController,
                decoration: InputDecoration(
                  labelText: 'Título del Certificado',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: issuedByController,
                decoration: InputDecoration(
                  labelText: 'Emitido por',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              studentNameController.dispose();
              studentIdController.dispose();
              programNameController.dispose();
              institutionNameController.dispose();
              certificateTitleController.dispose();
              issuedByController.dispose();
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final data = {
                'studentName': studentNameController.text,
                'studentId': studentIdController.text,
                'programName': programNameController.text,
                'institutionName': institutionNameController.text,
                'certificateTitle': certificateTitleController.text,
                'issuedBy': issuedByController.text,
                'issuedDate': DateTime.now().toString().split(' ')[0],
              };
              
              studentNameController.dispose();
              studentIdController.dispose();
              programNameController.dispose();
              institutionNameController.dispose();
              certificateTitleController.dispose();
              issuedByController.dispose();
              
              Navigator.of(context).pop(data);
            },
            child: Text('Generar PDF'),
          ),
        ],
      ),
    );
  }

  void _duplicateTemplate(CertificateTemplate template) async {
    final nameController = TextEditingController(text: '${template.name} (Copia)');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duplicar Plantilla'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Nombre de la copia',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Duplicar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await CertificateTemplateAdapter.duplicateTemplate(template.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plantilla duplicada exitosamente')),
        );
        _loadTemplates();
      } catch (e) {
        AlertService.showError(context, 'Error', 'Error duplicando plantilla: $e');
      }
    }
  }

  void _setAsDefault(CertificateTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Establecer como Plantilla por Defecto'),
        content: Text('¿Estás seguro de que quieres establecer "${template.name}" como la plantilla por defecto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CertificateTemplateAdapter.setDefaultTemplate(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plantilla por defecto actualizada')),
        );
        _loadTemplates();
      } catch (e) {
        AlertService.showError(context, 'Error', 'Error: $e');
      }
    }
  }

  void _deleteTemplate(CertificateTemplate template) async {
    if (template.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se puede eliminar la plantilla por defecto')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Plantilla'),
        content: Text('¿Estás seguro de que quieres eliminar "${template.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CertificateTemplateAdapter.deleteTemplate(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plantilla eliminada exitosamente')),
        );
        _loadTemplates();
      } catch (e) {
        AlertService.showError(context, 'Error', 'Error eliminando plantilla: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Plantillas PDF'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewTemplate,
            tooltip: 'Crear Nueva Plantilla',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : _buildTemplatesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay plantillas creadas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Crea tu primera plantilla de certificado',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewTemplate,
            icon: Icon(Icons.add),
            label: Text('Crear Plantilla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return Column(
      children: [
        // Plantilla por defecto
        if (_defaultTemplate != null)
          _buildDefaultTemplateCard(_defaultTemplate!),
        
        // Lista de plantillas
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              return _buildTemplateCard(template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultTemplateCard(CertificateTemplate template) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC), Color(0xff9C27B0)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Plantilla por Defecto',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () => _generateAndDownloadPDF(template),
                tooltip: 'Generar PDF',
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () => _editTemplate(template),
                tooltip: 'Editar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(CertificateTemplate template) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xff6C4DDC),
                  child: Icon(
                    Icons.description,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        template.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (template.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'POR DEFECTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Creada: ${_formatDate(template.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndDownloadPDF(template),
                    icon: Icon(Icons.picture_as_pdf, size: 18),
                    label: Text('Generar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editTemplate(template),
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xff6C4DDC),
                      side: BorderSide(color: Color(0xff6C4DDC)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'duplicate':
                        _duplicateTemplate(template);
                        break;
                      case 'set_default':
                        _setAsDefault(template);
                        break;
                      case 'delete':
                        _deleteTemplate(template);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 8),
                          Text('Duplicar'),
                        ],
                      ),
                    ),
                    if (!template.isDefault)
                      PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 20),
                            SizedBox(width: 8),
                            Text('Establecer por Defecto'),
                          ],
                        ),
                      ),
                    if (!template.isDefault)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
