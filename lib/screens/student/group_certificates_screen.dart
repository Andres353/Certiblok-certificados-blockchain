import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'package:frontend_app/services/adapters/certificate_adapter.dart';
import 'package:frontend_app/services/user_context_service.dart';
import 'package:frontend_app/services/grouped_qr_service.dart';
import 'package:frontend_app/screens/student/saved_grouped_qrs_screen.dart';

class GroupCertificatesScreen extends StatefulWidget {
  @override
  _GroupCertificatesScreenState createState() => _GroupCertificatesScreenState();
}

class _GroupCertificatesScreenState extends State<GroupCertificatesScreen> {
  List<dynamic> _certificates = [];
  List<dynamic> _selectedCertificates = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = UserContextService.currentContext?.userId;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Usuario no autenticado';
        });
        return;
      }

      final certificates = await CertificateAdapter.getCertificatesByStudent(userId);
      
      setState(() {
        _isLoading = false;
        _certificates = certificates;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando certificados: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8f9fa),
      appBar: AppBar(
        title: Text(
          'Crear QR Agrupado',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xff6C4DDC),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedGroupedQRsScreen(),
                ),
              );
            },
            icon: Icon(Icons.history),
            tooltip: 'Ver QRs guardados',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
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
          SizedBox(height: 20),
          Text(
            'Cargando certificados...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
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
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadCertificates,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_certificates.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC), Color(0xff8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Crear QR Agrupado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Selecciona los certificados que quieres incluir en el QR agrupado',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Selector de certificados
          _buildCertificateSelector(),

          SizedBox(height: 24),

          // Botones de acción
          _buildActionButtons(),

          if (_selectedCertificates.isNotEmpty) ...[
            SizedBox(height: 24),
            _buildSelectedCertificates(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'No hay certificados',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'No tienes certificados disponibles para agrupar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.checklist, color: Color(0xff6C4DDC)),
                SizedBox(width: 12),
                Text(
                  'Seleccionar Certificados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
                Spacer(),
                Text(
                  '${_selectedCertificates.length} de ${_certificates.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: _certificates.length,
              itemBuilder: (context, index) {
                final certificate = _certificates[index];
                final isSelected = _selectedCertificates.contains(certificate);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedCertificates.add(certificate);
                      } else {
                        _selectedCertificates.remove(certificate);
                      }
                    });
                  },
                  title: Text(
                    certificate['title'] ?? 'Sin título',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCertificateTypeLabel(certificate['certificate_type']),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Emitido: ${_formatDate(certificate['issued_at'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(0xff6C4DDC).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      color: isSelected ? Color(0xff6C4DDC) : Colors.grey[400],
                    ),
                  ),
                  activeColor: Color(0xff6C4DDC),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectedCertificates.isEmpty ? null : _selectAll,
            icon: Icon(Icons.select_all, size: 20),
            label: Text('Seleccionar Todos'),
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
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectedCertificates.isEmpty ? null : _clearSelection,
            icon: Icon(Icons.clear_all, size: 20),
            label: Text('Limpiar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[300]!),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCertificates() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: Color(0xff6C4DDC)),
                SizedBox(width: 12),
                Text(
                  'Certificados Seleccionados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _generateGroupedQR,
                  icon: Icon(Icons.qr_code, size: 20),
                  label: Text('Generar QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: _selectedCertificates.length,
              itemBuilder: (context, index) {
                final certificate = _selectedCertificates[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      color: Color(0xff6C4DDC),
                    ),
                  ),
                  title: Text(
                    certificate['title'] ?? 'Sin título',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  subtitle: Text(
                    _getCertificateTypeLabel(certificate['certificate_type']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectAll() {
    setState(() {
      _selectedCertificates = List.from(_certificates);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCertificates.clear();
    });
  }

  void _generateGroupedQR() {
    if (_selectedCertificates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona al menos un certificado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showNameDialog();
  }

  void _showNameDialog() {
    final TextEditingController nameController = TextEditingController();
    final defaultName = 'QR Agrupado ${_selectedCertificates.length} certificados';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nombre del QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Asigna un nombre a tu QR agrupado para identificarlo fácilmente:'),
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del QR',
                hintText: defaultName,
                border: OutlineInputBorder(),
              ),
              autofocus: true,
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
              final name = nameController.text.trim().isEmpty 
                  ? defaultName 
                  : nameController.text.trim();
              Navigator.pop(context);
              _createAndSaveGroupedQR(name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
            ),
            child: Text('Crear QR'),
          ),
        ],
      ),
    );
  }

  void _createAndSaveGroupedQR(String name) async {
    try {
      // Crear URL con múltiples IDs de certificados
      final certificateIds = _selectedCertificates.map((cert) => cert['id']).join(',');
      final groupedQRUrl = 'http://localhost:8081/#/verify/certificates/$certificateIds';
      final certificateTitles = _selectedCertificates.map((cert) => cert['title'] ?? 'Sin título').cast<String>().toList();
      
      print('🔍 DEBUG - Generando QR con URL: $groupedQRUrl');
      print('🔍 DEBUG - Certificados seleccionados: ${_selectedCertificates.length}');
      
      // Guardar QR
      await GroupedQRService.saveGroupedQR(
        name: name,
        qrUrl: groupedQRUrl,
        certificateIds: certificateIds.split(',').cast<String>(),
        certificateTitles: certificateTitles,
      );
      
      _showGroupedQRDialog(groupedQRUrl, name);
    } catch (e) {
      print('❌ Error generando QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGroupedQRDialog(String qrUrl, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Agrupado Generado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'QR guardado exitosamente',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Nombre: $name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${_selectedCertificates.length} certificados incluidos',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                width: 250,
                height: 250,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: FutureBuilder<QrPainter>(
                  future: _createQrPainter(qrUrl),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return CustomPaint(
                        painter: snapshot.data,
                        size: Size(218, 218),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error generando QR',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    } else {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6C4DDC)),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Comparte este QR para ver todos los certificados seleccionados',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _copyGroupedQRURL(qrUrl);
            },
            icon: Icon(Icons.copy, size: 18),
            label: Text('Copiar URL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[600],
              side: BorderSide(color: Colors.orange[600]!),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedGroupedQRsScreen(),
                ),
              );
            },
            icon: Icon(Icons.history, size: 18),
            label: Text('Ver Guardados'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xff6C4DDC),
              side: BorderSide(color: Color(0xff6C4DDC)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadGroupedQR(qrUrl);
            },
            icon: Icon(Icons.download, size: 18),
            label: Text('Descargar QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _copyGroupedQRURL(String qrUrl) async {
    try {
      await Clipboard.setData(ClipboardData(text: qrUrl));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('URL copiada al portapapeles'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copiando URL: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _downloadGroupedQR(String qrUrl) async {
    try {
      // Mostrar SnackBar de progreso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Generando QR...'),
            ],
          ),
          backgroundColor: Color(0xff6C4DDC),
          duration: Duration(seconds: 2),
        ),
      );

      // Generar QR como imagen
      final qrPainter = QrPainter(
        data: qrUrl,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      // Crear imagen del QR
      final picData = await qrPainter.toImageData(400);
      
      if (picData != null) {
        final bytes = picData.buffer.asUint8List();
        final blob = html.Blob([bytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Crear elemento de descarga
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'qr_agrupado_${_selectedCertificates.length}_certificados.png')
          ..style.display = 'none';
        
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        // Limpiar URL
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR agrupado descargado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('No se pudo generar la imagen del QR');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error descargando QR: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'N/A';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<QrPainter> _createQrPainter(String data) async {
    return QrPainter(
      data: data,
      version: QrVersions.auto,
      color: Colors.black,
      emptyColor: Colors.white,
    );
  }

}
