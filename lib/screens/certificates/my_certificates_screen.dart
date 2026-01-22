// lib/screens/certificates/my_certificates_screen.dart
// Pantalla para gestionar certificados emitidos

import 'package:flutter/material.dart';
import '../../services/adapters/certificate_adapter.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate.dart';
import 'certificate_detail_screen.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({Key? key}) : super(key: key);

  @override
  _MyCertificatesScreenState createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
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

      List<Certificate> certificates;
      
      // Determinar si es emisor o estudiante
      final isEmisor = userContext!.userRole == 'emisor';
      
      if (isEmisor) {
        // Para emisores: obtener solo los certificados emitidos por este emisor
        print('🔍 Cargando certificados emitidos por emisor: ${userContext.userId}');
        final certificatesData = await CertificateAdapter.getCertificatesByEmisor(userContext.userId);
        certificates = certificatesData.map((data) {
          if (data is Certificate) {
            return data;
          } else {
            return Certificate.fromSupabase(Map<String, dynamic>.from(data));
          }
        }).toList();
        print('📋 Certificados encontrados emitidos por este emisor: ${certificates.length}');
      } else {
        // Para estudiantes: obtener solo sus certificados
        print('🔍 Cargando certificados para estudiante: ${userContext.userId}');
        final certificatesData = await CertificateAdapter.getCertificates(
          studentId: userContext.userId,
        );
        certificates = certificatesData.map((data) {
          if (data is Certificate) {
            return data;
          } else {
            return Certificate.fromSupabase(Map<String, dynamic>.from(data));
          }
        }).toList();
        print('📋 Certificados encontrados para estudiante: ${certificates.length}');
      }

      setState(() {
        _certificates = certificates;
        _isLoading = false;
      });
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          UserContextService.currentContext?.userRole == 'emisor' 
            ? 'Certificados Emitidos' 
            : 'Mis Certificados'
        ),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCertificates,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros y búsqueda
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isMobile 
                        ? 'Buscar certificado...' 
                        : 'Buscar por título o tipo de certificado...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                SizedBox(height: isMobile ? 10 : 12),
                
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: isMobile ? 6 : 8),
                        child: FilterChip(
                          label: Text(
                            filter['label']!,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                          selected: _selectedFilter == filter['value'],
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter['value']!;
                            });
                          },
                          selectedColor: Color(0xff6C4DDC).withOpacity(0.2),
                          checkmarkColor: Color(0xff6C4DDC),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 4 : 8,
                          ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: isMobile ? 60 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              'No hay certificados',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron certificados con la búsqueda "$_searchQuery"'
                  : 'No tienes certificados emitidos aún.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[500],
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              SizedBox(height: isMobile ? 16 : 24),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 24,
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
                child: Text(
                  'Limpiar búsqueda',
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
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
        // Calcular número de columnas y aspect ratio según el ancho disponible
        int crossAxisCount;
        double childAspectRatio;
        final availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < 600;
        
        // Ajustar aspect ratio según el tamaño de pantalla
        if (availableWidth > 1400) {
          crossAxisCount = 4;
          childAspectRatio = 1.5;
        } else if (availableWidth > 1000) {
          crossAxisCount = 3;
          childAspectRatio = 1.5;
        } else if (availableWidth > 700) {
          crossAxisCount = 2;
          childAspectRatio = 1.4;
        } else {
          crossAxisCount = 1; // Móvil: 1 columna
          childAspectRatio = 1.2; // Más alto en móvil para que quepa todo el contenido
        }
        
        return GridView.builder(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: isMobile ? 8 : 12,
            mainAxisSpacing: isMobile ? 8 : 12,
          ),
          itemCount: _filteredCertificates.length,
          itemBuilder: (context, index) {
            final certificate = _filteredCertificates[index];
            return _buildCertificateCard(certificate, isMobile);
          },
        );
      },
    );
  }

  Widget _buildCertificateCard(Certificate certificate, bool isMobile) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: InkWell(
          onTap: () => _viewCertificate(certificate),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título del certificado
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 8 : 10,
                    horizontal: isMobile ? 8 : 12,
                  ),
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
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                SizedBox(height: isMobile ? 8 : 12),
                
                // Información en badges
                Row(
                  children: [
                    // Estado
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 4 : 6,
                        ),
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
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: isMobile ? 4 : 6),
                    
                    // Tipo de certificado
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 4 : 6,
                        ),
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
                            fontSize: isMobile ? 10 : 11,
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
                
                SizedBox(height: isMobile ? 6 : 12),
                
                // Información de institución y fecha combinadas en móvil
                if (isMobile)
                  // En móvil: combinar institución y fecha en una sola fila
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school, size: 12, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  certificate.institutionName,
                                  style: TextStyle(
                                    fontSize: 10,
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
                      ),
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              _formatDate(certificate.issuedAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // En desktop/tablet: mostrar separado
                  Column(
                    children: [
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
                      SizedBox(height: 8),
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
                    ],
                  ),
                
                SizedBox(height: isMobile ? 8 : 12),
                
                // Botón de acción principal
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewCertificate(certificate),
                    icon: Icon(Icons.visibility, size: isMobile ? 12 : 14),
                    label: Text(
                      'Ver Información',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
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

  void _viewCertificate(Certificate certificate) async {
    final userContext = UserContextService.currentContext;
    final isEmisor = userContext?.userRole == 'emisor';
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateDetailScreen(
          certificate: certificate,
          isAdminView: isEmisor, // Emisores pueden revocar certificados
        ),
      ),
    );
    
    // Si se revocó un certificado, recargar la lista
    if (result == true) {
      _loadCertificates();
    }
  }

  // Los estudiantes NO pueden revocar certificados
  // Esta funcionalidad está disponible solo para administradores y emisores

}


