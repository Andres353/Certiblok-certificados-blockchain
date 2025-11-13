// lib/screens/admin/manage_students_screen.dart
// Pantalla para que el administrador vea todos los estudiantes divididos por carreras

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_context_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({Key? key}) : super(key: key);

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _studentsByProgram = {};
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario debe tener institución asignada');
      }

      // Obtener todos los estudiantes de la institución
      final supabase = Supabase.instance.client;
      final studentsData = await supabase
          .from('users')
          .select('*')
          .eq('role', 'student')
          .eq('institution_id', userContext!.institutionId!);

      print('📊 Estudiantes encontrados: ${studentsData.length}');

      // Agrupar estudiantes por programa
      Map<String, List<Map<String, dynamic>>> grouped = {};
      
      for (var student in studentsData) {
        final programName = student['program'] as String? ?? 'Sin Programa';
        
        if (!grouped.containsKey(programName)) {
          grouped[programName] = [];
        }
        grouped[programName]!.add(student);
      }

      // Obtener programas únicos
      _programs = grouped.keys.map((programName) {
        final programStudents = grouped[programName]!;
        return {
          'name': programName,
          'count': programStudents.length,
        };
      }).toList();

      setState(() {
        _studentsByProgram = grouped;
        _isLoading = false;
      });

      print('📊 Programas encontrados: ${_programs.length}');
    } catch (e) {
      print('❌ Error cargando estudiantes: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando estudiantes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Estudiantes'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _studentsByProgram.isEmpty
              ? _buildEmptyState()
              : _buildStudentsView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'No hay estudiantes registrados',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los estudiantes aparecerán aquí cuando se registren',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsView() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen
            _buildSummaryCard(),
            SizedBox(height: 24),
            
            // Lista de programas
            ..._programs.map((program) => _buildProgramSection(program)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalStudents = _studentsByProgram.values
        .fold(0, (sum, students) => sum + students.length);
    final totalPrograms = _programs.length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(Icons.people, 'Estudiantes', totalStudents.toString()),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildSummaryItem(Icons.school, 'Carreras', totalPrograms.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramSection(Map<String, dynamic> program) {
    final students = _studentsByProgram[program['name']]!;
    final programName = program['name'] as String;
    final studentCount = program['count'] as int;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
          child: Icon(Icons.school, color: Color(0xff6C4DDC)),
        ),
        title: Text(
          programName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xff2E2F44),
          ),
        ),
        subtitle: Text(
          '$studentCount estudiante${studentCount != 1 ? 's' : ''}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        children: [
          Divider(height: 1),
          ...students.map((student) => _buildStudentCard(student)).toList(),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final fullName = student['full_name'] as String? ?? 'Sin nombre';
    final email = student['email'] as String? ?? 'Sin email';
    final studentId = student['student_id'] as String? ?? 'Sin ID';
    final phone = student['phone'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
        child: Icon(Icons.person, color: Color(0xff6C4DDC)),
      ),
      title: Text(
        fullName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xff2E2F44),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email.isNotEmpty) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
          if (studentId.isNotEmpty && studentId != 'Sin ID') ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('ID: $studentId', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
          if (phone != null && phone.isNotEmpty) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(phone, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
