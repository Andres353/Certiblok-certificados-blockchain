import 'package:flutter/material.dart';
import '../../constants/roles.dart';

class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard del Estudiante'),
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
                    'Bienvenido, Estudiante',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWeb ? 28 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    UserRoles.getRoleDescription(UserRoles.STUDENT),
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
              'Mis Certificados y Documentos',
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
                    'Ver Mis Certificados',
                    Icons.description,
                    'Consulta todos tus certificados emitidos',
                    () => _showComingSoon(context, 'Ver Certificados'),
                    color: Colors.blue,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Organizar Documentos',
                    Icons.folder,
                    'Organiza y categoriza tus documentos',
                    () => _showComingSoon(context, 'Organizar Documentos'),
                    color: Colors.green,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Compartir Certificados',
                    Icons.share,
                    'Comparte certificados por QR o enlace',
                    () => _showComingSoon(context, 'Compartir Certificados'),
                    color: Colors.orange,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Descargar PDFs',
                    Icons.download,
                    'Descarga tus certificados en PDF',
                    () => _showComingSoon(context, 'Descargar PDFs'),
                    color: Colors.red,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Historial Académico',
                    Icons.history_edu,
                    'Consulta tu historial académico completo',
                    () => _showComingSoon(context, 'Historial Académico'),
                    color: Colors.purple,
                    isWeb: isWeb,
                  ),
                  _buildFunctionalityCard(
                    context,
                    'Estado de Verificación',
                    Icons.verified,
                    'Verifica el estado de tus documentos',
                    () => _showComingSoon(context, 'Estado de Verificación'),
                    color: Colors.teal,
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
}
