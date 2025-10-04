// lib/screens/admin/student_id_management.dart
import 'package:flutter/material.dart';
import '../../services/student_id_generator.dart';

class StudentIdManagementScreen extends StatefulWidget {
  const StudentIdManagementScreen({super.key});

  @override
  State<StudentIdManagementScreen> createState() => _StudentIdManagementScreenState();
}

class _StudentIdManagementScreenState extends State<StudentIdManagementScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await StudentIdGenerator.getStudentIdStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando estadísticas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateTestIds() async {
    setState(() => _isLoading = true);
    try {
      final testIds = await StudentIdGenerator.generateMultipleStudentIds(5);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('IDs de Prueba Generados'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Se generaron 5 IDs de prueba:'),
              SizedBox(height: 16),
              ...testIds.map((id) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('• $id', style: TextStyle(fontFamily: 'monospace')),
              )),
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
      
      await _loadStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando IDs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de IDs de Estudiante'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.badge, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Sistema de IDs de Estudiante',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generación automática y gestión de identificadores únicos',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Estadísticas
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estadísticas del Sistema',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2E2F44),
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Año Actual',
                                  '${_stats['currentYear'] ?? 'N/A'}',
                                  Icons.calendar_today,
                                  Color(0xff10B981),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Estudiantes Este Año',
                                  '${_stats['studentsThisYear'] ?? 0}',
                                  Icons.school,
                                  Color(0xff3B82F6),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Estudiantes',
                                  '${_stats['totalStudents'] ?? 0}',
                                  Icons.people,
                                  Color(0xff8B5CF6),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Próximo ID',
                                  '${_stats['nextStudentId'] ?? 'N/A'}',
                                  Icons.next_plan,
                                  Color(0xffF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Información del Sistema
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Sistema',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2E2F44),
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildInfoItem(
                            Icons.format_list_numbered,
                            'Formato de ID',
                            'AÑO + NÚMERO (ej: 2024001)',
                          ),
                          _buildInfoItem(
                            Icons.auto_awesome,
                            'Generación',
                            'Automática al registrar estudiantes',
                          ),
                          _buildInfoItem(
                            Icons.security,
                            'Unicidad',
                            'Garantizada por el sistema',
                          ),
                          _buildInfoItem(
                            Icons.trending_up,
                            'Secuencial',
                            'Números incrementales por año',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Acciones
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acciones',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2E2F44),
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _loadStats,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Actualizar Estadísticas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xff10B981),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _generateTestIds,
                                  icon: Icon(Icons.science),
                                  label: Text('Generar IDs de Prueba'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xff3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xff6C4DDC), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2E2F44),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

