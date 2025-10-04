import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          // Header clickeable
          GestureDetector(
            onTap: () => _showInstitutionInfoModal(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff6C4DDC).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
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
                      Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca para ver información detallada de la institución',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 32),
          
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
          
          // Grid de funcionalidades que se ajusta a la pantalla
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calcular número de columnas para ajustar a la pantalla
                int crossAxisCount;
                double childAspectRatio;
                
                // Calcular el espacio disponible
                final availableWidth = constraints.maxWidth;
                
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
                  crossAxisCount = 1;
                  childAspectRatio = 3.0;
                }
                
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
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
                  'Carreras',
                  Icons.school,
                  'Administrar carreras académicas',
                  () => _navigateToFacultiesPrograms(context),
                  color: Colors.blue,
                  isWeb: true,
                ),
                _buildFunctionalityCard(
                  context,
                  'Programas y Postulaciones',
                  Icons.work_outline,
                  'Crear programas de pasantías y gestionar postulaciones de estudiantes',
                  () => _showProgramsAndApplicationsMenu(context),
                  color: Colors.indigo,
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
                );
              },
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
          // Header responsive clickeable
          GestureDetector(
            onTap: () => _showInstitutionInfoModal(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff6C4DDC).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
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
                      Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca para ver información detallada',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
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
                  'Carreras',
                  Icons.school,
                  'Administrar carreras',
                  () => _navigateToFacultiesPrograms(context),
                  color: Colors.blue,
                  isWeb: false,
                ),
                _buildFunctionalityCard(
                  context,
                  'Programas y Postulaciones',
                  Icons.work_outline,
                  'Crear programas de pasantías y gestionar postulaciones',
                  () => _showProgramsAndApplicationsMenu(context),
                  color: Colors.indigo,
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

  void _navigateToProgramsManagement(BuildContext context) {
    Navigator.of(context).pushNamed('/programs-management');
  }

  void _navigateToApplicationsManagement(BuildContext context) {
    Navigator.of(context).pushNamed('/applications-management');
  }

  void _showProgramsAndApplicationsMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.work_outline, color: Colors.indigo),
              SizedBox(width: 12),
              Text('Programas y Postulaciones'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona la acción que deseas realizar:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              _buildMenuOption(
                context,
                'Gestionar Programas',
                'Crear y administrar programas de pasantías',
                Icons.work_outline,
                Colors.indigo,
                () {
                  Navigator.of(context).pop();
                  _navigateToProgramsManagement(context);
                },
              ),
              SizedBox(height: 12),
              _buildMenuOption(
                context,
                'Gestionar Postulaciones',
                'Revisar y gestionar postulaciones de estudiantes',
                Icons.assignment_turned_in,
                Colors.orange,
                () {
                  Navigator.of(context).pop();
                  _navigateToApplicationsManagement(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
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

  void _showInstitutionInfoModal(BuildContext context) {
    final institution = _userContext?.currentInstitution;
    if (institution == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 600,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header del modal
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información de la Institución',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                institution.name,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido del modal
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: _buildInstitutionInfoContent(institution),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstitutionInfoContent(institution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Código de Institución
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xff6C4DDC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    color: Color(0xff6C4DDC),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Código de Institución',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        institution.institutionCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff6C4DDC),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _copyInstitutionCode(institution.institutionCode),
                    icon: Icon(Icons.copy, color: Color(0xff6C4DDC)),
                    tooltip: 'Copiar código',
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Comparte este código con tus estudiantes para que puedan registrarse en tu institución',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Descripción
        if (institution.description.isNotEmpty) ...[
          Text(
            'Descripción:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xff2E2F44),
            ),
          ),
          SizedBox(height: 4),
          Text(
            institution.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
        ],
        
        // Información adicional
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Estado',
                institution.status.displayName,
                Icons.info_outline,
                isWeb: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Programas',
                '${institution.settings.supportedPrograms.length}',
                Icons.menu_book,
                isWeb: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Registro de Estudiantes',
                institution.settings.allowStudentRegistration ? 'Habilitado' : 'Deshabilitado',
                Icons.person_add,
                isWeb: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Verificación Pública',
                institution.settings.allowPublicVerification ? 'Habilitada' : 'Deshabilitada',
                Icons.verified,
                isWeb: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Blockchain',
                institution.settings.enableBlockchain ? 'Habilitado' : 'Deshabilitado',
                Icons.link,
                isWeb: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Idioma',
                institution.settings.defaultLanguage.toUpperCase(),
                Icons.language,
                isWeb: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        // Fechas
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fechas de Registro',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Creado',
                      institution.createdAt != null 
                          ? '${institution.createdAt!.day}/${institution.createdAt!.month}/${institution.createdAt!.year}'
                          : 'No disponible',
                      Icons.calendar_today,
                      isWeb: true,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      'Actualizado',
                      institution.updatedAt != null 
                          ? '${institution.updatedAt!.day}/${institution.updatedAt!.month}/${institution.updatedAt!.year}'
                          : 'No disponible',
                      Icons.update,
                      isWeb: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyInstitutionCode(String code) {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código copiado al portapapeles: $code'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
