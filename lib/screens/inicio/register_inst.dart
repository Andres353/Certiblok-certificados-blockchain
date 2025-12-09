import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../header/HeaderRegisterInstitution.dart';
import '../../services/image_upload_service.dart';
import '../../services/adapters/institution_request_adapter.dart';
import '../../services/alert_service.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class InstitutionRequest {
  final String id;
  final String institutionName;
  final String shortName;
  final String institutionType;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final String city;
  final String country;
  final String department;
  final String website;
  final String description;
  final String logoUrl;
  final String documents;
  final String ruc; // RUC (Registro Único de Contribuyente) - Bolivia
  final String ministerialResolution; // Número de Resolución Ministerial - Bolivia
  final String status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  InstitutionRequest({
    required this.id,
    required this.institutionName,
    required this.shortName,
    required this.institutionType,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    required this.city,
    required this.country,
    required this.department,
    required this.website,
    required this.description,
    required this.logoUrl,
    required this.documents,
    required this.ruc,
    required this.ministerialResolution,
    this.status = 'pending',
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'institutionName': institutionName,
      'shortName': shortName,
      'institutionType': institutionType,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'city': city,
      'country': country,
      'department': department,
      'website': website,
      'description': description,
      'logoUrl': logoUrl,
      'documents': documents,
      'ruc': ruc,
      'ministerialResolution': ministerialResolution,
      'status': status,
      'requestedAt': requestedAt,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'rejectionReason': rejectionReason,
    };
  }

  static InstitutionRequest fromMap(Map<String, dynamic> map, String id) {
    return InstitutionRequest(
      id: id,
      institutionName: map['institutionName'] ?? '',
      shortName: map['shortName'] ?? '',
      institutionType: map['institutionType'] ?? '',
      contactName: map['contactName'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      department: map['department'] ?? '',
      website: map['website'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      documents: map['documents'] ?? '',
      ruc: map['ruc'] ?? '',
      ministerialResolution: map['ministerialResolution'] ?? '',
      status: map['status'] ?? 'pending',
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null 
          ? (map['reviewedAt'] as Timestamp).toDate() 
          : null,
      rejectionReason: map['rejectionReason'],
    );
  }
}

// Función para registrar solicitud de institución
Future<void> registerInstitutionRequest(InstitutionRequest request) async {
  try {
    // Usar el adaptador para registrar en Firebase o Supabase según configuración
    await InstitutionRequestAdapter.createRequest(
      institutionName: request.institutionName,
      shortName: request.shortName,
      institutionType: request.institutionType,
      contactName: request.contactName,
      contactEmail: request.contactEmail,
      contactPhone: request.contactPhone,
      address: request.address,
      city: request.city,
      country: request.country,
      department: request.department,
      website: request.website,
      description: request.description,
      logoUrl: request.logoUrl,
      documents: request.documents,
      ruc: request.ruc,
      ministerialResolution: request.ministerialResolution,
    );
    
    print('Solicitud de institución registrada exitosamente');
  } catch (e) {
    print('Error al registrar la solicitud: $e');
    rethrow;
  }
}

class RegisterInst extends StatefulWidget {
  const RegisterInst({super.key});

  @override
  State<RegisterInst> createState() => _RegisterInstState();
}

class _RegisterInstState extends State<RegisterInst> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controladores de texto
  final TextEditingController _institutionNameController = TextEditingController();
  final TextEditingController _shortNameController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _rucController = TextEditingController();
  final TextEditingController _ministerialResolutionController = TextEditingController();

  String _selectedInstitutionType = 'universidad';
  String _selectedDepartment = 'La Paz';
  bool _isLoading = false;

  final List<String> _institutionTypes = [
    'universidad',
    'instituto',
  ];

  final List<String> _departments = [
    'La Paz',
    'Cochabamba',
    'Santa Cruz',
    'Potosí',
    'Oruro',
    'Chuquisaca',
    'Tarija',
    'Beni',
    'Pando',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _institutionNameController.dispose();
    _shortNameController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _rucController.dispose();
    _ministerialResolutionController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      // En web solo mostrar galería, en móvil mostrar ambas opciones
      if (kIsWeb) {
        await _selectImageFromSource(ImageSource.gallery);
      } else {
        // Mostrar opciones de selección para móvil
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Galería'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _selectImageFromSource(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('Cámara'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _selectImageFromSource(ImageSource.camera);
                    },
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _selectImageFromSource(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      
      String? imageUrl;
      
      if (source == ImageSource.camera) {
        imageUrl = await ImageUploadService.pickAndUploadImageFromCamera(
          folder: 'institution_logos',
          maxWidth: 800,
          maxHeight: 800,
          quality: 85,
        );
      } else {
        imageUrl = await ImageUploadService.pickAndUploadImage(
          folder: 'institution_logos',
          maxWidth: 800,
          maxHeight: 800,
          quality: 85,
        );
      }

      if (imageUrl != null) {
        setState(() {
          _logoUrlController.text = imageUrl!;
        });
        
        AlertService.showSuccess(
          context,
          'Logo Subido',
          'El logo de la institución se ha subido exitosamente.',
        );
      }
    } catch (e) {
      AlertService.showError(
        context,
        'Error al Subir Logo',
        'No se pudo subir el logo: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateCurrentPage() {
    // Validar campos según la página actual
    if (_currentPage == 0) {
      // Página 1: Información Básica
      if (_institutionNameController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'El nombre completo de la institución es obligatorio',
        );
        return false;
      }
      if (_institutionNameController.text.trim().length < 3) {
        AlertService.showError(
          context,
          'Campo Inválido',
          'El nombre debe tener al menos 3 caracteres',
        );
        return false;
      }
      if (_shortNameController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'El nombre corto o sigla es obligatorio',
        );
        return false;
      }
      if (_shortNameController.text.trim().length < 2) {
        AlertService.showError(
          context,
          'Campo Inválido',
          'El nombre corto debe tener al menos 2 caracteres',
        );
        return false;
      }
      if (_rucController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'El RUC es obligatorio',
        );
        return false;
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(_rucController.text.trim())) {
        AlertService.showError(
          context,
          'Campo Inválido',
          'El RUC solo puede contener números',
        );
        return false;
      }
      if (_rucController.text.trim().length < 8) {
        AlertService.showError(
          context,
          'Campo Inválido',
          'El RUC debe tener al menos 8 dígitos',
        );
        return false;
      }
      if (_ministerialResolutionController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'El número de resolución ministerial es obligatorio',
        );
        return false;
      }
      if (_ministerialResolutionController.text.trim().length < 5) {
        AlertService.showError(
          context,
          'Campo Inválido',
          'El número de resolución debe tener al menos 5 caracteres',
        );
        return false;
      }
      // Validar descripción solo si tiene contenido
      if (_descriptionController.text.trim().isNotEmpty && 
          _descriptionController.text.trim().length < 20) {
        AlertService.showError(
          context,
          'Campo Inválido',
          'La descripción debe tener al menos 20 caracteres',
        );
        return false;
      }
      return true;
    } else if (_currentPage == 1) {
      // Página 2: Información de Contacto
      if (_contactNameController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'El nombre del contacto es obligatorio',
        );
        return false;
      }
      if (_contactEmailController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'El correo electrónico es obligatorio',
        );
        return false;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_contactEmailController.text.trim())) {
        AlertService.showError(
          context,
          'Campo Inválido',
          'Ingrese un correo electrónico válido',
        );
        return false;
      }
      if (_contactPhoneController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'El teléfono es obligatorio',
        );
        return false;
      }
      if (_addressController.text.trim().isEmpty) {
        AlertService.showError(
          context,
          'Campo Requerido',
          'La dirección es obligatoria',
        );
        return false;
      }
      // Validar sitio web solo si tiene contenido
      if (_websiteController.text.trim().isNotEmpty) {
        final uri = Uri.tryParse(_websiteController.text.trim());
        if (uri == null || !uri.hasAbsolutePath) {
          AlertService.showError(
            context,
            'Campo Inválido',
            'Ingrese una URL válida',
          );
          return false;
        }
      }
      return true;
    }
    // Página 3 no necesita validación (todos los campos son opcionales)
    return true;
  }

  void _nextPage() {
    if (_currentPage < 2) {
      // Validar campos del paso actual antes de avanzar
      if (!_validateCurrentPage()) {
        return; // No avanzar si hay errores
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final request = InstitutionRequest(
          id: '',
          institutionName: _institutionNameController.text.trim(),
          shortName: _shortNameController.text.trim(),
          institutionType: _selectedInstitutionType,
          contactName: _contactNameController.text.trim(),
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          address: _addressController.text.trim(),
          city: '', // Ciudad eliminada del formulario
          country: 'Bolivia',
          department: _selectedDepartment,
          website: _websiteController.text.trim(),
          description: _descriptionController.text.trim(),
          logoUrl: _logoUrlController.text.trim(),
          documents: 'pending_upload', // Placeholder
          ruc: _rucController.text.trim(),
          ministerialResolution: _ministerialResolutionController.text.trim(),
          requestedAt: DateTime.now(),
        );

        await registerInstitutionRequest(request);

        // Mostrar SweetAlert de confirmación
        AlertService.showSuccess(
          context,
          'Solicitud Enviada',
          'Tu solicitud de registro ha sido enviada exitosamente.\n\n'
          'Nuestro equipo la revisará y te contactaremos en un plazo de 2-3 días hábiles.\n\n'
          'Recibirás un email de confirmación en breve.',
          onOk: () {
            Navigator.of(context).pop(); // Volver al menú
          },
        );

      } catch (e) {
        AlertService.showError(
          context,
          'Error al Enviar Solicitud',
          'No se pudo enviar la solicitud de registro: $e',
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInstitutionTypeLabel(String type) {
    switch (type) {
      case 'universidad': return 'Universidad';
      case 'instituto': return 'Instituto';
      default: return type;
    }
  }

  Widget _buildImageWidget(String imageUrl) {
    // Si es una data URL (Base64), usar Image.memory
    if (imageUrl.startsWith('data:image/')) {
      try {
        // Extraer la parte base64 de la data URL
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[100],
              child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[100],
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      }
    }
    // Si es una URL HTTP/HTTPS, usar Image.network
    else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Solicitud de Registro Institucional'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header personalizado
          const HeaderRegisterInstitution(),
          
          // Indicador de progreso mejorado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paso ${_currentPage + 1} de 3',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff6C4DDC),
                            ),
                          ),
                          Text(
                            '${((_currentPage + 1) / 3 * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff6C4DDC),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / 3,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Formulario con páginas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(), // Deshabilitar scroll manual
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildPage1(), // Información básica
                    _buildPage2(), // Información de contacto
                    _buildPage3(), // Información adicional
                  ],
                ),
              ),
            ),
          ),

          // Botones de navegación mejorados
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xff6C4DDC), width: 2),
                        foregroundColor: Color(0xff6C4DDC),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Anterior',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 15),
                Expanded(
                  flex: _currentPage < 2 ? 1 : 1,
                  child: _currentPage < 2
                      ? ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff6C4DDC),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Siguiente',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff4CAF50),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Enviar Solicitud',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC).withOpacity(0.1), Color(0xff8B7DDC).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.school, color: Color(0xff6C4DDC), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Información Básica de la Institución',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff6C4DDC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Nombre completo (ancho completo)
          TextFormField(
            controller: _institutionNameController,
            decoration: InputDecoration(
              labelText: 'Nombre completo de la institución *',
              hintText: 'Ej: Universidad Mayor de San Andrés',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.school, color: Color(0xff6C4DDC)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre de la institución es requerido';
              }
              if (value.trim().length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Nombre corto y Tipo en 2 columnas
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _shortNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre corto o sigla *',
                    hintText: 'Ej: UMSA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.text_fields, color: Color(0xff6C4DDC)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre corto es requerido';
                    }
                    if (value.trim().length < 2) {
                      return 'El nombre corto debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedInstitutionType,
                  decoration: InputDecoration(
                    labelText: 'Tipo *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.category, color: Color(0xff6C4DDC)),
                  ),
                  items: _institutionTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getInstitutionTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInstitutionType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripción de la institución (opcional)',
              hintText: 'Breve descripción de los servicios académicos que ofrece',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.description, color: Color(0xff6C4DDC)),
            ),
            maxLines: 3,
            validator: (value) {
              // Si hay contenido, debe tener al menos 20 caracteres
              if (value != null && value.trim().isNotEmpty && value.trim().length < 20) {
                return 'La descripción debe tener al menos 20 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // RUC y Resolución Ministerial en 2 columnas
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rucController,
                  decoration: InputDecoration(
                    labelText: 'RUC *',
                    hintText: 'Ej: 1234567890123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.badge, color: Color(0xff6C4DDC)),
                    helperText: 'Registro Único de Contribuyente',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El RUC es requerido';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'El RUC solo puede contener números';
                    }
                    if (value.trim().length < 8) {
                      return 'El RUC debe tener al menos 8 dígitos';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _ministerialResolutionController,
                  decoration: InputDecoration(
                    labelText: 'Resolución Ministerial *',
                    hintText: 'Ej: RES-2024-001234',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.verified, color: Color(0xff6C4DDC)),
                    helperText: 'Número de resolución',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El número de resolución ministerial es requerido';
                    }
                    if (value.trim().length < 5) {
                      return 'El número de resolución debe tener al menos 5 caracteres';
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

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC).withOpacity(0.1), Color(0xff8B7DDC).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.contact_mail, color: Color(0xff6C4DDC), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Información de Contacto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff6C4DDC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nombre del contacto y Email en 2 columnas
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _contactNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del contacto *',
                    hintText: 'Ej: Juan Pérez',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.person, color: Color(0xff6C4DDC)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre del contacto es requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _contactEmailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico *',
                    hintText: 'Ej: admin@umsa.bo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.email, color: Color(0xff6C4DDC)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo electrónico es requerido';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Ingrese un correo electrónico válido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Teléfono y Dirección en 2 columnas
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _contactPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono *',
                    hintText: 'Ej: +591 2 2441555',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.phone, color: Color(0xff6C4DDC)),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El teléfono es requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección *',
                    hintText: 'Ej: Av. Villazón Nro. 1995',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.location_on, color: Color(0xff6C4DDC)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La dirección es requerida';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Departamento y Sitio web en 2 columnas
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: 'Departamento *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.map, color: Color(0xff6C4DDC)),
                  ),
                  items: _departments.map((department) {
                    return DropdownMenuItem(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: 'Sitio web',
                    hintText: 'Ej: https://www.umsa.bo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xff6C4DDC), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.web, color: Color(0xff6C4DDC)),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasAbsolutePath) {
                        return 'Ingrese una URL válida';
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

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC).withOpacity(0.1), Color(0xff8B7DDC).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xff6C4DDC), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Información Adicional',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff6C4DDC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logo upload section mejorado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3), width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff6C4DDC).withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.image, color: Color(0xff6C4DDC), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Logo de la Institución',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xff6C4DDC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sube el logo oficial de tu institución (opcional)',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                if (_logoUrlController.text.isNotEmpty)
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageWidget(_logoUrlController.text),
                    ),
                  )
                else
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload),
                      label: const Text('Seleccionar Logo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
                        foregroundColor: Color(0xff6C4DDC),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Color(0xff6C4DDC).withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_logoUrlController.text.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _logoUrlController.clear();
                          });
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Terms and conditions mejorado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC).withOpacity(0.08), Color(0xff8B7DDC).withOpacity(0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3), width: 1.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff6C4DDC).withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xff6C4DDC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.info, color: Color(0xff6C4DDC), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xff6C4DDC),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Al enviar esta solicitud, confirmas que la información proporcionada es veraz y completa.\n'
                  '• Tu solicitud será revisada por nuestro equipo en un plazo de 2-3 días hábiles.\n'
                  '• Te contactaremos al correo electrónico proporcionado para confirmar la aprobación.\n'
                  '• Una vez aprobada, podrás configurar tu institución y comenzar a usar el sistema.\n'
                  '• Nos reservamos el derecho de rechazar solicitudes que no cumplan con nuestros criterios.',
                  style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}