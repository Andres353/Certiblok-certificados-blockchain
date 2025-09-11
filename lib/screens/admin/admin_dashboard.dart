import 'package:flutter/material.dart';
import '../../services/user_context_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  UserContext? _userContext;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    try {
      final context = await UserContextService.loadUserContext();
      setState(() {
        _userContext = context;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando contexto de usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('=== DEBUG ADMIN DASHBOARD ===');
    print('AdminDashboard se está construyendo');
    print('Context: $context');
    
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
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrador - Dashboard'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
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
                  'Bienvenido, ${_userContext?.userName ?? 'Administrador'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Administrador de ${_userContext?.currentInstitution?.name ?? 'Institución'}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                if (_userContext?.currentInstitution?.shortName != null) ...[
                  SizedBox(height: 4),
                  Text(
                    '(${_userContext!.currentInstitution!.shortName})',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: 32),
          
          // Información de la institución
          if (_userContext?.currentInstitution != null) ...[
            _buildInstitutionInfoCard(context, isWeb: true),
            SizedBox(height: 24),
          ],
          
          // Funcionalidades principales
          Text(
            'Panel de Administración',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff2E2F44),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Grid de funcionalidades que se expande
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.1,
              children: [
                _buildFunctionalityCard(
                  context,
                  'Gestionar Emisores',
                  Icons.person_add,
                  'Crear, editar y gestionar usuarios emisores',
                  () => _navigateToManageEmisores(context),
                  color: Colors.purple,
                  isWeb: true,
                ),
                                  _buildFunctionalityCard(
                    context,
                    'Facultades y Programas',
                    Icons.school,
                    'Administrar facultades y programas académicos',
                    () => _navigateToFacultiesPrograms(context),
                    color: Colors.blue,
                    isWeb: true,
                  ),
                _buildFunctionalityCard(
                  context,
                  'Configuración del Sistema',
                  Icons.settings,
                  'Configurar parámetros del sistema',
                  () => _showComingSoon(context, 'Configuración'),
                  color: Colors.grey,
                  isWeb: true,
                ),
                _buildFunctionalityCard(
                  context,
                  'Ver Todos los Certificados',
                  Icons.description,
                  'Acceso completo a todos los certificados',
                  () => _showComingSoon(context, 'Ver Certificados'),
                  color: Colors.green,
                  isWeb: true,
                ),
                _buildFunctionalityCard(
                  context,
                  'Reportes del Sistema',
                  Icons.analytics,
                  'Generar reportes completos del sistema',
                  () => _showComingSoon(context, 'Reportes'),
                  color: Colors.orange,
                  isWeb: true,
                ),
                _buildFunctionalityCard(
                  context,
                  'Gestión de Usuarios',
                  Icons.people,
                  'Administrar todos los usuarios del sistema',
                  () => _showComingSoon(context, 'Gestión de Usuarios'),
                  color: Colors.purple,
                  isWeb: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header responsive
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
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
                  'Bienvenido, ${_userContext?.userName ?? 'Administrador'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Administrador de ${_userContext?.currentInstitution?.name ?? 'Institución'}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (_userContext?.currentInstitution?.shortName != null) ...[
                  SizedBox(height: 4),
                  Text(
                    '(${_userContext!.currentInstitution!.shortName})',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Información de la institución
          if (_userContext?.currentInstitution != null) ...[
            _buildInstitutionInfoCard(context, isWeb: false),
            SizedBox(height: 16),
          ],
          
          // Funcionalidades principales
          Text(
            'Panel de Administración',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff2E2F44),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Grid de funcionalidades responsive
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _buildFunctionalityCard(
                  context,
                  'Gestionar Emisores',
                  Icons.person_add,
                  'Crear, editar y gestionar usuarios emisores',
                  () => _navigateToManageEmisores(context),
                  color: Colors.purple,
                  isWeb: false,
                ),
                                  _buildFunctionalityCard(
                    context,
                    'Facultades y Programas',
                    Icons.school,
                    'Administrar facultades y programas',
                    () => _navigateToFacultiesPrograms(context),
                    color: Colors.blue,
                    isWeb: false,
                  ),
                _buildFunctionalityCard(
                  context,
                  'Configuración del Sistema',
                  Icons.settings,
                  'Configurar parámetros del sistema',
                  () => _showComingSoon(context, 'Configuración'),
                  color: Colors.grey,
                  isWeb: false,
                ),
                _buildFunctionalityCard(
                  context,
                  'Ver Todos los Certificados',
                  Icons.description,
                  'Acceso completo a todos los certificados',
                  () => _showComingSoon(context, 'Ver Certificados'),
                  color: Colors.green,
                  isWeb: false,
                ),
                _buildFunctionalityCard(
                  context,
                  'Reportes del Sistema',
                  Icons.analytics,
                  'Generar reportes completos del sistema',
                  () => _showComingSoon(context, 'Reportes'),
                  color: Colors.orange,
                  isWeb: false,
                ),
                _buildFunctionalityCard(
                  context,
                  'Gestión de Usuarios',
                  Icons.people,
                  'Administrar todos los usuarios del sistema',
                  () => _showComingSoon(context, 'Gestión de Usuarios'),
                  color: Colors.purple,
                  isWeb: false,
                ),
              ],
            ),
          ),
        ],
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

  void _navigateToManageEmisores(BuildContext context) {
    Navigator.of(context).pushNamed('/manage_emisores');
  }

  void _navigateToFacultiesPrograms(BuildContext context) {
    Navigator.of(context).pushNamed('/faculties_programs');
  }

  Widget _buildInstitutionInfoCard(BuildContext context, {required bool isWeb}) {
    final institution = _userContext?.currentInstitution;
    if (institution == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Color(0xff6C4DDC),
                  size: isWeb ? 32 : 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de la Institución',
                        style: TextStyle(
                          fontSize: isWeb ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        institution.name,
                        style: TextStyle(
                          fontSize: isWeb ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff6C4DDC),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (institution.description.isNotEmpty) ...[
              Text(
                'Descripción:',
                style: TextStyle(
                  fontSize: isWeb ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 4),
              Text(
                institution.description,
                style: TextStyle(
                  fontSize: isWeb ? 14 : 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Estado',
                    institution.status.displayName,
                    Icons.info_outline,
                    isWeb: isWeb,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Programas',
                    '${institution.settings.supportedPrograms.length}',
                    Icons.menu_book,
                    isWeb: isWeb,
                  ),
                ),
              ],
            ),
            if (institution.shortName.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoItem(
                'Nombre Corto',
                institution.shortName,
                Icons.label,
                isWeb: isWeb,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {required bool isWeb}) {
    return Row(
      children: [
        Icon(
          icon,
          size: isWeb ? 16 : 14,
          color: Color(0xff6C4DDC),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isWeb ? 12 : 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isWeb ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff2E2F44),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
