// lib/screens/emisor/emit_certificate_screen.dart
// Pantalla para emitir certificados con control de permisos

import 'package:flutter/material.dart';
import '../../services/emisor_permission_service.dart';

class EmitCertificateScreen extends StatefulWidget {
  final String studentId;
  final String institutionId;

  const EmitCertificateScreen({
    Key? key,
    required this.studentId,
    required this.institutionId,
  }) : super(key: key);

  @override
  _EmitCertificateScreenState createState() => _EmitCertificateScreenState();
}

class _EmitCertificateScreenState extends State<EmitCertificateScreen> {
  bool _isLoading = true;
  bool _canEmit = false;
  String _permissionReason = '';
  Map<String, dynamic> _studentInfo = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Verificar si el emisor puede emitir para este estudiante
      final canEmit = await EmisorPermissionService.canEmitForStudent(
        studentId: widget.studentId,
        institutionId: widget.institutionId,
      );

      if (canEmit) {
        // Obtener información del estudiante
        final students = await EmisorPermissionService.getStudentsForEmisor(
          institutionId: widget.institutionId,
        );
        
        final student = students.firstWhere(
          (s) => s['id'] == widget.studentId,
          orElse: () => {},
        );

        setState(() {
          _canEmit = true;
          _studentInfo = student;
        });
      } else {
        setState(() {
          _canEmit = false;
          _permissionReason = 'No tienes permisos para emitir certificados para este estudiante';
        });
      }
    } catch (e) {
      setState(() {
        _canEmit = false;
        _permissionReason = 'Error verificando permisos: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emitir Certificado'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _canEmit
              ? _buildEmitForm()
              : _buildPermissionDenied(),
    );
  }

  Widget _buildEmitForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del estudiante
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Estudiante',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
                        child: Text(
                          _studentInfo['fullName']?.substring(0, 1).toUpperCase() ?? 'S',
                          style: TextStyle(
                            color: Color(0xff6C4DDC),
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
                              _studentInfo['fullName'] ?? 'Estudiante',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ID: ${_studentInfo['studentIdInInstitution'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (_studentInfo['program'] != null) ...[
                              SizedBox(height: 2),
                              Text(
                                'Programa: ${_studentInfo['program']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (_studentInfo['faculty'] != null) ...[
                              SizedBox(height: 2),
                              Text(
                                'Facultad: ${_studentInfo['faculty']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Formulario de emisión
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos del Certificado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tipo de Certificado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                    initialValue: 'Certificado de Estudios',
                  ),
                  
                  SizedBox(height: 16),
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Fecha de Emisión',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    initialValue: DateTime.now().toString().split(' ')[0],
                  ),
                  
                  SizedBox(height: 16),
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Observaciones (Opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  
                  SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _emitCertificate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Emitir Certificado',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Colors.red[300],
            ),
            SizedBox(height: 24),
            Text(
              'Acceso Denegado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _permissionReason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  void _emitCertificate() {
    // Aquí se implementaría la lógica real de emisión de certificados
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Certificado emitido exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
