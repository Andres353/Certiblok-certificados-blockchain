// lib/screens/programs/program_details_screen.dart
// Pantalla de detalles de un programa específico

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../../models/program_opportunity.dart';
import '../../services/programs_opportunities_service.dart';
import '../../services/user_context_service.dart';
import 'application_form_screen.dart';

class ProgramDetailsScreen extends StatefulWidget {
  final ProgramOpportunity program;

  const ProgramDetailsScreen({Key? key, required this.program}) : super(key: key);

  @override
  _ProgramDetailsScreenState createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  bool _isLoading = false;
  bool _canApply = false;

  @override
  void initState() {
    super.initState();
    _checkCanApply();
  }

  Future<void> _checkCanApply() async {
    setState(() => _isLoading = true);
    
    try {
      final context = UserContextService.currentContext;
      if (context != null && context.userRole == 'student') {
        final canApply = await ProgramsOpportunitiesService.canStudentApply(
          widget.program.id,
          context.userId,
        );
        setState(() {
          _canApply = canApply;
          _isLoading = false;
        });
      } else {
        setState(() {
          _canApply = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _canApply = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Programa'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con imagen y título
            _buildHeader(isWeb),
            
            // Contenido principal
            Padding(
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica
                  _buildBasicInfo(isWeb),
                  
                  SizedBox(height: 24),
                  
                  // Descripción
                  _buildDescription(isWeb),
                  
                  SizedBox(height: 24),
                  
                  // Requisitos
                  _buildRequirements(isWeb),
                  
                  SizedBox(height: 24),
                  
                  // Información adicional
                  _buildAdditionalInfo(isWeb),
                  
                  SizedBox(height: 24),
                  
                  // Documento PDF
                  _buildPdfSection(isWeb),
                  
                  SizedBox(height: 32),
                  
                  // Botón de acción
                  _buildActionButton(isWeb),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    return Container(
      width: double.infinity,
      height: isWeb ? 300 : 250,
      child: Stack(
        children: [
          // Imagen de fondo si existe
          if (widget.program.imageUrl != null)
            Positioned.fill(
              child: Image.network(
                widget.program.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Error cargando imagen en header: $error');
                  return _buildGradientBackground(isWeb);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Color(0xff6C4DDC),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            _buildGradientBackground(isWeb),
          
          // Overlay oscuro para mejor legibilidad
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Contenido
          Padding(
            padding: EdgeInsets.all(isWeb ? 32 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.program.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 32 : 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.program.institutionName,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isWeb ? 18 : 16,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${widget.program.careerNames.join(', ')}',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: isWeb ? 16 : 14,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Estado del programa
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(int.parse(widget.program.statusColor.replaceAll('#', '0xFF'))),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.program.status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff6C4DDC),
            Color(0xff8B7DDC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _BackgroundPatternPainter(),
      ),
    );
  }

  Widget _buildBasicInfo(bool isWeb) {
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
              Icons.schedule,
              'Fecha límite',
              _formatDate(widget.program.applicationDeadline),
              isWeb,
            ),
            _buildInfoRow(
              Icons.people,
              'Cupos disponibles',
              '${widget.program.currentApplications}/${widget.program.maxApplications}',
              isWeb,
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Días restantes',
              '${widget.program.daysUntilDeadline} días',
              isWeb,
            ),
            _buildInfoRow(
              Icons.school,
              'Institución',
              widget.program.institutionName,
              isWeb,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isWeb) {
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
            child: Text(
              value,
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descripción',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            Text(
              widget.program.description,
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirements(bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requisitos',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            ...widget.program.requirements.map((requirement) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: isWeb ? 18 : 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requirement,
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(bool isWeb) {
    if (widget.program.additionalInfo.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            ...widget.program.additionalInfo.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isWeb) {
    final context = UserContextService.currentContext;
    
    if (context?.userRole != 'student') {
      return SizedBox.shrink();
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
        ),
      );
    }

    if (!_canApply) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.info, color: Colors.grey[600], size: 32),
            SizedBox(height: 8),
            Text(
              'No puedes postularte a este programa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'El programa está cerrado, sin cupos disponibles o ya te postulaste',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: isWeb ? 56 : 50,
      child: ElevatedButton.icon(
        onPressed: _navigateToApplicationForm,
        icon: Icon(Icons.send, size: isWeb ? 20 : 18),
        label: Text(
          'Postularme',
          style: TextStyle(
            fontSize: isWeb ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff6C4DDC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  void _navigateToApplicationForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationFormScreen(program: widget.program),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPdfSection(bool isWeb) {
    // Usar pdfData si existe, sino pdfUrl como fallback
    final hasPdfData = widget.program.pdfData != null && widget.program.pdfData!.isNotEmpty;
    final hasPdfUrl = widget.program.pdfUrl != null && widget.program.pdfUrl!.isNotEmpty;
    
    if (!hasPdfData && !hasPdfUrl) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red[600],
                  size: isWeb ? 28 : 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Documento PDF',
                  style: TextStyle(
                    fontSize: isWeb ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
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
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.program.pdfFileName ?? 'Documento.pdf',
                          style: TextStyle(
                            fontSize: isWeb ? 16 : 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Información detallada del programa, requisitos específicos y proceso de selección.',
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openPdf(hasPdfData ? widget.program.pdfData! : widget.program.pdfUrl!),
                          icon: Icon(Icons.open_in_new, size: 18),
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
                        child: OutlinedButton.icon(
                          onPressed: () => _copyPdfUrl(hasPdfData ? widget.program.pdfData! : widget.program.pdfUrl!),
                          icon: Icon(Icons.copy, size: 18),
                          label: Text('Copiar URL'),
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
          ],
        ),
      ),
    );
  }

  void _openPdf(String pdfContent) async {
    // Determinar si es base64 puro o data URL
    final String dataUrl = pdfContent.startsWith('data:') 
        ? pdfContent 
        : 'data:application/pdf;base64,$pdfContent';
    
    try {
      print('🔄 Abriendo PDF automáticamente...');
      print('📄 URL generada: ${dataUrl.substring(0, 100)}...');
      
      // Usar JavaScript para crear blob URL y abrir en nueva pestaña
      await _openPdfWithBlob(dataUrl);
      
    } catch (e) {
      print('❌ Error al abrir PDF: $e');
      // Fallback: copiar al portapapeles y mostrar instrucciones
      _openPdfFallback(dataUrl);
    }
  }

  Future<void> _openPdfWithBlob(String dataUrl) async {
    try {
      print('🔄 Creando blob URL con JavaScript...');
      
      // Extraer el base64 del data URL
      final String base64Data = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      print('📊 Base64 extraído: ${base64Data.substring(0, 50)}...');
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Data);
      print('📊 Bytes decodificados: ${bytes.length} bytes');
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      print('📄 Blob URL creada: $blobUrl');
      
      // Abrir en nueva pestaña
      html.window.open(blobUrl, '_blank');
      
      _showInfoSnackBar('PDF abierto en nueva pestaña');
      print('✅ PDF abierto exitosamente con blob URL');
      
      // Limpiar la URL del blob después de un tiempo
      Future.delayed(Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(blobUrl);
        print('🧹 Blob URL limpiada');
      });
      
    } catch (e) {
      print('❌ Error con blob URL: $e');
      
      // Fallback: intentar con url_launcher
      try {
        final Uri pdfUri = Uri.parse(dataUrl);
        if (await canLaunchUrl(pdfUri)) {
          await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
          _showInfoSnackBar('PDF abierto en nueva pestaña');
          print('✅ PDF abierto con url_launcher fallback');
        } else {
          throw Exception('No se puede abrir con url_launcher');
        }
      } catch (e2) {
        print('❌ Fallback también falló: $e2');
        throw e;
      }
    }
  }

  void _openPdfFallback(String dataUrl) {
    try {
      // Copiar URL al portapapeles automáticamente
      _copyToClipboard(dataUrl);
      
      // Mostrar instrucciones para abrir en nueva pestaña
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red[600]),
                SizedBox(width: 8),
                Text('PDF Copiado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 48,
                  color: Color(0xff6C4DDC),
                ),
                SizedBox(height: 16),
                Text(
                  'La URL del PDF ha sido copiada al portapapeles.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Text(
                  'Para ver el PDF:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Abre una nueva pestaña en tu navegador',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '2. Pega la URL en la barra de direcciones (Ctrl+V)',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '3. Presiona Enter',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.check, size: 16),
                label: Text('Entendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error al copiar PDF: $e');
      _showErrorSnackBar('Error al copiar URL del PDF: $e');
    }
  }



  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard(String text) async {
    try {
      // Copiar al portapapeles usando el mismo método que certificados
      await Clipboard.setData(ClipboardData(text: text));
      
      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL copiada al portapapeles'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error al copiar al portapapeles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al copiar URL'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyPdfUrl(String pdfUrl) {
    try {
      // Para data URLs muy largas, mostrar un mensaje especial
      if (pdfUrl.startsWith('data:') && pdfUrl.length > 1000) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('URL del PDF'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'La URL del PDF es muy larga. Selecciona y copia el texto:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 200, // Altura fija para mejor visualización
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        pdfUrl,
                        style: TextStyle(
                          fontSize: 12, // Tamaño más legible
                          fontFamily: 'monospace', // Fuente monoespaciada
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Presiona Ctrl+A para seleccionar todo, luego Ctrl+C para copiar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _copyToClipboard(pdfUrl);
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('Copiar Todo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      } else {
        // Para URLs normales o data URLs cortas
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('URL del PDF'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selecciona y copia la URL:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      pdfUrl,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _copyToClipboard(pdfUrl);
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('Copiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      }
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL mostrada para copiar'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error al copiar URL: $e');
      _showErrorSnackBar('Error al mostrar URL: $e');
    }
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Dibujar círculos de fondo
    for (int i = 0; i < 20; i++) {
      final x = (i * 50.0) % size.width;
      final y = (i * 30.0) % size.height;
      canvas.drawCircle(Offset(x, y), 20, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
