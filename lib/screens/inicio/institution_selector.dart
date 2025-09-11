// lib/screens/inicio/institution_selector.dart
// Selector de institución para usuarios multi-tenant

import 'package:flutter/material.dart';
import '../../models/institution.dart';
import '../../data/sample_institutions.dart';
import '../../services/institution_service.dart';

class InstitutionSelector extends StatefulWidget {
  final Function(Institution) onInstitutionSelected;
  final String? currentInstitutionId;

  const InstitutionSelector({
    Key? key,
    required this.onInstitutionSelected,
    this.currentInstitutionId,
  }) : super(key: key);

  @override
  State<InstitutionSelector> createState() => _InstitutionSelectorState();
}

class _InstitutionSelectorState extends State<InstitutionSelector> {
  List<Institution> _institutions = [];
  List<Institution> _filteredInstitutions = [];
  String _searchQuery = '';
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

  void _filterInstitutions(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredInstitutions = _institutions;
      } else {
        _filteredInstitutions = SampleInstitutions.searchInstitutions(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Institución'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header informativo
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona tu Institución',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Elige la institución académica a la que perteneces',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Barra de búsqueda
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterInstitutions,
              decoration: InputDecoration(
                hintText: 'Buscar institución...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Lista de instituciones
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredInstitutions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
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
                              'Intenta con otro término de búsqueda',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredInstitutions.length,
                        itemBuilder: (context, index) {
                          final institution = _filteredInstitutions[index];
                          final isSelected = institution.id == widget.currentInstitutionId;
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: isSelected ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? BorderSide(color: Color(0xff6C4DDC), width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(int.parse(institution.colors.primary.replaceAll('#', '0xFF'))),
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
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.school,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${institution.settings.supportedPrograms.length} programas',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        institution.status.displayName,
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Color(0xff6C4DDC),
                                      size: 28,
                                    )
                                  : Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                              onTap: () {
                                widget.onInstitutionSelected(institution);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
