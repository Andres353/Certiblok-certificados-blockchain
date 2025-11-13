// lib/screens/admin/all_certificates_screen.dart
// Pantalla para ver todos los certificados emitidos por la institución

import 'package:flutter/material.dart';
import '../../services/adapters/certificate_adapter.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate.dart';
import '../certificates/certificate_detail_screen.dart';

class AllCertificatesScreen extends StatefulWidget {
  const AllCertificatesScreen({Key? key}) : super(key: key);

  @override
  _AllCertificatesScreenState createState() => _AllCertificatesScreenState();
}

class _AllCertificatesScreenState extends State<AllCertificatesScreen> {
  bool _isLoading = true;
  List<Certificate> _certificates = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Todos'},
    {'value': 'active', 'label': 'Activos'},
    {'value': 'revoked', 'label': 'Revocados'},
    {'value': 'expired', 'label': 'Expirados'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoading = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario debe tener institución asignada');
      }

      print('🔍 Cargando todos los certificados de la institución: ${userContext!.institutionId}');
      final certificates = await CertificateAdapter.getCertificates(
        institutionId: userContext.institutionId,
      );
      
      setState(() {
        _certificates = certificates.cast<Certificate>();
        _isLoading = false;
      });
      
      print('📋 Certificados encontrados: ${_certificates.length}');
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error cargando certificados: $e');
      AlertService.showError(context, 'Error', 'Error cargando certificados: $e');
    }
  }

  List<Certificate> get _filteredCertificates {
    var filtered = _certificates;
    
    // Filtrar por estado
    if (_selectedFilter != 'all') {
      filtered = filtered.where((cert) => cert.status == _selectedFilter).toList();
    }
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((cert) {
        return cert.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               cert.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               cert.certificateType.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todos los Certificados'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadCertificates,
            icon: Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _buildCertificatesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar certificados...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          // Filtros de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter['value'];
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter['value']! : 'all';
                      });
                    },
                    selectedColor: Color(0xff6C4DDC).withOpacity(0.2),
                    checkmarkColor: Color(0xff6C4DDC),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesList() {
    final filteredCertificates = _filteredCertificates;
    
    if (filteredCertificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'No se encontraron certificados con los filtros aplicados'
                  : 'No hay certificados emitidos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'Intenta con otros filtros o términos de búsqueda'
                  : 'Los certificados aparecerán aquí cuando sean emitidos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredCertificates.length,
      itemBuilder: (context, index) {
        final certificate = filteredCertificates[index];
        return _buildCertificateCard(certificate);
      },
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {
    Color statusColor;
    IconData statusIcon;
    
    switch (certificate.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'revoked':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      case 'expired':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _viewCertificateDetails(certificate),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        certificate.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xff2E2F44),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          SizedBox(width: 4),
                          Text(
                            certificate.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Información del estudiante
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certificate.studentName,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Tipo de certificado
                Row(
                  children: [
                    Icon(Icons.school, color: Colors.grey[600], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certificate.certificateType,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Fecha de emisión
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Emitido: ${certificate.issuedAt.toString().split(' ')[0]}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewCertificateDetails(Certificate certificate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateDetailScreen(
          certificate: certificate,
          isAdminView: true, // Vista de administrador sin funcionalidades
        ),
      ),
    );
  }
}
