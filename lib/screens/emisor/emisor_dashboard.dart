// lib/screens/emisor/emisor_dashboard.dart
// Dashboard para emisores con control de permisos por área académica

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_context_service.dart';
import '../../services/emisor_permission_service.dart';
import '../../services/institution_status_service.dart';
import '../../services/adapters/auth_adapter.dart';
import '../../widgets/suspended_institution_widget.dart';
import '../certificates/emit_certificate_screen.dart';
import '../certificates/my_certificates_screen.dart';
import '../certificates/basic_template_editor_screen.dart';
import 'bulk_emit_certificates_screen.dart';
import 'emisor_manage_students_screen.dart';
import 'emisor_statistics_screen.dart';

class EmisorDashboard extends StatefulWidget {
  @override
  _EmisorDashboardState createState() => _EmisorDashboardState();
}

class _EmisorDashboardState extends State<EmisorDashboard> {
  UserContext? _userContext;
  Map<String, dynamic> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final context = await UserContextService.loadUserContext();
    setState(() {
      _userContext = context;
    });
    
    if (context != null) {
      // Verificar si la institución está suspendida
      if (context.institutionId != null) {
        final isSuspended = await InstitutionStatusService.isInstitutionSuspended(context.institutionId!);
        if (isSuspended) {
          setState(() {
            _isLoading = false;
          });
          return; // Mostrar pantalla de suspensión
        }
      }
      
      await _loadPermissions();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPermissions() async {
    final permissions = await EmisorPermissionService.getEmisorPermissions();
    setState(() {
      _permissions = permissions;
    });
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando...'),
          backgroundColor: Color(0xff6C4DDC),
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
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
                      userRole: 'emisor',
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
          return _buildNormalDashboard(context);
        },
      );
    }
    
    return _buildNormalDashboard(context);
  }

  Widget _buildNormalDashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard de Emisor'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: _userContext == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del emisor
                  _buildEmisorInfoCard(),
                  
                  SizedBox(height: 24),
                  
                  // Permisos del emisor
                  _buildPermissionsCard(),
                  
                  SizedBox(height: 24),
                  
                  // Cards de funcionalidades principales
                  _buildFunctionalityCards(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmisorInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xff6C4DDC),
                  child: Text(
                    (_userContext?.userName ?? 'E').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userContext?.userName ?? 'Emisor',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 4),
                  Text(
                        _userContext?.currentInstitution?.name ?? 'Institución',
                    style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildPermissionsCard() {
    if (_permissions.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final emisorType = _permissions['emisorType']?.toString() ?? 'general';
    final carreraName = _permissions['carreraName'] as String?;
    final facultadName = _permissions['facultadName'] as String?;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permisos de Emisión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Icon(
                  _getEmisorTypeIcon(emisorType),
                  color: Color(0xff6C4DDC),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getEmisorTypeDisplayName(emisorType),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      if (carreraName != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Carrera: $carreraName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (facultadName != null && carreraName == null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Facultad: $facultadName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Puedes emitir certificados para ${_getPermissionDescription(emisorType)}',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFunctionalityCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funcionalidades Principales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff2E2F44),
          ),
        ),
        SizedBox(height: 16),
        
        // Grid de funcionalidades que se ajusta a la pantalla
        LayoutBuilder(
          builder: (context, constraints) {
            // Calcular número de columnas para ajustar a la pantalla
            int crossAxisCount;
            double childAspectRatio;
            
            // Calcular el espacio disponible
            final availableWidth = constraints.maxWidth;
            
            if (availableWidth > 1400) {
              crossAxisCount = 4;
              childAspectRatio = 1.2;
            } else if (availableWidth > 1000) {
              crossAxisCount = 3;
              childAspectRatio = 1.1;
            } else if (availableWidth > 700) {
              crossAxisCount = 2;
              childAspectRatio = 1.2;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 2.5;
            }
            
            return GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildFunctionalityCard(
                  icon: Icons.description,
                  title: 'Emitir Certificados',
                  subtitle: 'Emisión individual y masiva',
                  color: Color(0xff6C4DDC),
                  onTap: () => _showEmitOptions(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.list_alt,
                  title: 'Mis Certificados',
                  subtitle: 'Ver certificados emitidos',
                  color: Color(0xff4CAF50),
                  onTap: () => _navigateToMyCertificates(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.people,
                  title: 'Gestionar Estudiantes',
                  subtitle: 'Administrar estudiantes',
                  color: Color(0xffFF9800),
                  onTap: () => _navigateToManageStudents(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.analytics,
                  title: 'Estadísticas',
                  subtitle: 'Ver métricas y reportes',
                  color: Color(0xff2196F3),
                  onTap: () => _navigateToStatistics(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.description,
                  title: 'Plantillas',
                  subtitle: 'Gestionar plantillas de certificados',
                  color: Color(0xff795548),
                  onTap: () => _navigateToTemplates(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.work_outline,
                  title: 'Programas y Postulaciones',
                  subtitle: 'Gestionar programas y postulaciones',
                  color: Color(0xff9C27B0),
                  onTap: () => _showProgramsAndApplicationsMenu(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFunctionalityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                icon,
                  color: color,
                  size: 30,
                ),
              ),
              SizedBox(height: 12),
              Text(
                  title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                  textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Métodos de navegación para las funcionalidades
  void _showEmitOptions() {
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
                    _navigateToEmitCertificate();
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
                    _navigateToBulkEmit();
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

  void _navigateToEmitCertificate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmitCertificateScreen(),
      ),
    );
  }

  void _navigateToBulkEmit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkEmitCertificatesScreen(),
      ),
    );
  }


  void _navigateToMyCertificates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyCertificatesScreen(),
      ),
    );
  }

  void _navigateToManageStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmisorManageStudentsScreen(),
      ),
    );
  }

  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmisorStatisticsScreen(),
      ),
    );
  }


  void _navigateToTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BasicTemplateEditorScreen(),
      ),
    );
  }

  void _showProgramsAndApplicationsMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.work_outline, color: Color(0xff6C4DDC), size: 28),
              SizedBox(width: 12),
              Text('Programas y Postulaciones'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona la acción que deseas realizar:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              
              // Opción 1: Crear Programa
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
                    _navigateToCreateProgram();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.work_outline, color: Color(0xff6C4DDC), size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crear Programa',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Crear nueva oportunidad de programa',
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
              
              // Opción 2: Gestionar Postulaciones
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff6C4DDC), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Color(0xff6C4DDC).withOpacity(0.1),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToApplicationsManagement();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.assignment_turned_in, color: Color(0xff6C4DDC), size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestionar Postulaciones',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Revisar y gestionar postulaciones de estudiantes',
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

  void _navigateToApplicationsManagement() {
    Navigator.pushNamed(context, '/applications-management');
  }

  void _navigateToCreateProgram() {
    Navigator.pushNamed(context, '/create-program');
  }


  IconData _getEmisorTypeIcon(String emisorType) {
    switch (emisorType) {
      case 'general':
        return Icons.school;
      case 'carrera':
        return Icons.menu_book;
      case 'facultad':
        return Icons.account_balance;
      default:
        return Icons.school;
    }
  }

  String _getEmisorTypeDisplayName(String emisorType) {
    switch (emisorType) {
      case 'general':
        return 'Emisor General';
      case 'carrera':
        return 'Emisor por Carrera';
      case 'facultad':
        return 'Emisor por Facultad';
      default:
        return 'Emisor General';
    }
  }

  String _getPermissionDescription(String emisorType) {
    switch (emisorType) {
      case 'general':
        return 'todos los estudiantes de la institución';
      case 'carrera':
        return 'estudiantes de tu carrera específica';
      case 'facultad':
        return 'estudiantes de tu facultad específica';
      default:
        return 'estudiantes de la institución';
    }
  }
}