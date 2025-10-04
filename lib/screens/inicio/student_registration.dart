// lib/screens/inicio/student_registration.dart
// Registro de estudiantes con código de institución

import 'package:flutter/material.dart';
import '../../models/institution.dart';
import '../../services/institution_service.dart';
import '../../services/auth_service.dart';
import '../../services/student_institution_service.dart';

class StudentRegistration extends StatefulWidget {
  @override
  _StudentRegistrationState createState() => _StudentRegistrationState();
}

class _StudentRegistrationState extends State<StudentRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _studentIdController.dispose();
    _programController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _validateInstitutionCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _codeError = 'Ingresa el código de tu institución';
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
        
        // Mostrar información de la institución
        _showInstitutionInfo(institution);
      } else {
        setState(() {
          _selectedInstitution = null;
          _codeError = 'Código de institución no válido o inactivo';
        });
      }
    } catch (e) {
      setState(() {
        _selectedInstitution = null;
        _codeError = 'Error al validar código: $e';
      });
    } finally {
      setState(() {
        _isValidatingCode = false;
      });
    }
  }

  void _showInstitutionInfo(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Institución Encontrada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              institution.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Código: ${institution.institutionCode}'),
            Text('Descripción: ${institution.description}'),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text(
                  'Institución verificada',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInstitution == null) {
      setState(() {
        _codeError = 'Debes validar el código de institución primero';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Registrar estudiante
      final result = await AuthService.registerStudent(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
      );

      if (result['success']) {
        // Crear relación estudiante-institución
        final studentId = result['studentId'];
        final relationResult = await StudentInstitutionService.addStudentToInstitution(
          studentId: studentId,
          institutionId: _selectedInstitution!.id,
          studentIdInInstitution: _studentIdController.text.trim(),
          program: _programController.text.trim().isNotEmpty ? _programController.text.trim() : null,
          faculty: _facultyController.text.trim().isNotEmpty ? _facultyController.text.trim() : null,
        );

        if (relationResult['success']) {
          // Mostrar éxito
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Registro Exitoso'),
              content: Text(
                'Tu cuenta ha sido creada exitosamente y te has vinculado a ${_selectedInstitution!.name}. '
                'Puedes iniciar sesión con tus credenciales.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    Navigator.pop(context); // Volver al login
                  },
                  child: Text('Iniciar Sesión'),
                ),
              ],
            ),
          );
        } else {
          // Mostrar error en la relación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cuenta creada pero error al vincular con la institución: ${relationResult['message']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al registrar estudiante'),
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
        title: Text('Registro de Estudiante'),
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
                      'Registro de Estudiante',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ingresa el código de tu institución para comenzar',
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

              // Información de la institución seleccionada
              if (_selectedInstitution != null) ...[
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedInstitution!.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            Text(
                              'Código: ${_selectedInstitution!.institutionCode}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 30),

              // Información Personal
              Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Nombre Completo
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu nombre completo';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // ID de Estudiante
              TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'ID de Estudiante',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Número de identificación estudiantil',
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

              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Confirmar Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma tu contraseña';
                  }
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),

              SizedBox(height: 30),

              // Botón de Registro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              SizedBox(height: 20),

              // Enlace al login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(color: Color(0xff6C4DDC)),
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
