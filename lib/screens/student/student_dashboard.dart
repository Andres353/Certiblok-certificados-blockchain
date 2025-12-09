import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_context_service.dart';
import '../../services/institution_status_service.dart';
import '../../services/adapters/auth_adapter.dart';
import '../../widgets/suspended_institution_widget.dart';
import 'join_institution_screen.dart';
import 'share_certificates_screen.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  UserContext? _userContext;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    setState(() {
      _isLoading = true;
    });
    
    // Cargar contexto desde SharedPreferences
    final context = await UserContextService.loadUserContext();
    
    // Si el usuario está logueado, cargar datos actualizados desde Supabase
    if (context != null) {
      try {
        final supabase = Supabase.instance.client;
        final userResponse = await supabase
            .from('users')
            .select('*')
            .eq('id', context.userId)
            .single();
            
        print('🔍 DEBUG - Datos del usuario desde Supabase:');
        print('   - ID: ${userResponse['id']}');
        print('   - Email: ${userResponse['email']}');
        print('   - Institution ID: ${userResponse['institution_id']}');
        print('   - Institution Name: ${userResponse['institution_name']}');
        print('   - Program: ${userResponse['program']}');
        print('   - Program ID: ${userResponse['program_id']}');
        
        // Crear nuevo contexto con datos actualizados
        final updatedContext = UserContext(
          userId: userResponse['id'] ?? context.userId,
          userRole: userResponse['role'] ?? context.userRole,
          institutionId: userResponse['institution_id'],
          institutionName: userResponse['institution_name'],
          institution: userResponse['institution_name'],
          currentInstitution: context.currentInstitution,
          userEmail: userResponse['email'] ?? context.userEmail,
          userName: userResponse['full_name'] ?? context.userName,
          mustChangePassword: userResponse['must_change_password'] ?? context.mustChangePassword,
          isTemporaryPassword: userResponse['is_temporary_password'] ?? context.isTemporaryPassword,
          program: userResponse['program'],
          programId: userResponse['program_id'],
        );
        
        // Actualizar el contexto en el servicio
        await UserContextService.setUserContext(updatedContext);
        
        print('🔍 DEBUG - Contexto actualizado:');
        print('   - Institution ID: ${updatedContext.institutionId}');
        print('   - Institution Name: ${updatedContext.institutionName}');
        print('   - Institution: ${updatedContext.institution}');
        print('   - Program: ${updatedContext.program}');
        
        // Verificar si la institución está suspendida
        if (updatedContext.institutionId != null) {
          final isSuspended = await InstitutionStatusService.isInstitutionSuspended(updatedContext.institutionId!);
          if (isSuspended) {
            setState(() {
              _userContext = updatedContext;
              _isLoading = false;
            });
            return; // Mostrar pantalla de suspensión
          }
        }
        
        setState(() {
          _userContext = updatedContext;
          _isLoading = false;
        });
      } catch (e) {
        print('Error cargando datos actualizados: $e');
        setState(() {
          _userContext = context;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _userContext = context;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Cerrar sesión y esperar a que se limpie
      await AuthAdapter.logout();
      // Esperar un momento para asegurar que la sesión se limpie completamente
      await Future.delayed(Duration(milliseconds: 300));
      // Verificar que la sesión esté realmente limpia
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null && mounted) {
        // Recargar la página para que _getInitialRoute() se ejecute con estado limpio
        html.window.location.reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando...'),
          backgroundColor: Color(0xff6C4DDC),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando tu información...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Verificar si la institución está suspendida
    if (_userContext?.institutionId != null) {
      return FutureBuilder<bool>(
        future: InstitutionStatusService.isInstitutionSuspended(_userContext!.institutionId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Verificando...'),
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
              ),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
            if (snapshot.hasData && snapshot.data == true) {
              return FutureBuilder(
                future: InstitutionStatusService.getSuspendedInstitutionInfo(_userContext!.institutionId!),
                builder: (context, institutionSnapshot) {
                  if (institutionSnapshot.hasData && institutionSnapshot.data != null) {
                    return SuspendedInstitutionWidget(
                      institution: institutionSnapshot.data!,
                      userRole: 'student',
                    );
                  }
                  return Scaffold(
                    appBar: AppBar(
                      title: Text('Error'),
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                    ),
                    body: Center(child: Text('Error al cargar información de la institución')),
                  );
                },
              );
            }
          
          // Si no está suspendida, mostrar el dashboard normal
          return _buildNormalDashboard(context, isWeb);
        },
      );
    }
    
    return _buildNormalDashboard(context, isWeb);
  }

  Widget _buildNormalDashboard(BuildContext context, bool isWeb) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard del Estudiante'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: _userContext == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No se pudo cargar la información del usuario',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header responsive
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
                    'Bienvenido, ${_userContext?.userName ?? 'Estudiante'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWeb ? 28 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userContext?.institutionName != null || _userContext?.institution != null || _userContext?.institutionId != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Estudiante de ${_userContext!.institutionName ?? _userContext!.institution}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isWeb ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Contenido condicional basado en vinculación
            if (_userContext?.institutionName != null || _userContext?.institution != null || _userContext?.institutionId != null) ...[
              // ESTUDIANTE VINCULADO - Mostrar funcionalidades
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mi Institución',
                    style: TextStyle(
                      fontSize: isWeb ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addInstitution,
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Cambiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xff6C4DDC),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildInstitutionCard(),
              SizedBox(height: 24),
              
              // Funcionalidades principales
              Text(
                'Mis Certificados y Documentos',
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Grid de funcionalidades responsive
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    int crossAxisCount;
                    double childAspectRatio;
                    
                    if (availableWidth > 1600) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.3;
                    } else if (availableWidth > 1200) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.2;
                    } else if (availableWidth > 900) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.1;
                    } else {
                      crossAxisCount = 2;
                      childAspectRatio = 1.1;
                    }
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                  children: [
                    _buildFunctionalityCard(
                      context,
                      'Ver Mis Certificados',
                      Icons.description,
                      'Consulta todos tus certificados emitidos',
                      () => Navigator.pushNamed(context, '/my-certificates'),
                      color: Colors.blue,
                      isWeb: isWeb,
                    ),
                    _buildFunctionalityCard(
                      context,
                      'Compartir Certificados',
                      Icons.share,
                      'Comparte certificados por QR o enlace',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShareCertificatesScreen(),
                        ),
                      ),
                      color: Colors.orange,
                      isWeb: isWeb,
                    ),
                    _buildFunctionalityCard(
                      context,
                      'Programas Disponibles',
                      Icons.work_outline,
                      'Postúlate a programas y pasantías',
                      () => Navigator.pushNamed(context, '/programs-opportunities'),
                      color: Colors.indigo,
                      isWeb: isWeb,
                    ),
                    _buildFunctionalityCard(
                      context,
                      'Mis Postulaciones',
                      Icons.assignment_turned_in,
                      'Revisa el estado de tus postulaciones',
                      () => Navigator.pushNamed(context, '/my-applications'),
                      color: Colors.purple,
                      isWeb: isWeb,
                    ),
                  ],
                    );
                  },
                ),
              ),
            ] else ...[
              // ESTUDIANTE NO VINCULADO - Solo mostrar mensaje de bienvenida
              _buildWelcomeMessage(),
              SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addInstitution() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => JoinInstitutionScreen()),
    );

    if (result == true) {
      // Recargar contexto del usuario si se agregó una nueva institución
      await _loadUserContext();
    }
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC).withOpacity(0.1), Color(0xff8B7DDC).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Color(0xff6C4DDC),
          ),
          SizedBox(height: 16),
          Text(
            '¡Bienvenido a CertiBlock!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff2E2F44),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Para comenzar, necesitas registrarte en una institución usando su código único.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _addInstitution,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.add),
              label: Text(
                'Vincularme con una Institución',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Pide el código de institución a tu administrador o profesor',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionCard() {
    final program = _userContext?.program ?? '';
    final institutionName = _userContext?.institutionName ?? _userContext?.institution ?? 'Institución';
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color(0xff6C4DDC).withOpacity(0.05),
              Color(0xff8B7DDC).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de carrera y Universidad
              Row(
                children: [
                  // Icono de carrera
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xff6C4DDC),
                          Color(0xff8B7DDC),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff6C4DDC).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _getCareerIcon(program),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Información de universidad y programa
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Universidad
                        Text(
                          institutionName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        // Programa/Carrera
                        if (program.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: Color(0xff6C4DDC),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  program,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'Programa no especificado',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Badge de estado
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Activo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  // Función para obtener el icono basado en la carrera (usando la misma lógica de basic_items_list_widget)
  Widget _getCareerIcon(String program) {
    final programLower = program.toLowerCase();
    IconData iconData;
    Color iconColor = Colors.white;

    // Mapeo de carreras a iconos (igual que en basic_items_list_widget)
    if (programLower.contains('ingeniería') || programLower.contains('ingenieria')) {
      if (programLower.contains('sistemas') || programLower.contains('informática') || programLower.contains('informatica') || programLower.contains('computación') || programLower.contains('computacion')) {
        iconData = Icons.computer;
      } else if (programLower.contains('civil')) {
        iconData = Icons.construction;
      } else if (programLower.contains('mecánica') || programLower.contains('mecanica')) {
        iconData = Icons.precision_manufacturing;
      } else if (programLower.contains('eléctrica') || programLower.contains('electrica')) {
        iconData = Icons.electrical_services;
      } else if (programLower.contains('industrial')) {
        iconData = Icons.factory;
      } else if (programLower.contains('química') || programLower.contains('quimica')) {
        iconData = Icons.science;
      } else if (programLower.contains('ambiental')) {
        iconData = Icons.eco;
      } else {
        iconData = Icons.engineering;
      }
    } else if (programLower.contains('medicina')) {
      iconData = Icons.medical_services;
    } else if (programLower.contains('enfermería') || programLower.contains('enfermeria')) {
      iconData = Icons.health_and_safety;
    } else if (programLower.contains('psicología') || programLower.contains('psicologia')) {
      iconData = Icons.psychology;
    } else if (programLower.contains('derecho') || programLower.contains('jurídica') || programLower.contains('juridica')) {
      iconData = Icons.gavel;
    } else if (programLower.contains('administración') || programLower.contains('administracion')) {
      iconData = Icons.business;
    } else if (programLower.contains('contaduría') || programLower.contains('contaduria')) {
      iconData = Icons.calculate;
    } else if (programLower.contains('economía') || programLower.contains('economia')) {
      iconData = Icons.trending_up;
    } else if (programLower.contains('arquitectura')) {
      iconData = Icons.architecture;
    } else if (programLower.contains('diseño') || programLower.contains('diseno')) {
      iconData = Icons.design_services;
    } else if (programLower.contains('comunicación') || programLower.contains('comunicacion')) {
      iconData = Icons.mic;
    } else if (programLower.contains('educación') || programLower.contains('educacion') || programLower.contains('pedagogía') || programLower.contains('pedagogia')) {
      iconData = Icons.school;
    } else if (programLower.contains('turismo')) {
      iconData = Icons.travel_explore;
    } else if (programLower.contains('marketing')) {
      iconData = Icons.campaign;
    } else if (programLower.contains('finanzas')) {
      iconData = Icons.account_balance;
    } else if (programLower.contains('mercadotecnia')) {
      iconData = Icons.shopping_cart;
    } else if (programLower.contains('relaciones internacionales')) {
      iconData = Icons.public;
    } else if (programLower.contains('filosofía') || programLower.contains('filosofia')) {
      iconData = Icons.auto_stories;
    } else if (programLower.contains('historia')) {
      iconData = Icons.history_edu;
    } else if (programLower.contains('literatura')) {
      iconData = Icons.menu_book;
    } else if (programLower.contains('biología') || programLower.contains('biologia')) {
      iconData = Icons.biotech;
    } else if (programLower.contains('química') || programLower.contains('quimica')) {
      iconData = Icons.science;
    } else if (programLower.contains('matemáticas') || programLower.contains('matematicas') || programLower.contains('matemática') || programLower.contains('matematica')) {
      iconData = Icons.functions;
    } else if (programLower.contains('física') || programLower.contains('fisica')) {
      iconData = Icons.speed;
    } else if (programLower.contains('odontología') || programLower.contains('odontologia')) {
      iconData = Icons.medical_information;
    } else if (programLower.contains('veterinaria') || programLower.contains('zootecnia')) {
      iconData = Icons.pets;
    } else if (programLower.contains('agronomía') || programLower.contains('agronomia') || programLower.contains('agrícola') || programLower.contains('agricola')) {
      iconData = Icons.agriculture;
    } else if (programLower.contains('farmacia') || programLower.contains('farmacéutica') || programLower.contains('farmaceutica')) {
      iconData = Icons.medication;
    } else if (programLower.contains('artes') || programLower.contains('plásticas') || programLower.contains('plasticas')) {
      iconData = Icons.palette;
    } else {
      // Icono por defecto
      iconData = Icons.school;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 36,
    );
  }

  
  Widget _buildFunctionalityCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap, {
    Color? color,
    bool isWeb = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 16.0 : 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isWeb ? 48 : 32,
                color: color ?? Color(0xff6C4DDC),
              ),
              SizedBox(height: isWeb ? 12 : 4),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: isWeb ? 8 : 2),
              Flexible(
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWeb ? 12 : 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: isWeb ? 4 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
