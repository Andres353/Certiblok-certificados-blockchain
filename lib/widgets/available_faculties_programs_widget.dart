// lib/widgets/available_faculties_programs_widget.dart
// Widget para mostrar facultades y programas disponibles para agregar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/global_faculties_programs_service.dart';
import '../services/user_context_service.dart';

class AvailableFacultiesProgramsWidget extends StatefulWidget {
  final String type; // 'faculties' o 'programs'
  final Function(Map<String, dynamic>) onItemSelected;
  final String? searchQuery;

  const AvailableFacultiesProgramsWidget({
    Key? key,
    required this.type,
    required this.onItemSelected,
    this.searchQuery,
  }) : assert(type == 'faculties' || type == 'programs', 'Type must be either "faculties" or "programs"'),
       super(key: key);

  @override
  _AvailableFacultiesProgramsWidgetState createState() => _AvailableFacultiesProgramsWidgetState();
}

class _AvailableFacultiesProgramsWidgetState extends State<AvailableFacultiesProgramsWidget> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? '';
    _loadItems();
  }

  @override
  void didUpdateWidget(AvailableFacultiesProgramsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldQuery = oldWidget.searchQuery ?? '';
    final newQuery = widget.searchQuery ?? '';
    if (oldQuery != newQuery) {
      _searchQuery = newQuery;
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        print('Error: No se pudo obtener el contexto de institución');
        if (mounted) {
          setState(() {
            _items = [];
            _isLoading = false;
          });
        }
        return;
      }

      List<Map<String, dynamic>> items = [];
      
      if (widget.type == 'faculties') {
        if (_searchQuery.isNotEmpty) {
          items = await GlobalFacultiesProgramsService.searchFaculties(_searchQuery);
        } else {
          items = await GlobalFacultiesProgramsService.getAvailableFacultiesForInstitution(
            userContext!.institutionId!,
          );
        }
      } else if (widget.type == 'programs') {
        if (_searchQuery.isNotEmpty) {
          items = await GlobalFacultiesProgramsService.searchPrograms(_searchQuery);
        } else {
          items = await GlobalFacultiesProgramsService.getAvailableProgramsForInstitution(
            userContext!.institutionId!,
          );
        }
      }

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando ${widget.type}: $e');
      if (mounted) {
        setState(() {
          _items = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return SizedBox.shrink();
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    try {
      if (_isLoading) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_items.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.type == 'faculties' ? Icons.school_outlined : Icons.menu_book_outlined,
                  size: isWeb ? 64 : 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No hay ${widget.type == 'faculties' ? 'facultades' : 'programas'} disponibles',
                  style: TextStyle(
                    fontSize: isWeb ? 18 : 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                    ? 'Intenta con otros términos de búsqueda'
                    : 'Todas las ${widget.type == 'faculties' ? 'facultades' : 'programas'} ya están en tu institución',
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.all(isWeb ? 16 : 12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWeb ? 3 : 2,
            childAspectRatio: isWeb ? 1.1 : 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return _buildItemCard(item, isWeb);
          },
        ),
      );
    } catch (e) {
      print('Error en build del widget: $e');
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error al cargar ${widget.type}',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool isWeb) {
    final isFaculty = widget.type == 'faculties';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onItemSelected(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isWeb ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono y nombre
              Row(
                children: [
                  Container(
                    width: isWeb ? 40 : 32,
                    height: isWeb ? 40 : 32,
                    decoration: BoxDecoration(
                      color: isFaculty ? Color(0xff6C4DDC) : Color(0xff8B5CF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFaculty ? Icons.school : Icons.menu_book,
                      color: Colors.white,
                      size: isWeb ? 20 : 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 14 : 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Código
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (isFaculty ? Color(0xff6C4DDC) : Color(0xff8B5CF6)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isFaculty ? Color(0xff6C4DDC) : Color(0xff8B5CF6)).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tag,
                      size: 12,
                      color: isFaculty ? Color(0xff6C4DDC) : Color(0xff8B5CF6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      item['code'] ?? item['careerCode'] ?? '',
                      style: TextStyle(
                        color: isFaculty ? Color(0xff6C4DDC) : Color(0xff8B5CF6),
                        fontSize: isWeb ? 11 : 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 8),
              
              // Información adicional
              if (isFaculty) ...[
                Text(
                  'Programas: ${item['programsCount'] ?? 0}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isWeb ? 11 : 10,
                  ),
                ),
              ] else ...[
                Text(
                  'Facultad: ${item['facultyName'] ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isWeb ? 11 : 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['duration'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Duración: ${item['duration']} semestres',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: isWeb ? 10 : 9,
                    ),
                  ),
                ],
              ],
              
              Spacer(),
              
              // Institución de origen
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item['institutionName'] ?? 'Institución',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isWeb ? 9 : 8,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: 8),
              
              // Botón de agregar
              SizedBox(
                width: double.infinity,
                height: isWeb ? 32 : 28,
                child: ElevatedButton(
                  onPressed: () => widget.onItemSelected(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFaculty ? Color(0xff6C4DDC) : Color(0xff8B5CF6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: isWeb ? 14 : 12),
                      SizedBox(width: 4),
                      Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: isWeb ? 11 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
