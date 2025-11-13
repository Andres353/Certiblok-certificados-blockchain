// lib/screens/admin/institution_management_screen.dart
// Pantalla para gestionar instituciones (crear, editar, eliminar)

import 'package:flutter/material.dart';
import '../../models/institution.dart';
import '../../data/sample_institutions.dart';
import '../../services/adapters/institution_adapter.dart';

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
      _institutions = await InstitutionAdapter.getAllInstitutions();
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular número de columnas basado en el ancho disponible
          int crossAxisCount = 4;
          if (constraints.maxWidth < 1400) {
            crossAxisCount = 3;
          }
          if (constraints.maxWidth < 1000) {
            crossAxisCount = 2;
          }
          if (constraints.maxWidth < 600) {
            crossAxisCount = 1;
          }
          
          return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 3.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredInstitutions.length,
        itemBuilder: (context, index) {
          final institution = _filteredInstitutions[index];
          return _buildInstitutionCard(institution, true);
            },
          );
        },
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: EdgeInsets.all(20),
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

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _viewInstitutionDetails(institution),
          borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con logo y estado
              Row(
                children: [
                  Container(
                        width: 32,
                        height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))).withOpacity(0.2),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                    ),
                    child: institution.logoUrl.isNotEmpty
                        ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              institution.logoUrl,
                                  width: 32,
                                  height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    institution.shortName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              institution.shortName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                    fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                      SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          institution.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                                color: Color(0xff2E2F44),
                          ),
                              maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                            SizedBox(height: 3),
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
                              institution.status.displayName,
                              style: TextStyle(
                                color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                              ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleInstitutionAction(value, institution),
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                        ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                                Icon(Icons.visibility, size: 18, color: Color(0xff6C4DDC)),
                                SizedBox(width: 12),
                            Text('Ver Detalles'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                                Icon(Icons.edit, size: 18, color: Colors.blue),
                                SizedBox(width: 12),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'suspend',
                        child: Row(
                          children: [
                                Icon(Icons.pause, size: 18, color: Colors.orange),
                                SizedBox(width: 12),
                            Text('Suspender'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 12),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
                  Spacer(),
                  
                  // Información adicional pegada abajo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                      _buildInfoChip(
                        Icons.school,
                    '${institution.settings.supportedPrograms.length} programas',
                        Color(0xff6C4DDC),
                      ),
                      _buildInfoChip(
                        Icons.calendar_today,
                    institution.createdAt.toString().split(' ')[0],
                        Colors.grey[600]!,
                    ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xff6C4DDC).withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con logo y título
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
                      Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
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
                      child: institution.logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                institution.logoUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      institution.shortName,
                                      style: TextStyle(
                                        color: Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                institution.shortName,
                                style: TextStyle(
                                  color: Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
              Text(
                            institution.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
              ),
              SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(institution.status),
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  institution.status.displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
              
              // Contenido del modal
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildInfoSection(
                      'Información General',
                      Icons.info_outline,
                      [
                        _buildInfoItem('Nombre Corto', institution.shortName),
                        _buildInfoItem('Código', institution.institutionCode),
                        _buildInfoItem('Programas', '${institution.settings.supportedPrograms.length} programas'),
                        _buildInfoItem('Creado', institution.createdAt.toString().split(' ')[0]),
                        _buildInfoItem('Actualizado', institution.updatedAt.toString().split(' ')[0]),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Descripción
                    _buildInfoSection(
                      'Descripción',
                      Icons.description,
                      [
                        _buildInfoItem('', institution.description, isDescription: true),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Programas soportados
                    if (institution.settings.supportedPrograms.isNotEmpty)
                      _buildInfoSection(
                        'Programas Soportados',
                        Icons.school,
                        institution.settings.supportedPrograms.map((program) => 
                          _buildInfoItem('', '• $program', isProgram: true),
                        ).toList(),
                      ),
                  ],
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
            onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editInstitution(institution);
            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Editar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(InstitutionStatus status) {
    switch (status) {
      case InstitutionStatus.active:
        return Icons.check_circle;
      case InstitutionStatus.inactive:
        return Icons.pause_circle;
      case InstitutionStatus.suspended:
        return Icons.block;
      case InstitutionStatus.pending:
        return Icons.schedule;
    }
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xff6C4DDC), size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isDescription = false, bool isProgram = false}) {
    if (isDescription) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    }
    
    if (isProgram) {
      return Padding(
        padding: EdgeInsets.only(left: 16, bottom: 4),
        child: Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
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
