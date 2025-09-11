import 'package:flutter/material.dart';
import '../../constants/roles.dart';

class EmisorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard del Emisor'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header responsive
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWeb ? 24 : 20),
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
                      fontSize: isWeb ? 28 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    UserRoles.getRoleDescription(UserRoles.EMISOR),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isWeb ? 18 : 16,
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
                fontSize: isWeb ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Grid de funcionalidades responsive
            Expanded(
              child: GridView.count(
                crossAxisCount: isWeb ? 3 : 2,
                crossAxisSpacing: isWeb ? 20 : 16,
                mainAxisSpacing: isWeb ? 20 : 16,
                childAspectRatio: isWeb ? 1.0 : 1.1,
                children: [
                  _buildFunctionalityCard(
                    context,
                    'Emitir Certificados',
                    Icons.school,
                    'Crear y emitir nuevos certificados para estudiantes',
                    () => _showComingSoon(context, 'Emitir Certificados'),
                    color: Colors.purple,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Gestionar Estudiantes',
                    Icons.people,
                    'Ver y validar información de estudiantes',
                    () => _showComingSoon(context, 'Gestionar Estudiantes'),
                    color: Colors.blue,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Ver Certificados',
                    Icons.description,
                    'Consultar certificados emitidos',
                    () => _showComingSoon(context, 'Ver Certificados'),
                    color: Colors.green,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Plantillas',
                    Icons.edit_note,
                    'Editar plantillas de certificados',
                    () => _showComingSoon(context, 'Plantillas'),
                    color: Colors.orange,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Validaciones',
                    Icons.verified,
                    'Validar información académica',
                    () => _showComingSoon(context, 'Validaciones'),
                    color: Colors.blue,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Reportes',
                    Icons.analytics,
                    'Generar reportes de emisión',
                    () => _showComingSoon(context, 'Reportes'),
                    color: Colors.purple,
                    isWeb: isWeb,
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
