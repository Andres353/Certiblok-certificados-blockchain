import 'package:flutter/material.dart';
import '../constants/roles.dart';

class EmisorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard del Emisor - UV'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del rol
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
                    'Bienvenido, Emisor de Certificados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    UserRoles.getRoleDescription(UserRoles.EMISOR),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Funcionalidades principales
            Text(
              'Funcionalidades Disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Grid de funcionalidades
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFunctionalityCard(
                    context,
                    'Emitir Certificados',
                    Icons.school,
                    'Crear y emitir nuevos certificados para estudiantes',
                    () => _showComingSoon(context, 'Emitir Certificados'),
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Gestionar Estudiantes',
                    Icons.people,
                    'Ver y validar información de estudiantes',
                    () => _showComingSoon(context, 'Gestionar Estudiantes'),
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Ver Certificados',
                    Icons.description,
                    'Consultar certificados emitidos',
                    () => _showComingSoon(context, 'Ver Certificados'),
                    color: Colors.green,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Plantillas',
                    Icons.edit_note,
                    'Editar plantillas de certificados',
                    () => _showComingSoon(context, 'Plantillas'),
                    color: Colors.orange,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Validaciones',
                    Icons.verified,
                    'Validar información académica',
                    () => _showComingSoon(context, 'Validaciones'),
                    color: Colors.blue,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Reportes',
                    Icons.analytics,
                    'Generar reportes de emisión',
                    () => _showComingSoon(context, 'Reportes'),
                    color: Colors.purple,
                  ),
                ],
              ),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color ?? Color(0xff6C4DDC),
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
          title: Text('Próximamente'),
          content: Text('La funcionalidad "$feature" estará disponible en la próxima versión.'),
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
