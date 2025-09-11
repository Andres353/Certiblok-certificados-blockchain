// lib/screens/admin/institution_management_screen.dart
// Pantalla para gestionar instituciones (crear, editar, eliminar)

import 'package:flutter/material.dart';
import '../../models/institution.dart';
import '../../data/sample_institutions.dart';
import '../../services/institution_service.dart';

class InstitutionManagementScreen extends StatefulWidget {
  @override
  _InstitutionManagementScreenState createState() => _InstitutionManagementScreenState();
}

class _InstitutionManagementScreenState extends State<InstitutionManagementScreen> {
  List<Institution> _institutions = [];
  List<Institution> _filteredInstitutions = [];
  String _searchQuery = '';
  InstitutionStatus? _statusFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar instituciones desde Firestore
      _institutions = await InstitutionService.getAllInstitutions();
      _filteredInstitutions = _institutions;
    } catch (e) {
      print('Error loading institutions: $e');
      // Fallback a datos de ejemplo si hay error
      _institutions = SampleInstitutions.allInstitutions;
      _filteredInstitutions = _institutions;
    }
    
    setState(() => _isLoading = false);
  }

  void _filterInstitutions() {
    setState(() {
      _filteredInstitutions = _institutions.where((institution) {
        // Filtro por búsqueda
        bool matchesSearch = _searchQuery.isEmpty ||
            institution.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            institution.shortName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            institution.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Filtro por estado
        bool matchesStatus = _statusFilter == null || institution.status == _statusFilter;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Instituciones'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadInstitutions,
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
                  child: _buildInstitutionsList(isWeb),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInstitution,
        icon: Icon(Icons.add),
        label: Text('Crear Institución'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
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
            onChanged: (value) {
              _searchQuery = value;
              _filterInstitutions();
            },
            decoration: InputDecoration(
              hintText: 'Buscar instituciones...',
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
              children: [
                _buildFilterChip('Todas', null),
                SizedBox(width: 8),
                _buildFilterChip('Activas', InstitutionStatus.active),
                SizedBox(width: 8),
                _buildFilterChip('Inactivas', InstitutionStatus.inactive),
                SizedBox(width: 8),
                _buildFilterChip('Suspendidas', InstitutionStatus.suspended),
                SizedBox(width: 8),
                _buildFilterChip('Pendientes', InstitutionStatus.pending),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, InstitutionStatus? status) {
    final isSelected = _statusFilter == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? status : null;
          _filterInstitutions();
        });
      },
      selectedColor: Color(0xff6C4DDC).withOpacity(0.2),
      checkmarkColor: Color(0xff6C4DDC),
    );
  }

  Widget _buildInstitutionsList(bool isWeb) {
    if (_filteredInstitutions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No se encontraron instituciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Intenta con otros filtros o crea una nueva institución',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return isWeb ? _buildWebGrid() : _buildMobileList();
  }

  Widget _buildWebGrid() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredInstitutions.length,
        itemBuilder: (context, index) {
          final institution = _filteredInstitutions[index];
          return _buildInstitutionCard(institution, true);
        },
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredInstitutions.length,
      itemBuilder: (context, index) {
        final institution = _filteredInstitutions[index];
        return _buildInstitutionCard(institution, false);
      },
    );
  }

  Widget _buildInstitutionCard(Institution institution, bool isWeb) {
    Color statusColor;
    IconData statusIcon;
    
    switch (institution.status) {
      case InstitutionStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case InstitutionStatus.inactive:
        statusColor = Colors.grey;
        statusIcon = Icons.pause_circle;
        break;
      case InstitutionStatus.suspended:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      case InstitutionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewInstitutionDetails(institution),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con logo y estado
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        institution.shortName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          institution.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            SizedBox(width: 4),
                            Text(
                              institution.status.displayName,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleInstitutionAction(value, institution),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 16),
                            SizedBox(width: 8),
                            Text('Ver Detalles'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'suspend',
                        child: Row(
                          children: [
                            Icon(Icons.pause, size: 16),
                            SizedBox(width: 8),
                            Text('Suspender'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Descripción
              Text(
                institution.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12),
              
              // Información adicional
              Row(
                children: [
                  Icon(Icons.school, color: Colors.grey[500], size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${institution.settings.supportedPrograms.length} programas',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.calendar_today, color: Colors.grey[500], size: 16),
                  SizedBox(width: 4),
                  Text(
                    institution.createdAt.toString().split(' ')[0],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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

  void _createInstitution() {
    // TODO: Implementar creación de institución
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Creación de institución en desarrollo')),
    );
  }

  void _viewInstitutionDetails(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(institution.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nombre Corto', institution.shortName),
              _buildDetailRow('Descripción', institution.description),
              _buildDetailRow('Estado', institution.status.displayName),
              _buildDetailRow('Programas', '${institution.settings.supportedPrograms.length}'),
              _buildDetailRow('Creado', institution.createdAt.toString().split(' ')[0]),
              _buildDetailRow('Actualizado', institution.updatedAt.toString().split(' ')[0]),
              SizedBox(height: 16),
              Text(
                'Programas Soportados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...institution.settings.supportedPrograms.map((program) => 
                Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 4),
                  child: Text('• $program'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editInstitution(institution);
            },
            child: Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _handleInstitutionAction(String action, Institution institution) {
    switch (action) {
      case 'view':
        _viewInstitutionDetails(institution);
        break;
      case 'edit':
        _editInstitution(institution);
        break;
      case 'suspend':
        _suspendInstitution(institution);
        break;
      case 'delete':
        _deleteInstitution(institution);
        break;
    }
  }

  void _editInstitution(Institution institution) {
    // TODO: Implementar edición de institución
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edición de institución en desarrollo')),
    );
  }

  void _suspendInstitution(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspender Institución'),
        content: Text('¿Estás seguro de que quieres suspender ${institution.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar suspensión
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Suspensión en desarrollo')),
              );
            },
            child: Text('Suspender', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _deleteInstitution(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Institución'),
        content: Text('¿Estás seguro de que quieres eliminar ${institution.name}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar eliminación
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Eliminación en desarrollo')),
              );
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
