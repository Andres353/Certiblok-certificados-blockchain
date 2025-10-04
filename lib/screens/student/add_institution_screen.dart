// lib/screens/student/add_institution_screen.dart
// Pantalla para que estudiantes agreguen más instituciones usando códigos

import 'package:flutter/material.dart';
import '../../models/institution.dart';
import '../../services/institution_service.dart';
import '../../services/student_institution_service.dart';
import '../../services/user_context_service.dart';

class AddInstitutionScreen extends StatefulWidget {
  @override
  _AddInstitutionScreenState createState() => _AddInstitutionScreenState();
}

class _AddInstitutionScreenState extends State<AddInstitutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _programController = TextEditingController();
  final _facultyController = TextEditingController();

  bool _isLoading = false;
  bool _isValidatingCode = false;
  Institution? _selectedInstitution;
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    _studentIdController.dispose();
    _programController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _validateInstitutionCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _codeError = 'Ingresa el código de la institución';
        _selectedInstitution = null;
      });
      return;
    }

    setState(() {
      _isValidatingCode = true;
      _codeError = null;
    });

    try {
      final institution = await InstitutionService.getInstitutionByCode(
        _codeController.text.trim().toUpperCase(),
      );

      if (institution != null) {
        setState(() {
          _selectedInstitution = institution;
          _codeError = null;
        });
      } else {
        setState(() {
          _codeError = 'Código de institución no válido o institución inactiva';
          _selectedInstitution = null;
        });
      }
    } catch (e) {
      setState(() {
        _codeError = 'Error al validar el código: $e';
        _selectedInstitution = null;
      });
    } finally {
      setState(() => _isValidatingCode = false);
    }
  }

  Future<void> _addInstitution() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInstitution == null) {
      setState(() {
        _codeError = 'Debes validar el código de institución primero';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.userId == null) {
        throw Exception('No se pudo obtener el contexto del usuario');
      }

      // Verificar si ya está registrado en esta institución
      final isAlreadyRegistered = await StudentInstitutionService.isStudentInInstitution(
        userContext!.userId,
        _selectedInstitution!.id,
      );

      if (isAlreadyRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya estás registrado en esta institución'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Agregar estudiante a la institución
      final result = await StudentInstitutionService.addStudentToInstitution(
        studentId: userContext.userId,
        institutionId: _selectedInstitution!.id,
        studentIdInInstitution: _studentIdController.text.trim(),
        program: _programController.text.trim().isNotEmpty ? _programController.text.trim() : null,
        faculty: _facultyController.text.trim().isNotEmpty ? _facultyController.text.trim() : null,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Te has registrado exitosamente en ${_selectedInstitution!.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Regresar con éxito
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al registrarse en la institución'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Institución'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agregar Nueva Institución',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Usa el código de institución para registrarte',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Código de Institución
              Text(
                'Código de Institución',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: 'Ej: UVA001',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: _codeError,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        if (_codeError != null) {
                          setState(() => _codeError = null);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isValidatingCode ? null : _validateInstitutionCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isValidatingCode
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Validar'),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Institución Seleccionada
              if (_selectedInstitution != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xff6C4DDC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _selectedInstitution!.institutionCode,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedInstitution!.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _selectedInstitution!.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],

              // Información de Registro
              if (_selectedInstitution != null) ...[
                Text(
                  'Información de Registro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // ID de Estudiante en la Institución
                TextFormField(
                  controller: _studentIdController,
                  decoration: InputDecoration(
                    labelText: 'ID de Estudiante en ${_selectedInstitution!.shortName}',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Tu número de identificación en esta institución',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu ID de estudiante';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Programa (Opcional)
                TextFormField(
                  controller: _programController,
                  decoration: InputDecoration(
                    labelText: 'Programa (Opcional)',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Ej: Ingeniería de Sistemas, Medicina, etc.',
                  ),
                ),

                SizedBox(height: 16),

                // Facultad (Opcional)
                TextFormField(
                  controller: _facultyController,
                  decoration: InputDecoration(
                    labelText: 'Facultad (Opcional)',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Ej: Facultad de Ingeniería, Facultad de Medicina, etc.',
                  ),
                ),

                SizedBox(height: 30),

                // Botón de Registro
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addInstitution,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Registrando...'),
                            ],
                          )
                        : Text(
                            'Registrarse en ${_selectedInstitution!.shortName}',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
