// lib/screens/certificates/certificate_template_screen.dart
// Pantalla de plantilla de certificado

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import '../../services/certificate_service.dart';
import '../../models/certificate_template.dart';

class CertificateTemplateScreen extends StatelessWidget {
  final Certificate certificate;

  const CertificateTemplateScreen({Key? key, required this.certificate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plantilla de Certificado'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadCertificate(context),
            tooltip: 'Descargar PDF',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareCertificate(context),
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: 800),
          child: _buildCertificateTemplate(context),
        ),
        ),
      ),
    );
  }

  Widget _buildCertificateTemplate(BuildContext context) {
    // Verificar si el certificado usa una plantilla personalizada
    final bool useTemplate = certificate.data['useTemplate'] == true;
    final bool useCustomCertificate = certificate.data['useCustomCertificate'] == true;
    
    if (useTemplate && certificate.data['templateData'] != null) {
      // Renderizar con plantilla personalizada
      return _buildTemplateCertificate(context);
    } else if (useCustomCertificate && certificate.data['customCertificateData'] != null) {
      // Renderizar certificado cargado desde PC
      return _buildCustomCertificate(context);
    } else {
      // Renderizar certificado estándar
      return _buildStandardCertificate(context);
    }
  }

  Widget _buildTemplateCertificate(BuildContext context) {
    try {
      final templateData = certificate.data['templateData'] as Map<String, dynamic>;
      final design = TemplateDesign.fromMap(templateData['design'] ?? {});
      final layout = TemplateLayout.fromMap(templateData['layout'] ?? {});
      
      return Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          color: _parseColor(design.backgroundColor),
          borderRadius: BorderRadius.circular(design.borderRadius),
          border: Border.all(
            color: _parseColor(design.borderColor),
            width: design.borderWidth.toDouble(),
          ),
          boxShadow: [
            if (layout.showShadow)
              BoxShadow(
                color: _parseColor(layout.shadowColor),
                blurRadius: layout.shadowBlur.toDouble(),
                offset: Offset(0, layout.shadowOffset.toDouble()),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(design.borderRadius),
          child: Stack(
            children: [
              // Imagen de fondo
              if (design.certificateBackgroundUrl.isNotEmpty)
                _buildBackgroundImage(design.certificateBackgroundUrl),
              
              // Patrón de fondo
              if (layout.backgroundPattern != 'none')
                _buildBackgroundPattern(layout, design),
              
              // Logo de la institución
              if (design.institutionLogoUrl.isNotEmpty)
                _buildInstitutionLogo(design),
              
              // Contenido principal
              Padding(
                padding: EdgeInsets.all(layout.padding.left.toDouble()),
                child: Column(
                  children: [
                    // Header
                    if (layout.showHeader)
                      _buildTemplateHeader(design, layout),
                    
                    // Título principal
                    _buildTemplateTitle(design),
                    
                    SizedBox(height: 20),
                    
                    // Subtítulo
                    _buildTemplateSubtitle(design),
                    
                    SizedBox(height: 40),
                    
                    // Nombre del estudiante
                    _buildTemplateStudentName(design),
                    
                    SizedBox(height: 30),
                    
                    // Descripción
                    _buildTemplateDescription(design),
                    
                    Spacer(),
                    
                    // Firmas
                    if (layout.showFooter)
                      _buildTemplateSignatures(design),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error renderizando plantilla: $e');
      return _buildStandardCertificate(context);
    }
  }

  Widget _buildCustomCertificate(BuildContext context) {
    try {
      final customData = certificate.data['customCertificateData'] as Map<String, dynamic>;
      final fileData = customData['fileData'] as String;
      final isPdf = customData['isPdf'] == true;
      
      if (isPdf) {
        // Para PDFs, mostrar el visor completo
        return _buildPdfViewer(context, fileData);
      } else {
        // Para imágenes, mostrar la imagen
        final bytes = base64Decode(fileData);
        return Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error renderizando certificado personalizado: $e');
      return _buildStandardCertificate(context);
    }
  }

  Widget _buildPdfViewer(BuildContext context, String base64Data) {
    return Container(
      padding: EdgeInsets.all(20),
      child: _buildPdfContent(context, base64Data),
    );
  }

  Widget _buildPdfContent(BuildContext context, String base64Data) {
    try {
      // Convertir base64 a bytes para mostrar información
      final bytes = base64Decode(base64Data);
      final fileSize = (bytes.length / 1024).toStringAsFixed(1);
      
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
            // Header del PDF
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 48,
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documento PDF',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          certificate.title,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tamaño: $fileSize KB',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Vista previa del PDF
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 80,
                    color: Colors.red[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Vista previa del PDF',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'El contenido del PDF se muestra aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openPdfInNewTab(context, base64Data),
                        icon: Icon(Icons.open_in_new),
                        label: Text('Abrir PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _downloadPdf(context, base64Data),
                        icon: Icon(Icons.download),
                        label: Text('Descargar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Información adicional
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Para una mejor experiencia, puedes abrir el PDF completo en una nueva pestaña o descargarlo a tu dispositivo.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error procesando PDF: $e');
      return _buildErrorWidget(context, 'Error procesando PDF: $e');
    }
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          SizedBox(height: 20),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text('Volver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadPdf(BuildContext context, String base64Data) {
    try {
      // Crear data URL para descargar
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      
      // Mostrar alerta de éxito
      Alert(
        context: context,
        type: AlertType.success,
        title: "PDF Listo",
        desc: "El PDF está listo para descargar. ¿Deseas copiar la URL al portapapeles?",
        buttons: [
          DialogButton(
            child: Text(
              "Copiar URL",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: dataUrl));
              Navigator.pop(context);
              Alert(
                context: context,
                type: AlertType.info,
                title: "URL Copiada",
                desc: "La URL del PDF ha sido copiada al portapapeles.",
                buttons: [
                  DialogButton(
                    child: Text(
                      "OK",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ).show();
            },
            color: Color(0xff6C4DDC),
          ),
          DialogButton(
            child: Text(
              "Cancelar",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () => Navigator.pop(context),
            color: Colors.grey,
          ),
        ],
      ).show();
    } catch (e) {
      Alert(
        context: context,
        type: AlertType.error,
        title: "Error",
        desc: "Error preparando descarga: $e",
        buttons: [
          DialogButton(
            child: Text(
              "OK",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () => Navigator.pop(context),
            color: Colors.red,
          ),
        ],
      ).show();
    }
  }

  void _openPdfInNewTab(BuildContext context, String base64Data) {
    try {
      // Crear data URL para el PDF
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      print('Abriendo PDF: $dataUrl');
      
      // Copiar la URL al portapapeles para que el usuario pueda abrirla
      Clipboard.setData(ClipboardData(text: dataUrl));
      
      // Mostrar alerta de éxito
      Alert(
        context: context,
        type: AlertType.success,
        title: "URL Copiada",
        desc: "La URL del PDF ha sido copiada al portapapeles. Pégala en el navegador para abrir el PDF completo.",
        buttons: [
          DialogButton(
            child: Text(
              "OK",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () => Navigator.pop(context),
            color: Color(0xff6C4DDC),
          ),
        ],
      ).show();
    } catch (e) {
      print('Error abriendo PDF: $e');
      Alert(
        context: context,
        type: AlertType.error,
        title: "Error",
        desc: "Error abriendo PDF: $e",
        buttons: [
          DialogButton(
            child: Text(
              "OK",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () => Navigator.pop(context),
            color: Colors.red,
          ),
        ],
      ).show();
    }
  }


  Widget _buildStandardCertificate(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con logo y título
          _buildHeader(),
          
          // Línea decorativa
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC), Color(0xff9C27B0)],
              ),
            ),
          ),
          
          // Contenido principal
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                // Título del certificado
                _buildCertificateTitle(),
                
                SizedBox(height: 40),
                
                // Información del estudiante
                _buildStudentInfo(),
                
                SizedBox(height: 40),
                
                // Descripción del certificado
                _buildCertificateDescription(),
                
                SizedBox(height: 40),
                
                // Información institucional
                _buildInstitutionInfo(),
                
                SizedBox(height: 40),
                
                // Firma y fecha
                _buildSignatureSection(),
              ],
            ),
          ),
          
          // Footer con QR y validación
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff6C4DDC), Color(0xff9C27B0)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Logo de la institución (placeholder)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.school,
              color: Color(0xff6C4DDC),
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.institutionName.isNotEmpty 
                    ? certificate.institutionName 
                    : 'Institución Educativa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (certificate.institutionCode.isNotEmpty)
                  Text(
                    'Código: ${certificate.institutionCode}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          // Estado del certificado
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: certificate.status == 'active' ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              certificate.status == 'active' ? 'VÁLIDO' : 'REVOCADO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateTitle() {
    return Column(
      children: [
        Text(
          'CERTIFICADO',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xff6C4DDC),
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _getCertificateTypeLabel(certificate.certificateType),
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        Text(
          certificate.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'OTORGADO A',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff6C4DDC),
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 16),
          Text(
            certificate.studentName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            certificate.studentEmail,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (certificate.studentIdInInstitution.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'ID: ${certificate.studentIdInInstitution}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (certificate.programName.isNotEmpty)
                _buildInfoItem('Programa', certificate.programName),
              if (certificate.facultyName.isNotEmpty)
                _buildInfoItem('Facultad', certificate.facultyName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCertificateDescription() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        certificate.description,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInstitutionInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMITIDO POR',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                certificate.issuedByName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getRoleLabel(certificate.issuedByRole),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'FECHA DE EMISIÓN',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _formatDate(certificate.issuedAt),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (certificate.expiresAt != null)
                Text(
                  'Válido hasta: ${_formatDate(certificate.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Línea de firma del emisor
          Column(
            children: [
              Container(
                width: 200,
                height: 1,
                color: Colors.black,
              ),
              SizedBox(height: 8),
              Text(
                certificate.issuedByName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getRoleLabel(certificate.issuedByRole),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          // Línea de firma de la institución
          Column(
            children: [
              Container(
                width: 200,
                height: 1,
                color: Colors.black,
              ),
              SizedBox(height: 8),
              Text(
                certificate.institutionName.isNotEmpty 
                  ? certificate.institutionName 
                  : 'Institución Educativa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Institución',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Text(
            'VERIFICACIÓN',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ID del certificado
              Column(
                children: [
                  Text(
                    'ID del Certificado',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      certificate.id,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // Hash único
              Column(
                children: [
                  Text(
                    'Hash Único',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      certificate.uniqueHash.substring(0, 16) + '...',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // QR Code (placeholder)
              Column(
                children: [
                  Text(
                    'Código QR',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(
                      Icons.qr_code,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Para verificar este certificado, visite: certiblock.com/validate',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getCertificateTypeLabel(String type) {
    switch (type) {
      case 'graduation':
        return 'DE GRADUACIÓN';
      case 'constancy':
        return 'DE CONSTANCIA';
      case 'achievement':
        return 'DE LOGRO';
      case 'participation':
        return 'DE PARTICIPACIÓN';
      default:
        return 'ACADÉMICO';
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrador';
      case 'admin_institution':
        return 'Administrador de Institución';
      case 'emisor':
        return 'Emisor Autorizado';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _downloadCertificate(BuildContext context) {
    // TODO: Implementar descarga de PDF
    Alert(
      context: context,
      type: AlertType.warning,
      title: "En Desarrollo",
      desc: "La funcionalidad de descarga estará disponible próximamente.",
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.orange,
        ),
      ],
    ).show();
  }

  void _shareCertificate(BuildContext context) {
    // TODO: Implementar compartir certificado
    Alert(
      context: context,
      type: AlertType.warning,
      title: "En Desarrollo",
      desc: "La funcionalidad de compartir estará disponible próximamente.",
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.orange,
        ),
      ],
    ).show();
  }

  // Métodos auxiliares para plantillas personalizadas
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.black;
    }
  }

  Widget _buildBackgroundImage(String imageUrl) {
    return Positioned.fill(
      child: imageUrl.startsWith('data:')
          ? Image.network(imageUrl, fit: BoxFit.cover)
          : Container(), // Ignorar URLs de Firebase Storage por ahora
    );
  }

  Widget _buildBackgroundPattern(TemplateLayout layout, TemplateDesign design) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPatternPainter(
          pattern: layout.backgroundPattern,
          color: _parseColor(layout.patternColor),
          opacity: layout.patternOpacity,
        ),
      ),
    );
  }

  Widget _buildInstitutionLogo(TemplateDesign design) {
    if (design.institutionLogoUrl.isEmpty) return Container();
    
    return Positioned(
      left: design.logoPosition == 'top-left' ? 20 : 
            design.logoPosition == 'top-center' ? 300 : 580,
      top: design.logoPosition.contains('top') ? 20 : 500,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: design.institutionLogoUrl.startsWith('data:')
            ? Image.network(design.institutionLogoUrl, fit: BoxFit.contain)
            : Container(), // Ignorar URLs de Firebase Storage por ahora
      ),
    );
  }

  Widget _buildTemplateHeader(TemplateDesign design, TemplateLayout layout) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _parseColor(design.primaryColor),
            _parseColor(design.secondaryColor),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(design.borderRadius),
          topRight: Radius.circular(design.borderRadius),
        ),
      ),
      child: Center(
        child: Text(
          certificate.institutionName,
          style: _getTextStyle(
            design.titleFontFamily,
            design.titleFontSize,
            _parseColor(design.headerTextColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateTitle(TemplateDesign design) {
    return Column(
      children: [
        Text(
          'CERTIFICADO',
          style: _getTextStyle(
            design.titleFontFamily,
            design.titleFontSize,
            _parseColor(design.primaryColor),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _getCertificateTypeLabel(certificate.certificateType),
          style: _getTextStyle(
            design.subtitleFontFamily,
            design.subtitleFontSize,
            _parseColor(design.textColor),
          ),
        ),
        SizedBox(height: 16),
        Text(
          certificate.title,
          style: _getTextStyle(
            design.titleFontFamily,
            design.titleFontSize + 8,
            _parseColor(design.textColor),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTemplateSubtitle(TemplateDesign design) {
    return Text(
      'DE GRADUACIÓN',
      style: _getTextStyle(
        design.subtitleFontFamily,
        design.subtitleFontSize,
        _parseColor(design.textColor),
      ),
    );
  }

  Widget _buildTemplateStudentName(TemplateDesign design) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'OTORGADO A',
            style: _getTextStyle(
              design.smallFontFamily,
              design.smallFontSize,
              _parseColor(design.primaryColor),
            ),
          ),
          SizedBox(height: 16),
          Text(
            certificate.studentName,
            style: _getTextStyle(
              design.titleFontFamily,
              design.titleFontSize + 8,
              _parseColor(design.textColor),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateDescription(TemplateDesign design) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        certificate.description,
        style: _getTextStyle(
          design.bodyFontFamily,
          design.bodyFontSize,
          _parseColor(design.textColor),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTemplateSignatures(TemplateDesign design) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Firma del emisor
        Column(
          children: [
            Container(
              width: 200,
              height: 1,
              color: Colors.black,
            ),
            SizedBox(height: 8),
            Text(
              design.issuerName.isNotEmpty ? design.issuerName : certificate.issuedByName,
              style: _getTextStyle(
                design.smallFontFamily,
                design.smallFontSize + 2,
                _parseColor(design.textColor),
              ),
            ),
            Text(
              design.issuerTitleLabel.isNotEmpty ? design.issuerTitleLabel : 'Emisor Autorizado',
              style: _getTextStyle(
                design.smallFontFamily,
                design.smallFontSize,
                _parseColor(design.textColor),
              ),
            ),
          ],
        ),
        // Fecha
        Column(
          children: [
            Container(
              width: 200,
              height: 1,
              color: Colors.black,
            ),
            SizedBox(height: 8),
            Text(
              design.dateLabel.isNotEmpty ? design.dateLabel : 'Fecha de Emisión',
              style: _getTextStyle(
                design.smallFontFamily,
                design.smallFontSize,
                _parseColor(design.textColor),
              ),
            ),
            Text(
              _formatDate(certificate.issuedAt),
              style: _getTextStyle(
                design.smallFontFamily,
                design.smallFontSize + 2,
                _parseColor(design.textColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  TextStyle _getTextStyle(String fontFamily, double fontSize, Color color) {
    try {
      switch (fontFamily.toLowerCase()) {
        case 'roboto':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'open sans':
          return GoogleFonts.openSans(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'lato':
          return GoogleFonts.lato(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'montserrat':
          return GoogleFonts.montserrat(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'poppins':
          return GoogleFonts.poppins(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'playfair display':
          return GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'merriweather':
          return GoogleFonts.merriweather(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'source sans pro':
          return GoogleFonts.sourceCodePro(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'nunito':
          return GoogleFonts.nunito(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'comic sans ms':
          return GoogleFonts.comicNeue(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'garamond':
          return GoogleFonts.crimsonText(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'times new roman':
          return GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'arial':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'helvetica':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'impact':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w900,
          );
        case 'bookman':
          return GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'avant garde':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        case 'palatino':
          return GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          );
        default:
          return TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          );
      }
    } catch (e) {
      return TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w500,
      );
    }
  }
}

// Custom painter para patrones de fondo
class _BackgroundPatternPainter extends CustomPainter {
  final String pattern;
  final Color color;
  final double opacity;

  _BackgroundPatternPainter({
    required this.pattern,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    switch (pattern) {
      case 'dots':
        _paintDots(canvas, size, paint);
        break;
      case 'lines':
        _paintLines(canvas, size, paint);
        break;
      case 'grid':
        _paintGrid(canvas, size, paint);
        break;
      case 'diagonal':
        _paintDiagonal(canvas, size, paint);
        break;
    }
  }

  void _paintDots(Canvas canvas, Size size, Paint paint) {
    const double spacing = 20.0;
    const double radius = 2.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  void _paintLines(Canvas canvas, Size size, Paint paint) {
    const double spacing = 30.0;
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size, Paint paint) {
    const double spacing = 40.0;
    
    // Líneas verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Líneas horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _paintDiagonal(Canvas canvas, Size size, Paint paint) {
    const double spacing = 30.0;
    
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
