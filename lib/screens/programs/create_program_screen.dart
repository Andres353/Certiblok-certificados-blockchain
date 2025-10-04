// lib/screens/programs/create_program_screen.dart
// Pantalla para crear nuevos programas

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/programs_opportunities_service.dart';
import '../../services/user_context_service.dart';
import '../../services/image_upload_service.dart';

class CreateProgramScreen extends StatefulWidget {
  @override
  _CreateProgramScreenState createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _maxApplicationsController = TextEditingController();
  
  DateTime? _selectedDeadline;
  Set<String> _selectedCareerIds = <String>{};
  List<String> _requirements = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Archivos
  String? _imageUrl;
  String? _pdfUrl;
  String? _pdfFileName;
  String? _pdfData; // Base64 puro del PDF (igual que certificados)
  bool _isUploadingImage = false;
  bool _isUploadingPdf = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _maxApplicationsController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadInstitutionCareers() async {
    try {
      final context = UserContextService.currentContext;
      if (context?.institutionId == null) {
        return [];
      }

      // Cargar carreras específicas de la institución desde Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('programs')
          .where('institutionId', isEqualTo: context!.institutionId)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } catch (e) {
      print('Error cargando carreras de la institución: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Programa'),
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
                      // Información básica
                      _buildBasicInfoSection(isWeb),
                      
                      SizedBox(height: 24),
                      
                      // Selección de carrera
                      _buildCareerSection(isWeb),
                      
                      SizedBox(height: 24),
                      
                      // Fecha límite y cupos
                      _buildDateAndSlotsSection(isWeb),
                      
                      SizedBox(height: 24),
                      
                      // Requisitos
                      _buildRequirementsSection(isWeb),
                      
                      SizedBox(height: 24),
                      
                      // Archivos
                      _buildFilesSection(isWeb),
                      
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

  Widget _buildBasicInfoSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            
            // Título
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del Programa *',
                hintText: 'Ej: Pasantía en Desarrollo de Software',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xff6C4DDC)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título es obligatorio';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              maxLines: isWeb ? 6 : 4,
              decoration: InputDecoration(
                labelText: 'Descripción *',
                hintText: 'Describe el programa, sus objetivos y beneficios...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xff6C4DDC)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carreras Disponibles',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Selecciona las carreras que pueden participar en esta pasantía',
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            
            // Selección de carrera
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadInstitutionCareers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Error al cargar carreras: ${snapshot.error}');
                }
                
                final careers = snapshot.data ?? [];
                
                if (careers.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[600]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No hay carreras registradas en tu institución. Primero debes agregar carreras desde el panel de administración.',
                            style: TextStyle(color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Container(
                  height: isWeb ? 200 : 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: careers.length,
                    itemBuilder: (context, index) {
                      final career = careers[index];
                      final careerId = career['id'] as String;
                      final isSelected = _selectedCareerIds.contains(careerId);
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Color(0xff6C4DDC).withOpacity(0.1)
                              : Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedCareerIds.add(careerId);
                              } else {
                                _selectedCareerIds.remove(careerId);
                              }
                            });
                          },
                          title: Text(
                            career['name'],
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Color(0xff6C4DDC) : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'Carrera académica',
                            style: TextStyle(
                              fontSize: isWeb ? 12 : 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          activeColor: Color(0xff6C4DDC),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            
            // Indicador de carreras seleccionadas
            if (_selectedCareerIds.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedCareerIds.length} carrera${_selectedCareerIds.length > 1 ? 's' : ''} seleccionada${_selectedCareerIds.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 14 : 12,
                        ),
                      ),
                    ),
                    if (_selectedCareerIds.length > 1)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCareerIds.clear();
                          });
                        },
                        child: Text(
                          'Limpiar',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: isWeb ? 12 : 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildDateAndSlotsSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha Límite y Cupos',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDeadline,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                          SizedBox(width: 12),
                          Text(
                            _selectedDeadline != null
                                ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                                : 'Seleccionar fecha límite *',
                            style: TextStyle(
                              color: _selectedDeadline != null ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxApplicationsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cupos Máximos *',
                      hintText: 'Ej: 50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xff6C4DDC)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Los cupos son obligatorios';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Ingresa un número válido';
                      }
                      return null;
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

  Widget _buildRequirementsSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requisitos',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            
            // Lista de requisitos
            if (_requirements.isNotEmpty) ...[
              ..._requirements.asMap().entries.map((entry) {
                final index = entry.key;
                final requirement = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          requirement,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeRequirement(index),
                        icon: Icon(Icons.close, size: 20, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 16),
            ],
            
            // Agregar nuevo requisito
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _requirementsController,
                    decoration: InputDecoration(
                      hintText: 'Agregar requisito...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xff6C4DDC)),
                      ),
                    ),
                    onFieldSubmitted: (_) => _addRequirement(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _addRequirement,
                  icon: Icon(Icons.add, color: Color(0xff6C4DDC)),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archivos (Opcional)',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            
            // Imagen
            _buildImageUploadSection(isWeb),
            
            SizedBox(height: 16),
            
            // PDF
            _buildPdfUploadSection(isWeb),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen de la Pasantía',
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff2E2F44),
          ),
        ),
        SizedBox(height: 8),
        
        if (_imageUrl != null) ...[
          Container(
            height: isWeb ? 200 : 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickImage,
                  icon: _isUploadingImage 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.edit, size: 16),
                  label: Text(_isUploadingImage ? 'Subiendo...' : 'Cambiar Imagen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _imageUrl = null;
                  });
                },
                icon: Icon(Icons.delete, size: 16),
                label: Text('Eliminar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            height: isWeb ? 120 : 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: _isUploadingImage ? null : _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isUploadingImage
                      ? CircularProgressIndicator()
                      : Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                  SizedBox(height: 8),
                  Text(
                    _isUploadingImage ? 'Subiendo imagen...' : 'Toca para agregar imagen',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPdfUploadSection(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF con Información',
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff2E2F44),
          ),
        ),
        SizedBox(height: 8),
        
        if (_pdfUrl != null) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pdfFileName ?? 'Documento PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 14 : 12,
                        ),
                      ),
                      Text(
                        'PDF subido correctamente',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: isWeb ? 12 : 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _pdfUrl = null;
                      _pdfFileName = null;
                    });
                  },
                  icon: Icon(Icons.delete, color: Colors.red[600]),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            height: isWeb ? 80 : 60,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: _isUploadingPdf ? null : _pickPdf,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isUploadingPdf
                      ? CircularProgressIndicator()
                      : Icon(Icons.upload_file, size: 30, color: Colors.grey[600]),
                  SizedBox(height: 4),
                  Text(
                    _isUploadingPdf ? 'Subiendo PDF...' : 'Toca para subir PDF',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(bool isWeb) {
    return SizedBox(
      width: double.infinity,
      height: isWeb ? 56 : 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitProgram,
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.save, size: isWeb ? 20 : 18),
        label: Text(
          _isSubmitting ? 'Creando...' : 'Crear Programa',
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

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDeadline = date;
      });
    }
  }

  void _addRequirement() {
    final requirement = _requirementsController.text.trim();
    if (requirement.isNotEmpty) {
      setState(() {
        _requirements.add(requirement);
        _requirementsController.clear();
      });
    }
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _uploadImage(file.bytes!, file.name);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _uploadPdf(file.bytes!, file.name);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar PDF: $e');
    }
  }

  Future<void> _uploadImage(Uint8List bytes, String fileName) async {
    setState(() => _isUploadingImage = true);

    try {
      final context = UserContextService.currentContext;
      if (context?.institutionId == null) {
        throw Exception('Usuario no autenticado');
      }

      print('🔄 Iniciando subida de imagen: $fileName');
      print('📊 Tamaño del archivo: ${bytes.length} bytes');

      // Usar el servicio real de subida de imágenes
      final imageUrl = await ImageUploadService.uploadImageBytes(
        bytes,
        'program_images/${context!.institutionId}_${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      
      print('✅ Imagen subida exitosamente');
      print('🔗 URL: $imageUrl');

      setState(() {
        _imageUrl = imageUrl;
        _isUploadingImage = false;
      });

      _showSuccessSnackBar('Imagen subida correctamente');
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar('Error al subir imagen: $e');
    }
  }

  Future<void> _uploadPdf(Uint8List bytes, String fileName) async {
    setState(() => _isUploadingPdf = true);

    try {
      final context = UserContextService.currentContext;
      if (context?.institutionId == null) {
        throw Exception('Usuario no autenticado');
      }

      print('🔄 Iniciando subida de PDF: $fileName');
      print('📊 Tamaño del archivo: ${bytes.length} bytes');

      // Procesar PDF usando el mismo método que certificados (base64 puro)
      final pdfData = await ImageUploadService.uploadPdfBytes(
        bytes,
        'program_pdfs/${context!.institutionId}_${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      
      print('✅ PDF procesado exitosamente');
      print('🔗 Base64 generado: ${pdfData.substring(0, 100)}...');

      setState(() {
        _pdfData = pdfData; // Almacenar base64 puro
        _pdfFileName = fileName;
        _isUploadingPdf = false;
      });

      _showSuccessSnackBar('PDF subido correctamente');
    } catch (e) {
      print('❌ Error al subir PDF: $e');
      setState(() => _isUploadingPdf = false);
      _showErrorSnackBar('Error al subir PDF: $e');
    }
  }

  Future<void> _submitProgram() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDeadline == null) {
      _showErrorSnackBar('Selecciona una fecha límite');
      return;
    }

    if (_requirements.isEmpty) {
      _showErrorSnackBar('Agrega al menos un requisito');
      return;
    }

    if (_selectedCareerIds.isEmpty) {
      _showErrorSnackBar('Selecciona al menos una carrera');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener información de carreras de la institución
      final careers = await _loadInstitutionCareers();
      
      final selectedCareers = careers.where(
        (c) => _selectedCareerIds.contains(c['id']),
      ).toList();
      
      final careerIds = selectedCareers.map((c) => c['id'] as String).toList();
      final careerNames = selectedCareers.map((c) => c['name'] as String).toList();

      await ProgramsOpportunitiesService.createProgramOpportunity(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        institutionId: context.institutionId ?? '',
        institutionName: context.institutionName ?? 'Institución',
        facultyId: '', // Ya no se usa facultad
        facultyName: '', // Ya no se usa facultad
        careerIds: careerIds,
        careerNames: careerNames,
        requirements: _requirements,
        applicationDeadline: _selectedDeadline!,
        maxApplications: int.parse(_maxApplicationsController.text),
        createdBy: context.userId,
        createdByName: context.userName,
        imageUrl: _imageUrl,
        pdfUrl: _pdfUrl,
        pdfFileName: _pdfFileName,
        pdfData: _pdfData,
      );

      _showSuccessDialog();
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Error al crear programa: $e');
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
            Text('¡Programa Creado!'),
          ],
        ),
        content: Text('El programa ha sido creado exitosamente.'),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
