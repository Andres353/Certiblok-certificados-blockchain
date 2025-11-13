// lib/widgets/suspended_institution_widget.dart
// Widget para mostrar cuando una institución está suspendida

import 'package:flutter/material.dart';
import '../models/institution.dart';

class SuspendedInstitutionWidget extends StatelessWidget {
  final Institution institution;
  final String userRole; // 'admin', 'emisor', 'student'

  const SuspendedInstitutionWidget({
    Key? key,
    required this.institution,
    required this.userRole,
  }) : super(key: key);

  // Obtener el mensaje específico según el rol
  String _getRoleSpecificMessage() {
    switch (userRole.toLowerCase()) {
      case 'admin':
        return 'Como administrador de ${institution.name}, su acceso al sistema ha sido temporalmente suspendido. Esta medida fue tomada por el super administrador del sistema.';
      case 'emisor':
        return 'Como emisor de certificados de ${institution.name}, su capacidad para emitir certificados ha sido temporalmente suspendida. Esta medida fue tomada por el super administrador del sistema.';
      case 'student':
        return 'Como estudiante de ${institution.name}, su acceso a los certificados y funcionalidades del sistema ha sido temporalmente suspendido. Esta medida fue tomada por el super administrador del sistema.';
      default:
        return 'Su acceso al sistema ha sido temporalmente suspendido. Esta medida fue tomada por el super administrador del sistema.';
    }
  }

  // Obtener las consecuencias específicas según el rol
  List<String> _getRoleSpecificConsequences() {
    switch (userRole.toLowerCase()) {
      case 'admin':
        return [
          'No podrá gestionar usuarios, programas o configuraciones de la institución',
          'No podrá acceder al panel de administración',
          'No podrá emitir o gestionar certificados',
          'Los estudiantes y emisores de su institución también están afectados',
          'Sus certificados existentes siguen siendo válidos para verificación',
        ];
      case 'emisor':
        return [
          'No podrá emitir nuevos certificados',
          'No podrá acceder a las plantillas de certificados',
          'No podrá gestionar certificados existentes',
          'Los estudiantes no podrán solicitar certificados',
          'Sus certificados emitidos anteriormente siguen siendo válidos',
        ];
      case 'student':
        return [
          'No podrá solicitar nuevos certificados',
          'No podrá acceder a su perfil de estudiante',
          'No podrá ver el estado de sus certificados',
          'No podrá descargar certificados existentes',
          'Sus certificados ya emitidos siguen siendo válidos para verificación',
        ];
      default:
        return [
          'No podrá acceder a las funcionalidades del sistema',
          'Sus datos y certificados existentes siguen siendo válidos',
          'La suspensión es temporal y puede ser levantada',
        ];
    }
  }

  // Obtener el icono específico según el rol
  IconData _getRoleSpecificIcon() {
    switch (userRole.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'emisor':
        return Icons.assignment_turned_in;
      case 'student':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  // Obtener el color específico según el rol
  Color _getRoleSpecificColor() {
    switch (userRole.toLowerCase()) {
      case 'admin':
        return Colors.blue;
      case 'emisor':
        return Colors.orange;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Obtener el título específico según el rol
  String _getRoleSpecificTitle() {
    switch (userRole.toLowerCase()) {
      case 'admin':
        return 'Acceso de Administrador Suspendido';
      case 'emisor':
        return 'Acceso de Emisor Suspendido';
      case 'student':
        return 'Acceso de Estudiante Suspendido';
      default:
        return 'Acceso Suspendido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(30),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Icono específico del rol
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getRoleSpecificColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getRoleSpecificIcon(),
                  size: 40,
                  color: _getRoleSpecificColor(),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Título específico del rol
              Text(
                _getRoleSpecificTitle(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getRoleSpecificColor(),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16),
              
              // Nombre de la institución
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getRoleSpecificColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRoleSpecificColor().withOpacity(0.3)),
                ),
                child: Text(
                  institution.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _getRoleSpecificColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Mensaje específico del rol
              Text(
                _getRoleSpecificMessage(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              
              SizedBox(height: 24),
              
              // Información específica del rol
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getRoleSpecificColor().withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRoleSpecificColor().withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _getRoleSpecificColor(),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Consecuencias de la Suspensión',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getRoleSpecificColor(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...(_getRoleSpecificConsequences().map((consequence) => Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getRoleSpecificColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              consequence,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList()),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Botón de contacto
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Aquí podrías agregar funcionalidad para contactar soporte
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Redirigiendo a soporte técnico...'),
                        backgroundColor: Colors.blue[600],
                      ),
                    );
                  },
                  icon: Icon(Icons.support_agent),
                  label: Text('Contactar Soporte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Botón de cerrar sesión
              TextButton(
                onPressed: () {
                  // Aquí podrías agregar funcionalidad para cerrar sesión
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.grey[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
