import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_context_service.dart';
import 'global_careers_dashboard.dart';

class ProgramsScreen extends StatefulWidget {
  @override
  _ProgramsScreenState createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar programas cuando regreses de otra pantalla
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        print('Error: No se pudo obtener el contexto de institución');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo obtener la información de la institución')),
        );
        return;
      }

      final institutionId = userContext!.institutionId!;
      print('Cargando programas para institución: $institutionId');

      QuerySnapshot querySnapshot = await _firestore
          .collection('programs')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        _programs = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList()
          ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      });

      print('Programas cargados: ${_programs.length}');
    } catch (e) {
      print('Error cargando programas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando programas: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProgram(String programId, String programName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar el programa "$programName"?'),
          actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
      await _firestore.collection('programs').doc(programId).update({
        'status': 'inactive',
          'deletedAt': Timestamp.now(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Programa eliminado exitosamente'),
            backgroundColor: Colors.green,
        ),
        );

        _loadPrograms();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error eliminando programa: $e'),
          backgroundColor: Colors.red,
        ),
      );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Widget _buildProgramCard(Map<String, dynamic> program, bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Aquí puedes agregar navegación o acción al tocar la card
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isWeb ? 12 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono grande del programa
              Center(
                child: Container(
                  width: isWeb ? 50 : 45,
                  height: isWeb ? 50 : 45,
                  decoration: BoxDecoration(
                    color: _getProgramColor(program['name'] ?? ''),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _getProgramColor(program['name'] ?? '').withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getProgramIcon(program['name'] ?? ''),
                    color: Colors.white,
                    size: isWeb ? 24 : 20,
                  ),
                ),
              ),
              
              SizedBox(height: 10),
              
              // Nombre del programa
              Flexible(
                child: Center(
                  child: Text(
                    program['name'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 14 : 12,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              SizedBox(height: 6),
              
              // Código del programa
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getProgramColor(program['name'] ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getProgramColor(program['name'] ?? '').withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Código: ${program['code'] ?? 'N/A'}',
                    style: TextStyle(
                      color: _getProgramColor(program['name'] ?? ''),
                      fontSize: isWeb ? 11 : 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              SizedBox(height: 6),
              
              // Icono de eliminar discreto en la esquina
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _deleteProgram(
                      program['id'],
                      program['name'] ?? 'Sin nombre',
                    ),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: isWeb ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para obtener el icono del programa
  IconData _getProgramIcon(String programName) {
    final name = programName.toLowerCase();
    
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

  // Función para obtener el color del programa
  Color _getProgramColor(String programName) {
    final name = programName.toLowerCase();
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Programas'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
              children: [
          // Header con gradiente
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, size: 32, color: Colors.white),
                    SizedBox(width: 16),
                    Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                            'Gestión de Programas',
                  style: TextStyle(
                    color: Colors.white,
                              fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                            'Administra los programas académicos de tu institución',
                  style: TextStyle(
                    color: Colors.white70,
                              fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
                  ],
                ),
          SizedBox(height: 24),
          
                // Botón para ir a carreras globales
          Row(
            children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GlobalCareersDashboard(),
                          ),
                        );
                        // Recargar programas cuando regreses
                        _loadPrograms();
                      },
                      icon: Icon(Icons.public),
                      label: Text('Carreras Globales'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xff6C4DDC),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _programs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                              size: 80,
                              color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                              'No hay programas registrados',
                          style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                              'Agrega programas desde Carreras Globales',
                          style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
          SizedBox(height: 24),
              ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GlobalCareersDashboard(),
                                  ),
                                );
                                // Recargar programas cuando regreses
                                _loadPrograms();
                              },
                icon: Icon(Icons.add),
                              label: Text('Agregar Programas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                ),
              ),
            ],
          ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(24),
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                              'Mis Programas Activos (${_programs.length})',
                          style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2E2F44),
                              ),
                            ),
                            SizedBox(height: 16),
                            Expanded(
                              child: GridView.builder(
                                physics: AlwaysScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: _getMaxCrossAxisExtent(MediaQuery.of(context).size.width),
                                  childAspectRatio: _getChildAspectRatio(MediaQuery.of(context).size.width),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _programs.length,
                                itemBuilder: (context, index) {
                                  final program = _programs[index];
                                  return _buildProgramCard(program, MediaQuery.of(context).size.width > 800);
                                },
                              ),
                            ),
                      ],
                    ),
                      ),
          ),
        ],
      ),
    );
  }
}