import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/institution_request_service.dart';
import '../../widgets/institution_header.dart';

class InstitutionRequestsScreen extends StatefulWidget {
  const InstitutionRequestsScreen({super.key});

  @override
  State<InstitutionRequestsScreen> createState() => _InstitutionRequestsScreenState();
}

class _InstitutionRequestsScreenState extends State<InstitutionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<InstitutionRequest> _requests = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await InstitutionRequestService.getAllRequests();
      final stats = await InstitutionRequestService.getRequestStats();
      
      setState(() {
        _requests = requests;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  List<InstitutionRequest> get _filteredRequests {
    var filtered = _requests;

    // Filtrar por estado
    if (_selectedStatus != 'all') {
      filtered = filtered.where((r) => r.status == _selectedStatus).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) =>
          r.institutionName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.contactName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.contactEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.city.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Instituciones'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list, size: 18),
                  const SizedBox(width: 4),
                  Text('Todas (${_stats['total'] ?? 0})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending, size: 18),
                  const SizedBox(width: 4),
                  Text('Pendientes (${_stats['pending'] ?? 0})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 4),
                  Text('Aprobadas (${_stats['approved'] ?? 0})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel, size: 18),
                  const SizedBox(width: 4),
                  Text('Rechazadas (${_stats['rejected'] ?? 0})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header de la institución
          const InstitutionHeader(),
          
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, contacto, email o ciudad...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                
                // Filtros
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por estado',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
                          DropdownMenuItem(value: 'approved', child: Text('Aprobadas')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rechazadas')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestsList(_filteredRequests),
                          _buildRequestsList(_filteredRequests.where((r) => r.status == 'pending').toList()),
                          _buildRequestsList(_filteredRequests.where((r) => r.status == 'approved').toList()),
                          _buildRequestsList(_filteredRequests.where((r) => r.status == 'rejected').toList()),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay solicitudes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron solicitudes con los filtros aplicados',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<InstitutionRequest> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: request.getStatusColor().withOpacity(0.1),
              child: Icon(
                _getInstitutionIcon(request.institutionType),
                color: request.getStatusColor(),
              ),
            ),
            title: Text(
              request.institutionName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${request.getInstitutionTypeLabel()} • ${request.city}, ${request.country}'),
                Text('Contacto: ${request.contactName} (${request.contactEmail})'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: request.getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.getStatusLabel(),
                        style: TextStyle(
                          color: request.getStatusColor(),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Solicitado: ${_formatDate(request.requestedAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (request.status == 'pending') ...[
                  IconButton(
                    onPressed: () => _showRequestDetails(request),
                    icon: const Icon(Icons.visibility),
                    tooltip: 'Ver detalles',
                  ),
                  IconButton(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Aprobar',
                  ),
                  IconButton(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Rechazar',
                  ),
                ] else ...[
                  IconButton(
                    onPressed: () => _showRequestDetails(request),
                    icon: const Icon(Icons.visibility),
                    tooltip: 'Ver detalles',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getInstitutionIcon(String type) {
    switch (type) {
      case 'university': return Icons.school;
      case 'college': return Icons.account_balance;
      case 'school': return Icons.school_outlined;
      case 'institute': return Icons.science;
      case 'academy': return Icons.auto_stories;
      default: return Icons.business;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRequestDetails(InstitutionRequest request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo de la institución
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: request.logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                request.logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getInstitutionIcon(request.institutionType),
                                    size: 40,
                                    color: Color(0xff6C4DDC),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              _getInstitutionIcon(request.institutionType),
                              size: 40,
                              color: Color(0xff6C4DDC),
                            ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      request.institutionName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      request.shortName,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: request.getStatusColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: request.getStatusColor(),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        request.getStatusLabel(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido del modal
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información básica
                      _buildSectionTitle('Información Básica'),
                      SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem('Tipo de Institución', request.getInstitutionTypeLabel(), Icons.business),
                        _buildDetailItem('Descripción', request.description, Icons.description),
                        _buildDetailItem('Sitio Web', request.website.isNotEmpty ? request.website : 'No especificado', Icons.language),
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // Información de contacto
                      _buildSectionTitle('Información de Contacto'),
                      SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem('Nombre del Contacto', request.contactName, Icons.person),
                        _buildDetailItem('Email', request.contactEmail, Icons.email),
                        _buildDetailItem('Teléfono', request.contactPhone, Icons.phone),
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // Ubicación
                      _buildSectionTitle('Ubicación'),
                      SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem('Dirección', request.address, Icons.location_on),
                        _buildDetailItem('Ciudad', '${request.city}, ${request.country}', Icons.place),
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // Información de la solicitud
                      _buildSectionTitle('Información de la Solicitud'),
                      SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem('Fecha de Solicitud', _formatDate(request.requestedAt), Icons.schedule),
                        if (request.reviewedBy != null)
                          _buildDetailItem('Revisado por', request.reviewedBy!, Icons.admin_panel_settings),
                        if (request.reviewedAt != null)
                          _buildDetailItem('Fecha de Revisión', _formatDate(request.reviewedAt!), Icons.check_circle),
                        if (request.rejectionReason != null)
                          _buildDetailItem('Motivo de Rechazo', request.rejectionReason!, Icons.cancel, Colors.red),
                      ]),
                    ],
                  ),
                ),
              ),
              
              // Botones de acción
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    if (request.status == 'pending') ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _rejectRequest(request);
                        },
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Rechazar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _approveRequest(request);
                        },
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Aprobar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xff2E2F44),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, [Color? valueColor]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xff6C4DDC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Color(0xff6C4DDC),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _approveRequest(InstitutionRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Solicitud'),
        content: Text(
          '¿Estás seguro de que deseas aprobar la solicitud de "${request.institutionName}"?\n\n'
          'Esto creará la institución y enviará las credenciales de acceso al contacto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processApproval(request);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(InstitutionRequest request) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro de que deseas rechazar la solicitud de "${request.institutionName}"?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo *',
                hintText: 'Explique por qué se rechaza la solicitud',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe proporcionar un motivo para el rechazo')),
                );
                return;
              }
              
              Navigator.of(context).pop();
              await _processRejection(request, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproval(InstitutionRequest request) async {
    try {
      // Obtener el ID del usuario actual de Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      final superAdminId = currentUser?.uid ?? 'super_admin_system';
      
      print('Super Admin ID: $superAdminId');
      
      final success = await InstitutionRequestService.approveRequest(
        request.id,
        superAdminId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud de "${request.institutionName}" aprobada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al aprobar la solicitud'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processRejection(InstitutionRequest request, String reason) async {
    try {
      // Obtener el ID del usuario actual de Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      final superAdminId = currentUser?.uid ?? 'super_admin_system';
      
      print('Super Admin ID: $superAdminId');
      
      final success = await InstitutionRequestService.rejectRequest(
        request.id,
        superAdminId,
        reason,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud de "${request.institutionName}" rechazada'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al rechazar la solicitud'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
