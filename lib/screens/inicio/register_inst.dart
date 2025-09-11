import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../header/HeaderRegisterStudent.dart';
import '../../services/image_upload_service.dart';

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
  final String website;
  final String description;
  final String logoUrl;
  final String documents;
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
    required this.website,
    required this.description,
    required this.logoUrl,
    required this.documents,
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
      'website': website,
      'description': description,
      'logoUrl': logoUrl,
      'documents': documents,
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
      website: map['website'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      documents: map['documents'] ?? '',
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
    await firestore
        .collection('institution_requests')
        .add(request.toMap());
    
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
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();

  String _selectedInstitutionType = 'university';
  String _selectedCountry = 'Colombia';
  bool _isLoading = false;

  final List<String> _institutionTypes = [
    'university',
    'college',
    'school',
    'institute',
    'academy',
    'other'
  ];

  final List<String> _countries = [
    'Colombia',
    'México',
    'Argentina',
    'Chile',
    'Perú',
    'Ecuador',
    'Venezuela',
    'Bolivia',
    'Uruguay',
    'Paraguay',
    'Brasil',
    'Estados Unidos',
    'España',
    'Otro'
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
    _cityController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logo subido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
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
          city: _cityController.text.trim(),
          country: _selectedCountry,
          website: _websiteController.text.trim(),
          description: _descriptionController.text.trim(),
          logoUrl: _logoUrlController.text.trim(),
          documents: 'pending_upload', // Placeholder
          requestedAt: DateTime.now(),
        );

        await registerInstitutionRequest(request);

        // Mostrar diálogo de confirmación
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('Solicitud Enviada'),
              ],
            ),
            content: const Text(
              'Tu solicitud de registro ha sido enviada exitosamente. '
              'Nuestro equipo la revisará y te contactaremos en un plazo de 2-3 días hábiles.\n\n'
              'Recibirás un email de confirmación en breve.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver al menú
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInstitutionTypeLabel(String type) {
    switch (type) {
      case 'university': return 'Universidad';
      case 'college': return 'Colegio';
      case 'school': return 'Escuela';
      case 'institute': return 'Instituto';
      case 'academy': return 'Academia';
      case 'other': return 'Otro';
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
      appBar: AppBar(
        title: const Text('Solicitud de Registro Institucional'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header personalizado
          const HeaderRegisterStudent(),
          
          // Indicador de progreso
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 3,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  '${_currentPage + 1}/3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),

          // Formulario con páginas
          Expanded(
        child: Form(
          key: _formKey,
              child: PageView(
                controller: _pageController,
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

          // Botones de navegación
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Anterior'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 15),
                Expanded(
                  child: _currentPage < 2
                      ? ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Siguiente'),
                        )
                      : ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
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
                              : const Text('Enviar Solicitud'),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Básica de la Institución',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _institutionNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre completo de la institución *',
              hintText: 'Ej: Universidad del Valle',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
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

          TextFormField(
            controller: _shortNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre corto o sigla *',
              hintText: 'Ej: UV, UdeA, UIS',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.text_fields),
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
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedInstitutionType,
            decoration: const InputDecoration(
              labelText: 'Tipo de institución *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
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
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción de la institución *',
              hintText: 'Breve descripción de los servicios académicos que ofrece',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es requerida';
              }
              if (value.trim().length < 20) {
                return 'La descripción debe tener al menos 20 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de Contacto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _contactNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del contacto principal *',
              hintText: 'Ej: Juan Pérez',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre del contacto es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

              TextFormField(
            controller: _contactEmailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico de contacto *',
              hintText: 'Ej: admin@universidad.edu.co',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
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
              const SizedBox(height: 16),

              TextFormField(
            controller: _contactPhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono de contacto *',
              hintText: 'Ej: +57 2 3212100',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El teléfono es requerido';
              }
              return null;
            },
              ),
              const SizedBox(height: 16),

              TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección *',
              hintText: 'Ej: Calle 13 #100-00',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La dirección es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad *',
                    hintText: 'Ej: Cali',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La ciudad es requerida';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'País *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: _countries.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              labelText: 'Sitio web',
              hintText: 'Ej: https://www.universidad.edu.co',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.web),
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
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 20),

          // Logo upload section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logo de la Institución',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[700],
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
          const SizedBox(height: 20),

          TextFormField(
            controller: _logoUrlController,
            decoration: const InputDecoration(
              labelText: 'URL del logo (alternativa)',
              hintText: 'https://ejemplo.com/logo.png',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                // Permitir URLs HTTP/HTTPS válidas
                if (value.startsWith('http://') || value.startsWith('https://')) {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasAbsolutePath) {
                    return 'Ingrese una URL válida';
                  }
                }
                // Permitir data URLs (Base64) para nuestra solución temporal
                else if (value.startsWith('data:image/')) {
                  // Validar que sea una data URL válida
                  if (!value.contains('base64,')) {
                    return 'Formato de imagen no válido';
                  }
                }
                // Cualquier otro formato no es válido
                else {
                  return 'Ingrese una URL válida o seleccione una imagen';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Terms and conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Términos y Condiciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
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