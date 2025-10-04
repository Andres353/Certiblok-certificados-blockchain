// lib/screens/emisor/emisor_dashboard.dart
// Dashboard para emisores con control de permisos por área académica

import 'package:flutter/material.dart';
import '../../services/user_context_service.dart';
import '../../services/emisor_permission_service.dart';
import '../certificates/emit_certificate_screen.dart';
import '../certificates/my_certificates_screen.dart';
import '../certificates/template_management_screen.dart';

class EmisorDashboard extends StatefulWidget {
  @override
  _EmisorDashboardState createState() => _EmisorDashboardState();
}

class _EmisorDashboardState extends State<EmisorDashboard> {
  UserContext? _userContext;
  Map<String, dynamic> _permissions = {};
  List<Map<String, dynamic>> _allowedStudents = [];
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
      await _loadPermissions();
      await _loadAllowedStudents();
    }
  }

  Future<void> _loadPermissions() async {
    final permissions = await EmisorPermissionService.getEmisorPermissions();
    setState(() {
      _permissions = permissions;
    });
  }

  Future<void> _loadAllowedStudents() async {
    if (_userContext?.institutionId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final students = await EmisorPermissionService.getStudentsForEmisor(
        institutionId: _userContext!.institutionId!,
      );
      
      setState(() {
        _allowedStudents = students;
      });
    } catch (e) {
      print('Error cargando estudiantes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard de Emisor'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
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
                  
                  SizedBox(height: 24),
                  
                  // Lista de estudiantes permitidos
                  _buildStudentsCard(),
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
                  title: 'Emitir Certificado',
                  subtitle: 'Crear nuevo certificado',
                  color: Color(0xff6C4DDC),
                  onTap: () => _navigateToEmitCertificate(),
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
                  icon: Icons.settings,
                  title: 'Configuración',
                  subtitle: 'Ajustes del emisor',
                  color: Color(0xff9C27B0),
                  onTap: () => _navigateToSettings(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.assignment_turned_in,
                  title: 'Gestionar Postulaciones',
                  subtitle: 'Revisar postulaciones de estudiantes',
                  color: Color(0xffFF5722),
                  onTap: () => _navigateToApplicationsManagement(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.work_outline,
                  title: 'Crear Programa',
                  subtitle: 'Crear nueva oportunidad de programa',
                  color: Color(0xff795548),
                  onTap: () => _navigateToCreateProgram(),
                ),
                _buildFunctionalityCard(
                  icon: Icons.help,
                  title: 'Ayuda',
                  subtitle: 'Soporte y guías',
                  color: Color(0xff607D8B),
                  onTap: () => _navigateToHelp(),
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

  Widget _buildStudentsCard() {
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
                Text(
                  'Estudiantes Disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
                Spacer(),
                Text(
                  '${_allowedStudents.length} estudiantes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_allowedStudents.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No hay estudiantes disponibles para tu área de permisos',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _allowedStudents.length,
                itemBuilder: (context, index) {
                  final student = _allowedStudents[index];
                  return _buildStudentCard(student);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
            child: Text(
              student['fullName']?.substring(0, 1).toUpperCase() ?? 'S',
              style: TextStyle(
                color: Color(0xff6C4DDC),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['fullName'] ?? 'Estudiante',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ID: ${student['studentIdInInstitution'] ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (student['program'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Programa: ${student['program']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                if (student['faculty'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Facultad: ${student['faculty']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _emitCertificate(student),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text('Emitir'),
          ),
        ],
      ),
    );
  }

  void _emitCertificate(Map<String, dynamic> student) {
    // Aquí se implementaría la lógica para emitir certificados
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de emisión de certificados en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Métodos de navegación para las funcionalidades
  void _navigateToEmitCertificate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmitCertificateScreen(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a Gestionar Estudiantes...'),
        backgroundColor: Color(0xffFF9800),
      ),
    );
    // TODO: Implementar navegación a pantalla de gestión de estudiantes
  }

  void _navigateToStatistics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a Estadísticas...'),
        backgroundColor: Color(0xff2196F3),
      ),
    );
    // TODO: Implementar navegación a pantalla de estadísticas
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a Configuración...'),
        backgroundColor: Color(0xff9C27B0),
      ),
    );
    // TODO: Implementar navegación a pantalla de configuración
  }

  void _navigateToTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateManagementScreen(),
      ),
    );
  }

  void _navigateToApplicationsManagement() {
    Navigator.pushNamed(context, '/applications-management');
  }

  void _navigateToCreateProgram() {
    Navigator.pushNamed(context, '/create-program');
  }

  void _navigateToHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a Ayuda...'),
        backgroundColor: Color(0xff607D8B),
      ),
    );
    // TODO: Implementar navegación a pantalla de ayuda
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