// lib/screens/certificates/template_preview_widget.dart
// Widget de vista previa de plantillas de certificados

import 'package:flutter/material.dart';
import '../../models/certificate_template.dart';

class TemplatePreviewWidget extends StatelessWidget {
  final CertificateTemplate template;

  const TemplatePreviewWidget({Key? key, required this.template}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(template.design.borderRadius),
        border: template.layout.showBorder
            ? Border.all(
                color: _parseColor(template.design.borderColor),
                width: template.design.borderWidth,
              )
            : null,
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
          // Header
          if (template.layout.showHeader) _buildHeader(),
          
          // Línea decorativa
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _parseColor(template.design.primaryColor),
                  _parseColor(template.design.secondaryColor),
                ],
              ),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(template.layout.padding.top),
              child: _buildContent(),
            ),
          ),
          
          // Footer
          if (template.layout.showFooter) _buildFooter(),
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
          colors: [
            _parseColor(template.design.headerBackgroundColor),
            _parseColor(template.design.secondaryColor),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(template.design.borderRadius),
          topRight: Radius.circular(template.design.borderRadius),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: template.design.logoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      template.design.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.school,
                        color: _parseColor(template.design.primaryColor),
                        size: 30,
                      ),
                    ),
                  )
                : Icon(
                    Icons.school,
                    color: _parseColor(template.design.primaryColor),
                    size: 30,
                  ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Institución Educativa',
                  style: TextStyle(
                    color: _parseColor(template.design.headerTextColor),
                    fontSize: template.design.titleFontSize * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Código: UNIVAL',
                  style: TextStyle(
                    color: _parseColor(template.design.headerTextColor).withOpacity(0.7),
                    fontSize: template.design.smallFontSize,
                  ),
                ),
              ],
            ),
          ),
          // Estado del certificado
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VÁLIDO',
              style: TextStyle(
                color: Colors.white,
                fontSize: template.design.smallFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Ordenar campos por orden
    final sortedFields = List<TemplateField>.from(template.fields)
      ..sort((a, b) => a.order.compareTo(b.order));

    return SingleChildScrollView(
      child: Column(
        children: sortedFields.map((field) {
          if (!field.isVisible) return SizedBox.shrink();
          
          return Container(
            margin: EdgeInsets.only(
              top: field.position.y,
              left: field.position.x,
              right: 0,
              bottom: 8,
            ),
            width: field.position.width,
            height: field.position.height,
            child: _buildField(field),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildField(TemplateField field) {
    final style = field.style;
    
    Widget content;
    
    switch (field.type) {
      case 'text':
        content = Text(
          _getFieldValue(field),
          style: TextStyle(
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
            color: _parseColor(style.color),
            decoration: style.isUnderline ? TextDecoration.underline : null,
          ),
          textAlign: _getTextAlign(style.textAlign),
        );
        break;
      case 'date':
        content = Text(
          _getFieldValue(field),
          style: TextStyle(
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
            color: _parseColor(style.color),
          ),
          textAlign: _getTextAlign(style.textAlign),
        );
        break;
      case 'image':
        content = template.design.logoUrl.isNotEmpty
            ? Image.network(
                template.design.logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image,
                  size: style.fontSize,
                  color: _parseColor(style.color),
                ),
              )
            : Icon(
                Icons.image,
                size: style.fontSize,
                color: _parseColor(style.color),
              );
        break;
      case 'qr':
        content = Container(
          width: style.fontSize * 2,
          height: style.fontSize * 2,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _parseColor(style.color)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.qr_code,
            size: style.fontSize,
            color: _parseColor(style.color),
          ),
        );
        break;
      case 'signature':
        content = Column(
          children: [
            Container(
              width: field.position.width,
              height: 1,
              color: _parseColor(style.color),
            ),
            SizedBox(height: 4),
            Text(
              _getFieldValue(field),
              style: TextStyle(
                fontFamily: style.fontFamily,
                fontSize: style.fontSize,
                fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
                color: _parseColor(style.color),
              ),
              textAlign: _getTextAlign(style.textAlign),
            ),
          ],
        );
        break;
      default:
        content = Text(
          _getFieldValue(field),
          style: TextStyle(
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            color: _parseColor(style.color),
          ),
          textAlign: _getTextAlign(style.textAlign),
        );
    }

    return Container(
      decoration: BoxDecoration(
        color: style.backgroundColor != 'transparent' 
            ? _parseColor(style.backgroundColor) 
            : null,
        borderRadius: BorderRadius.circular(style.borderRadius),
      ),
      child: content,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(template.design.borderRadius),
          bottomRight: Radius.circular(template.design.borderRadius),
        ),
      ),
      child: Column(
        children: [
          Text(
            'VERIFICACIÓN',
            style: TextStyle(
              fontSize: template.design.smallFontSize,
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
                      fontSize: template.design.smallFontSize * 0.8,
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
                      'ABC123...',
                      style: TextStyle(
                        fontSize: template.design.smallFontSize * 0.8,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // QR Code
              Column(
                children: [
                  Text(
                    'Código QR',
                    style: TextStyle(
                      fontSize: template.design.smallFontSize * 0.8,
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
              fontSize: template.design.smallFontSize * 0.8,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getFieldValue(TemplateField field) {
    // Reemplazar variables con datos de ejemplo
    String value = field.value;
    
    // Variables comunes
    value = value.replaceAll('{{studentName}}', 'Juan Pérez');
    value = value.replaceAll('{{description}}', 'Por haber completado exitosamente el programa académico');
    value = value.replaceAll('{{issuedAt}}', '18/9/2025');
    value = value.replaceAll('{{issuedByName}}', 'Dr. María González');
    value = value.replaceAll('{{id}}', 'CERT-123456');
    value = value.replaceAll('{{institutionName}}', 'Universidad del Valle');
    value = value.replaceAll('{{programName}}', 'Ingeniería en Sistemas');
    value = value.replaceAll('{{facultyName}}', 'Facultad de Ingeniería');
    
    return value;
  }

  TextAlign _getTextAlign(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
