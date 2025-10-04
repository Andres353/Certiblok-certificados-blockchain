import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/roles.dart';
import '../../services/user_context_service.dart';
import 'join_institution_screen.dart';

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
    
    // Si el usuario está logueado, cargar datos actualizados desde Firestore
    if (context != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(context.userId)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          
          // Crear nuevo contexto con datos actualizados
          final updatedContext = UserContext(
            userId: userData['userId'] ?? context.userId,
            userRole: userData['role'] ?? context.userRole,
            institutionId: userData['institutionId'],
            institutionName: userData['institutionName'],
            institution: userData['institution'],
            currentInstitution: context.currentInstitution,
            userEmail: userData['email'] ?? context.userEmail,
            userName: userData['fullName'] ?? context.userName,
            mustChangePassword: userData['mustChangePassword'] ?? context.mustChangePassword,
            isTemporaryPassword: userData['isTemporaryPassword'] ?? context.isTemporaryPassword,
            program: userData['program'],
            programId: userData['programId'],
          );
          
          // Actualizar el contexto en el servicio
          await UserContextService.setUserContext(updatedContext);
          
          setState(() {
            _userContext = updatedContext;
            _isLoading = false;
          });
        } else {
          setState(() {
            _userContext = context;
            _isLoading = false;
          });
        }
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
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard del Estudiante'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(
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
                  SizedBox(height: 8),
                  Text(
                    UserRoles.getRoleDescription(UserRoles.STUDENT),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isWeb ? 18 : 16,
                    ),
                  ),
                  if (_userContext?.institutionName != null || _userContext?.institution != null) ...[
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
            if (_userContext?.institutionName != null || _userContext?.institution != null) ...[
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
                child: GridView.count(
                  crossAxisCount: isWeb ? 3 : 2,
                  crossAxisSpacing: isWeb ? 20 : 16,
                  mainAxisSpacing: isWeb ? 20 : 16,
                  childAspectRatio: isWeb ? 1.0 : 1.1,
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
                      'Organizar Documentos',
                      Icons.folder,
                      'Organiza y categoriza tus documentos',
                      () => _showComingSoon(context, 'Organizar Documentos'),
                      color: Colors.green,
                      isWeb: isWeb,
                    ),
                    _buildFunctionalityCard(
                      context,
                      'Compartir Certificados',
                      Icons.share,
                      'Comparte certificados por QR o enlace',
                      () => _showComingSoon(context, 'Compartir Certificados'),
                      color: Colors.orange,
                      isWeb: isWeb,
                    ),
                    _buildFunctionalityCard(
                      context,
                      'Descargar PDFs',
                      Icons.download,
                      'Descarga tus certificados en PDF',
                      () => _showComingSoon(context, 'Descargar PDFs'),
                      color: Colors.red,
                      isWeb: isWeb,
                    ),
                    _buildFunctionalityCard(
                      context,
                      'Historial Académico',
                      Icons.history_edu,
                      'Consulta tu historial académico completo',
                      () => _showComingSoon(context, 'Historial Académico'),
                      color: Colors.purple,
                      isWeb: isWeb,
                    ),
                    _buildFunctionalityCard(
                      context,
                      'Estado de Verificación',
                      Icons.verified,
                      'Verifica el estado de tus documentos',
                      () => _showComingSoon(context, 'Estado de Verificación'),
                      color: Colors.teal,
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
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xff6C4DDC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _userContext?.institutionId?.substring(0, 3).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userContext?.institutionName ?? _userContext?.institution ?? 'Institución',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      if (_userContext?.program != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Programa: ${_userContext!.program}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Activo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
  
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Funcionalidad en Desarrollo'),
          content: Text('La funcionalidad "$feature" estará disponible próximamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}
