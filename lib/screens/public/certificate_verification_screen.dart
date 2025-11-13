// lib/screens/public/certificate_verification_screen.dart
// Pantalla pública para verificar certificados mediante QR o ID

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../../services/adapters/certificate_adapter.dart';
import '../../models/certificate.dart';

class CertificateVerificationScreen extends StatefulWidget {
  final String certificateId;
  
  const CertificateVerificationScreen({
    Key? key,
    required this.certificateId,
  }) : super(key: key);

  @override
  _CertificateVerificationScreenState createState() => _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState extends State<CertificateVerificationScreen> {
  bool _isLoading = true;
  Certificate? _certificate;
  String? _errorMessage;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _verifyCertificate();
  }

  Future<void> _verifyCertificate() async {
    try {
      setState(() => _isLoading = true);
      
      // Usar el adapter para obtener el certificado (método público sin autenticación)
      final certificateData = await CertificateAdapter.getCertificatePublic(widget.certificateId);
      
      if (certificateData == null) {
        setState(() {
          _isLoading = false;
          _isValid = false;
          _errorMessage = 'Certificado no encontrado';
        });
        return;
      }
      
      // Convertir a objeto Certificate si es necesario
      Certificate certificate;
      if (certificateData is Certificate) {
        certificate = certificateData;
      } else if (certificateData is Map<String, dynamic>) {
        certificate = Certificate.fromSupabase(certificateData);
      } else {
        throw Exception('Formato de certificado no válido');
      }
      
      // Verificar estado del certificado
      if (certificate.status != 'active') {
        String statusMessage = '';
        switch (certificate.status) {
          case 'revoked':
            statusMessage = 'Certificado revocado';
            break;
          case 'expired':
            statusMessage = 'Certificado expirado';
            break;
          default:
            statusMessage = 'Certificado no válido';
        }
        
        setState(() {
          _isLoading = false;
          _isValid = false;
          _errorMessage = statusMessage;
          _certificate = certificate;
        });
        return;
      }
      
      // Verificar expiración
      if (certificate.expiresAt != null && DateTime.now().isAfter(certificate.expiresAt!)) {
        setState(() {
          _isLoading = false;
          _isValid = false;
          _errorMessage = 'Certificado expirado';
          _certificate = certificate;
        });
        return;
      }
      
      setState(() {
        _isLoading = false;
        _isValid = true;
        _certificate = certificate;
        _errorMessage = null;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isValid = false;
        _errorMessage = 'Error al verificar certificado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verificación de Certificado'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _isValid
              ? _buildValidCertificate()
              : _buildInvalidCertificate(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
          ),
          SizedBox(height: 16),
          Text(
            'Verificando certificado...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidCertificate() {
    if (_certificate == null) return _buildInvalidCertificate();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header de verificación exitosa
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'CERTIFICADO VÁLIDO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Verificado el ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ID: ${_certificate!.id}',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Información del certificado
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: Color(0xff6C4DDC), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Información del Certificado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow('Título', _certificate!.title, Icons.title),
                  _buildInfoRow('Tipo', _certificate!.certificateType, Icons.category),
                  if (_certificate!.description.isNotEmpty)
                    _buildInfoRow('Descripción', _certificate!.description, Icons.description),
                  _buildInfoRow('Estado', _getStatusText(), _getStatusIcon(), _getStatusColor()),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Información del estudiante
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Color(0xff6C4DDC), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Información del Estudiante',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow('Nombre', _certificate!.studentName, Icons.person),
                  if (_certificate!.studentEmail != null)
                    _buildInfoRow('Email', _certificate!.studentEmail!, Icons.email),
                  if (_certificate!.studentIdInInstitution != null && _certificate!.studentIdInInstitution!.isNotEmpty)
                    _buildInfoRow('ID Institucional', _certificate!.studentIdInInstitution!, Icons.badge),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Información académica
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: Color(0xff6C4DDC), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Información Académica',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (_certificate!.programName != null)
                    _buildInfoRow('Programa', _certificate!.programName!, Icons.school),
                  _buildInfoRow('Institución', _certificate!.institutionName, Icons.business),
                  _buildInfoRow('Código Institución', _certificate!.institutionCode, Icons.code),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Información de emisión
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: Color(0xff6C4DDC), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Información de Emisión',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (_certificate!.issuedByName != null)
                    _buildInfoRow('Emitido por', _certificate!.issuedByName!, Icons.person_pin),
                  if (_certificate!.issuedByRole != null)
                    _buildInfoRow('Rol del Emisor', _certificate!.issuedByRole!, Icons.work),
                  _buildInfoRow('Fecha de Emisión', _formatDate(_certificate!.issuedAt), Icons.calendar_today),
                  if (_certificate!.expiresAt != null)
                    _buildInfoRow('Fecha de Expiración', _formatDate(_certificate!.expiresAt!), Icons.schedule),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Sección del PDF del certificado
          if (_certificate!.pdfUrl != null && _certificate!.pdfUrl!.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Color(0xff6C4DDC), size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Certificado PDF',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 48,
                            color: Colors.red[600],
                          ),
                          SizedBox(height: 12),
                          Text(
                            _certificate!.pdfFileName ?? 'Certificado.pdf',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff2E2F44),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Haz clic en el botón para ver o descargar el certificado',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openPdf(),
                            icon: Icon(Icons.visibility),
                            label: Text('Ver PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff6C4DDC),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _downloadPdf(),
                            icon: Icon(Icons.download),
                            label: Text('Descargar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          SizedBox(height: 24),
          
          // Botón para verificar otro certificado
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.refresh),
              label: Text('Verificar Otro Certificado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInvalidCertificate() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            SizedBox(height: 24),
            Text(
              'CERTIFICADO NO VÁLIDO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage ?? 'El certificado no pudo ser verificado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.refresh),
              label: Text('Intentar Otro Certificado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, [Color? iconColor]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? Color(0xff6C4DDC),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getStatusText() {
    switch (_certificate!.status.toLowerCase()) {
      case 'active':
        return 'VÁLIDO';
      case 'revoked':
        return 'REVOCADO';
      case 'expired':
        return 'EXPIRADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  IconData _getStatusIcon() {
    switch (_certificate!.status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'revoked':
        return Icons.block;
      case 'expired':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor() {
    switch (_certificate!.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'revoked':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openPdf() async {
    try {
      // Buscar PDF en diferentes campos posibles
      String? pdfData;
      
      // Primero buscar en campos de URL
      String? pdfUrl = _certificate!.pdfUrl;
      
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        print('🔍 DEBUG - PDF URL encontrada: $pdfUrl');
        final Uri url = Uri.parse(pdfUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar('No se pudo abrir el PDF');
        }
        return;
      }
      
      // Si no hay URL, buscar en el campo data.customCertificateData
      if (_certificate!.data != null && _certificate!.data is Map<String, dynamic>) {
        final data = _certificate!.data as Map<String, dynamic>;
        final customData = data['customCertificateData'];
        print('🔍 DEBUG - customCertificateData tipo: ${customData.runtimeType}');
        
        if (customData is String) {
          pdfData = customData;
          print('🔍 DEBUG - PDF Data encontrada como String: ${pdfData != null ? 'Sí' : 'No'}');
        } else if (customData is Map<String, dynamic>) {
          // Si es un Map, buscar campos comunes de PDF
          pdfData = customData['data'] ?? 
                   customData['content'] ?? 
                   customData['base64'] ??
                   customData['fileData'] ??
                   customData['certificateData'] ??
                   customData['pdfData'];
          print('🔍 DEBUG - PDF Data encontrada en Map: ${pdfData != null ? 'Sí' : 'No'}');
        }
      }
      
      if (pdfData == null || pdfData.isEmpty) {
        _showErrorSnackBar('No hay PDF disponible para este certificado');
        return;
      }
      
      // Procesar PDF desde base64
      await _openPdfFromBase64(pdfData);
      
    } catch (e) {
      _showErrorSnackBar('Error al abrir el PDF: $e');
    }
  }

  Future<void> _downloadPdf() async {
    try {
      // Buscar PDF en diferentes campos posibles
      String? pdfData;
      
      // Primero buscar en campos de URL
      String? pdfUrl = _certificate!.pdfUrl;
      
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        print('🔍 DEBUG - PDF URL encontrada: $pdfUrl');
        final Uri url = Uri.parse(pdfUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          _showSuccessSnackBar('PDF descargado correctamente');
        } else {
          _showErrorSnackBar('No se pudo descargar el PDF');
        }
        return;
      }
      
      // Si no hay URL, buscar en el campo data.customCertificateData
      if (_certificate!.data != null && _certificate!.data is Map<String, dynamic>) {
        final data = _certificate!.data as Map<String, dynamic>;
        final customData = data['customCertificateData'];
        print('🔍 DEBUG - customCertificateData tipo: ${customData.runtimeType}');
        
        if (customData is String) {
          pdfData = customData;
          print('🔍 DEBUG - PDF Data encontrada como String: ${pdfData != null ? 'Sí' : 'No'}');
        } else if (customData is Map<String, dynamic>) {
          // Si es un Map, buscar campos comunes de PDF
          pdfData = customData['data'] ?? 
                   customData['content'] ?? 
                   customData['base64'] ??
                   customData['fileData'] ??
                   customData['certificateData'] ??
                   customData['pdfData'];
          print('🔍 DEBUG - PDF Data encontrada en Map: ${pdfData != null ? 'Sí' : 'No'}');
        }
      }
      
      if (pdfData == null || pdfData.isEmpty) {
        _showErrorSnackBar('No hay PDF disponible para este certificado');
        return;
      }
      
      // Procesar PDF desde base64
      await _downloadPdfFromBase64(pdfData);
      
    } catch (e) {
      _showErrorSnackBar('Error al descargar el PDF: $e');
    }
  }

  Future<void> _openPdfFromBase64(String base64Data) async {
    try {
      print('🔄 Abriendo PDF desde base64...');
      
      // Crear data URL
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      
      // Usar JavaScript para crear blob URL y abrir en nueva pestaña
      await _openPdfWithBlobUrl(dataUrl);
      
    } catch (e) {
      print('❌ Error al abrir PDF desde base64: $e');
      _showErrorSnackBar('Error al abrir PDF: $e');
    }
  }

  Future<void> _downloadPdfFromBase64(String base64Data) async {
    try {
      print('🔄 Descargando PDF desde base64...');
      
      // Crear data URL
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      
      // Usar JavaScript para crear blob URL y descargar
      await _downloadPdfWithBlobUrl(dataUrl);
      
      _showSuccessSnackBar('PDF descargado correctamente');
      
    } catch (e) {
      print('❌ Error al descargar PDF desde base64: $e');
      _showErrorSnackBar('Error al descargar PDF: $e');
    }
  }

  Future<void> _openPdfWithBlobUrl(String dataUrl) async {
    try {
      print('🔄 Creando blob URL con JavaScript...');
      
      // Extraer el base64 del data URL
      final String base64Data = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Data);
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      
      // Abrir en nueva pestaña
      html.window.open(blobUrl, '_blank');
      
      // Limpiar la URL del blob después de un tiempo
      Future.delayed(Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
      
    } catch (e) {
      print('❌ Error con blob URL: $e');
      throw e;
    }
  }

  Future<void> _downloadPdfWithBlobUrl(String dataUrl) async {
    try {
      print('🔄 Creando blob URL para descarga...');
      
      // Extraer el base64 del data URL
      final String base64Data = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Data);
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      
      // Crear elemento de descarga
      final anchor = html.AnchorElement(href: blobUrl);
      anchor.download = 'certificado_${_certificate!.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      anchor.click();
      
      // Limpiar la URL del blob después de un tiempo
      Future.delayed(Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
      
    } catch (e) {
      print('❌ Error con blob URL: $e');
      throw e;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 3),
      ),
    );
  }
}
