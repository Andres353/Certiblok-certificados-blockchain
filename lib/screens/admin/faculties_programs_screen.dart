import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_context_service.dart';

class FacultiesProgramsScreen extends StatefulWidget {
  @override
  _FacultiesProgramsScreenState createState() => _FacultiesProgramsScreenState();
}

class _FacultiesProgramsScreenState extends State<FacultiesProgramsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  
  // Controllers para formularios
  final TextEditingController _facultyNameController = TextEditingController();
  final TextEditingController _facultyCodeController = TextEditingController();
  final TextEditingController _facultyDescriptionController = TextEditingController();
  
  final TextEditingController _programNameController = TextEditingController();
  final TextEditingController _programCodeController = TextEditingController();
  final TextEditingController _programDescriptionController = TextEditingController();
  final TextEditingController _programDurationController = TextEditingController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _programs = [];
  String? _selectedFacultyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFaculties();
    _loadPrograms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _facultyNameController.dispose();
    _facultyCodeController.dispose();
    _facultyDescriptionController.dispose();
    _programNameController.dispose();
    _programCodeController.dispose();
    _programDescriptionController.dispose();
    _programDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
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
      print('Cargando facultades para institución: $institutionId');

      QuerySnapshot querySnapshot = await _firestore
          .collection('faculties')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      setState(() {
        _faculties = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList()
          ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      });

      print('Facultades cargadas: ${_faculties.length}');
    } catch (e) {
      print('Error cargando facultades: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando facultades: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPrograms() async {
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
      print('Cargando programas para institución: $institutionId');

      QuerySnapshot querySnapshot = await _firestore
          .collection('programs')
          .where('institutionId', isEqualTo: institutionId)
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

  Future<void> _createFaculty() async {
    if (_facultyNameController.text.isEmpty || _facultyCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa el nombre y código de la facultad')),
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

      // Verificar si el código ya existe en esta institución
      QuerySnapshot existingFaculty = await _firestore
          .collection('faculties')
          .where('institutionId', isEqualTo: institutionId)
          .where('code', isEqualTo: _facultyCodeController.text.trim().toUpperCase())
          .get();

      if (existingFaculty.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El código de facultad ya existe en esta institución')),
        );
        return;
      }

      // Crear nueva facultad
      await _firestore.collection('faculties').add({
        'name': _facultyNameController.text.trim(),
        'code': _facultyCodeController.text.trim().toUpperCase(),
        'description': _facultyDescriptionController.text.trim(),
        'status': 'active',
        'programsCount': 0,
        'institutionId': institutionId,
        'institutionName': institutionName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Limpiar campos
      _facultyNameController.clear();
      _facultyCodeController.clear();
      _facultyDescriptionController.clear();

      // Recargar lista
      await _loadFaculties();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facultad creada exitosamente')),
      );
    } catch (e) {
      print('Error creando facultad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando facultad: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createProgram() async {
    if (_programNameController.text.isEmpty || 
        _programCodeController.text.isEmpty || 
        _selectedFacultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos requeridos')),
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

      // Verificar si el código ya existe en esta institución
      QuerySnapshot existingProgram = await _firestore
          .collection('programs')
          .where('institutionId', isEqualTo: institutionId)
          .where('code', isEqualTo: _programCodeController.text.trim().toUpperCase())
          .get();

      if (existingProgram.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El código de programa ya existe en esta institución')),
        );
        return;
      }

      // Obtener información de la facultad
      final faculty = _faculties.firstWhere((f) => f['id'] == _selectedFacultyId);

      // Crear nuevo programa
      await _firestore.collection('programs').add({
        'name': _programNameController.text.trim(),
        'code': _programCodeController.text.trim().toUpperCase(),
        'description': _programDescriptionController.text.trim(),
        'duration': int.tryParse(_programDurationController.text) ?? 10,
        'modality': 'presencial',
        'status': 'active',
        'facultyId': _selectedFacultyId,
        'facultyName': faculty['name'],
        'facultyCode': faculty['code'],
        'institutionId': institutionId,
        'institutionName': institutionName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar contador de programas en la facultad
      await _firestore.collection('faculties').doc(_selectedFacultyId).update({
        'programsCount': FieldValue.increment(1),
      });

      // Limpiar campos
      _programNameController.clear();
      _programCodeController.clear();
      _programDescriptionController.clear();
      _programDurationController.clear();
      _selectedFacultyId = null;

      // Recargar listas
      await _loadFaculties();
      await _loadPrograms();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programa creado exitosamente')),
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

  Future<void> _deleteFaculty(String facultyId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar esta facultad? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        await _firestore.collection('faculties').doc(facultyId).delete();
        await _loadFaculties();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facultad eliminada exitosamente')),
        );
      } catch (e) {
        print('Error eliminando facultad: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando facultad: $e')),
        );
      }
    }
  }

  Future<void> _deleteProgram(String programId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar este programa? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        // Obtener información del programa para actualizar el contador
        final program = _programs.firstWhere((p) => p['id'] == programId);
        
        await _firestore.collection('programs').doc(programId).delete();
        
        // Actualizar contador de programas en la facultad
        await _firestore.collection('faculties').doc(program['facultyId']).update({
          'programsCount': FieldValue.increment(-1),
        });
        
        await _loadFaculties();
        await _loadPrograms();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Programa eliminado exitosamente')),
        );
      } catch (e) {
        print('Error eliminando programa: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando programa: $e')),
        );
      }
    }
  }

  void _showCreateFacultyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWeb = screenWidth > 800;
        
        return AlertDialog(
          title: Text(
            'Crear Nueva Facultad',
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
                    controller: _facultyNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Facultad *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _facultyCodeController,
                    decoration: InputDecoration(
                      labelText: 'Código de la Facultad *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.tag),
                      hintText: 'Ej: FAC-ING',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _facultyDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
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
                _createFaculty();
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
                'Crear Facultad',
                style: TextStyle(fontSize: isWeb ? 16 : 14),
              ),
            ),
          ],
        );
      },
    );
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
                  TextField(
                    controller: _programCodeController,
                    decoration: InputDecoration(
                      labelText: 'Código del Programa *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.tag),
                      hintText: 'Ej: ING-SIS',
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
                  SizedBox(height: 16),
                  TextField(
                    controller: _programDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Facultades y Programas'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.school),
              text: 'Facultades',
            ),
            Tab(
              icon: Icon(Icons.menu_book),
              text: 'Programas',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFacultiesTab(isWeb),
                _buildProgramsTab(isWeb),
              ],
            ),
    );
  }

  Widget _buildFacultiesTab(bool isWeb) {
    return Padding(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Facultades',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 28 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Administra las facultades de la institución',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isWeb ? 18 : 16,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Controles
          Row(
            children: [
              Expanded(
                child: Text(
                  'Facultades Registradas (${_faculties.length})',
                  style: TextStyle(
                    fontSize: isWeb ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateFacultyDialog,
                icon: Icon(Icons.add),
                label: Text('Crear Facultad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Lista de facultades
          Expanded(
            child: _faculties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: isWeb ? 80 : 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay facultades registradas',
                          style: TextStyle(
                            fontSize: isWeb ? 20 : 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Crea la primera facultad para comenzar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isWeb ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _faculties.length,
                    itemBuilder: (context, index) {
                      final faculty = _faculties[index];
                      return _buildFacultyCard(faculty, isWeb);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsTab(bool isWeb) {
    return Padding(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Programas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 28 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Administra los programas académicos de cada facultad',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isWeb ? 18 : 16,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Controles
          Row(
            children: [
              Expanded(
                child: Text(
                  'Programas Registrados (${_programs.length})',
                  style: TextStyle(
                    fontSize: isWeb ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _faculties.isEmpty 
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Primero debes crear al menos una facultad')),
                        );
                      }
                    : _showCreateProgramDialog,
                icon: Icon(Icons.add),
                label: Text('Crear Programa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Lista de programas
          Expanded(
            child: _programs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: isWeb ? 80 : 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay programas registrados',
                          style: TextStyle(
                            fontSize: isWeb ? 20 : 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Crea el primer programa para comenzar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isWeb ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _programs.length,
                    itemBuilder: (context, index) {
                      final program = _programs[index];
                      return _buildProgramCard(program, isWeb);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyCard(Map<String, dynamic> faculty, bool isWeb) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: isWeb ? 30 : 25,
              backgroundColor: Color(0xff6C4DDC),
              child: Icon(
                Icons.school,
                color: Colors.white,
                size: isWeb ? 24 : 20,
              ),
            ),
            SizedBox(width: isWeb ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faculty['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 18 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Código: ${faculty['code']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
                  if (faculty['description'] != null && faculty['description'].isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      faculty['description'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: isWeb ? 12 : 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 4),
                  Text(
                    'Programas: ${faculty['programsCount'] ?? 0}',
                    style: TextStyle(
                      color: Color(0xff6C4DDC),
                      fontSize: isWeb ? 12 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteFaculty(faculty['id']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program, bool isWeb) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: isWeb ? 30 : 25,
              backgroundColor: Color(0xff8B5CF6),
              child: Icon(
                Icons.menu_book,
                color: Colors.white,
                size: isWeb ? 24 : 20,
              ),
            ),
            SizedBox(width: isWeb ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 18 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Código: ${program['code']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Facultad: ${program['facultyName']}',
                    style: TextStyle(
                      color: Color(0xff6C4DDC),
                      fontSize: isWeb ? 12 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (program['duration'] != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Duración: ${program['duration']} semestres',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: isWeb ? 12 : 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteProgram(program['id']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
