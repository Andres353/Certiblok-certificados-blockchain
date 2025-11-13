// lib/screens/student/saved_grouped_qrs_screen.dart
// Pantalla para gestionar QRs agrupados guardados

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'package:frontend_app/models/grouped_qr.dart';
import 'package:frontend_app/services/grouped_qr_service.dart';

class SavedGroupedQRsScreen extends StatefulWidget {
  @override
  _SavedGroupedQRsScreenState createState() => _SavedGroupedQRsScreenState();
}

class _SavedGroupedQRsScreenState extends State<SavedGroupedQRsScreen> {
  List<GroupedQR> _groupedQRs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroupedQRs();
  }

  Future<void> _loadGroupedQRs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final qrs = await GroupedQRService.getGroupedQRs();
      
      setState(() {
        _isLoading = false;
        _groupedQRs = qrs;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando QRs guardados: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8f9fa),
      appBar: AppBar(
        title: Text(
          'QRs Agrupados Guardados',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xff6C4DDC),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _groupedQRs.isEmpty
                  ? _buildEmptyState()
                  : _buildQRsList(),
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
            'Cargando QRs guardados...',
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
              onPressed: _loadGroupedQRs,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'No hay QRs guardados',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Crea tu primer QR agrupado para verlo aquí',
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

  Widget _buildQRsList() {
    return RefreshIndicator(
      onRefresh: _loadGroupedQRs,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _groupedQRs.length,
        itemBuilder: (context, index) {
          final qr = _groupedQRs[index];
          return _buildQRCard(qr);
        },
      ),
    );
  }

  Widget _buildQRCard(GroupedQR qr) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC), Color(0xff8B5CF6)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qr.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${qr.certificateIds.length} certificados • ${_formatDate(qr.createdAt)}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) => _handleMenuAction(value, qr),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('Ver QR'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 8),
                          Text('Copiar URL'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text('Descargar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificados incluidos:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2E2F44),
                  ),
                ),
                SizedBox(height: 8),
                ...qr.certificateTitles.take(3).map((title) => 
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Color(0xff6C4DDC)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (qr.certificateTitles.length > 3)
                  Text(
                    '... y ${qr.certificateTitles.length - 3} más',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewQR(qr),
                        icon: Icon(Icons.visibility, size: 18),
                        label: Text('Ver QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xff6C4DDC),
                          side: BorderSide(color: Color(0xff6C4DDC)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyURL(qr),
                        icon: Icon(Icons.copy, size: 18),
                        label: Text('Copiar URL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[600],
                          side: BorderSide(color: Colors.orange[600]!),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadQR(qr),
                        icon: Icon(Icons.download, size: 18),
                        label: Text('Descargar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
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
    );
  }

  void _handleMenuAction(String action, GroupedQR qr) {
    switch (action) {
      case 'view':
        _viewQR(qr);
        break;
      case 'copy':
        _copyURL(qr);
        break;
      case 'download':
        _downloadQR(qr);
        break;
      case 'delete':
        _deleteQR(qr);
        break;
    }
  }

  void _copyURL(GroupedQR qr) async {
    try {
      await Clipboard.setData(ClipboardData(text: qr.qrUrl));
      
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

  void _viewQR(GroupedQR qr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(qr.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${qr.certificateIds.length} certificados incluidos',
              style: TextStyle(fontSize: 16),
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
                future: _createQrPainter(qr.qrUrl),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _copyURL(qr);
            },
            icon: Icon(Icons.copy, size: 18),
            label: Text('Copiar URL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[600],
              side: BorderSide(color: Colors.orange[600]!),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadQR(qr);
            },
            icon: Icon(Icons.download, size: 18),
            label: Text('Descargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadQR(GroupedQR qr) async {
    try {
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

      final qrPainter = QrPainter(
        data: qr.qrUrl,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final picData = await qrPainter.toImageData(400);
      
      if (picData != null) {
        final bytes = picData.buffer.asUint8List();
        final blob = html.Blob([bytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', '${qr.name.replaceAll(' ', '_')}_qr.png')
          ..style.display = 'none';
        
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR descargado exitosamente'),
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

  void _deleteQR(GroupedQR qr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar QR'),
        content: Text('¿Estás seguro de que quieres eliminar "${qr.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await GroupedQRService.deleteGroupedQR(qr.id);
                await _loadGroupedQRs();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('QR eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error eliminando QR: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<QrPainter> _createQrPainter(String data) async {
    return QrPainter(
      data: data,
      version: QrVersions.auto,
      color: Colors.black,
      emptyColor: Colors.white,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Hace un momento';
    }
  }
}
