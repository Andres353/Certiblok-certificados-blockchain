// lib/screens/certificates/template_management_screen.dart
// Pantalla de gestión de plantillas de certificados

import 'package:flutter/material.dart';
import '../../services/certificate_template_service.dart';
import '../../services/user_context_service.dart';
import '../../models/certificate_template.dart';
import 'advanced_template_editor_screen.dart';

class TemplateManagementScreen extends StatefulWidget {
  @override
  _TemplateManagementScreenState createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  bool _isLoading = true;
  List<CertificateTemplate> _templates = [];
  CertificateTemplate? _defaultTemplate;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Cargando plantillas...');
      _templates = await CertificateTemplateService.getTemplates();
      print('✅ Plantillas cargadas: ${_templates.length}');
      
      _defaultTemplate = await CertificateTemplateService.getDefaultTemplate();
      print('✅ Plantilla por defecto: ${_defaultTemplate?.name ?? "Ninguna"}');
      
      // Si no hay plantillas, crear una por defecto
      if (_templates.isEmpty) {
        print('🔄 No hay plantillas, creando plantilla por defecto...');
        try {
          await CertificateTemplateService.createDefaultTemplate(
            UserContextService.currentContext?.institutionId ?? 'default'
          );
          // Recargar plantillas después de crear la por defecto
          _templates = await CertificateTemplateService.getTemplates();
          _defaultTemplate = await CertificateTemplateService.getDefaultTemplate();
          print('✅ Plantilla por defecto creada');
        } catch (e) {
          print('❌ Error creando plantilla por defecto: $e');
        }
      }
    } catch (e) {
      print('❌ Error cargando plantillas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando plantillas: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
        await CertificateTemplateService.duplicateTemplate(template.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plantilla duplicada exitosamente')),
        );
        _loadTemplates();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicando plantilla: $e')),
        );
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
        await CertificateTemplateService.setDefaultTemplate(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plantilla por defecto actualizada')),
        );
        _loadTemplates();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        await CertificateTemplateService.deleteTemplate(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plantilla eliminada exitosamente')),
        );
        _loadTemplates();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando plantilla: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Plantillas'),
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
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editTemplate(template),
            tooltip: 'Editar',
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(CertificateTemplate template) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xff6C4DDC),
          child: Icon(
            Icons.description,
            color: Colors.white,
          ),
        ),
        title: Text(
          template.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Creada: ${_formatDate(template.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (template.isDefault) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC),
                      borderRadius: BorderRadius.circular(10),
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
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editTemplate(template);
                break;
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
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
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
        onTap: () => _editTemplate(template),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
