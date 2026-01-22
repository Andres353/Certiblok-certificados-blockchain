import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:frontend_app/widgets/user_info_card.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_context_service.dart';
import '../../services/institution_status_service.dart';
import '../../services/adapters/auth_adapter.dart';
import '../../widgets/suspended_institution_widget.dart';
import '../../widgets/auth_session_monitor.dart';
import 'admin_emit_certificate_screen.dart';
import 'admin_bulk_emit_certificates_screen.dart';
import 'all_certificates_screen.dart';
import 'system_reports_screen.dart';
import 'manage_students_screen.dart';
import '../certificates/basic_template_editor_screen.dart';

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
      
      // Verificar si la institución está suspendida
      if (context?.institutionId != null) {
        final isSuspended = await InstitutionStatusService.isInstitutionSuspended(context!.institutionId!);
        if (isSuspended) {
          setState(() {
            _userContext = context;
            _isLoading = false;
          });
          return; // Mostrar pantalla de suspensión
        }
      }
      
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
                      userRole: 'admin',
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
    return AuthSessionMonitor(
      onSessionExpired: () {
        // La sesión ya fue cerrada, solo redirigir
        html.window.location.reload();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Administrador - Dashboard'),
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
        body: isWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header clickeable
          if (_userContext != null)
          UserInfoCard(userContext: _userContext!, isWeb: true),
          
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
                  'Gestionar Estudiantes',
                  Icons.people,
                  'Ver estudiantes de la institución por carrera',
                  () => _navigateToManageStudents(context),
                  color: Colors.teal,
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
                  'Emitir Certificado',
                  Icons.add_circle,
                  'Emitir certificados a estudiantes de cualquier carrera',
                  () => _showEmitCertificateOptions(context),
                  color: Colors.green,
                  isWeb: true,
                ),
                _buildFunctionalityCard(
                  context,
                  'Creación de Plantilla',
                  Icons.design_services,
                  'Crear y gestionar plantillas de certificados',
                  () => _navigateToTemplateManagement(context),
                  color: Colors.purple,
                  isWeb: true,
                ),
                _buildFunctionalityCard(
                  context,
                  'Ver Todos los Certificados',
                  Icons.description,
                  'Acceso completo a todos los certificados',
                  () => _navigateToAllCertificates(context),
                  color: Colors.teal,
                  isWeb: true,
                ),
                _buildFunctionalityCard(
                  context,
                  'Reportes del Sistema',
                  Icons.analytics,
                  'Generar reportes completos del sistema',
                  () => _navigateToSystemReports(context),
                  color: Colors.orange,
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
          if (_userContext != null)
          UserInfoCard(userContext: _userContext!),
          
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
                  'Gestionar Estudiantes',
                  Icons.people,
                  'Ver estudiantes por carrera',
                  () => _navigateToManageStudents(context),
                  color: Colors.teal,
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
                  'Emitir Certificado',
                  Icons.add_circle,
                  'Emitir certificados',
                  () => _showEmitCertificateOptions(context),
                  color: Colors.green,
                  isWeb: false,
                ),
                _buildFunctionalityCard(
                  context,
                  'Creación de Plantilla',
                  Icons.design_services,
                  'Crear y gestionar plantillas',
                  () => _navigateToTemplateManagement(context),
                  color: Colors.purple,
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
                  'Ver Todos los Certificados',
                  Icons.description,
                  'Acceso completo a todos los certificados',
                  () => _navigateToAllCertificates(context),
                  color: Colors.green,
                  isWeb: false,
                ),
                _buildFunctionalityCard(
                  context,
                  'Reportes del Sistema',
                  Icons.analytics,
                  'Generar reportes completos del sistema',
                  () => _navigateToSystemReports(context),
                  color: Colors.orange,
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
  
  void _navigateToManageEmisores(BuildContext context) {
    Navigator.of(context).pushNamed('/manage_emisores');
  }

  void _navigateToFacultiesPrograms(BuildContext context) {
    Navigator.of(context).pushNamed('/faculties_programs');
  }

  void _navigateToManageStudents(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageStudentsScreen(),
      ),
    );
  }

  void _showEmitCertificateOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Color(0xff6C4DDC), size: 28),
              SizedBox(width: 12),
              Text('Emitir Certificado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona el tipo de emisión:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              
              // Opción 1: Emisión Individual
              Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff6C4DDC), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Color(0xff6C4DDC).withOpacity(0.1),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToEmitCertificate(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.person_add, color: Color(0xff6C4DDC), size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emisión Individual',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Emitir un certificado a un estudiante',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Color(0xff6C4DDC), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Opción 2: Emisión Masiva
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff6C4DDC), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Color(0xff6C4DDC).withOpacity(0.1),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToBulkEmitCertificates(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.send, color: Color(0xff6C4DDC), size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emisión Masiva',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Emitir múltiples certificados a la vez',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Color(0xff6C4DDC), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEmitCertificate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEmitCertificateScreen(),
      ),
    );
  }

  void _navigateToBulkEmitCertificates(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminBulkEmitCertificatesScreen(),
      ),
    );
  }

  void _navigateToTemplateManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BasicTemplateEditorScreen(),
      ),
    );
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


  

  void _navigateToAllCertificates(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllCertificatesScreen(),
      ),
    );
  }

  void _navigateToSystemReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SystemReportsScreen(),
      ),
    );
  }
}
