// lib/screens/certificates/certificate_detail_screen.dart
// Pantalla de detalle del certificado

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/certificate_service.dart';
import 'certificate_template_screen.dart';

class CertificateDetailScreen extends StatelessWidget {
  final Certificate certificate;

  const CertificateDetailScreen({
    Key? key,
    required this.certificate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Certificado'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareCertificate(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            certificate.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2E2F44),
                            ),
                          ),
                        ),
                        _buildStatusChip(certificate.status),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      certificate.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Información del estudiante
            _buildInfoCard(
              'Información del Estudiante',
              Icons.person,
              [
                _buildInfoRow('Nombre', certificate.studentName, context),
                _buildInfoRow('Email', certificate.studentEmail, context),
                _buildInfoRow('ID en Institución', certificate.studentIdInInstitution, context),
                _buildInfoRow('Programa', certificate.programName, context),
                _buildInfoRow('Facultad', certificate.facultyName, context),
              ],
              context,
            ),
            
            SizedBox(height: 16),
            
            // Información institucional
            _buildInfoCard(
              'Información Institucional',
              Icons.school,
              [
                _buildInfoRow('Institución', certificate.institutionName, context),
                _buildInfoRow('Código de Institución', certificate.institutionCode, context),
                _buildInfoRow('Tipo de Certificado', _getCertificateTypeLabel(certificate.certificateType), context),
              ],
              context,
            ),
            
            SizedBox(height: 16),
            
            // Información de emisión
            _buildInfoCard(
              'Información de Emisión',
              Icons.workspace_premium,
              [
                _buildInfoRow('Emitido por', certificate.issuedByName, context),
                _buildInfoRow('Rol del Emisor', _getRoleLabel(certificate.issuedByRole), context),
                _buildInfoRow('Fecha de Emisión', _formatDate(certificate.issuedAt), context),
                if (certificate.expiresAt != null)
                  _buildInfoRow('Fecha de Expiración', _formatDate(certificate.expiresAt!), context),
                if (certificate.revokedAt != null)
                  _buildInfoRow('Fecha de Revocación', _formatDate(certificate.revokedAt!), context),
                if (certificate.revokedReason != null)
                  _buildInfoRow('Motivo de Revocación', certificate.revokedReason!, context),
              ],
              context,
            ),
            
            SizedBox(height: 16),
            
            // Código QR y validación
            _buildInfoCard(
              'Validación',
              Icons.qr_code,
              [
                _buildInfoRow('ID del Certificado', certificate.id, context, isCode: true),
                _buildInfoRow('Hash Único', certificate.uniqueHash, context, isCode: true),
                _buildInfoRow('Código QR', certificate.qrCode, context, isCode: true),
                if (certificate.blockchainHash != null)
                  _buildInfoRow('Hash Blockchain', certificate.blockchainHash!, context, isCode: true),
              ],
              context,
            ),
            
            SizedBox(height: 16),
            
            // Historial de validaciones
            if (certificate.validationHistory.isNotEmpty)
              _buildValidationHistory(),
            
            SizedBox(height: 32),
            
            // Botones de acción
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children, BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xff6C4DDC)),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context, {bool isCode = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: isCode
                ? GestureDetector(
                    onTap: () => _copyToClipboard(value, context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Activo';
        break;
      case 'revoked':
        color = Colors.red;
        label = 'Revocado';
        break;
      case 'expired':
        color = Colors.orange;
        label = 'Expirado';
        break;
      default:
        color = Colors.grey;
        label = 'Desconocido';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildValidationHistory() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Color(0xff6C4DDC)),
                SizedBox(width: 8),
                Text(
                  'Historial de Validaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...certificate.validationHistory.map((validation) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: validation['isValid'] == true 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: validation['isValid'] == true 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      validation['isValid'] == true ? Icons.check_circle : Icons.cancel,
                      color: validation['isValid'] == true ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            validation['message'] ?? 'Validación',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: validation['isValid'] == true ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                          if (validation['validatedAt'] != null)
                            Text(
                              _formatDate(DateTime.parse(validation['validatedAt'])),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _viewTemplate(context),
            icon: Icon(Icons.visibility),
            label: Text('Ver Plantilla del Certificado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _downloadCertificate(context),
            icon: Icon(Icons.download),
            label: Text('Descargar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        // Botón para actualizar información de institución si está vacía
        if (certificate.institutionName.isEmpty || certificate.institutionCode.isEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateInstitutionInfo(context),
              icon: Icon(Icons.refresh),
              label: Text('Actualizar Información de Institución'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (certificate.institutionName.isEmpty || certificate.institutionCode.isEmpty)
          SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyQRCode(context),
                icon: Icon(Icons.qr_code),
                label: Text('Copiar QR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xff6C4DDC),
                  side: BorderSide(color: Color(0xff6C4DDC)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareCertificate(context),
                icon: Icon(Icons.share),
                label: Text('Compartir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xff6C4DDC),
                  side: BorderSide(color: Color(0xff6C4DDC)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getCertificateTypeLabel(String type) {
    switch (type) {
      case 'graduation':
        return 'Certificado de Graduación';
      case 'constancy':
        return 'Constancia de Estudios';
      case 'achievement':
        return 'Certificado de Logro';
      case 'participation':
        return 'Certificado de Participación';
      default:
        return type;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrador';
      case 'admin_institution':
        return 'Administrador de Institución';
      case 'emisor':
        return 'Emisor';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyQRCode(BuildContext context) {
    _copyToClipboard(certificate.qrCode, context);
  }

  void _viewTemplate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateTemplateScreen(certificate: certificate),
      ),
    );
  }

  void _updateInstitutionInfo(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Actualizando información...'),
            ],
          ),
        ),
      );

      // Actualizar la información de la institución
      await CertificateService.forceUpdateInstitutionInfo(certificate.id);

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Información de institución actualizada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Recargar la pantalla
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CertificateDetailScreen(certificate: certificate),
        ),
      );
    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      Navigator.of(context).pop();
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _shareCertificate(BuildContext context) {
    // TODO: Implementar compartir certificado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de compartir en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _downloadCertificate(BuildContext context) {
    // TODO: Implementar descarga de PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de descarga en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
