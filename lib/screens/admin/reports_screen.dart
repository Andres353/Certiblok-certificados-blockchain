// lib/screens/admin/reports_screen.dart
// Pantalla de reportes y estadísticas del sistema

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/alert_service.dart';
import '../../services/adapters/institution_adapter.dart';
import '../../models/institution.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, int> _stats = {};
  List<Institution> _institutions = [];
  Map<String, int> _certificatesByInstitution = {};
  bool _isLoading = true;

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
}
