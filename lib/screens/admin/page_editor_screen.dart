// lib/screens/admin/page_editor_screen.dart
// Pantalla para editar información de la página principal

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/alert_service.dart';

class PageEditorScreen extends StatefulWidget {
  @override
  _PageEditorScreenState createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _welcomeMessageController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _pageData = {};

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _welcomeMessageController.dispose();
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _companyWebsiteController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('page_content')
          .doc('main_page')
          .get();
      
      if (doc.exists) {
        _pageData = doc.data()!;
        _populateControllers();
      } else {
        // Crear datos por defecto si no existen
        _pageData = _getDefaultPageData();
        _populateControllers();
      }
    } catch (e) {
      print('❌ Error cargando datos de página: $e');
      AlertService.showError(context, 'Error', 'Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getDefaultPageData() {
    return {
      'title': 'Bienvenido a Certiblock',
      'description': 'Esta plataforma permite registrar y validar certificados académicos a través de la tecnología Blockchain, garantizando seguridad y trazabilidad.',
      'welcomeMessage': 'Bienvenido a nuestra plataforma de certificados digitales',
      'companyName': 'Certiblock',
      'companyDescription': 'Plataforma líder en certificados digitales con tecnología Blockchain',
      'companyWebsite': 'https://certiblock.com',
      'companyEmail': 'info@certiblock.com',
      'companyPhone': '+1 (555) 123-4567',
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  void _populateControllers() {
    _titleController.text = _pageData['title'] ?? '';
    _descriptionController.text = _pageData['description'] ?? '';
    _welcomeMessageController.text = _pageData['welcomeMessage'] ?? '';
    _companyNameController.text = _pageData['companyName'] ?? '';
    _companyDescriptionController.text = _pageData['companyDescription'] ?? '';
    _companyWebsiteController.text = _pageData['companyWebsite'] ?? '';
    _companyEmailController.text = _pageData['companyEmail'] ?? '';
    _companyPhoneController.text = _pageData['companyPhone'] ?? '';
  }

  Future<void> _savePageData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'welcomeMessage': _welcomeMessageController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'companyDescription': _companyDescriptionController.text.trim(),
        'companyWebsite': _companyWebsiteController.text.trim(),
        'companyEmail': _companyEmailController.text.trim(),
        'companyPhone': _companyPhoneController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('page_content')
          .doc('main_page')
          .set(updatedData, SetOptions(merge: true));

      AlertService.showSuccess(context, 'Éxito', 'Información de página actualizada correctamente');
    } catch (e) {
      print('❌ Error guardando datos: $e');
      AlertService.showError(context, 'Error', 'Error guardando datos: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor de Página'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _savePageData,
            icon: _isSaving 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.save),
            tooltip: 'Guardar Cambios',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información General
                    _buildSectionCard(
                      'Información General',
                      Icons.info,
                      [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Título Principal',
                          hint: 'Bienvenido a Certiblock',
                          validator: (value) => value?.isEmpty == true ? 'El título es obligatorio' : null,
                        ),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Descripción Principal',
                          hint: 'Descripción de la plataforma...',
                          maxLines: 3,
                          validator: (value) => value?.isEmpty == true ? 'La descripción es obligatoria' : null,
                        ),
                        _buildTextField(
                          controller: _welcomeMessageController,
                          label: 'Mensaje de Bienvenida',
                          hint: 'Mensaje de bienvenida...',
                          maxLines: 2,
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Información de la Empresa
                    _buildSectionCard(
                      'Información de la Empresa',
                      Icons.business,
                      [
                        _buildTextField(
                          controller: _companyNameController,
                          label: 'Nombre de la Empresa',
                          hint: 'Certiblock',
                          validator: (value) => value?.isEmpty == true ? 'El nombre es obligatorio' : null,
                        ),
                        _buildTextField(
                          controller: _companyDescriptionController,
                          label: 'Descripción de la Empresa',
                          hint: 'Descripción de la empresa...',
                          maxLines: 3,
                        ),
                        _buildTextField(
                          controller: _companyWebsiteController,
                          label: 'Sitio Web',
                          hint: 'https://certiblock.com',
                        ),
                        _buildTextField(
                          controller: _companyEmailController,
                          label: 'Email de Contacto',
                          hint: 'info@certiblock.com',
                        ),
                        _buildTextField(
                          controller: _companyPhoneController,
                          label: 'Teléfono de Contacto',
                          hint: '+1 (555) 123-4567',
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Botón de Guardar
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _savePageData,
                        icon: _isSaving 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.save),
                        label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xff6C4DDC)),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xff6C4DDC)),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
