// lib/widgets/basic_items_list_widget.dart
// Widget básico para mostrar lista de elementos sin comparaciones complejas

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_context_service.dart';

class BasicItemsListWidget extends StatefulWidget {
  final String type; // 'faculties' o 'programs'
  final Function(Map<String, dynamic>) onItemSelected;
  final String searchQuery;
  final BasicItemsListWidgetController? controller;

  const BasicItemsListWidget({
    Key? key,
    required this.type,
    required this.onItemSelected,
    this.searchQuery = '',
    this.controller,
  }) : super(key: key);

  @override
  _BasicItemsListWidgetState createState() => _BasicItemsListWidgetState();
}

// Clase para acceder a los métodos del widget
class BasicItemsListWidgetController {
  _BasicItemsListWidgetState? _state;
  
  void _attachState(_BasicItemsListWidgetState state) {
    _state = state;
  }
  
  void reload() {
    _state?._loadItems();
  }
}

class _BasicItemsListWidgetState extends State<BasicItemsListWidget> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late BasicItemsListWidgetController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _controller._attachState(this);
    } else {
      _controller = BasicItemsListWidgetController();
      _controller._attachState(this);
    }
    _loadItems();
  }

  @override
  void didUpdateWidget(BasicItemsListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userContext = UserContextService.currentContext;
      if (userContext == null || userContext.institutionId == null) {
        setState(() {
          _errorMessage = 'No se pudo obtener el contexto de institución';
          _isLoading = false;
        });
        return;
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String institutionId = userContext.institutionId!;
      
      List<Map<String, dynamic>> items = [];
      
       if (widget.type == 'faculties') {
         // Obtener todas las facultades activas
         QuerySnapshot querySnapshot = await firestore
             .collection('faculties')
             .where('status', isEqualTo: 'active')
             .get();

         items = querySnapshot.docs.map((doc) {
           final data = doc.data() as Map<String, dynamic>;
           return {
             'id': doc.id,
             'name': data['name'] ?? 'Sin nombre',
             'code': data['code'] ?? '',
             'description': data['description'] ?? '',
             'institutionId': data['institutionId'] ?? '',
             'institutionName': data['institutionName'] ?? '',
             'programsCount': data['programsCount'] ?? 0,
             'status': data['status'] ?? 'active',
           };
         }).toList();
         
         // Filtrar las que no pertenecen a la institución actual
         items = items.where((faculty) {
           final facultyInstitutionId = faculty['institutionId'];
           return facultyInstitutionId != null && facultyInstitutionId != institutionId;
         }).toList();
         
       } else if (widget.type == 'programs') {
         // Obtener solo las carreras globales (isGlobal: true)
         QuerySnapshot querySnapshot = await firestore
             .collection('programs')
             .where('status', isEqualTo: 'active')
             .where('isGlobal', isEqualTo: true)
             .get();

         items = querySnapshot.docs.map((doc) {
           final data = doc.data() as Map<String, dynamic>;
           return {
             'id': doc.id,
             'name': data['name'] ?? 'Sin nombre',
             'code': data['code'] ?? '',
             'careerCode': data['careerCode'] ?? data['code'] ?? '',
             'duration': data['duration'] ?? 10,
             'modality': data['modality'] ?? 'presencial',
             'description': data['description'] ?? '',
             'facultyId': data['facultyId'] ?? '',
             'facultyName': data['facultyName'] ?? '',
             'facultyCode': data['facultyCode'] ?? '',
             'institutionId': data['institutionId'] ?? '',
             'institutionName': data['institutionName'] ?? '',
             'status': data['status'] ?? 'active',
             'isGlobal': data['isGlobal'] ?? false,
           };
         }).toList();
         
         // Filtrar las que no pertenecen a la institución actual
         items = items.where((program) {
           final programInstitutionId = program['institutionId'];
           return programInstitutionId != null && programInstitutionId != institutionId;
         }).toList();
       }

      // Filtrar por búsqueda si hay query
      if (widget.searchQuery.isNotEmpty) {
        items = items.where((item) {
          final name = (item['name'] ?? '').toLowerCase();
          final category = _getCareerCategory(item['name'] ?? '').toLowerCase();
          return name.contains(widget.searchQuery) || category.contains(widget.searchQuery);
        }).toList();
      }

      // Ordenar por nombre
      items.sort((a, b) {
        final nameA = a['name'] ?? '';
        final nameB = b['name'] ?? '';
        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando ${widget.type}: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar ${widget.type}: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return SizedBox.shrink();
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando ${widget.type}...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadItems,
                child: Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.type == 'faculties' ? Icons.school_outlined : Icons.menu_book_outlined,
                size: isWeb ? 64 : 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                widget.searchQuery.isNotEmpty 
                  ? 'No se encontraron carreras'
                  : 'No hay ${widget.type == 'faculties' ? 'facultades' : 'programas'} disponibles',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
               Text(
                 widget.searchQuery.isNotEmpty
                   ? 'Intenta con otros términos de búsqueda'
                   : widget.type == 'faculties' 
                     ? 'Todas las facultades ya están en tu institución'
                     : 'No se encontraron carreras en el sistema global',
                 style: TextStyle(
                   fontSize: isWeb ? 14 : 12,
                   color: Colors.grey[500],
                 ),
                 textAlign: TextAlign.center,
               ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      child: GridView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: _getMaxCrossAxisExtent(screenWidth),
          childAspectRatio: _getChildAspectRatio(screenWidth),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildItemCard(item, isWeb);
        },
      ),
    );
  }

  // Calcular ancho máximo de cada card basado en el ancho de pantalla
  double _getMaxCrossAxisExtent(double screenWidth) {
    if (screenWidth > 1400) {
      return 200; // Cards más pequeñas en pantallas muy grandes (7+ columnas)
    } else if (screenWidth > 1200) {
      return 220; // Cards pequeñas en pantallas grandes (5-6 columnas)
    } else if (screenWidth > 1000) {
      return 240; // Cards medianas en pantallas medianas-grandes (4-5 columnas)
    } else if (screenWidth > 800) {
      return 280; // Cards normales en pantallas medianas (3-4 columnas)
    } else if (screenWidth > 600) {
      return 300; // Cards más grandes en pantallas pequeñas (2 columnas)
    } else {
      return double.infinity; // 1 columna en móviles
    }
  }

  // Calcular proporción de las cards basado en el ancho de pantalla
  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth > 1400) {
      return 0.9; // Cards más altas para evitar overflow
    } else if (screenWidth > 1200) {
      return 0.95; // Cards más altas para evitar overflow
    } else if (screenWidth > 1000) {
      return 1.0; // Cards normales
    } else if (screenWidth > 800) {
      return 1.1; // Cards un poco más altas
    } else if (screenWidth > 600) {
      return 1.2; // Cards más altas en pantallas pequeñas
    } else {
      return 1.3; // Cards más altas en móviles
    }
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onItemSelected(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isWeb ? 12 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono grande de la carrera
              Center(
                child: Container(
                  width: isWeb ? 50 : 45,
                  height: isWeb ? 50 : 45,
                  decoration: BoxDecoration(
                    color: _getCareerColor(item['name'] ?? ''),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _getCareerColor(item['name'] ?? '').withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCareerIcon(item['name'] ?? ''),
                    color: Colors.white,
                    size: isWeb ? 24 : 20,
                  ),
                ),
              ),
              
              SizedBox(height: 10),
              
              // Nombre de la carrera
              Flexible(
                child: Center(
                  child: Text(
                    item['name'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 14 : 12, // Restored original font size
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              SizedBox(height: 6),
              
              // Categoría de la carrera
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getCareerColor(item['name'] ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getCareerColor(item['name'] ?? '').withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getCareerCategory(item['name'] ?? ''),
                    style: TextStyle(
                      color: _getCareerColor(item['name'] ?? ''),
                      fontSize: isWeb ? 11 : 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              SizedBox(height: 6),
              
              // Botón de agregar
              SizedBox(
                width: double.infinity,
                height: isWeb ? 36 : 32,
                child: ElevatedButton(
                  onPressed: () => widget.onItemSelected(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCareerColor(item['name'] ?? ''),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: isWeb ? 16 : 14),
                      SizedBox(width: 6),
                      Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para obtener el icono de la carrera
  IconData _getCareerIcon(String careerName) {
    final name = careerName.toLowerCase();
    
    if (name.contains('ingeniería') || name.contains('ingenieria')) {
      if (name.contains('sistemas') || name.contains('informática') || name.contains('computación')) {
        return Icons.computer;
      } else if (name.contains('civil')) {
        return Icons.construction;
      } else if (name.contains('mecánica') || name.contains('mecanica')) {
        return Icons.precision_manufacturing;
      } else if (name.contains('eléctrica') || name.contains('electrica')) {
        return Icons.electrical_services;
      } else if (name.contains('industrial')) {
        return Icons.factory;
      } else if (name.contains('química') || name.contains('quimica')) {
        return Icons.science;
      } else if (name.contains('ambiental')) {
        return Icons.eco;
      } else {
        return Icons.engineering;
      }
    } else if (name.contains('medicina')) {
      return Icons.medical_services;
    } else if (name.contains('enfermería') || name.contains('enfermeria')) {
      return Icons.health_and_safety;
    } else if (name.contains('psicología') || name.contains('psicologia')) {
      return Icons.psychology;
    } else if (name.contains('derecho') || name.contains('jurídica') || name.contains('juridica')) {
      return Icons.gavel;
    } else if (name.contains('administración') || name.contains('administracion')) {
      return Icons.business;
    } else if (name.contains('contaduría') || name.contains('contaduria')) {
      return Icons.calculate;
    } else if (name.contains('economía') || name.contains('economia')) {
      return Icons.trending_up;
    } else if (name.contains('arquitectura')) {
      return Icons.architecture;
    } else if (name.contains('diseño') || name.contains('diseno')) {
      return Icons.design_services;
    } else if (name.contains('comunicación') || name.contains('comunicacion')) {
      return Icons.mic;
    } else if (name.contains('educación') || name.contains('educacion') || name.contains('pedagogía') || name.contains('pedagogia')) {
      return Icons.school;
    } else if (name.contains('turismo')) {
      return Icons.travel_explore;
    } else if (name.contains('marketing')) {
      return Icons.campaign;
    } else if (name.contains('finanzas')) {
      return Icons.account_balance;
    } else if (name.contains('mercadotecnia')) {
      return Icons.shopping_cart;
    } else if (name.contains('relaciones internacionales')) {
      return Icons.public;
    } else if (name.contains('filosofía') || name.contains('filosofia')) {
      return Icons.auto_stories;
    } else if (name.contains('historia')) {
      return Icons.history_edu;
    } else if (name.contains('literatura')) {
      return Icons.menu_book;
    } else if (name.contains('matemáticas') || name.contains('matematicas')) {
      return Icons.functions;
    } else if (name.contains('física') || name.contains('fisica')) {
      return Icons.speed;
    } else if (name.contains('química') || name.contains('quimica')) {
      return Icons.science;
    } else if (name.contains('biología') || name.contains('biologia')) {
      return Icons.biotech;
    } else if (name.contains('veterinaria')) {
      return Icons.pets;
    } else if (name.contains('odontología') || name.contains('odontologia')) {
      return Icons.medical_information;
    } else if (name.contains('farmacia')) {
      return Icons.medication;
    } else if (name.contains('nutrición') || name.contains('nutricion')) {
      return Icons.restaurant;
    } else if (name.contains('fisioterapia')) {
      return Icons.healing;
    } else if (name.contains('trabajo social')) {
      return Icons.people;
    } else if (name.contains('sociología') || name.contains('sociologia')) {
      return Icons.groups;
    } else if (name.contains('antropología') || name.contains('antropologia')) {
      return Icons.explore;
    } else if (name.contains('ciencias políticas') || name.contains('ciencias politicas')) {
      return Icons.how_to_vote;
    } else if (name.contains('geografía') || name.contains('geografia')) {
      return Icons.map;
    } else if (name.contains('idiomas') || name.contains('lenguas')) {
      return Icons.translate;
    } else if (name.contains('música') || name.contains('musica')) {
      return Icons.music_note;
    } else if (name.contains('arte') || name.contains('bellas artes')) {
      return Icons.palette;
    } else if (name.contains('deporte') || name.contains('educación física') || name.contains('educacion fisica')) {
      return Icons.sports;
    } else {
      return Icons.school;
    }
  }

  // Función para obtener el color de la carrera
  Color _getCareerColor(String careerName) {
    final name = careerName.toLowerCase();
    
    if (name.contains('ingeniería') || name.contains('ingenieria')) {
      return Color(0xff3B82F6); // Azul
    } else if (name.contains('medicina') || name.contains('enfermería') || name.contains('enfermeria') || 
               name.contains('psicología') || name.contains('psicologia') || name.contains('veterinaria') ||
               name.contains('odontología') || name.contains('odontologia') || name.contains('farmacia') ||
               name.contains('nutrición') || name.contains('nutricion') || name.contains('fisioterapia')) {
      return Color(0xffEF4444); // Rojo
    } else if (name.contains('derecho') || name.contains('jurídica') || name.contains('juridica') ||
               name.contains('ciencias políticas') || name.contains('ciencias politicas')) {
      return Color(0xff8B5CF6); // Púrpura
    } else if (name.contains('administración') || name.contains('administracion') || 
               name.contains('contaduría') || name.contains('contaduria') || name.contains('economía') || 
               name.contains('economia') || name.contains('finanzas') || name.contains('marketing') ||
               name.contains('mercadotecnia')) {
      return Color(0xff10B981); // Verde
    } else if (name.contains('arquitectura') || name.contains('diseño') || name.contains('diseno') ||
               name.contains('arte') || name.contains('música') || name.contains('musica')) {
      return Color(0xffF59E0B); // Naranja
    } else if (name.contains('educación') || name.contains('educacion') || name.contains('pedagogía') || 
               name.contains('pedagogia') || name.contains('trabajo social')) {
      return Color(0xff06B6D4); // Cian
    } else if (name.contains('comunicación') || name.contains('comunicacion') || name.contains('turismo') ||
               name.contains('relaciones internacionales')) {
      return Color(0xffEC4899); // Rosa
    } else if (name.contains('filosofía') || name.contains('filosofia') || name.contains('historia') ||
               name.contains('literatura') || name.contains('sociología') || name.contains('sociologia') ||
               name.contains('antropología') || name.contains('antropologia')) {
      return Color(0xff6B7280); // Gris
    } else if (name.contains('matemáticas') || name.contains('matematicas') || name.contains('física') || 
               name.contains('fisica') || name.contains('química') || name.contains('quimica') ||
               name.contains('biología') || name.contains('biologia')) {
      return Color(0xff6366F1); // Índigo
    } else {
      return Color(0xff8B5CF6); // Púrpura por defecto
    }
  }

  // Función para obtener la categoría de la carrera
  String _getCareerCategory(String careerName) {
    final name = careerName.toLowerCase();
    
    if (name.contains('ingeniería') || name.contains('ingenieria')) {
      return 'Ingeniería';
    } else if (name.contains('medicina') || name.contains('enfermería') || name.contains('enfermeria') || 
               name.contains('psicología') || name.contains('psicologia') || name.contains('veterinaria') ||
               name.contains('odontología') || name.contains('odontologia') || name.contains('farmacia') ||
               name.contains('nutrición') || name.contains('nutricion') || name.contains('fisioterapia')) {
      return 'Salud';
    } else if (name.contains('derecho') || name.contains('jurídica') || name.contains('juridica') ||
               name.contains('ciencias políticas') || name.contains('ciencias politicas')) {
      return 'Derecho';
    } else if (name.contains('administración') || name.contains('administracion') || 
               name.contains('contaduría') || name.contains('contaduria') || name.contains('economía') || 
               name.contains('economia') || name.contains('finanzas') || name.contains('marketing') ||
               name.contains('mercadotecnia')) {
      return 'Negocios';
    } else if (name.contains('arquitectura') || name.contains('diseño') || name.contains('diseno') ||
               name.contains('arte') || name.contains('música') || name.contains('musica')) {
      return 'Arte & Diseño';
    } else if (name.contains('educación') || name.contains('educacion') || name.contains('pedagogía') || 
               name.contains('pedagogia') || name.contains('trabajo social')) {
      return 'Educación';
    } else if (name.contains('comunicación') || name.contains('comunicacion') || name.contains('turismo') ||
               name.contains('relaciones internacionales')) {
      return 'Comunicación';
    } else if (name.contains('filosofía') || name.contains('filosofia') || name.contains('historia') ||
               name.contains('literatura') || name.contains('sociología') || name.contains('sociologia') ||
               name.contains('antropología') || name.contains('antropologia')) {
      return 'Humanidades';
    } else if (name.contains('matemáticas') || name.contains('matematicas') || name.contains('física') || 
               name.contains('fisica') || name.contains('química') || name.contains('quimica') ||
               name.contains('biología') || name.contains('biologia')) {
      return 'Ciencias';
    } else {
      return 'General';
    }
  }
}
