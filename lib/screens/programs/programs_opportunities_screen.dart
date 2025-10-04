// lib/screens/programs/programs_opportunities_screen.dart
// Pantalla para mostrar programas y pasantías disponibles

import 'package:flutter/material.dart';
import '../../models/program_opportunity.dart';
import '../../services/programs_opportunities_service.dart';
import '../../services/user_context_service.dart';
import 'program_details_screen.dart';
import 'application_form_screen.dart';

class ProgramsOpportunitiesScreen extends StatefulWidget {
  @override
  _ProgramsOpportunitiesScreenState createState() => _ProgramsOpportunitiesScreenState();
}

class _ProgramsOpportunitiesScreenState extends State<ProgramsOpportunitiesScreen> {
  List<ProgramOpportunity> _programs = [];
  List<ProgramOpportunity> _filteredPrograms = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, open, closed, my_institution

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Cargando programas para estudiantes...');
      
      // Para estudiantes, mostrar todos los programas disponibles
      final programs = await ProgramsOpportunitiesService.getAllProgramsForDebug();
      
      // Filtrar solo programas activos y abiertos para postulaciones
      final availablePrograms = programs.where((program) {
        return program.isActive && program.isOpenForApplications;
      }).toList();
      
      print('📊 Programas disponibles: ${availablePrograms.length}');
      
      setState(() {
        _programs = availablePrograms;
        _filteredPrograms = availablePrograms;
        _isLoading = false;
      });
      
      if (availablePrograms.isEmpty) {
        _showInfoSnackBar('No hay programas disponibles en este momento');
      }
    } catch (e) {
      print('❌ Error cargando programas: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar programas: $e');
    }
  }

  void _filterPrograms() {
    setState(() {
      _filteredPrograms = _programs.where((program) {
        // Filtro por búsqueda
        final matchesSearch = _searchQuery.isEmpty ||
            program.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            program.description.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filtro por estado
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'open':
            matchesFilter = program.isOpenForApplications && program.hasAvailableSlots;
            break;
          case 'closed':
            matchesFilter = !program.isOpenForApplications || !program.hasAvailableSlots;
            break;
          case 'my_institution':
            final context = UserContextService.currentContext;
            matchesFilter = context?.institutionId == program.institutionId;
            break;
          case 'all':
          default:
            matchesFilter = true;
            break;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Programas y Pasantías'),
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
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilters(),
          
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
                _filterPrograms();
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
                _buildFilterChip('Abiertos', 'open'),
                SizedBox(width: 8),
                _buildFilterChip('Cerrados', 'closed'),
                SizedBox(width: 8),
                _buildFilterChip('Mi Institución', 'my_institution'),
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
          _filterPrograms();
        });
      },
      selectedColor: Color(0xff6C4DDC).withOpacity(0.2),
      checkmarkColor: Color(0xff6C4DDC),
    );
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
            'No hay programas disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No se encontraron programas que coincidan con tu búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPrograms,
            icon: Icon(Icons.refresh),
            label: Text('Actualizar'),
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
    if (isWeb) {
      return GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _filteredPrograms.length,
        itemBuilder: (context, index) => _buildProgramCard(_filteredPrograms[index], isWeb),
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredPrograms.length,
        itemBuilder: (context, index) => _buildProgramCard(_filteredPrograms[index], isWeb),
      );
    }
  }

  Widget _buildProgramCard(ProgramOpportunity program, bool isWeb) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToProgramDetails(program),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      program.title,
                      style: TextStyle(
                        fontSize: isWeb ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E2F44),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(program.statusColor.replaceAll('#', '0xFF'))).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      program.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(int.parse(program.statusColor.replaceAll('#', '0xFF'))),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Institución
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      program.institutionName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4),
              
              // Facultad/Carrera
              Row(
                children: [
                  Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${program.careerNames.join(', ')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Descripción
              Text(
                program.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: isWeb ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              Spacer(),
              
              // Footer con información adicional
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    '${program.currentApplications}/${program.maxApplications}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Spacer(),
                  if (program.isOpenForApplications) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      '${program.daysUntilDeadline} días',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProgramDetails(ProgramOpportunity program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailsScreen(program: program),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
