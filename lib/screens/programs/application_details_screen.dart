// lib/screens/programs/application_details_screen.dart
// Pantalla de detalles de una postulación específica

import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final Application application;

  const ApplicationDetailsScreen({Key? key, required this.application}) : super(key: key);

  @override
  _ApplicationDetailsScreenState createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de Postulación'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              _buildHeader(isWeb),
              
              SizedBox(height: 24),
              
              // Información del programa
              _buildProgramInfo(isWeb),
              
              SizedBox(height: 24),
              
              // Información del estudiante
              _buildStudentInfo(isWeb),
              
              SizedBox(height: 24),
              
              // Certificados seleccionados
              _buildCertificatesSection(isWeb),
              
              SizedBox(height: 24),
              
              // Carta de motivación
              _buildMotivationSection(isWeb),
              
              SizedBox(height: 24),
              
              // Información de revisión
              if (widget.application.reviewedAt != null)
                _buildReviewInfo(isWeb),
              
              SizedBox(height: 24),
              
              // Acciones disponibles
              _buildActions(isWeb),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse(widget.application.status.color.replaceAll('#', '0xFF'))),
              Color(int.parse(widget.application.status.color.replaceAll('#', '0xFF'))).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(widget.application.status),
              size: isWeb ? 48 : 40,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              widget.application.status.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Postulación enviada el ${_formatDate(widget.application.submittedAt)}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isWeb ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramInfo(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Programa',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.work,
              'Programa',
              widget.application.programTitle,
              isWeb,
            ),
            _buildInfoRow(
              Icons.school,
              'Institución',
              widget.application.institutionName,
              isWeb,
            ),
            _buildInfoRow(
              Icons.schedule,
              'Fecha de envío',
              _formatDate(widget.application.submittedAt),
              isWeb,
            ),
            if (widget.application.reviewedAt != null)
              _buildInfoRow(
                Icons.check_circle,
                'Fecha de revisión',
                _formatDate(widget.application.reviewedAt!),
                isWeb,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Estudiante',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              'Nombre',
              widget.application.studentName,
              isWeb,
            ),
            _buildInfoRow(
              Icons.email,
              'Email',
              widget.application.studentEmail,
              isWeb,
            ),
            _buildInfoRow(
              Icons.description,
              'CV',
              widget.application.cvFileName,
              isWeb,
              onTap: () => _downloadCV(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificados Incluidos',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            if (widget.application.certificateDetails.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No se incluyeron certificados',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...widget.application.certificateDetails.map((cert) => 
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert['title'] ?? 'Certificado',
                        style: TextStyle(
                          fontSize: isWeb ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${cert['type'] ?? 'Tipo'} - ${cert['institutionName'] ?? 'Institución'}',
                        style: TextStyle(
                          fontSize: isWeb ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Emitido: ${_formatDate(DateTime.parse(cert['issuedAt']))}',
                        style: TextStyle(
                          fontSize: isWeb ? 12 : 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationSection(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carta de Motivación',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                widget.application.motivationLetter,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewInfo(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de Revisión',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            if (widget.application.reviewedByName != null)
              _buildInfoRow(
                Icons.person,
                'Revisado por',
                widget.application.reviewedByName!,
                isWeb,
              ),
            if (widget.application.notes != null && widget.application.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    'Notas del revisor:',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      widget.application.notes!,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            if (widget.application.rejectionReason != null && widget.application.rejectionReason!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    'Motivo de rechazo:',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      widget.application.rejectionReason!,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 13,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Disponibles',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            
            if (widget.application.canBeWithdrawn) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _withdrawApplication(),
                  icon: Icon(Icons.cancel, size: 18),
                  label: Text('Retirar Postulación'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _downloadCV(),
                icon: Icon(Icons.download, size: 18),
                label: Text('Descargar CV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xff6C4DDC),
                  side: BorderSide(color: Color(0xff6C4DDC)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isWeb, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: isWeb ? 20 : 18, color: Color(0xff6C4DDC)),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isWeb ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff2E2F44),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: onTap != null ? Color(0xff6C4DDC) : Colors.grey[700],
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule;
      case ApplicationStatus.under_review:
        return Icons.visibility;
      case ApplicationStatus.approved:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ApplicationStatus.withdrawn:
        return Icons.undo;
    }
  }

  void _downloadCV() {
    // TODO: Implementar descarga de CV
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de descarga en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _withdrawApplication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirar Postulación'),
        content: Text('¿Estás seguro de que quieres retirar tu postulación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Retirar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApplicationService.withdrawApplication(widget.application.id);
        Navigator.pop(context, true); // Volver con resultado de éxito
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al retirar postulación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
