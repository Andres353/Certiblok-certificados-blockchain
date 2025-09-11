// lib/screens/admin/super_admin_dashboard.dart
// Dashboard para Super Administradores del sistema multi-tenant

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/institution_service.dart';
import '../../models/institution.dart';
import 'institution_management_screen.dart';
import 'institution_requests_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  List<Institution> _institutions = [];
  bool _isLoading = true;
  Map<String, int> _stats = {};
  StreamSubscription? _institutionsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _institutionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar SOLO las instituciones reales de Firebase
      final allInstitutions = await InstitutionService.getAllInstitutions();
      
      print('🔍 Cargando instituciones desde Firebase:');
      print('   - Total encontradas: ${allInstitutions.length}');
      
      _institutions = allInstitutions;
      
      // Calcular estadísticas reales
      int total = allInstitutions.length;
      int active = 0;
      int inactive = 0;
      int suspended = 0;
      int pending = 0;

      for (var institution in allInstitutions) {
        switch (institution.status) {
          case InstitutionStatus.active:
            active++;
            break;
          case InstitutionStatus.inactive:
            inactive++;
            break;
          case InstitutionStatus.suspended:
            suspended++;
            break;
          case InstitutionStatus.pending:
            pending++;
            break;
        }
      }

      _stats = {
        'total': total,
        'active': active,
        'inactive': inactive,
        'suspended': suspended,
        'pending': pending,
      };
      
      print('✅ Datos reales cargados:');
      print('   - Instituciones: ${_institutions.length}');
      print('   - Estadísticas: $_stats');
      
    } catch (e) {
      print('❌ Error cargando datos: $e');
      // Mostrar estado vacío si hay error
      _institutions = [];
      _stats = {'total': 0, 'active': 0, 'inactive': 0, 'suspended': 0, 'pending': 0};
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _forceRefresh() async {
    print('🔄 Forzando actualización completa...');
    
    // Cancelar suscripción actual
    _institutionsSubscription?.cancel();
    
    // Limpiar datos actuales
    setState(() {
      _institutions = [];
      _stats = {'total': 0, 'active': 0, 'inactive': 0, 'suspended': 0, 'pending': 0};
      _isLoading = true;
    });
    
    // Cargar datos frescos
    await _loadData();
    
    // Reconfigurar suscripción
    _setupRealtimeUpdates();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Datos actualizados desde Firebase'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _setupRealtimeUpdates() {
    // Escuchar cambios en tiempo real en la colección de instituciones
    _institutionsSubscription = FirebaseFirestore.instance
        .collection('institutions')
        .snapshots()
        .listen((snapshot) {
      print('🔄 Actualización detectada en Firebase');
      print('   - Documentos encontrados: ${snapshot.docs.length}');
      
      final institutions = snapshot.docs
          .map((doc) {
            print('   - Procesando documento: ${doc.id}');
            print('   - Datos: ${doc.data()}');
            return Institution.fromFirestore(doc.data(), doc.id);
          })
          .toList();
      
      print('📋 Instituciones procesadas:');
      for (var inst in institutions) {
        print('   - ${inst.name} (${inst.status.name}) - Programas: ${inst.settings.supportedPrograms.length}');
      }
      
      // Calcular estadísticas reales
      int total = institutions.length;
      int active = 0;
      int inactive = 0;
      int suspended = 0;
      int pending = 0;

      for (var institution in institutions) {
        switch (institution.status) {
          case InstitutionStatus.active:
            active++;
            break;
          case InstitutionStatus.inactive:
            inactive++;
            break;
          case InstitutionStatus.suspended:
            suspended++;
            break;
          case InstitutionStatus.pending:
            pending++;
            break;
        }
      }

      final stats = {
        'total': total,
        'active': active,
        'inactive': inactive,
        'suspended': suspended,
        'pending': pending,
      };

      print('📊 Datos actualizados desde Firebase:');
      print('   - Instituciones: ${institutions.length}');
      print('   - Estadísticas: $stats');

      if (mounted) {
        setState(() {
          _institutions = institutions;
          _stats = stats;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('❌ Error en actualización: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Super Admin - Dashboard'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _forceRefresh();
            },
            icon: Icon(Icons.refresh),
            tooltip: 'Forzar Actualización',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildWebLayout();
                } else {
                  return _buildMobileLayout();
                }
              },
            ),
    );
  }

  Widget _buildWebLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar con estadísticas
          Container(
            width: 300,
            child: Column(
              children: [
                _buildStatsCard(),
                SizedBox(height: 20),
                _buildQuickActionsCard(),
              ],
            ),
          ),
          SizedBox(width: 24),
          // Contenido principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 24),
                _buildInstitutionsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildStatsCard(),
          SizedBox(height: 20),
          _buildQuickActionsCard(),
          SizedBox(height: 20),
          _buildInstitutionsList(),
        ],
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
            'Panel de Super Administración',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gestiona todas las instituciones del sistema',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas del Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            _buildStatItem('Total Instituciones', _stats['total'] ?? 0, Icons.school, Colors.blue),
            _buildStatItem('Activas', _stats['active'] ?? 0, Icons.check_circle, Colors.green),
            _buildStatItem('Inactivas', _stats['inactive'] ?? 0, Icons.pause_circle, Colors.grey),
            _buildStatItem('Suspendidas', _stats['suspended'] ?? 0, Icons.block, Colors.red),
            _buildStatItem('Pendientes', _stats['pending'] ?? 0, Icons.schedule, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Spacer(),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: Text(
              value.toString(),
              key: ValueKey(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            _buildActionButton(
              'Solicitudes de Instituciones',
              Icons.pending_actions,
              Colors.orange,
              () => _navigateToInstitutionRequests(),
            ),
            _buildActionButton(
              'Gestionar Instituciones',
              Icons.business,
              Colors.blue,
              () => _navigateToInstitutionManagement(),
            ),
            _buildActionButton(
              'Ver Analytics',
              Icons.analytics,
              Colors.purple,
              () => _showAnalytics(),
            ),
            _buildActionButton(
              'Configuración Sistema',
              Icons.settings,
              Colors.grey,
              () => _showSystemSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff2E2F44),
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionsList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Instituciones Registradas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
                Spacer(),
                Text(
                  '${_institutions.length} instituciones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _institutions.isEmpty
                ? Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No hay instituciones en Firebase',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Las instituciones aparecerán aquí cuando sean aprobadas desde las solicitudes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _navigateToInstitutionRequests,
                            icon: Icon(Icons.pending_actions),
                            label: Text('Ver Solicitudes Pendientes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 400, // Limitar altura máxima
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _institutions.length,
                      itemBuilder: (context, index) {
                        final institution = _institutions[index];
                        return _buildInstitutionCard(institution);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionCard(Institution institution) {
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
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
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
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          institution.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              institution.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
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
                SizedBox(width: 16),
                Icon(Icons.school, color: Colors.grey[500], size: 16),
                SizedBox(width: 4),
                Text(
                  '${institution.settings.supportedPrograms.length} programas',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
        onTap: () => _viewInstitutionDetails(institution),
      ),
    );
  }

  void _navigateToInstitutionRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionRequestsScreen(),
      ),
    );
  }

  void _navigateToInstitutionManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionManagementScreen(),
      ),
    );
  }

  void _showAnalytics() {
    // TODO: Implementar analytics
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Analytics en desarrollo')),
    );
  }

  void _showSystemSettings() {
    // TODO: Implementar configuración del sistema
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configuración del sistema en desarrollo')),
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

  void _viewInstitutionDetails(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(institution.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción: ${institution.description}'),
            SizedBox(height: 8),
            Text('Programas: ${institution.settings.supportedPrograms.length}'),
            SizedBox(height: 8),
            Text('Estado: ${institution.status.displayName}'),
            SizedBox(height: 8),
            Text('Creado: ${institution.createdAt.toString().split(' ')[0]}'),
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

  void _editInstitution(Institution institution) {
    // TODO: Implementar edición de institución
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edición de institución en desarrollo')),
    );
  }

  void _suspendInstitution(Institution institution) {
    // TODO: Implementar suspensión de institución
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Suspensión de institución en desarrollo')),
    );
  }

  void _deleteInstitution(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Institución'),
        content: Text('¿Estás seguro de que quieres eliminar ${institution.name}?'),
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
