import 'package:flutter/material.dart';
import '../constants/roles.dart';

class PublicDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verificador de Certificados - UV'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informativo
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
                    'Verificador de Certificados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Universidad del Valle - Sistema Blockchain',
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
              '¿Cómo verificar un certificado?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Opciones de verificación
            Expanded(
              child: Column(
                children: [
                  _buildVerificationOption(
                    context,
                    'Escanear Código QR',
                    Icons.qr_code_scanner,
                    'Escanea el código QR del certificado para verificar su autenticidad',
                    () => _showComingSoon(context, 'Escanear QR'),
                    color: Colors.green,
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildVerificationOption(
                    context,
                    'Buscar por Número',
                    Icons.search,
                    'Busca un certificado por su número de identificación',
                    () => _showComingSoon(context, 'Búsqueda por Número'),
                    color: Colors.blue,
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildVerificationOption(
                    context,
                    'Verificar por Email',
                    Icons.email,
                    'Verifica un certificado usando el email del estudiante',
                    () => _showComingSoon(context, 'Verificación por Email'),
                    color: Colors.orange,
                  ),
                  
                  Spacer(),
                  
                  // Información adicional
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ℹ️ Información Importante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Todos los certificados están verificados con tecnología blockchain\n'
                          '• La información es inmutable y segura\n'
                          '• Puedes verificar cualquier certificado emitido por la UV\n'
                          '• Los datos están protegidos y solo se muestran públicamente',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
  
  Widget _buildVerificationOption(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (color ?? Color(0xff6C4DDC)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color ?? Color(0xff6C4DDC),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E2F44),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
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
