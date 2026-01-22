// lib/screens/programs/application_details_screen.dart
// Pantalla de detalles de una postulación específica

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:url_launcher/url_launcher.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';
import '../../services/supabase/supabase_certificate_service.dart';

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
                  child: InkWell(
                    onTap: () => _viewCertificate(cert),
                    child: Row(
                      children: [
                        Expanded(
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
                              if (cert['issuedAt'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Emitido: ${_formatDate(DateTime.parse(cert['issuedAt']))}',
                        style: TextStyle(
                          fontSize: isWeb ? 12 : 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                            ],
                          ),
                        ),
                        Icon(Icons.visibility, size: 18, color: Color(0xff6C4DDC)),
                      ],
                    ),
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
            if (widget.application.motivationPdfData != null && widget.application.motivationPdfData!.isNotEmpty)
              SizedBox(
              width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openMotivationPdf(),
                  icon: Icon(Icons.picture_as_pdf, size: 18),
                  label: Text('Ver PDF de Carta de Motivación'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xff6C4DDC),
                    side: BorderSide(color: Color(0xff6C4DDC)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.description, size: 18),
                  label: Text('Carta de motivación en texto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey),
                    padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMotivationPdf() async {
    final pdfData = widget.application.motivationPdfData;
    if (pdfData == null || pdfData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay PDF de carta de motivación disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      await _openPdfFromBase64(pdfData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _downloadCV() async {
    try {
      final cvUrl = widget.application.cvUrl;
      if (cvUrl.isEmpty) {
        throw Exception('CV no disponible');
      }

      // Si es una URL de Supabase Storage o HTTP(S), abrirla
      if (cvUrl.startsWith('http://') || cvUrl.startsWith('https://')) {
        final uri = Uri.parse(cvUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('No se pudo abrir la URL del CV');
        }
      } else {
        // Es base64, convertir y abrir con blob URL
        await _openPdfFromBase64(cvUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir CV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openPdfFromBase64(String base64Data) async {
    try {
      print('🔄 Abriendo PDF desde base64...');
      
      // Determinar si es base64 puro o data URL
      String dataUrl;
      if (base64Data.startsWith('data:application/pdf;base64,')) {
        dataUrl = base64Data;
      } else if (base64Data.startsWith('data:')) {
        dataUrl = base64Data;
      } else {
        dataUrl = 'data:application/pdf;base64,$base64Data';
      }
      
      // Extraer el base64 del data URL
      final String base64Content = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Content);
      print('📊 Bytes decodificados: ${bytes.length} bytes');
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      print('📄 Blob URL creada: $blobUrl');
      
      // Abrir en nueva pestaña
      html.window.open(blobUrl, '_blank');
      
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('PDF abierto en nueva pestaña'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Limpiar la URL del blob después de un tiempo
      Future.delayed(Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(blobUrl);
        print('🧹 Blob URL limpiada');
      });
      
    } catch (e) {
      print('❌ Error al abrir PDF: $e');
      throw Exception('Error al abrir PDF: $e');
    }
  }

  void _viewCertificate(Map<String, dynamic> cert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: Color(0xff6C4DDC), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                cert['title'] ?? 'Certificado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCertificateInfoRow(
                      Icons.category,
                      'Tipo',
                      cert['type'] ?? 'N/A',
                    ),
                    SizedBox(height: 8),
                    _buildCertificateInfoRow(
                      Icons.school,
                      'Institución',
                      cert['institutionName'] ?? 'N/A',
                    ),
                    if (cert['issuedAt'] != null) ...[
                      SizedBox(height: 8),
                      _buildCertificateInfoRow(
                        Icons.calendar_today,
                        'Fecha de Emisión',
                        _formatDate(DateTime.parse(cert['issuedAt'])),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openCertificatePdf(cert);
                  },
                  icon: Icon(Icons.picture_as_pdf, size: 20),
                  label: Text('Ver PDF del Certificado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Color(0xff6C4DDC)),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xff2E2F44),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  void _openCertificatePdf(Map<String, dynamic> cert) async {
    try {
      final certId = cert['id'];
      if (certId == null || certId.toString().isEmpty) {
        throw Exception('ID de certificado no disponible');
      }

      // Obtener el certificado completo de Supabase
      final certificate = await SupabaseCertificateService.getCertificate(certId.toString());
      
      if (certificate == null) {
        throw Exception('Certificado no encontrado');
      }

      // Buscar PDF en el campo data
      final data = certificate.data;
      final customData = data['customCertificateData'];
      
      String? pdfData;
      if (customData is String) {
        pdfData = customData;
      } else if (customData is Map<String, dynamic>) {
        pdfData = customData['fileData'] ?? 
                 customData['data'] ?? 
                 customData['content'] ?? 
                 customData['base64'] ??
                 customData['pdfData'];
      }

      if (pdfData != null && pdfData.isNotEmpty) {
        await _openPdfFromBase64(pdfData);
      } else {
        throw Exception('No hay PDF disponible para este certificado');
      }
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Error al abrir PDF del certificado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
