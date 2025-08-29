import 'package:flutter/material.dart';
import '../constants/roles.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('=== DEBUG ADMIN DASHBOARD ===');
    print('AdminDashboard se está construyendo');
    print('Context: $context');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrador UV - Dashboard'),
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
                    'Bienvenido, Administrador UV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    UserRoles.getRoleDescription(UserRoles.ADMIN_UV),
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
              'Panel de Administración',
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
                    'Gestionar Emisores',
                    Icons.person_add,
                    'Crear, editar y gestionar usuarios emisores',
                    () => _navigateToManageEmisores(context),
                    color: Colors.purple,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Facultades y Programas',
                    Icons.school,
                    'Administrar facultades y programas académicos',
                    () => _showComingSoon(context, 'Facultades y Programas'),
                    color: Colors.blue,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Configuración del Sistema',
                    Icons.settings,
                    'Configurar parámetros del sistema',
                    () => _showComingSoon(context, 'Configuración'),
                    color: Colors.grey,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Ver Todos los Certificados',
                    Icons.description,
                    'Acceso completo a todos los certificados',
                    () => _showComingSoon(context, 'Ver Certificados'),
                    color: Colors.green,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Reportes del Sistema',
                    Icons.analytics,
                    'Generar reportes completos del sistema',
                    () => _showComingSoon(context, 'Reportes'),
                    color: Colors.orange,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Gestión de Usuarios',
                    Icons.people,
                    'Administrar todos los usuarios del sistema',
                    () => _showComingSoon(context, 'Gestión de Usuarios'),
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
}
