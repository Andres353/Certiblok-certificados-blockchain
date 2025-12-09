// lib/screens/admin/super_admin_dashboard.dart
// Dashboard para Super Administradores del sistema multi-tenant

import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/adapters/institution_adapter.dart';
import '../../services/adapters/institution_request_adapter.dart';
import '../../services/adapters/auth_adapter.dart';
import '../../services/alert_service.dart';
import '../../models/institution.dart';
import 'institution_management_screen.dart';
import 'institution_requests_screen.dart';
import 'page_editor_screen.dart';
import 'reports_screen.dart';
import 'blockchain_wallet_setup_screen.dart';

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
      // Cargar instituciones desde Supabase
      final allInstitutions = await InstitutionAdapter.getAllInstitutions();
      
      print('🔍 Cargando instituciones desde Supabase:');
      print('   - Total encontradas: ${allInstitutions.length}');
      
      _institutions = allInstitutions;
      
      // Calcular estadísticas reales de instituciones
      int total = allInstitutions.length;
      int active = 0;
      int inactive = 0;
      int suspended = 0;

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
            // Las instituciones pendientes no se cuentan aquí
            break;
        }
      }

      // Cargar estadísticas de solicitudes pendientes
      int pendingRequests = 0;
      try {
        final requestStats = await InstitutionRequestAdapter.getRequestStats();
        pendingRequests = requestStats['pending'] ?? 0;
        print('📋 Solicitudes pendientes: $pendingRequests');
      } catch (e) {
        print('⚠️ Error cargando estadísticas de solicitudes: $e');
      }

      _stats = {
        'total': total,
        'active': active,
        'inactive': inactive,
        'suspended': suspended,
        'pending': pendingRequests, // Usar solicitudes pendientes en lugar de instituciones pendientes
      };
      
      print('✅ Datos reales cargados:');
      print('   - Instituciones: ${_institutions.length}');
      print('   - Solicitudes pendientes: $pendingRequests');
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
    
    AlertService.showSuccess(context, 'Éxito', 'Datos actualizados desde Supabase');
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Cerrar sesión y esperar a que se limpie
      await AuthAdapter.logout();
      // Esperar un momento para asegurar que la sesión se limpie completamente
      await Future.delayed(Duration(milliseconds: 300));
      // Verificar que la sesión esté realmente limpia
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null && mounted) {
        // Recargar la página para que _getInitialRoute() se ejecute con estado limpio
        html.window.location.reload();
      }
    }
  }

  void _setupRealtimeUpdates() {
    // Cargar instituciones desde Supabase
    _loadInstitutionsFromSupabase();
  }

  Future<void> _loadInstitutionsFromSupabase() async {
    try {
      print('🔄 Cargando instituciones desde Supabase...');
      
      // Cargar instituciones usando InstitutionAdapter
      final institutions = await InstitutionAdapter.getAllInstitutions();
      
      print('📋 Instituciones procesadas:');
      for (var inst in institutions) {
        print('   - ${inst.name} (${inst.status.name}) - Programas: ${inst.settings.supportedPrograms.length}');
      }
      
      // Calcular estadísticas reales de instituciones
      int total = institutions.length;
      int active = 0;
      int inactive = 0;
      int suspended = 0;

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
            // Las instituciones pendientes no se cuentan aquí
            break;
        }
      }

      // Cargar estadísticas de solicitudes pendientes
      int pendingRequests = 0;
      try {
        final requestStats = await InstitutionRequestAdapter.getRequestStats();
        pendingRequests = requestStats['pending'] ?? 0;
        print('📋 Solicitudes pendientes: $pendingRequests');
      } catch (e) {
        print('⚠️ Error cargando estadísticas de solicitudes: $e');
      }

      final stats = {
        'total': total,
        'active': active,
        'inactive': inactive,
        'suspended': suspended,
        'pending': pendingRequests, // Usar solicitudes pendientes
      };

      print('📊 Datos actualizados desde Supabase:');
      print('   - Instituciones: ${institutions.length}');
      print('   - Solicitudes pendientes: $pendingRequests');
      print('   - Estadísticas: $stats');

      if (mounted) {
        setState(() {
          _institutions = institutions;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando instituciones desde Supabase: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
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
            
            // Estadísticas de Instituciones
            Text(
              'Instituciones',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff6C4DDC),
              ),
            ),
            SizedBox(height: 8),
            _buildStatItem('Total Instituciones', _stats['total'] ?? 0, Icons.school, Colors.blue),
            _buildStatItem('Activas', _stats['active'] ?? 0, Icons.check_circle, Colors.green),
            _buildStatItem('Inactivas', _stats['inactive'] ?? 0, Icons.pause_circle, Colors.grey),
            _buildStatItem('Suspendidas', _stats['suspended'] ?? 0, Icons.block, Colors.red),
            _buildStatItem('Solicitudes Pendientes', _stats['pending'] ?? 0, Icons.schedule, Colors.orange),
            
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
              'Ver Reportes',
              Icons.analytics,
              Colors.purple,
              () => _navigateToReports(),
            ),
            _buildActionButton(
              'Editar Información de Página',
              Icons.edit,
              Colors.green,
              () => _navigateToPageEditor(),
            ),
            _buildActionButton(
              'Wallet Blockchain',
              Icons.account_balance_wallet,
              Color(0xff6C4DDC),
              () => _navigateToBlockchainWallet(),
            ),
          ],
        ),
      ),
    );
  }


  Color _getStatusColor(InstitutionStatus status) {
    switch (status) {
      case InstitutionStatus.active:
        return Colors.green;
      case InstitutionStatus.inactive:
        return Colors.grey;
      case InstitutionStatus.suspended:
        return Colors.red;
      case InstitutionStatus.pending:
        return Colors.orange;
    }
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
                            'No hay instituciones registradas',
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
          child: institution.logoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    institution.logoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          institution.shortName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
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
            if (institution.status != InstitutionStatus.suspended)
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
            if (institution.status == InstitutionStatus.suspended)
              PopupMenuItem(
                value: 'reactivate',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Reactivar', style: TextStyle(color: Colors.green)),
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

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsScreen(),
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
      case 'reactivate':
        _reactivateInstitution(institution);
        break;
      case 'delete':
        _deleteInstitution(institution);
        break;
    }
  }

  void _viewInstitutionDetails(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
          children: [
              // Header con gradiente
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
                      Color(int.parse(institution.colors.secondary.replaceAll('#', '0xFF'))),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo y nombre
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: institution.logoUrl.isNotEmpty
                  ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        institution.logoUrl,
                                    width: 56,
                                    height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              institution.shortName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                institution.shortName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                institution.institutionCode,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontFamily: 'monospace',
              ),
            ),
          ],
        ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Estado con badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(institution.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(institution.status).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
          mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(institution.status),
                            color: _getStatusColor(institution.status),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            institution.status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(institution.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido principal con scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      // Información de la institución
                      _buildInfoSection(
                        'Información de la Institución',
                        Icons.school,
                        [
                          _buildInfoRow('Nombre Completo', institution.name),
                          _buildInfoRow('Nombre Corto', institution.shortName),
                          _buildInfoRow('Código', institution.institutionCode),
                          _buildInfoRow('Descripción', institution.description.isNotEmpty 
                              ? institution.description 
                              : 'Sin descripción'),
                          _buildInfoRow('Estado Actual', institution.status.displayName),
                          _buildInfoRow('Fecha de Creación', _formatDate(institution.createdAt)),
                          _buildInfoRow('Última Actualización', _formatDate(institution.updatedAt)),
                          _buildInfoRow('Creado por', institution.createdBy.isNotEmpty 
                              ? institution.createdBy 
                              : 'Sistema'),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Estadísticas de la institución
                      _buildInfoSection(
                        'Estadísticas',
                        Icons.analytics,
                        [
                          _buildInfoRow('Programas Soportados', '${institution.settings.supportedPrograms.length} programas'),
                          _buildInfoRow('Registro de Estudiantes', 
                              institution.settings.allowStudentRegistration ? 'Habilitado' : 'Deshabilitado'),
                          _buildInfoRow('Verificación de Email', 
                              institution.settings.requireEmailVerification ? 'Requerida' : 'No requerida'),
                          _buildInfoRow('Verificación Pública', 
                              institution.settings.allowPublicVerification ? 'Habilitada' : 'Deshabilitada'),
                          _buildInfoRow('Blockchain', 
                              institution.settings.enableBlockchain ? 'Habilitado' : 'Deshabilitado'),
                          _buildInfoRow('Idioma', institution.settings.defaultLanguage.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botones de acción
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
                    ),
                    Row(
                      children: [
                        if (institution.status != InstitutionStatus.suspended)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _suspendInstitution(institution);
                            },
                            icon: Icon(Icons.pause, size: 16),
                            label: Text('Suspender'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        if (institution.status == InstitutionStatus.suspended) ...[
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _reactivateInstitution(institution);
                            },
                            icon: Icon(Icons.check_circle, size: 16),
                            label: Text('Reactivar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ],
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

  // Función auxiliar para construir secciones de información
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // Función auxiliar para construir filas de información
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
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


  // Función auxiliar para obtener el icono del estado
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

  // Función auxiliar para formatear fechas
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _editInstitution(Institution institution) {
    // TODO: Implementar edición de institución
    AlertService.showInfo(context, 'Info', 'Edición de institución en desarrollo');
  }

  void _suspendInstitution(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Suspender Institución'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres suspender esta institución?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consecuencias de la suspensión:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Todos los usuarios de esta institución no podrán acceder al sistema\n'
                    '• Los administradores, emisores y estudiantes verán un mensaje informativo\n'
                    '• Los certificados existentes seguirán siendo válidos\n'
                    '• La institución podrá ser reactivada posteriormente',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmSuspendInstitution(institution);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Suspender'),
          ),
        ],
      ),
    );
  }

  void _confirmSuspendInstitution(Institution institution) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Actualizar el estado de la institución a suspendida
      final updatedInstitution = institution.copyWith(
        status: InstitutionStatus.suspended,
        updatedAt: DateTime.now(),
      );

      print('🔄 Actualizando institución ${institution.name} a estado suspendida...');
      print('   - ID: ${institution.id}');
      print('   - Estado anterior: ${institution.status}');
      print('   - Estado nuevo: ${updatedInstitution.status}');

      // Actualizar en la base de datos
      final success = await InstitutionAdapter.updateInstitution(institution.id, updatedInstitution);
      
      if (!success) {
        throw Exception('No se pudo actualizar el estado de la institución');
      }
      
      print('✅ Institución ${institution.name} suspendida exitosamente en la base de datos');

      // Cerrar el diálogo de carga
      Navigator.pop(context);

      // Actualizar la lista local y recalcular estadísticas
      setState(() {
        final index = _institutions.indexWhere((inst) => inst.id == institution.id);
        if (index != -1) {
          _institutions[index] = updatedInstitution;
        }
      });
      
      // Recalcular estadísticas (incluyendo solicitudes pendientes)
      await _recalculateStats();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Institución ${institution.name} suspendida exitosamente'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      Navigator.pop(context);
      
      print('❌ Error al suspender institución: $e');
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al suspender institución: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reactivateInstitution(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Reactivar Institución'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres reactivar esta institución?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consecuencias de la reactivación:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Todos los usuarios de esta institución podrán acceder al sistema nuevamente\n'
                    '• Los administradores, emisores y estudiantes podrán usar sus dashboards normales\n'
                    '• La institución volverá a estar completamente operativa',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmReactivateInstitution(institution);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  void _confirmReactivateInstitution(Institution institution) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Actualizar el estado de la institución a activa
      final updatedInstitution = institution.copyWith(
        status: InstitutionStatus.active,
        updatedAt: DateTime.now(),
      );

      print('🔄 Reactivando institución ${institution.name}...');
      print('   - ID: ${institution.id}');
      print('   - Estado anterior: ${institution.status}');
      print('   - Estado nuevo: ${updatedInstitution.status}');

      // Actualizar en la base de datos
      final success = await InstitutionAdapter.updateInstitution(institution.id, updatedInstitution);
      
      if (!success) {
        throw Exception('No se pudo reactivar la institución');
      }
      
      print('✅ Institución ${institution.name} reactivada exitosamente');

      // Cerrar el diálogo de carga
      Navigator.pop(context);

      // Actualizar la lista local y recalcular estadísticas
      setState(() {
        final index = _institutions.indexWhere((inst) => inst.id == institution.id);
        if (index != -1) {
          _institutions[index] = updatedInstitution;
        }
      });
      
      // Recalcular estadísticas (incluyendo solicitudes pendientes)
      await _recalculateStats();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Institución ${institution.name} reactivada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      Navigator.pop(context);
      
      print('❌ Error al reactivar institución: $e');
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reactivar institución: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              AlertService.showInfo(context, 'Info', 'Eliminación en desarrollo');
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToPageEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageEditorScreen(),
      ),
    );
  }

  void _navigateToBlockchainWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockchainWalletSetupScreen(),
      ),
    );
  }

  // Función para recalcular estadísticas en tiempo real
  Future<void> _recalculateStats() async {
    int total = _institutions.length;
    int active = 0;
    int inactive = 0;
    int suspended = 0;

    for (final institution in _institutions) {
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
          // Las instituciones pendientes no se cuentan aquí
          break;
      }
    }

    // Cargar estadísticas de solicitudes pendientes
    int pendingRequests = 0;
    try {
      final requestStats = await InstitutionRequestAdapter.getRequestStats();
      pendingRequests = requestStats['pending'] ?? 0;
    } catch (e) {
      print('⚠️ Error cargando estadísticas de solicitudes en _recalculateStats: $e');
    }

    if (mounted) {
      setState(() {
        _stats = {
          'total': total,
          'active': active,
          'inactive': inactive,
          'suspended': suspended,
          'pending': pendingRequests, // Usar solicitudes pendientes
        };
      });
    }

    print('📊 Estadísticas actualizadas:');
    print('   - Total: $total');
    print('   - Activas: $active');
    print('   - Inactivas: $inactive');
    print('   - Suspendidas: $suspended');
    print('   - Solicitudes pendientes: $pendingRequests');
  }



}
