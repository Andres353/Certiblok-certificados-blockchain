// lib/screens/programs/applications_management_screen.dart
// Pantalla para gestionar postulaciones (Admin/Emisor)

import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../models/program_opportunity.dart';
import '../../services/application_service.dart';
import '../../services/supabase/supabase_programs_service.dart';
import '../../services/user_context_service.dart';
import 'application_details_screen.dart';

class ApplicationsManagementScreen extends StatefulWidget {
  @override
  _ApplicationsManagementScreenState createState() => _ApplicationsManagementScreenState();
}

class _ApplicationsManagementScreenState extends State<ApplicationsManagementScreen> {
  List<Application> _applications = [];
  List<ProgramOpportunity> _programs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _expandedProgramId; // Para controlar qué programa está expandido
  Set<String> _processingApplications = {}; // IDs de aplicaciones que se están procesando

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario debe tener institución asignada');
      }

      // Cargar tanto aplicaciones como programas
      final applications = await ApplicationService.getInstitutionApplications();
      
      // Obtener todos los programas de la institución
      final allPrograms = await SupabaseProgramsService.getProgramsByInstitution(userContext!.institutionId!);
      
      print('📊 Total programas en institución: ${allPrograms.length}');
      
      // Filtrar programas según el rol
      List<ProgramOpportunity> programs;
      if (userContext.isSuperAdmin) {
        // Super admin ve todos los programas
        programs = allPrograms;
      } else if (userContext.userRole == 'admin_institution') {
        // Los administradores ven todos los programas de su institución
        programs = allPrograms;
        print('📊 Administrador: mostrando todos los programas de la institución');
      } else {
        // Emisores solo ven programas creados por ellos
        programs = allPrograms.where((program) {
          final matches = program.createdBy == userContext.userId;
          if (matches) {
            print('✅ Programa ${program.title} creado por el usuario');
          }
          return matches;
        }).toList();
      }
      
      print('📊 Programas para mostrar: ${programs.length}');
      
      setState(() {
        _applications = applications;
        _programs = programs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar datos: $e');
    }
  }

  List<Application> get _filteredApplications {
    // No filtrar aplicaciones, retornar todas
    return _applications;
  }

  List<ProgramOpportunity> get _filteredPrograms {
    var filtered = _programs;
    
    // Filtro por búsqueda en programas (pasantías)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((program) {
        final query = _searchQuery.toLowerCase();
        return program.title.toLowerCase().contains(query) ||
            program.institutionName.toLowerCase().contains(query) ||
            program.description.toLowerCase().contains(query);
      }).toList();
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
            onPressed: _loadData,
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
                : _filteredPrograms.isEmpty
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
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar pasantía por nombre, institución o descripción...',
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
    // Organizar aplicaciones por programa
    Map<String, List<Application>> applicationsByProgram = {};
    for (var app in _filteredApplications) {
      if (!applicationsByProgram.containsKey(app.programId)) {
        applicationsByProgram[app.programId] = [];
      }
      applicationsByProgram[app.programId]!.add(app);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredPrograms.length,
      itemBuilder: (context, index) {
        final program = _filteredPrograms[index];
        final programApplications = applicationsByProgram[program.id] ?? [];
        final isExpanded = _expandedProgramId == program.id;
        
        return _buildProgramCard(program, programApplications, isExpanded, isWeb);
      },
    );
  }

  Widget _buildProgramCard(ProgramOpportunity program, List<Application> applications, bool isExpanded, bool isWeb) {
    final pendingCount = applications.where((app) => app.status == ApplicationStatus.pending).length;
    final totalCount = applications.length;
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header del programa
          InkWell(
            onTap: () {
              setState(() {
                _expandedProgramId = isExpanded ? null : program.id;
              });
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.title,
                          style: TextStyle(
                            fontSize: isWeb ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '$totalCount postulación${totalCount != 1 ? 'es' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (pendingCount > 0) ...[
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pendingCount pendiente${pendingCount != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Color(0xff6C4DDC),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido expandido con las postulaciones
          if (isExpanded) ...[
            Divider(height: 1),
            if (applications.isEmpty)
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, color: Colors.grey[400], size: 48),
                      SizedBox(height: 8),
                      Text(
                        'No hay postulaciones',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...applications.map((app) => _buildApplicationCard(app, isWeb, true)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Application application, bool isWeb, [bool withMargin = false]) {
    return Container(
      margin: withMargin ? EdgeInsets.symmetric(horizontal: 12, vertical: 8) : EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: withMargin ? Border(left: BorderSide(color: Color(0xff6C4DDC), width: 3)) : null,
      ),
      child: Card(
        elevation: withMargin ? 2 : 4,
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
                        onPressed: _processingApplications.contains(application.id)
                            ? null
                            : () => _updateApplicationStatus(application, ApplicationStatus.approved),
                        icon: _processingApplications.contains(application.id)
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.check, size: 16),
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
                        onPressed: _processingApplications.contains(application.id)
                            ? null
                            : () => _updateApplicationStatus(application, ApplicationStatus.rejected),
                        icon: _processingApplications.contains(application.id)
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.close, size: 16),
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
    // Verificar si ya se está procesando esta aplicación
    if (_processingApplications.contains(application.id)) {
      _showInfoSnackBar('La operación ya está en proceso...');
      return;
    }

    try {
      // Agregar a la lista de procesamiento
      setState(() {
        _processingApplications.add(application.id);
      });

      String? notes;
      String? rejectionReason;
      
      if (newStatus == ApplicationStatus.rejected) {
        notes = await _showRejectionReasonDialog();
        if (notes == null) {
          // Usuario canceló, remover del set y salir
          setState(() {
            _processingApplications.remove(application.id);
          });
          return;
        }
        rejectionReason = notes;
      }
      
      await ApplicationService.updateApplicationStatus(
        applicationId: application.id,
        status: newStatus,
        notes: notes,
        rejectionReason: rejectionReason,
      );
      
      // Remover del set de procesamiento
      setState(() {
        _processingApplications.remove(application.id);
      });
      
      _loadData();
      _showSuccessSnackBar('Estado actualizado exitosamente');
    } catch (e) {
      // Remover del set en caso de error
      setState(() {
        _processingApplications.remove(application.id);
      });
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
