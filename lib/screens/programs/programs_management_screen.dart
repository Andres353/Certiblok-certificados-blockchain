// lib/screens/programs/programs_management_screen.dart
// Pantalla para gestionar programas (Admin)

import 'package:flutter/material.dart';
import '../../models/program_opportunity.dart';
import '../../services/adapters/programs_adapter.dart';
import '../../services/user_context_service.dart';
import 'create_program_screen.dart';

class ProgramsManagementScreen extends StatefulWidget {
  @override
  _ProgramsManagementScreenState createState() => _ProgramsManagementScreenState();
}

class _ProgramsManagementScreenState extends State<ProgramsManagementScreen> {
  List<ProgramOpportunity> _programs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, active, inactive, open, closed
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Cargando programas en gestión...');
      
      // Obtener el contexto del usuario para filtrar por institución
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario debe tener institución asignada');
      }
      
      // Filtrar programas por la institución del administrador
      final programs = await ProgramsAdapter.getProgramsByInstitution(userContext!.institutionId!);
      
      print('📊 Programas cargados para institución ${userContext.institutionId}: ${programs.length}');
      
      setState(() {
        _programs = programs;
        _isLoading = false;
      });
      
      if (programs.isEmpty) {
        _showInfoSnackBar('No hay programas disponibles para tu institución');
      }
    } catch (e) {
      print('❌ Error cargando programas: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar programas: $e');
    }
  }

  List<ProgramOpportunity> get _filteredPrograms {
    var filtered = _programs;
    
    // Filtro por estado
    switch (_selectedFilter) {
      case 'active':
        filtered = filtered.where((program) => program.isActive).toList();
        break;
      case 'inactive':
        filtered = filtered.where((program) => !program.isActive).toList();
        break;
      case 'open':
        filtered = filtered.where((program) => program.isOpenForApplications && program.hasAvailableSlots).toList();
        break;
      case 'closed':
        filtered = filtered.where((program) => !program.isOpenForApplications || !program.hasAvailableSlots).toList();
        break;
    }
    
    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((program) =>
          program.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          program.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          program.institutionName.toLowerCase().contains(_searchQuery.toLowerCase())
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
        title: Text('Gestión de Programas'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadPrograms,
            icon: Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateProgram(),
        icon: Icon(Icons.add),
        label: Text('Crear Programa'),
        backgroundColor: Color(0xff6C4DDC),
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
                    : _buildProgramsList(isWeb),
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
              hintText: 'Buscar programas...',
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
                _buildFilterChip('Todos', 'all'),
                SizedBox(width: 8),
                _buildFilterChip('Activos', 'active'),
                SizedBox(width: 8),
                _buildFilterChip('Inactivos', 'inactive'),
                SizedBox(width: 8),
                _buildFilterChip('Abiertos', 'open'),
                SizedBox(width: 8),
                _buildFilterChip('Cerrados', 'closed'),
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
          _buildStatCard('Activos', stats['active']!, Colors.green),
          SizedBox(width: 12),
          _buildStatCard('Abiertos', stats['open']!, Colors.orange),
          SizedBox(width: 12),
          _buildStatCard('Cerrados', stats['closed']!, Colors.red),
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
    int total = _programs.length;
    int active = _programs.where((program) => program.isActive).length;
    int open = _programs.where((program) => program.isOpenForApplications && program.hasAvailableSlots).length;
    int closed = _programs.where((program) => !program.isOpenForApplications || !program.hasAvailableSlots).length;
    
    return {
      'total': total,
      'active': active,
      'open': open,
      'closed': closed,
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay programas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Crea tu primer programa para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateProgram,
            icon: Icon(Icons.add),
            label: Text('Crear Programa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsList(bool isWeb) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWeb ? 3 : 2,
          childAspectRatio: 2.0, // Mucho más ancho que alto para cards horizontales
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
      itemCount: _filteredPrograms.length,
      itemBuilder: (context, index) => _buildProgramCard(_filteredPrograms[index], isWeb),
    );
  }

  Widget _buildProgramCard(ProgramOpportunity program, bool isWeb) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: InkWell(
          onTap: () => _showProgramDetailsModal(program),
          borderRadius: BorderRadius.circular(16),
           child: Padding(
             padding: EdgeInsets.all(12),
               child: Stack(
                 children: [
                   // Contenido principal
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Título del programa
                       Text(
                         program.title,
                         style: TextStyle(
                           fontSize: isWeb ? 16 : 14,
                           fontWeight: FontWeight.bold,
                           color: Color(0xff2E2F44),
                           height: 1.2,
                         ),
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                       ),
                       
                       SizedBox(height: 6),
                       
                       // Información en fila
                       Row(
                         children: [
                           // Estado
                           Container(
                             padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                             decoration: BoxDecoration(
                               color: _getStatusColor(program.status).withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(
                                 color: _getStatusColor(program.status).withOpacity(0.3),
                                 width: 1,
                               ),
                             ),
                             child: Text(
                               program.status,
                               style: TextStyle(
                                 color: _getStatusColor(program.status),
                                 fontSize: 10,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ),
                           
                           SizedBox(width: 8),
                           
                           // Carreras
                           if (program.careerNames.isNotEmpty)
                             Container(
                               padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                               decoration: BoxDecoration(
                                 color: Color(0xff6C4DDC).withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Text(
                                 program.careerNames.length > 1 
                                     ? '${program.careerNames.length} carreras'
                                     : program.careerNames.first,
                                 style: TextStyle(
                                   fontSize: 10,
                                   color: Color(0xff6C4DDC),
                                   fontWeight: FontWeight.w500,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                         ],
                       ),
                     ],
                   ),
                   
                   // Menú de 3 puntos en la esquina superior derecha
                   Positioned(
                     top: 0,
                     right: 0,
                     child: PopupMenuButton<String>(
                       onSelected: (value) => _handleProgramAction(value, program),
                       icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
                       itemBuilder: (context) => [
                         PopupMenuItem(
                           value: 'edit',
                           child: Row(
                             children: [
                               Icon(Icons.edit, size: 16, color: Colors.blue),
                               SizedBox(width: 8),
                               Text('Editar'),
                             ],
                           ),
                         ),
                         PopupMenuItem(
                           value: 'toggle',
                           child: Row(
                             children: [
                               Icon(Icons.power_settings_new, size: 16, color: Colors.orange),
                               SizedBox(width: 8),
                               Text(program.isActive ? 'Desactivar' : 'Activar'),
                             ],
                           ),
                         ),
                         PopupMenuItem(
                           value: 'delete',
                           child: Row(
                             children: [
                               Icon(Icons.delete, size: 16, color: Colors.red),
                               SizedBox(width: 8),
                               Text('Eliminar'),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                   
                   // Estadísticas en la esquina inferior izquierda
                   Positioned(
                     bottom: 0,
                     left: 0,
                     child: Row(
                       children: [
                         _buildInfoChip(
                           Icons.people,
                           '${program.currentApplications}/${program.maxApplications}',
                           Colors.blue,
                         ),
                         
                         SizedBox(width: 8),
                         
                         _buildInfoChip(
                           Icons.schedule,
                           '${program.daysUntilDeadline}d',
                           Colors.orange,
                         ),
                       ],
                     ),
                   ),
                   
                   // Botón Ver Info en la esquina inferior derecha
                   Positioned(
                     bottom: 0,
                     right: 0,
                     child: Container(
                       width: 120,
                       height: 32,
                       child: ElevatedButton.icon(
                         onPressed: () => _showProgramDetailsModal(program),
                         icon: Icon(Icons.info_outline, size: 14),
                         label: Text('Ver Info', style: TextStyle(fontSize: 12)),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Color(0xff6C4DDC),
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(6),
                           ),
                           elevation: 0,
                         ),
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

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showProgramDetailsModal(ProgramOpportunity program) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWeb = screenWidth > 800;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: isWeb ? 600 : double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del modal
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xff6C4DDC),
                        Color(0xff8E7CC3),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.work_outline, color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program.title,
                              style: TextStyle(
                                fontSize: isWeb ? 24 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              program.institutionName,
                              style: TextStyle(
                                fontSize: isWeb ? 16 : 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
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
                        // Estado y fechas
                        _buildDetailSection(
                          'Estado del Programa',
                          [
                            _buildDetailRow('Estado', program.status, _getStatusColor(program.status)),
                            _buildDetailRow('Fecha límite', _formatDate(program.applicationDeadline), Colors.grey[600]!),
                            _buildDetailRow('Días restantes', '${program.daysUntilDeadline} días', Colors.orange),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Carreras
                        _buildDetailSection(
                          'Carreras Disponibles',
                          program.careerNames.map((career) => 
                            _buildDetailRow('•', career, Colors.grey[700]!)
                          ).toList(),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Descripción
                        _buildDetailSection(
                          'Descripción',
                          [
                            _buildDetailText(program.description),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Requisitos
                        if (program.requirements.isNotEmpty)
                          _buildDetailSection(
                            'Requisitos',
                            program.requirements.map((req) => 
                              _buildDetailRow('•', req, Colors.grey[700]!)
                            ).toList(),
                          ),
                        
                        SizedBox(height: 24),
                        
                        // Información de cupos
                        _buildDetailSection(
                          'Información de Cupos',
                          [
                            _buildDetailRow('Postulaciones actuales', '${program.currentApplications}', Colors.blue),
                            _buildDetailRow('Cupos máximos', '${program.maxApplications}', Colors.green),
                            _buildDetailRow('Disponibilidad', 
                              program.hasAvailableSlots ? 'Disponible' : 'Sin cupos', 
                              program.hasAvailableSlots ? Colors.green : Colors.red
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Archivos adjuntos
                        _buildDetailSection(
                          'Archivos Adjuntos',
                          [
                            if (program.imageUrl != null) ...[
                                Text(
                                  'Imagen de la Pasantía',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff2E2F44),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      program.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('❌ Error cargando imagen: $error');
                                        print('🔗 URL de imagen: ${program.imageUrl}');
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image, color: Colors.red, size: 40),
                                              SizedBox(height: 8),
                                              Text(
                                                'Error al cargar imagen',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'URL: ${program.imageUrl}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: Color(0xff6C4DDC),
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'Cargando imagen...',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                              if (program.pdfUrl != null) ...[
                                Text(
                                  'Documento PDF',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff2E2F44),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: InkWell(
                                    onTap: () => _openPdf(program.pdfUrl!),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red[600],
                                            size: 32,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                program.pdfFileName ?? 'Documento PDF',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xff2E2F44),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Toca para abrir el documento',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.open_in_new,
                                          color: Colors.red[600],
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            if (program.imageUrl == null && program.pdfUrl == null) ...[
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      color: Colors.grey[400],
                                      size: 48,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No hay archivos adjuntos',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Este programa no tiene imagen ni documento PDF',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Información del creador
                        _buildDetailSection(
                          'Información del Creador',
                          [
                            _buildDetailRow('Creado por', program.createdByName, Colors.grey[600]!),
                            _buildDetailRow('Fecha de creación', _formatDate(program.createdAt), Colors.grey[600]!),
                            _buildDetailRow('Última actualización', _formatDate(program.updatedAt), Colors.grey[600]!),
                          ],
                        ),
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
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _handleProgramAction('edit', program);
                          },
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xff6C4DDC),
                            side: BorderSide(color: Color(0xff6C4DDC)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, size: 18),
                          label: Text('Cerrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff6C4DDC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff2E2F44),
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != '•')
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
          if (label != '•') SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: label == '•' ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Abierto':
        return Colors.green;
      case 'Sin cupos':
        return Colors.orange;
      case 'Cerrado':
        return Colors.red;
      case 'Inactivo':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _openPdf(String pdfUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red[600]),
              SizedBox(width: 8),
              Text('Documento PDF'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('URL del documento:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  pdfUrl,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Para abrir el PDF, copia la URL y ábrela en tu navegador.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showInfoSnackBar('URL copiada al portapapeles');
                // En una implementación real, aquí copiarías la URL al portapapeles
              },
              icon: Icon(Icons.copy, size: 16),
              label: Text('Copiar URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCreateProgram() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProgramScreen(),
      ),
    ).then((_) => _loadPrograms());
  }

  void _handleProgramAction(String action, ProgramOpportunity program) {
    switch (action) {
      case 'edit':
        _editProgram(program);
        break;
      case 'toggle':
        _toggleProgramStatus(program);
        break;
      case 'delete':
        _deleteProgram(program);
        break;
    }
  }

  void _editProgram(ProgramOpportunity program) {
    // TODO: Implementar edición de programa
    _showInfoSnackBar('Edición de programa en desarrollo');
  }

  Future<void> _toggleProgramStatus(ProgramOpportunity program) async {
    try {
      await ProgramsAdapter.toggleProgramStatus(
        program.id,
        !program.isActive,
      );
      _loadPrograms();
      _showSuccessSnackBar('Estado del programa actualizado');
    } catch (e) {
      _showErrorSnackBar('Error al actualizar estado: $e');
    }
  }

  Future<void> _deleteProgram(ProgramOpportunity program) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmar Eliminación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar esta pasantía?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    program.institutionName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: Icon(Icons.delete, size: 18),
            label: Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    // Si el usuario confirmó, eliminar el programa
    if (confirmed == true) {
      try {
        // Mostrar indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Eliminando programa...'),
              ],
            ),
          ),
        );

        // Eliminar el programa usando el adapter
        await ProgramsAdapter.deleteProgram(program.id);

        // Cerrar el diálogo de carga
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Recargar la lista de programas
        await _loadPrograms();

        // Mostrar mensaje de éxito
        _showSuccessSnackBar('Programa eliminado exitosamente');
      } catch (e) {
        print('❌ Error eliminando programa: $e');
        
        // Cerrar el diálogo de carga si está abierto
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        _showErrorSnackBar('Error al eliminar programa: $e');
      }
    }
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
      ),
    );
  }
}
