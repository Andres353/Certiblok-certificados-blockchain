// lib/screens/emisor/emisor_manage_students_screen.dart
// Pantalla para que el emisor vea y gestione los estudiantes según sus asignaciones

import 'package:flutter/material.dart';
import '../../services/user_context_service.dart';
import '../../services/emisor_permission_service.dart';
import '../certificates/emit_certificate_screen.dart';

class EmisorManageStudentsScreen extends StatefulWidget {
  const EmisorManageStudentsScreen({Key? key}) : super(key: key);

  @override
  State<EmisorManageStudentsScreen> createState() => _EmisorManageStudentsScreenState();
}

class _EmisorManageStudentsScreenState extends State<EmisorManageStudentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic> _permissions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario debe tener institución asignada');
      }

      // Obtener estudiantes permitidos para el emisor
      final students = await EmisorPermissionService.getStudentsForEmisor(
        institutionId: userContext!.institutionId!,
      );

      // Obtener permisos del emisor
      final permissions = await EmisorPermissionService.getEmisorPermissions();

      setState(() {
        _students = students;
        _permissions = permissions;
        _isLoading = false;
      });

      print('📊 Estudiantes cargados para emisor: ${_students.length}');
    } catch (e) {
      print('❌ Error cargando estudiantes: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando estudiantes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Estudiantes'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : _buildStudentsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'No hay estudiantes disponibles',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No hay estudiantes en tus carreras asignadas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de resumen
            _buildSummaryCard(),
            SizedBox(height: 24),
            
            // Información de permisos
            _buildPermissionsInfo(),
            SizedBox(height: 24),
            
            // Lista de estudiantes
            Text(
              'Estudiantes (${_students.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            
            ..._students.map((student) => _buildStudentCard(student)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Estudiantes Disponibles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '${_students.length} estudiante${_students.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsInfo() {
    final emisorType = _permissions['emisorType']?.toString() ?? 'general';
    final carreraName = _permissions['carreraName'] as String?;
    final facultadName = _permissions['facultadName'] as String?;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Color(0xff6C4DDC),
              size: 32,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permisos de Emisión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 4),
                  if (emisorType == 'general')
                    Text(
                      'Puedes emitir certificados a todos los estudiantes',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    )
                  else if (carreraName != null)
                    Text(
                      'Carrera: $carreraName',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    )
                  else if (facultadName != null)
                    Text(
                      'Facultad: $facultadName',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final fullName = student['fullName'] ?? 'Sin nombre';
    final email = student['email'] ?? 'Sin email';
    final studentId = student['studentIdInInstitution'] ?? student['studentId'] ?? 'Sin ID';
    final program = student['program'] ?? 'Sin programa';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
              child: Text(
                fullName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Color(0xff6C4DDC),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 4),
                  if (studentId != 'Sin ID') ...[
                    Text(
                      'ID: $studentId',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  SizedBox(height: 4),
                  if (email != 'Sin email' && email.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 4),
                  if (program != 'Sin programa') ...[
                    Row(
                      children: [
                        Icon(Icons.school, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Carrera: $program',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _onEmitCertificate(student),
              icon: Icon(Icons.description, size: 20),
              label: Text('Emitir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onEmitCertificate(Map<String, dynamic> student) {
    // Navegar directamente a la pantalla de emitir certificado con el estudiante seleccionado
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmitCertificateScreen(
          studentId: student['id'],
        ),
      ),
    );
  }
}

