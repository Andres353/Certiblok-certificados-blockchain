// lib/screens/programs/programs_opportunities_screen.dart
// Pantalla para mostrar programas y pasantías disponibles

import 'package:flutter/material.dart';
import '../../models/program_opportunity.dart';
import '../../services/adapters/programs_adapter.dart';
import '../../services/user_context_service.dart';
import 'program_details_screen.dart';

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
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener todas las pasantías disponibles
      final allPrograms = await ProgramsAdapter.getAllProgramsForDebug();

      // Filtrar pasantías activas de la institución del estudiante
      final activePrograms = allPrograms.where((program) => 
        program.isActive && 
        program.institutionId == context.institutionId
      ).toList();

      // Filtrar pasantías que incluyan la carrera del estudiante
      List<ProgramOpportunity> availablePrograms = [];
      
      if (context.programId != null) {
        availablePrograms = activePrograms.where((program) => 
          program.careerIds.contains(context.programId!)
        ).toList();
      } else {
        availablePrograms = activePrograms; // Mostrar todas si no tiene carrera
      }
      
      setState(() {
        _programs = availablePrograms;
        _filteredPrograms = availablePrograms;
        _isLoading = false;
      });
      
      if (availablePrograms.isEmpty) {
        _showInfoSnackBar('No hay pasantías disponibles para tu carrera');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar pasantías: $e');
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
        title: Text('Pasantías Disponibles'),
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
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay pasantías disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No se encontraron pasantías que coincidan con tu búsqueda',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular número de columnas para ajustar a la pantalla (igual que dashboard principal)
        int crossAxisCount;
        double childAspectRatio;
        
        // Calcular el espacio disponible
        final availableWidth = constraints.maxWidth;
        
        if (availableWidth > 1400) {
          crossAxisCount = 4;
          childAspectRatio = 1.6; // Más anchos y menos altos
        } else if (availableWidth > 1000) {
          crossAxisCount = 3;
          childAspectRatio = 1.5; // Más anchos y menos altos
        } else if (availableWidth > 700) {
          crossAxisCount = 2;
          childAspectRatio = 1.6; // Más anchos y menos altos
        } else {
          crossAxisCount = 1;
          childAspectRatio = 3.0; // Más anchos y menos altos
        }
        
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredPrograms.length,
          itemBuilder: (context, index) {
            final program = _filteredPrograms[index];
            return _buildProgramCard(program);
          },
        );
      },
    );
  }

  Widget _buildProgramCard(ProgramOpportunity program) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: InkWell(
          onTap: () => _navigateToProgramDetails(program),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del programa
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xff6C4DDC).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    program.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Información en badges
                Row(
                  children: [
                    // Estado
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(int.parse(program.statusColor.replaceAll('#', '0xFF'))).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(int.parse(program.statusColor.replaceAll('#', '0xFF'))).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          program.status,
                          style: TextStyle(
                            color: Color(int.parse(program.statusColor.replaceAll('#', '0xFF'))),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 6),
                    
                    // Postulantes
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xff6C4DDC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xff6C4DDC).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${program.currentApplications}/${program.maxApplications}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xff6C4DDC),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Información de institución
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          program.institutionName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 6),
                
                // Carreras
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          program.careerNames.join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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