import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_context_service.dart';
import '../../services/global_careers_initializer.dart';
import '../../services/institution_service.dart';
import '../../widgets/basic_items_list_widget.dart';

class GlobalCareersDashboard extends StatefulWidget {
  @override
  _GlobalCareersDashboardState createState() => _GlobalCareersDashboardState();
}

class _GlobalCareersDashboardState extends State<GlobalCareersDashboard> {
  bool _isLoading = false;
  bool _showInitializeButton = true;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  
  // Variables para crear programa
  final TextEditingController _programNameController = TextEditingController();
  final TextEditingController _programDurationController = TextEditingController();
  String? _selectedFacultyId;
  List<Map<String, dynamic>> _faculties = [];
  
  // Controlador para la lista de carreras
  final BasicItemsListWidgetController _careersListController = BasicItemsListWidgetController();

  @override
  void initState() {
    super.initState();
    _checkIfGlobalCareersExist();
    _loadFaculties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _programNameController.dispose();
    _programDurationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfGlobalCareersExist() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('programs')
          .where('isGlobal', isEqualTo: true)
          .limit(1)
          .get();
      
      setState(() {
        _showInitializeButton = querySnapshot.docs.isEmpty;
      });
    } catch (e) {
      print('Error verificando carreras globales: $e');
    }
  }

  Future<void> _initializeGlobalCareers() async {
    setState(() => _isLoading = true);

    try {
      final result = await GlobalCareersInitializer.initializeGlobalCareers();
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Carreras globales inicializadas: ${result['added']} agregadas, ${result['skipped']} ya existían'
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _showInitializeButton = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al inicializar carreras globales'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addProgramToInstitution(Map<String, dynamic> program) async {
    setState(() => _isLoading = true);

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Agregando carrera...'),
            ],
          ),
        );
      },
    );

    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null || userContext?.currentInstitution?.name == null) {
        throw Exception('No se pudo obtener la información de la institución');
      }

      // Verificar si el programa ya existe en la institución
      final existingPrograms = await FirebaseFirestore.instance
          .collection('programs')
          .where('institutionId', isEqualTo: userContext!.institutionId!)
          .where('name', isEqualTo: program['name'])
          .get();

      if (existingPrograms.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La carrera "${program['name']}" ya existe en tu institución'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Generar código único para la institución usando InstitutionService
      final institutionShortName = userContext.currentInstitution?.shortName ?? 'INST';
      final careerCode = await InstitutionService.generateCareerCode(
        institutionShortName,
        program['name'],
      );

      // Agregar el programa a la institución
      await FirebaseFirestore.instance.collection('programs').add({
        'name': program['name'],
        'code': careerCode, // Usar el código de carrera como código principal
        'careerCode': careerCode, // Código único para vinculación
        'duration': program['duration'],
        'modality': program['modality'],
        'description': program['description'],
        'category': program['category'],
        'status': 'active',
        'institutionId': userContext.institutionId!,
        'institutionName': userContext.currentInstitution!.name,
        'facultyId': '', // Se asignará cuando se cree la facultad
        'facultyName': '',
        'facultyCode': '',
        'isGlobal': false, // Marcar como programa de la institución
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Carrera "${program['name']}" agregada a tu institución con código: $careerCode'),
          backgroundColor: Colors.green,
        ),
      );

      // Recargar la lista de carreras para que no aparezca la carrera agregada
      _careersListController.reload();

    } catch (e) {
      // Cerrar diálogo de carga en caso de error
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _loadFaculties() async {
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('faculties')
          .where('institutionId', isEqualTo: userContext!.institutionId)
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        _faculties = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Sin nombre',
            'code': data['code'] ?? '',
            'description': data['description'] ?? '',
            'institutionId': data['institutionId'] ?? '',
            'institutionName': data['institutionName'] ?? '',
            'status': data['status'] ?? 'active',
            'createdAt': data['createdAt'],
            'programsCount': data['programsCount'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print('Error cargando facultades: $e');
    }
  }

  Future<void> _createProgram() async {
    if (_programNameController.text.isEmpty || 
        _selectedFacultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa el nombre del programa y selecciona una facultad')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener contexto del usuario actual
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        print('Error: No se pudo obtener el contexto de institución');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo obtener la información de la institución')),
        );
        return;
      }

      final institutionId = userContext!.institutionId!;
      final institutionName = userContext.currentInstitution?.name ?? 'Institución';
      final institutionShortName = userContext.currentInstitution?.shortName ?? 'INST';

      // Obtener información de la facultad
      final faculty = _faculties.firstWhere((f) => f['id'] == _selectedFacultyId);

      // Generar código de carrera automáticamente
      final careerCode = await InstitutionService.generateCareerCode(
        institutionShortName,
        _programNameController.text.trim(),
      );

      // Crear nuevo programa con código de carrera
      await FirebaseFirestore.instance.collection('programs').add({
        'name': _programNameController.text.trim(),
        'code': careerCode, // Usar el código de carrera como código principal
        'careerCode': careerCode, // Código único para vinculación
        'duration': int.tryParse(_programDurationController.text) ?? 10,
        'modality': 'presencial',
        'status': 'active',
        'facultyId': _selectedFacultyId,
        'facultyName': faculty['name'],
        'facultyCode': faculty['code'],
        'institutionId': institutionId,
        'institutionName': institutionName,
        'isGlobal': false, // Programa personalizado, no global
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar contador de programas en la facultad
      await FirebaseFirestore.instance.collection('faculties').doc(_selectedFacultyId).update({
        'programsCount': FieldValue.increment(1),
      });

      // Limpiar campos
      _programNameController.clear();
      _programDurationController.clear();
      _selectedFacultyId = null;

      // Recargar facultades
      await _loadFaculties();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programa creado exitosamente con código: $careerCode'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error creando programa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando programa: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateProgramDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWeb = screenWidth > 800;
        
        return AlertDialog(
          title: Text(
            'Crear Nuevo Programa',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: isWeb ? 500 : double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _programNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Programa *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.menu_book),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El código de carrera se generará automáticamente',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedFacultyId,
                    decoration: InputDecoration(
                      labelText: 'Facultad *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: _faculties.map((faculty) {
                      return DropdownMenuItem<String>(
                        value: faculty['id'],
                        child: Text('${faculty['code']} - ${faculty['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFacultyId = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _programDurationController,
                    decoration: InputDecoration(
                      labelText: 'Duración (semestres)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.schedule),
                      hintText: '10',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: isWeb ? 16 : 14),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createProgram();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 24 : 20,
                  vertical: isWeb ? 12 : 10,
                ),
              ),
              child: Text(
                'Crear Programa',
                style: TextStyle(fontSize: isWeb ? 16 : 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel izquierdo - Buscador y Acciones
        Container(
          width: 400,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.public,
                      size: 32,
                      color: Color(0xff10B981),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Carreras Globales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff10B981),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Selecciona las carreras que deseas agregar a tu institución',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Buscador de carreras
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
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
                        Icon(Icons.search, color: Color(0xff10B981)),
                        SizedBox(width: 8),
                        Text(
                          'Buscar Carreras',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff10B981),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre de carrera...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xff10B981)),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Botones de acción
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
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
                        Icon(Icons.settings, color: Color(0xff10B981)),
                        SizedBox(width: 8),
                        Text(
                          'Acciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff10B981),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Botón de inicialización (solo si no existen carreras globales)
                    if (_showInitializeButton) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange[600]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Primera vez usando Carreras Globales',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Inicializa la base de datos con carreras predefinidas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _initializeGlobalCareers,
                                icon: _isLoading 
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(Icons.add_circle_outline, size: 16),
                                label: Text(_isLoading ? 'Inicializando...' : 'Inicializar Carreras Globales'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    // Botón de crear programa personalizado
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateProgramDialog,
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Crear Programa Personalizado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 20),

        // Panel derecho - Lista de carreras
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header de la lista
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xff10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Color(0xff10B981),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Carreras Disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff10B981),
                        ),
                      ),
                      Spacer(),
                      if (_isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff10B981)),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Lista de carreras
                Expanded(
                  child: BasicItemsListWidget(
                    type: 'programs',
                    onItemSelected: _addProgramToInstitution,
                    searchQuery: _searchQuery,
                    controller: _careersListController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.public,
                size: 28,
                color: Color(0xff10B981),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carreras Globales Disponibles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff10B981),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Selecciona las carreras que deseas agregar a tu institución',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Buscador de carreras
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                  Icon(Icons.search, color: Color(0xff10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Buscar Carreras',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff10B981),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre de carrera...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xff10B981)),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Botones de acción
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                  Icon(Icons.settings, color: Color(0xff10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Acciones',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff10B981),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Botón de inicialización (solo si no existen carreras globales)
              if (_showInitializeButton) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[600]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Primera vez usando Carreras Globales',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Inicializa la base de datos con carreras predefinidas',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _initializeGlobalCareers,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.add_circle_outline, size: 16),
                          label: Text(_isLoading ? 'Inicializando...' : 'Inicializar Carreras Globales'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Botón de crear programa personalizado
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateProgramDialog,
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Crear Programa Personalizado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Lista de carreras globales
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header de la lista
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xff10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Color(0xff10B981),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Carreras Disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff10B981),
                        ),
                      ),
                      Spacer(),
                      if (_isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff10B981)),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Lista de carreras
                Expanded(
                  child: BasicItemsListWidget(
                    type: 'programs',
                    onItemSelected: _addProgramToInstitution,
                    searchQuery: _searchQuery,
                    controller: _careersListController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carreras Globales',
          style: TextStyle(
            fontSize: isWeb ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xff10B981),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff10B981).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 24 : 16),
          child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }
}
