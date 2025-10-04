// lib/screens/certificates/my_certificates_screen.dart
// Pantalla para gestionar certificados emitidos

import 'package:flutter/material.dart';
import '../../services/certificate_service.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';
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

      // Obtener certificados del estudiante actual
      final certificates = await CertificateService.getCertificates(
        studentId: userContext!.userId,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      setState(() {
        _certificates = certificates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AlertService.showError(context, 'Error', 'Error cargando certificados: $e');
    }
  }

  List<Certificate> get _filteredCertificates {
    var filtered = _certificates;
    
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
        title: Text('Mis Certificados'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCertificates,
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
                            _loadCertificates();
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
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredCertificates.length,
      itemBuilder: (context, index) {
        final certificate = _filteredCertificates[index];
        return _buildCertificateCard(certificate);
      },
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewCertificate(certificate),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      certificate.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E2F44),
                      ),
                    ),
                  ),
                  _buildStatusChip(certificate.status),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Descripción del certificado
              if (certificate.description.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certificate.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              
              if (certificate.description.isNotEmpty)
                SizedBox(height: 4),
              
              // Tipo de certificado
              Row(
                children: [
                  Icon(Icons.workspace_premium, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    _getCertificateTypeLabel(certificate.certificateType),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4),
              
              // Fecha de emisión
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Emitido: ${_formatDate(certificate.issuedAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Acciones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewCertificate(certificate),
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text('Ver'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xff6C4DDC),
                        side: BorderSide(color: Color(0xff6C4DDC)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  if (certificate.status == 'active')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareCertificate(certificate),
                        icon: Icon(Icons.share, size: 16),
                        label: Text('Compartir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Activo';
        break;
      case 'revoked':
        color = Colors.red;
        label = 'Revocado';
        break;
      case 'expired':
        color = Colors.orange;
        label = 'Expirado';
        break;
      default:
        color = Colors.grey;
        label = 'Desconocido';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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

  void _viewCertificate(Certificate certificate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateDetailScreen(certificate: certificate),
      ),
    );
  }

  void _shareCertificate(Certificate certificate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Compartir Certificado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Título: ${certificate.title}'),
            Text('Tipo: ${_getCertificateTypeLabel(certificate.certificateType)}'),
            SizedBox(height: 16),
            Text('Opciones de compartir:'),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.qr_code),
              title: Text('Código QR'),
              subtitle: Text('Generar código QR para compartir'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Código QR');
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Enlace Público'),
              subtitle: Text('Generar enlace para compartir'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Enlace Público');
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Descargar PDF'),
              subtitle: Text('Descargar como archivo PDF'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Descargar PDF');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    AlertService.showInfo(context, 'Próximamente', '$feature estará disponible próximamente');
  }
}
