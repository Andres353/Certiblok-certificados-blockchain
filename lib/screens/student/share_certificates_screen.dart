// lib/screens/student/share_certificates_screen.dart
// Pantalla para compartir certificados del estudiante

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/adapters/certificate_adapter.dart';
import '../../models/certificate.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';
import 'group_certificates_screen.dart';
import 'saved_grouped_qrs_screen.dart';

class ShareCertificatesScreen extends StatefulWidget {
  @override
  _ShareCertificatesScreenState createState() => _ShareCertificatesScreenState();
}

class _ShareCertificatesScreenState extends State<ShareCertificatesScreen> {
  List<Certificate> _certificates = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoading = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final certificates = (await CertificateAdapter.getCertificates(
        studentId: userContext!.userId,
      )).cast<Certificate>();

      setState(() {
        _certificates = certificates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error cargando certificados: $e');
      AlertService.showError(context, 'Error', 'Error cargando certificados: $e');
    }
  }

  List<Certificate> get _filteredCertificates {
    if (_searchQuery.isEmpty) return _certificates;
    
    return _certificates.where((cert) {
      return cert.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             cert.certificateType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compartir Certificados'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildCertificatesList()),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No tienes certificados para compartir',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Una vez que recibas certificados de tu institución, podrás compartirlos aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar certificados...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          SizedBox(height: 12),
          // Botones para QRs agrupados
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _certificates.isNotEmpty ? _navigateToGroupScreen : null,
                  icon: Icon(Icons.qr_code_2, size: 20),
                  label: Text('Crear QR Agrupado'),
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
                child: OutlinedButton.icon(
                  onPressed: _navigateToSavedGroupedQRs,
                  icon: Icon(Icons.list_alt, size: 20),
                  label: Text('Ver QR Agrupado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xff6C4DDC),
                    side: BorderSide(color: Color(0xff6C4DDC)),
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
    );
  }

  Widget _buildCertificatesList() {
    final filteredCerts = _filteredCertificates;
    
    if (filteredCerts.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron certificados',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCerts.length,
      itemBuilder: (context, index) {
        final certificate = filteredCerts[index];
        return _buildCertificateCard(certificate);
      },
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xff6C4DDC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description,
                    color: Color(0xff6C4DDC),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getCertificateTypeLabel(certificate.certificateType),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Emitido: ${_formatDate(certificate.issuedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: certificate.status == 'active' 
                        ? Colors.green[100] 
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    certificate.status == 'active' ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 12,
                      color: certificate.status == 'active' 
                          ? Colors.green[700] 
                          : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showShareOptions(certificate),
                    icon: Icon(Icons.share, size: 18),
                    label: Text('Compartir'),
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
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadQR(certificate),
                    icon: Icon(Icons.download, size: 18),
                    label: Text('Descargar QR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xff6C4DDC),
                      side: BorderSide(color: Color(0xff6C4DDC)),
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
    );
  }

  void _showShareOptions(Certificate certificate) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Compartir Certificado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 8),
            Text(
              certificate.title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            _buildShareOption(
              icon: Icons.email,
              title: 'Enviar por Email',
              subtitle: 'Enviar QR por correo electrónico',
              onTap: () {
                Navigator.pop(context);
                _shareByEmail(certificate);
              },
            ),
            _buildShareOption(
              icon: Icons.link,
              title: 'Copiar Enlace',
              subtitle: 'Copiar enlace de verificación',
              onTap: () {
                Navigator.pop(context);
                _copyLink(certificate);
              },
            ),
            _buildShareOption(
              icon: Icons.qr_code,
              title: 'Mostrar QR',
              subtitle: 'Mostrar código QR en pantalla',
              onTap: () {
                Navigator.pop(context);
                _showQRCode(certificate);
              },
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xff6C4DDC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(0xff6C4DDC)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xff2E2F44),
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _shareByEmail(Certificate certificate) {
    // Mostrar diálogo para ingresar email del destinatario
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enviar Certificado por Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa el email del destinatario:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email del destinatario',
                hintText: 'ejemplo@correo.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                // Guardar el email temporalmente
                _recipientEmail = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_recipientEmail != null && _recipientEmail!.isNotEmpty) {
                _sendEmailViaEmailJS(certificate, _recipientEmail!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Por favor ingresa un email válido'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Text('Enviar'),
          ),
        ],
      ),
    );
  }

  String? _recipientEmail;

  Future<void> _sendEmailViaEmailJS(Certificate certificate, String recipientEmail) async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Enviando email...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );

      // Configuración de EmailJS
      const String serviceId = 'service_bdav8mg';
      const String templateId = 'template_2fs5k3c';
      const String userId = 'o1eUKl5D0Qq9fJ1Jv';
      const String url = 'https://api.emailjs.com/api/v1.0/email/send';

      // Preparar el contenido del email
      final String subject = 'Certificado: ${certificate.title}';
      final String message = '''
Hola,

Te comparto mi certificado: ${certificate.title}

Puedes verificar su autenticidad escaneando el código QR adjunto o visitando el siguiente enlace:
${certificate.qrCode}

Detalles del certificado:
- Tipo: ${_getCertificateTypeLabel(certificate.certificateType)}
- Emitido: ${_formatDate(certificate.issuedAt)}
- Institución: ${certificate.institutionName}

Saludos,
${UserContextService.currentContext?.userName ?? 'Estudiante'}
''';

      // Preparar los datos para EmailJS
      final Map<String, dynamic> data = {
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'name': 'CertiBlock',
          'to_email': recipientEmail,
          'message': message,
          'subject': subject,
        }
      };

      // Enviar email usando EmailJS
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Email enviado exitosamente a $recipientEmail'),
            backgroundColor: Colors.green,
          ),
        );
        print('✅ Email enviado exitosamente via EmailJS a: $recipientEmail');
      } else {
        throw Exception('Error enviando email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error enviando email via EmailJS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enviando email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyLink(Certificate certificate) {
    try {
      Clipboard.setData(ClipboardData(text: certificate.qrCode));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enlace copiado al portapapeles'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copiando enlace: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQRCode(Certificate certificate) {
    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Código QR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: certificate.qrCode,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  certificate.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xff2E2F44),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _downloadQR(certificate);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Descargar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mostrando QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _downloadQR(Certificate certificate) async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generando QR...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Generar QR como imagen con fondo blanco
      final qrPainter = QrPainter(
        data: certificate.qrCode,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      
      // Crear un canvas para renderizar el QR
      final picData = await qrPainter.toImageData(200);
      
      // Convertir a bytes
      final bytes = picData!.buffer.asUint8List();
      
      // Crear blob y descargar
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url);
      anchor.download = 'certificado_${certificate.id}_qr.png';
      anchor.style.display = 'none';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR descargado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error descargando QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCertificateTypeLabel(String? type) {
    if (type == null || type.isEmpty) {
      return 'Certificado';
    }
    
    switch (type.toLowerCase().trim()) {
      case 'graduation':
        return 'Certificado de Graduación';
      case 'constancy':
        return 'Constancia de Estudios';
      case 'achievement':
        return 'Certificado de Logro';
      case 'participation':
        return 'Certificado de Participación';
      default:
        return 'Certificado';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToGroupScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupCertificatesScreen(),
      ),
    );
  }

  void _navigateToSavedGroupedQRs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedGroupedQRsScreen(),
      ),
    );
  }

}
