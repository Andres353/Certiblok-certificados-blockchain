// lib/screens/admin/reports_screen.dart
// Pantalla de reportes y estadísticas del sistema

import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/alert_service.dart';
import '../../services/adapters/institution_adapter.dart';
import '../../models/institution.dart';
import '../../services/blockchain/blockchain_service.dart';
import '../../services/blockchain/blockchain_config.dart';
import 'package:web3dart/web3dart.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, int> _stats = {};
  List<Institution> _institutions = [];
  Map<String, int> _certificatesByInstitution = {};
  bool _isLoading = true;
  
  // Estadísticas de blockchain
  Map<String, dynamic> _blockchainStats = {};
  bool _isLoadingBlockchain = false;

  @override
  void initState() {
    super.initState();
    _loadSystemStats();
  }

  Future<void> _loadSystemStats() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      // Obtener estadísticas de usuarios
      final usersResponse = await supabase.from('users').select('role');
      int totalUsers = usersResponse.length;
      int students = 0;
      int emisors = 0;
      int admins = 0;
      
      for (var user in usersResponse) {
        switch (user['role']) {
          case 'student':
            students++;
            break;
          case 'emisor':
            emisors++;
            break;
          case 'super_admin':
            admins++;
            break;
        }
      }
      
      // Obtener estadísticas de certificados
      final certificatesResponse = await supabase.from('certificates').select('id, institution_id');
      int totalCertificates = certificatesResponse.length;
      
      // Contar certificados por institución
      Map<String, int> certificatesByInstitution = {};
      for (var cert in certificatesResponse) {
        String institutionId = cert['institution_id'] ?? 'unknown';
        certificatesByInstitution[institutionId] = (certificatesByInstitution[institutionId] ?? 0) + 1;
      }
      
      // Obtener estadísticas de solicitudes
      final requestsResponse = await supabase.from('institution_requests').select('status');
      int pendingRequests = 0;
      int approvedRequests = 0;
      int rejectedRequests = 0;
      
      for (var request in requestsResponse) {
        switch (request['status']) {
          case 'pending':
            pendingRequests++;
            break;
          case 'approved':
            approvedRequests++;
            break;
          case 'rejected':
            rejectedRequests++;
            break;
        }
      }
      
      // Cargar instituciones para obtener nombres
      final institutions = await InstitutionAdapter.getAllInstitutions();
      
      // Cargar estadísticas de blockchain
      await _loadBlockchainStats();
      
      setState(() {
        _stats = {
          'total_users': totalUsers,
          'students': students,
          'emisors': emisors,
          'admins': admins,
          'total_certificates': totalCertificates,
          'pending_requests': pendingRequests,
          'approved_requests': approvedRequests,
          'rejected_requests': rejectedRequests,
        };
        _institutions = institutions;
        _certificatesByInstitution = certificatesByInstitution;
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Error cargando estadísticas: $e');
      setState(() => _isLoading = false);
      AlertService.showError(context, 'Error', 'Error cargando estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes del Sistema'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _exportToPdf,
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
          ),
          IconButton(
            onPressed: _loadSystemStats,
            icon: Icon(Icons.refresh),
            tooltip: 'Actualizar Reportes',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildUsersReport(),
                  SizedBox(height: 24),
                  _buildCertificatesReport(),
                  SizedBox(height: 24),
                  _buildCertificatesByInstitutionChart(),
                  SizedBox(height: 24),
                  _buildRequestsReport(),
                  SizedBox(height: 24),
                  _buildBlockchainStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportes y Estadísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Análisis completo del sistema CertiBlock',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersReport() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Usuarios del Sistema',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildStatItem('Total Usuarios', _stats['total_users'] ?? 0, Icons.people, Colors.purple),
            _buildStatItem('Estudiantes', _stats['students'] ?? 0, Icons.school, Colors.blue),
            _buildStatItem('Emisores', _stats['emisors'] ?? 0, Icons.verified_user, Colors.green),
            _buildStatItem('Administradores', _stats['admins'] ?? 0, Icons.admin_panel_settings, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesReport() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Certificados Emitidos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildStatItem('Total Certificados', _stats['total_certificates'] ?? 0, Icons.card_membership, Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsReport() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Solicitudes de Instituciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildStatItem('Pendientes', _stats['pending_requests'] ?? 0, Icons.pending_actions, Colors.orange),
            _buildStatItem('Aprobadas', _stats['approved_requests'] ?? 0, Icons.check_circle_outline, Colors.green),
            _buildStatItem('Rechazadas', _stats['rejected_requests'] ?? 0, Icons.cancel_outlined, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesByInstitutionChart() {
    // Preparar datos para el gráfico
    List<Map<String, dynamic>> chartData = [];
    
    for (var institution in _institutions) {
      int certificateCount = _certificatesByInstitution[institution.id] ?? 0;
      if (certificateCount > 0) { // Solo mostrar instituciones con certificados
        chartData.add({
          'name': institution.shortName.isNotEmpty ? institution.shortName : institution.name,
          'count': certificateCount,
          'color': Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
        });
      }
    }
    
    // Ordenar por número de certificados (descendente)
    chartData.sort((a, b) => b['count'].compareTo(a['count']));
    
    if (chartData.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Color(0xff6C4DDC), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Certificados por Institución',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No hay certificados emitidos aún',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Encontrar el valor máximo para escalar las barras
    int maxValue = chartData.isNotEmpty ? chartData.first['count'] : 1;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Certificados por Institución',
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
              height: 300,
              child: Column(
                children: [
                  // Gráfico de barras horizontal
                  Expanded(
                    child: ListView.builder(
                      itemCount: chartData.length,
                      itemBuilder: (context, index) {
                        var data = chartData[index];
                        double percentage = maxValue > 0 ? (data['count'] / maxValue) : 0.0;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre de la institución y valor
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff2E2F44),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${data['count']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: data['color'],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              // Barra de progreso
                              Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    // Barra de fondo
                                    Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    // Barra de progreso
                                    FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: percentage,
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: data['color'],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Leyenda con colores
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: chartData.take(5).map((data) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: data['color'],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    data['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff2E2F44),
            ),
          ),
          Spacer(),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBlockchainStats() async {
    setState(() => _isLoadingBlockchain = true);
    
    try {
      // Obtener información de la wallet
      Map<String, String>? walletInfo;
      EtherAmount? balance;
      try {
        final blockchainService = BlockchainService();
        walletInfo = await blockchainService.getWalletInfo();
        
        if (walletInfo != null) {
          try {
            await blockchainService.initialize(BlockchainConfig.contractAddress);
            balance = await blockchainService.getBalance();
          } catch (e) {
            print('⚠️ No se pudo obtener balance: $e');
          }
        }
      } catch (e) {
        print('⚠️ Error obteniendo información de wallet: $e');
      }
      
      setState(() {
        _blockchainStats = {
          'wallet_address': walletInfo?['address'] ?? 'No configurada',
          'wallet_configured_by': walletInfo?['configured_by'] ?? 'N/A',
          'wallet_configured_at': walletInfo?['configured_at'] ?? 'N/A',
          'balance_matic': balance != null ? balance.getValueInUnit(EtherUnit.ether) : null,
          'contract_address': BlockchainConfig.contractAddress,
          'network': BlockchainConfig.useTestnet ? 'Polygon Mumbai Testnet' : 'Polygon Mainnet',
          'chain_id': BlockchainConfig.chainId,
          'explorer_url': BlockchainConfig.explorerUrl,
        };
        _isLoadingBlockchain = false;
      });
      
    } catch (e) {
      print('❌ Error cargando estadísticas de blockchain: $e');
      setState(() {
        _blockchainStats = {};
        _isLoadingBlockchain = false;
      });
    }
  }

  Widget _buildBlockchainStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Estadísticas de Blockchain',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            if (_isLoadingBlockchain)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_blockchainStats.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No hay estadísticas de blockchain disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SizedBox(height: 16),
              
              // Información de la red
              Text(
                'Configuración de Red',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 12),
              _buildBlockchainInfoRow('Red', _blockchainStats['network'] ?? 'N/A'),
              _buildBlockchainInfoRow('Chain ID', '${_blockchainStats['chain_id'] ?? 'N/A'}'),
              _buildBlockchainInfoRow('Contrato', _formatAddress(_blockchainStats['contract_address'] ?? 'N/A')),
              
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              
              // Información de la wallet
              Text(
                'Wallet Blockchain',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 12),
              _buildBlockchainInfoRow('Dirección', _formatAddress(_blockchainStats['wallet_address'] ?? 'No configurada')),
              if (_blockchainStats['balance_matic'] != null)
                _buildBlockchainInfoRow(
                  'Balance',
                  '${(_blockchainStats['balance_matic'] as double).toStringAsFixed(4)} MATIC',
                ),
              _buildBlockchainInfoRow('Configurada por', _blockchainStats['wallet_configured_by'] ?? 'N/A'),
              
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              
              // Costos estimados
              Text(
                'Costos Estimados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
              ),
              SizedBox(height: 12),
              _buildBlockchainInfoRow(
                'Costo Total Estimado',
                '${(_blockchainStats['estimated_cost_matic'] as double? ?? 0.0).toStringAsFixed(4)} MATIC',
              ),
              _buildBlockchainInfoRow(
                'Costo por Certificado',
                '~0.006 MATIC (~\$0.004 USD)',
              ),
              
              SizedBox(height: 16),
              
              // Botón para ver en explorador
              if (_blockchainStats['contract_address'] != null && 
                  _blockchainStats['contract_address'] != 'N/A' &&
                  _blockchainStats['explorer_url'] != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final explorerUrl = _blockchainStats['explorer_url'] as String;
                      final contractAddress = _blockchainStats['contract_address'] as String;
                      final url = '$explorerUrl/address/$contractAddress';
                      // Abrir directamente en nueva pestaña
                      html.window.open(url, '_blank');
                    },
                    icon: Icon(Icons.open_in_new, size: 18),
                    label: Text('Ver Contrato en Polygonscan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildBlockchainInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address == 'N/A' || address == 'No configurada' || address.isEmpty) {
      return address;
    }
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  Future<void> _exportToPdf() async {
    try {
      setState(() => _isLoading = true);
      
      // Crear documento PDF
      final pdf = pw.Document();
      final now = DateTime.now();
      
      // Página 1: Portada y Resumen Ejecutivo
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Portada
              pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'REPORTE DEL SISTEMA',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'CertiBlock - Sistema de Certificados Académicos',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      'Generado el: ${_formatDate(now)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              
              // Resumen Ejecutivo
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Resumen Ejecutivo',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Estadísticas principales en tabla
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildTableRow('Total de Usuarios', '${_stats['total_users'] ?? 0}', true),
                  _buildTableRow('Estudiantes', '${_stats['students'] ?? 0}'),
                  _buildTableRow('Emisores', '${_stats['emisors'] ?? 0}'),
                  _buildTableRow('Administradores', '${_stats['admins'] ?? 0}'),
                  _buildTableRow('Total Certificados', '${_stats['total_certificates'] ?? 0}', true),
                  _buildTableRow('Solicitudes Pendientes', '${_stats['pending_requests'] ?? 0}'),
                  _buildTableRow('Solicitudes Aprobadas', '${_stats['approved_requests'] ?? 0}'),
                  _buildTableRow('Solicitudes Rechazadas', '${_stats['rejected_requests'] ?? 0}'),
                ],
              ),
            ];
          },
        ),
      );
      
      // Página 2: Certificados por Institución
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Certificados por Institución',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              if (_certificatesByInstitution.isEmpty)
                pw.Text(
                  'No hay certificados emitidos aún',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Encabezado
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue100),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Institución',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Certificados',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Datos
                    ..._institutions.map((institution) {
                      int count = _certificatesByInstitution[institution.id] ?? 0;
                      if (count == 0) return null;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              institution.shortName.isNotEmpty 
                                  ? institution.shortName 
                                  : institution.name,
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              count.toString(),
                              style: pw.TextStyle(fontSize: 11),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }).whereType<pw.TableRow>().toList(),
                  ],
                ),
            ];
          },
        ),
      );
      
      // Página 3: Estadísticas de Blockchain
      if (_blockchainStats.isNotEmpty)
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Estadísticas de Blockchain',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _buildTableRow('Red', _blockchainStats['network'] ?? 'N/A'),
                    _buildTableRow('Chain ID', '${_blockchainStats['chain_id'] ?? 'N/A'}'),
                    _buildTableRow('Dirección del Contrato', _blockchainStats['contract_address'] ?? 'N/A'),
                    _buildTableRow('Dirección de Wallet', _blockchainStats['wallet_address'] ?? 'No configurada'),
                    if (_blockchainStats['balance_matic'] != null)
                      _buildTableRow(
                        'Balance',
                        '${(_blockchainStats['balance_matic'] as double).toStringAsFixed(4)} MATIC',
                      ),
                    _buildTableRow('Configurada por', _blockchainStats['wallet_configured_by'] ?? 'N/A'),
                    _buildTableRow('Costo por Certificado', '~0.006 MATIC (~\$0.004 USD)'),
                  ],
                ),
              ];
            },
          ),
        );
      
      // Generar bytes del PDF
      final pdfBytes = await pdf.save();
      
      // Descargar el PDF usando el mismo método que PDFGeneratorService
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'reporte_sistema_${_formatDateForFile(now)}.pdf')
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      setState(() => _isLoading = false);
      AlertService.showSuccess(
        context,
        'Éxito',
        'Reporte exportado exitosamente como PDF',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error exportando PDF: $e');
      AlertService.showError(
        context,
        'Error',
        'Error al exportar reporte: $e',
      );
    }
  }

  pw.TableRow _buildTableRow(String label, String value, [bool isHeader = false]) {
    return pw.TableRow(
      decoration: isHeader 
          ? pw.BoxDecoration(color: PdfColors.blue100)
          : null,
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isHeader ? 12 : 11,
            ),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isHeader ? 12 : 11,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateForFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }
}
