// lib/services/pdf_generator_service.dart
// Servicio para generar PDFs de plantillas de certificados

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/certificate_template.dart';

class PDFGeneratorService {
  // Generar PDF desde una plantilla
  static Future<Uint8List> generatePDFFromTemplate({
    required CertificateTemplate template,
    Map<String, dynamic>? sampleData,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Datos de muestra si no se proporcionan
      final data = sampleData ?? {
        'studentName': 'Juan Pérez',
        'studentId': '2024001',
        'programName': 'Ingeniería de Sistemas',
        'institutionName': 'Universidad Ejemplo',
        'certificateTitle': template.name,
        'issuedDate': DateTime.now().toString().split(' ')[0],
        'issuedBy': 'Director Académico',
      };

      // Cargar logo si existe
      pw.ImageProvider? logoImage;
      final logoUrl = data['logoUrl'] as String?;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        try {
          logoImage = await _loadImageFromUrl(logoUrl);
        } catch (e) {
          print('⚠️ No se pudo cargar el logo: $e');
        }
      }

      // Crear página del certificado en formato horizontal
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape, // Formato horizontal
          margin: pw.EdgeInsets.all(20), // Márgenes más pequeños para aprovechar el espacio
          build: (pw.Context context) {
            return _buildCertificatePage(template, data, logoImage);
          },
        ),
      );

      // Convertir a bytes
      return await pdf.save();
    } catch (e) {
      print('❌ Error generando PDF: $e');
      throw Exception('Error generando PDF: $e');
    }
  }

  // Construir la página del certificado usando la misma lógica que la vista previa
  static pw.Widget _buildCertificatePage(CertificateTemplate template, Map<String, dynamic> data, pw.ImageProvider? logoImage) {
    return pw.Container(
      width: double.infinity, // Usar todo el ancho disponible
      height: double.infinity, // Usar toda la altura disponible
      decoration: pw.BoxDecoration(
        color: _parsePdfColor(template.design.backgroundColor),
        borderRadius: pw.BorderRadius.circular(template.design.borderRadius),
        border: template.layout.showBorder
            ? pw.Border.all(
                color: _parsePdfColor(template.design.borderColor),
                width: template.design.borderWidth,
              )
            : null,
      ),
      child: pw.Column(
        children: [
          // Header
          if (template.layout.showHeader) _buildHeader(template, data, logoImage),
          
          // Línea decorativa
          pw.Container(
            height: 4,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  _parsePdfColor(template.design.primaryColor),
                  _parsePdfColor(template.design.secondaryColor),
                ],
              ),
            ),
          ),
          
          // Contenido principal
          pw.Expanded(
            child: pw.Container(
              // No usar padding aquí para evitar que recorte los elementos posicionados
              // Los campos están posicionados absolutamente y pueden extenderse hasta los bordes
              child: _buildContent(template, data),
            ),
          ),
          
          // Footer
          if (template.layout.showFooter) _buildFooter(template, data),
        ],
      ),
    );
  }

  // Construir logo - mostrar imagen si está cargada
  static pw.Widget _buildLogo(pw.ImageProvider? logoImage) {
    if (logoImage != null) {
      try {
        return pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
          ),
          child: pw.Image(
            logoImage,
            fit: pw.BoxFit.cover,
          ),
        );
      } catch (e) {
        print('❌ Error mostrando logo en PDF: $e');
        return _buildPlaceholderLogo();
      }
    } else {
      return _buildPlaceholderLogo();
    }
  }

  // Construir logo placeholder
  static pw.Widget _buildPlaceholderLogo() {
    return pw.Container(
      width: 80,
      height: 80,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Center(
        child: pw.Text(
          'LOGO',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey,
          ),
        ),
      ),
    );
  }

  // Cargar imagen desde URL
  static Future<pw.ImageProvider?> _loadImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        return pw.MemoryImage(imageBytes);
      } else {
        print('❌ Error cargando logo: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error cargando logo desde URL: $e');
      return null;
    }
  }

  // Construir header usando la misma lógica que la vista previa
  static pw.Widget _buildHeader(CertificateTemplate template, Map<String, dynamic> data, pw.ImageProvider? logoImage) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 32, vertical: 20), // Ajustado para formato horizontal
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            _parsePdfColor(template.design.headerBackgroundColor),
            _parsePdfColor(template.design.secondaryColor),
          ],
        ),
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(template.design.borderRadius),
          topRight: pw.Radius.circular(template.design.borderRadius),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Logo a la izquierda
          _buildLogo(logoImage),
          // Nombre de institución centrado
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                data['institutionName'] ?? 'Institución Educativa',
                style: pw.TextStyle(
                  color: _parsePdfColor(template.design.headerTextColor),
                  fontSize: template.design.titleFontSize * 0.8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          // Estado del certificado
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              'VÁLIDO',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: template.design.smallFontSize * 1.2,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construir contenido usando exactamente la misma lógica que la vista previa
  // Usar Stack con Positioned para posicionamiento absoluto, igual que la vista previa
  static pw.Widget _buildContent(CertificateTemplate template, Map<String, dynamic> data) {
    // Filtrar campos visibles
    final visibleFields = template.fields.where((field) => field.isVisible).toList();

    // Usar Stack con Positioned para posicionamiento absoluto, igual que la vista previa
    // Ajustar posiciones para compensar el padding de 20 que hay en la vista previa
    return pw.Stack(
      children: visibleFields.map((field) {
        return pw.Positioned(
          left: field.position.x + 20, // Añadir padding de 20
          top: field.position.y + 20, // Añadir padding de 20
          child: pw.Container(
            width: field.position.width,
            height: field.position.height,
            padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: field.style.backgroundColor != 'transparent' 
                  ? _parsePdfColor(field.style.backgroundColor) 
                  : null,
              borderRadius: pw.BorderRadius.circular(field.style.borderRadius),
            ),
            child: _buildField(field, data),
          ),
        );
      }).toList(),
    );
  }

  // Construir un campo individual usando exactamente la misma lógica que la vista previa
  static pw.Widget _buildField(TemplateField field, Map<String, dynamic> data) {
    final style = field.style;
    
    pw.Widget content;
    
    switch (field.type) {
      case 'signature':
        // Replicar exactamente la estructura de la vista previa
        pw.CrossAxisAlignment crossAlign;
        if (style.textAlign == 'right') {
          crossAlign = pw.CrossAxisAlignment.end;
        } else if (style.textAlign == 'left') {
          crossAlign = pw.CrossAxisAlignment.start;
        } else {
          crossAlign = pw.CrossAxisAlignment.center;
        }
        
        content = pw.Column(
          crossAxisAlignment: crossAlign,
          children: [
            // Línea de firma
            pw.Container(
              width: field.position.width,
              height: 1,
              color: _parsePdfColor(style.color),
            ),
            pw.SizedBox(height: 4),
            // Texto de la firma
            pw.Text(
              _getFieldValue(field, data),
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: style.fontSize,
                fontWeight: style.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontStyle: style.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
                color: _parsePdfColor(style.color),
                letterSpacing: 0.5,
              ),
              textAlign: _getTextAlign(style.textAlign),
            ),
          ],
        );
        break;
      case 'image':
        content = pw.Container(
          width: field.position.width,
          height: field.position.height,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _parsePdfColor(style.color)),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'IMG',
                  style: pw.TextStyle(
                    fontSize: style.fontSize * 0.6,
                    color: _parsePdfColor(style.color),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 'qr':
        content = pw.Container(
          width: field.position.width,
          height: field.position.height,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _parsePdfColor(style.color)),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'QR',
                  style: pw.TextStyle(
                    fontSize: style.fontSize * 0.6,
                    color: _parsePdfColor(style.color),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      default:
        content = pw.Text(
          _getFieldValue(field, data),
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: style.fontSize,
            fontWeight: style.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: style.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
            color: _parsePdfColor(style.color),
            letterSpacing: 0.5,
          ),
          textAlign: _getTextAlign(style.textAlign),
        );
    }

    // El padding y decoration ya están en el contenedor padre (Positioned)
    return content;
  }

  // Construir footer usando la misma lógica que la vista previa
  static pw.Widget _buildFooter(CertificateTemplate template, Map<String, dynamic> data) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Ajustado para formato horizontal
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(template.design.borderRadius),
          bottomRight: pw.Radius.circular(template.design.borderRadius),
        ),
      ),
      child: pw.Container(),
    );
  }

  // Obtener valor del campo con reemplazo de variables
  static String _getFieldValue(TemplateField field, Map<String, dynamic> data) {
    String value = field.value;
    
    // Variables comunes
    value = value.replaceAll('{{studentName}}', data['studentName'] ?? 'Juan Pérez');
    value = value.replaceAll('{{description}}', 'Por haber completado exitosamente el programa académico');
    value = value.replaceAll('{{issuedAt}}', data['issuedDate'] ?? '18/9/2025');
    value = value.replaceAll('{{issuedByName}}', data['issuedBy'] ?? 'Dr. María González');
    value = value.replaceAll('{{id}}', 'CERT-123456');
    value = value.replaceAll('{{institutionName}}', data['institutionName'] ?? 'Universidad del Valle');
    value = value.replaceAll('{{programName}}', data['programName'] ?? 'Ingeniería en Sistemas');
    value = value.replaceAll('{{facultyName}}', 'Facultad de Ingeniería');
    
    return value;
  }

  // Obtener alineación de texto
  static pw.TextAlign _getTextAlign(String align) {
    switch (align) {
      case 'left':
        return pw.TextAlign.left;
      case 'right':
        return pw.TextAlign.right;
      case 'center':
      default:
        return pw.TextAlign.center;
    }
  }

  // Convertir color string a PdfColor
  static PdfColor _parsePdfColor(String colorString) {
    try {
      final color = int.parse(colorString.replaceFirst('#', '0xFF'));
      return PdfColor.fromInt(color);
    } catch (e) {
      return PdfColors.grey;
    }
  }

  // Descargar PDF
  static void downloadPDF(Uint8List pdfBytes, String fileName) {
    try {
      print('📄 Iniciando descarga de PDF: $fileName');
      print('📄 Tamaño del PDF: ${pdfBytes.length} bytes');
      
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      
      html.Url.revokeObjectUrl(url);
      print('✅ PDF descargado exitosamente');
    } catch (e) {
      print('❌ Error descargando PDF: $e');
      throw Exception('Error descargando PDF: $e');
    }
  }

  // Generar nombre de archivo
  static String generateFileName(CertificateTemplate template) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanName = template.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return '${cleanName}_${timestamp}.pdf';
  }
}
