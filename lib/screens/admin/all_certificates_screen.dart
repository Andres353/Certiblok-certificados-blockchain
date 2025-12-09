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
      if (userContext?.userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Para administradores: obtener solo los certificados emitidos por este administrador
      print('🔍 Cargando certificados emitidos por administrador: ${userContext!.userId}');
      final certificatesData = await CertificateAdapter.getCertificatesByEmisor(userContext.userId);
      
      final certificates = certificatesData.map((data) {
        if (data is Certificate) {
          return data;
        } else {
          return Certificate.fromSupabase(Map<String, dynamic>.from(data));
        }
      }).toList();
      
      setState(() {
        _certificates = certificates;
        _isLoading = false;
      });
      
      print('📋 Certificados encontrados emitidos por este administrador: ${certificates.length}');
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
      filtered = filtered.where((cert) {
        if (_selectedFilter == 'active') {
          return cert.status.toLowerCase() == 'active';
        } else if (_selectedFilter == 'revoked') {
          return cert.status.toLowerCase() == 'revoked';
        } else if (_selectedFilter == 'expired') {
          return cert.status.toLowerCase() == 'expired' ||
                 (cert.expiresAt != null && cert.expiresAt!.isBefore(DateTime.now()));
        }
        return true;
      }).toList();
    }
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((cert) {
        return cert.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
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
      body: Column(
        children: [
          // Filtros y búsqueda
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por título o tipo de certificado...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                SizedBox(height: 12),
                
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter['label']!),
                          selected: _selectedFilter == filter['value'],
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter['value']!;
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
          ),
          
          // Lista de certificados
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredCertificates.isEmpty
                    ? _buildEmptyState()
                    : _buildCertificatesList(),
          ),
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
              Icons.workspace_premium_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No hay certificados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron certificados con la búsqueda "$_searchQuery"'
                  : 'No tienes certificados emitidos aún.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular número de columnas para ajustar a la pantalla (igual que dashboard principal)
        int crossAxisCount;
        double childAspectRatio;
        
        // Calcular el espacio disponible
        final availableWidth = constraints.maxWidth;
        
        if (availableWidth > 1400) {
          crossAxisCount = 4;
          childAspectRatio = 1.6; // Más anchos y menos altos
        } else if (availableWidth > 1000) {
          crossAxisCount = 3;
          childAspectRatio = 1.5; // Más anchos y menos altos
        } else if (availableWidth > 700) {
          crossAxisCount = 2;
          childAspectRatio = 1.6; // Más anchos y menos altos
        } else {
          crossAxisCount = 1;
          childAspectRatio = 3.0; // Más anchos y menos altos
        }
        
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredCertificates.length,
          itemBuilder: (context, index) {
            final certificate = _filteredCertificates[index];
            return _buildCertificateCard(certificate);
          },
        );
      },
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white, // Color sólido sin degradado
        ),
        child: InkWell(
          onTap: () => _viewCertificateDetails(certificate),
          borderRadius: BorderRadius.circular(16),
            child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Título del certificado
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xff6C4DDC).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    certificate.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Información en badges
                Row(
                  children: [
                    // Estado
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(certificate.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(certificate.status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(certificate.status),
                          style: TextStyle(
                            color: _getStatusColor(certificate.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 6),
                    
                    // Tipo de certificado
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xff6C4DDC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xff6C4DDC).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getCertificateTypeLabel(certificate.certificateType),
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xff6C4DDC),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Información de institución
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          certificate.institutionName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 6),
                
                // Fecha de emisión
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDate(certificate.issuedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Botón de acción principal
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewCertificateDetails(certificate),
                    icon: Icon(Icons.visibility, size: 14),
                    label: Text('Ver Información'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'revoked':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'ACTIVO';
      case 'revoked':
        return 'REVOCADO';
      case 'expired':
        return 'EXPIRADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  String _getCertificateTypeLabel(String type) {
    switch (type) {
      case 'graduation':
        return 'Certificado de Graduación';
      case 'constancy':
        return 'Constancia de Estudios';
      case 'achievement':
        return 'Certificado de Logro';
      case 'participation':
        return 'Certificado de Participación';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewCertificateDetails(Certificate certificate) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateDetailScreen(
          certificate: certificate,
          isAdminView: true, // Vista de administrador sin funcionalidades
        ),
      ),
    );
    
    // Si se revocó un certificado, recargar la lista
    if (result == true) {
      _loadCertificates();
    }
  }
}
