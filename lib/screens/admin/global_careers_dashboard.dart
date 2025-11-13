import 'package:flutter/material.dart';
import '../../services/user_context_service.dart';
import '../../services/adapters/careers_adapter.dart';
import '../../widgets/basic_items_list_widget.dart';
import '../../services/global_careers_initializer.dart';
import '../../services/alert_service.dart';

class GlobalCareersDashboard extends StatefulWidget {
  @override
  _GlobalCareersDashboardState createState() => _GlobalCareersDashboardState();
}

class _GlobalCareersDashboardState extends State<GlobalCareersDashboard> {
  bool _isLoading = false;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  
  // Variables para crear programa
  final TextEditingController _programNameController = TextEditingController();
  final TextEditingController _programDurationController = TextEditingController();
  
  // Controlador para la lista de carreras
  final BasicItemsListWidgetController _careersListController = BasicItemsListWidgetController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _programNameController.dispose();
    _programDurationController.dispose();
    super.dispose();
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
      
      print('🔍 DEBUG - Agregando carrera global...');
      print('   - UserContext: ${userContext != null ? "Existe" : "No existe"}');
      print('   - InstitutionId: ${userContext?.institutionId}');
      print('   - InstitutionName: ${userContext?.currentInstitution?.name}');
      print('   - UserRole: ${userContext?.userRole}');
      
      if (userContext?.institutionId == null || userContext?.currentInstitution?.name == null) {
        print('❌ Error: No se pudo obtener la información de la institución');
        throw Exception('No se pudo obtener la información de la institución');
      }

      // Verificar si el programa ya existe en la institución
      final existingPrograms = await CareersAdapter.getProgramsByInstitution(userContext!.institutionId!);
      final programExists = existingPrograms.any((p) => p['name'] == program['name']);

      if (programExists) {
        AlertService.showWarning(
          context,
          'Carrera Duplicada',
          'La carrera "${program['name']}" ya existe en tu institución',
        );
        return;
      }

      // Generar código único para la institución
      final careerCode = await CareersAdapter.generateUniqueProgramCode(userContext.institutionId!);

      // Usar CareersAdapter para crear programa
      final result = await CareersAdapter.createProgram(
        name: program['name'],
        code: careerCode,
        facultyId: null, // Se asignará cuando se cree la facultad
        facultyName: 'Sin asignar',
        institutionId: userContext.institutionId!,
        institutionName: userContext.currentInstitution!.name,
        duration: program['duration'] ?? 10,
        modality: program['modality'] ?? 'presencial',
        description: program['description'],
      );

      if (!result['success']) {
        throw Exception(result['message'] ?? 'Error creando programa');
      }

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      AlertService.showSuccess(
        context,
        'Carrera Agregada',
        'La carrera "${program['name']}" ha sido agregada a tu institución con código: $careerCode',
      );

      // Recargar la lista de carreras para que no aparezca la carrera agregada
      _careersListController.reload();

    } catch (e) {
      // Cerrar diálogo de carga en caso de error
      Navigator.of(context).pop();
      
      AlertService.showError(
        context,
        'Error',
        'Error: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _createProgram() async {
    if (_programNameController.text.isEmpty) {
      AlertService.showWarning(
        context,
        'Campo Requerido',
        'Por favor completa el nombre del programa',
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
        AlertService.showError(
          context,
          'Error',
          'No se pudo obtener la información de la institución',
        );
        return;
      }

      final institutionId = userContext!.institutionId!;
      final institutionName = userContext.currentInstitution?.name ?? 'Institución';

      // Validar que el nombre no exista en las carreras globales disponibles
      final programName = _programNameController.text.trim();
      final globalCareers = GlobalCareersInitializer.globalCareers;
      final programNameLower = programName.toLowerCase();
      
      final existsInGlobalCareers = globalCareers.any((career) {
        final careerName = (career['name'] ?? '').toString().toLowerCase().trim();
        return careerName == programNameLower;
      });

      if (existsInGlobalCareers) {
        setState(() {
          _isLoading = false;
        });
        AlertService.showWarning(
          context,
          'Programa Duplicado',
          'No se puede crear un programa personalizado con el nombre "$programName" porque ya existe en las carreras globales disponibles. Por favor, agrega esa carrera desde la lista de carreras disponibles.',
        );
        return;
      }

      // Generar código de carrera automáticamente
      final careerCode = await CareersAdapter.generateUniqueProgramCode(institutionId);

      // Usar CareersAdapter para crear programa
      final result = await CareersAdapter.createProgram(
        name: _programNameController.text.trim(),
        code: careerCode,
        facultyId: null, // Sin facultad asignada
        facultyName: 'Sin asignar',
        institutionId: institutionId,
        institutionName: institutionName,
        duration: int.tryParse(_programDurationController.text) ?? 10,
        modality: 'presencial',
        description: null,
      );

      if (!result['success']) {
        throw Exception(result['message'] ?? 'Error creando programa');
      }

      // Limpiar campos
      _programNameController.clear();
      _programDurationController.clear();

      // Mostrar mensaje de éxito
      AlertService.showSuccess(
        context,
        'Programa Creado',
        'El programa ha sido creado exitosamente con código: $careerCode',
      );

    } catch (e) {
      print('Error creando programa: $e');
      AlertService.showError(
        context,
        'Error',
        'Error creando programa: $e',
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
