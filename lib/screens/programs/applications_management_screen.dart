// lib/screens/programs/applications_management_screen.dart
// Pantalla para gestionar postulaciones (Admin/Emisor)

import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';
import '../../services/user_context_service.dart';
import 'application_details_screen.dart';

class ApplicationsManagementScreen extends StatefulWidget {
  @override
  _ApplicationsManagementScreenState createState() => _ApplicationsManagementScreenState();
}

class _ApplicationsManagementScreenState extends State<ApplicationsManagementScreen> {
  List<Application> _applications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, under_review, approved, rejected
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    
    try {
      final applications = await ApplicationService.getInstitutionApplications();
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar postulaciones: $e');
    }
  }

  List<Application> get _filteredApplications {
    var filtered = _applications;
    
    // Filtro por estado
    if (_selectedFilter != 'all') {
      filtered = filtered.where((app) => app.status.toString() == _selectedFilter).toList();
    }
    
    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) =>
          app.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.programTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.studentEmail.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Postulaciones'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadApplications,
            icon: Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilters(),
          
          // Estadísticas
          _buildStats(),
          
          // Contenido principal
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredApplications.isEmpty
                    ? _buildEmptyState()
                    : _buildApplicationsList(isWeb),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por estudiante, programa o email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
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
              children: [
                _buildFilterChip('Todas', 'all'),
                SizedBox(width: 8),
                _buildFilterChip('Pendientes', 'pending'),
                SizedBox(width: 8),
                _buildFilterChip('En Revisión', 'under_review'),
                SizedBox(width: 8),
                _buildFilterChip('Aprobadas', 'approved'),
                SizedBox(width: 8),
                _buildFilterChip('Rechazadas', 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Color(0xff6C4DDC).withOpacity(0.2),
      checkmarkColor: Color(0xff6C4DDC),
    );
  }

  Widget _buildStats() {
    final stats = _getStats();
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total', stats['total']!, Colors.blue),
          SizedBox(width: 12),
          _buildStatCard('Pendientes', stats['pending']!, Colors.orange),
          SizedBox(width: 12),
          _buildStatCard('Aprobadas', stats['approved']!, Colors.green),
          SizedBox(width: 12),
          _buildStatCard('Rechazadas', stats['rejected']!, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getStats() {
    int total = _applications.length;
    int pending = _applications.where((app) => app.status == ApplicationStatus.pending).length;
    int approved = _applications.where((app) => app.status == ApplicationStatus.approved).length;
    int rejected = _applications.where((app) => app.status == ApplicationStatus.rejected).length;
    
    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay postulaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No se encontraron postulaciones que coincidan con tu búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(bool isWeb) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredApplications.length,
      itemBuilder: (context, index) => _buildApplicationCard(_filteredApplications[index], isWeb),
    );
  }

  Widget _buildApplicationCard(Application application, bool isWeb) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToApplicationDetails(application),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estudiante y estado
              Row(
                children: [
                  CircleAvatar(
                    radius: isWeb ? 24 : 20,
                    backgroundColor: Color(0xff6C4DDC),
                    child: Text(
                      application.studentName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWeb ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.studentName,
                          style: TextStyle(
                            fontSize: isWeb ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        Text(
                          application.studentEmail,
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse(application.status.color.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      application.status.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Información del programa
              Row(
                children: [
                  Icon(Icons.work, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application.programTitle,
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff2E2F44),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Fechas
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Enviado: ${_formatDate(application.submittedAt)}',
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (application.reviewedAt != null) ...[
                    SizedBox(width: 16),
                    Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'Revisado: ${_formatDate(application.reviewedAt!)}',
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              
              SizedBox(height: 12),
              
              // Acciones rápidas
              if (application.status == ApplicationStatus.pending || 
                  application.status == ApplicationStatus.under_review) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateApplicationStatus(application, ApplicationStatus.approved),
                        icon: Icon(Icons.check, size: 16),
                        label: Text('Aprobar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateApplicationStatus(application, ApplicationStatus.rejected),
                        icon: Icon(Icons.close, size: 16),
                        label: Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToApplicationDetails(Application application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationDetailsScreen(application: application),
      ),
    );
  }

  Future<void> _updateApplicationStatus(Application application, ApplicationStatus newStatus) async {
    try {
      String? notes;
      String? rejectionReason;
      
      if (newStatus == ApplicationStatus.rejected) {
        notes = await _showRejectionReasonDialog();
        if (notes == null) return; // Usuario canceló
        rejectionReason = notes;
      }
      
      await ApplicationService.updateApplicationStatus(
        applicationId: application.id,
        status: newStatus,
        notes: notes,
        rejectionReason: rejectionReason,
      );
      
      _loadApplications();
      _showSuccessSnackBar('Estado actualizado exitosamente');
    } catch (e) {
      _showErrorSnackBar('Error al actualizar estado: $e');
    }
  }

  Future<String?> _showRejectionReasonDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Motivo de Rechazo'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Explica el motivo del rechazo...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
