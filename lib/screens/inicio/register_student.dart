import 'package:flutter/material.dart';
import '../../services/adapters/auth_adapter.dart';
import '../../services/student_id_generator.dart';
import '../../services/alert_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterStudent extends StatefulWidget {
  const RegisterStudent({super.key});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedBirthDate;

  String _generateSecurePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final rand = Random();
    return String.fromCharCodes(Iterable.generate(12, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(Duration(days: 18 * 365)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        final year = picked.year.toString();
        _birthDateController.text = '$day/$month/$year';
      });
    }
  }

  Future<void> sendEmail({
    required String name,
    required String email,
    required String message,
  }) async {
    const serviceId = 'service_bdav8mg';
    const templateId = 'template_2fs5k3c';
    const userId = 'o1eUKl5D0Qq9fJ1Jv';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'name': name,
          'to_email': email,
          'message': message,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Fallo al enviar el correo: ${response.body}');
    }
  }

  Future<void> _registerStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final document = _documentController.text.trim();
      final birthDate = _birthDateController.text.trim();
      final address = _addressController.text.trim();

      try {
        // Generar contraseña temporal y ID de estudiante
        final tempPassword = _generateSecurePassword();
        final studentId = await StudentIdGenerator.generateStudentId();

        // Registrar estudiante usando Supabase con contraseña temporal
        final result = await AuthAdapter.registerStudent(
          email: email,
          password: tempPassword,
          fullName: fullName,
          studentId: studentId,
          phone: phone,
          document: document,
          birthDate: birthDate,
          address: address,
        );

        if (result['success']) {
          // Enviar email con contraseña temporal usando EmailJS
          try {
            await sendEmail(
              name: fullName,
              email: email,
              message: '¡Bienvenido a Certiblock!\n\n'
                      'Tu cuenta ha sido creada exitosamente.\n\n'
                      'Credenciales de acceso:\n'
                      'Email: $email\n'
                      'Contraseña temporal: $tempPassword\n\n'
                      'IMPORTANTE: Debes cambiar esta contraseña en tu primer inicio de sesión.\n\n'
                      'Si no solicitaste este registro, puedes ignorar este email.',
            );

            // Mostrar SweetAlert de éxito
            AlertService.showSuccess(
              context,
              'Registro Exitoso',
              'Tu cuenta ha sido creada exitosamente.\n\n'
              'La contraseña temporal ha sido enviada a:\n$email\n\n'
              'IMPORTANTE: Debes cambiar esta contraseña en tu primer inicio de sesión.',
              onOk: () {
                Navigator.pop(context); // Volver al login
              },
            );
          } catch (emailError) {
            // Si falla el email, aún permitir continuar
            AlertService.showWarning(
              context,
              'Registro Exitoso',
              'Tu cuenta ha sido creada exitosamente.\n\n'
              'Sin embargo, hubo un error al enviar el email con tu contraseña temporal.\n\n'
              'Error: $emailError\n\n'
              'Por favor, contacta al administrador para obtener tus credenciales.',
              onOk: () {
                Navigator.pop(context); // Volver al login
              },
            );
          }
        } else {
          throw Exception(result['message'] ?? 'Error desconocido');
        }
      } catch (e) {
        AlertService.showError(
          context,
          'Error al Registrar',
          'No se pudo registrar el estudiante: $e',
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }



  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Registro de Estudiante',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Crea tu cuenta para acceder a la plataforma educativa',
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

              // Formulario
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información Personal',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 24),
                              
                              // Nombre completo
                              TextFormField(
                                controller: _fullNameController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre Completo *',
                                  prefixIcon: Icon(Icons.person, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El nombre completo es obligatorio';
                                  }
                                  
                                  // Limpiar espacios extra y dividir en palabras
                                  final cleanValue = value.trim().replaceAll(RegExp(r'\s+'), ' ');
                                  final words = cleanValue.split(' ');
                                  
                                  // Validar que tenga al menos 2 palabras (nombre y apellido)
                                  if (words.length < 2) {
                                    return 'Debe incluir nombre y al menos un apellido';
                                  }
                                  
                                  // Validar que cada palabra tenga al menos 2 caracteres
                                  for (String word in words) {
                                    if (word.length < 2) {
                                      return 'Cada parte del nombre debe tener al menos 2 caracteres';
                                    }
                                  }
                                  
                                  // Validar que no contenga números
                                  if (RegExp(r'[0-9]').hasMatch(cleanValue)) {
                                    return 'El nombre no puede contener números';
                                  }
                                  
                                  // Validar que no contenga caracteres especiales
                                  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(cleanValue)) {
                                    return 'El nombre no puede contener caracteres especiales';
                                  }
                                  
                                  // Validar longitud total mínima
                                  if (cleanValue.length < 5) {
                                    return 'El nombre completo debe tener al menos 5 caracteres';
                                  }
                                  
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Email
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Correo Electrónico *',
                                  prefixIcon: Icon(Icons.email, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El email es obligatorio';
                                  }
                                  // Validar formato de email correctamente
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Ingresa un email válido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Teléfono
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Teléfono *',
                                  prefixIcon: Icon(Icons.phone, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El teléfono es obligatorio';
                                  }
                                  // Validar que solo contenga números
                                  final phoneRegex = RegExp(r'^[0-9]+$');
                                  if (!phoneRegex.hasMatch(value)) {
                                    return 'El teléfono solo puede contener números';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Documento de identidad
                              TextFormField(
                                controller: _documentController,
                                decoration: InputDecoration(
                                  labelText: 'Documento de Identidad *',
                                  prefixIcon: Icon(Icons.badge, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El documento es obligatorio';
                                  }
                                  // Validar que solo contenga números
                                  final documentRegex = RegExp(r'^[0-9]+$');
                                  if (!documentRegex.hasMatch(value)) {
                                    return 'El documento solo puede contener números';
                                  }
                                  if (value.length < 6) {
                                    return 'El documento debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Fecha de nacimiento
                              TextFormField(
                                controller: _birthDateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Fecha de Nacimiento *',
                                  hintText: 'Selecciona tu fecha de nacimiento',
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                onTap: _selectBirthDate,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'La fecha de nacimiento es obligatoria';
                                  }
                                  if (_selectedBirthDate == null) {
                                    return 'Selecciona una fecha válida';
                                  }
                                  // Validar que la fecha no sea después de hoy
                                  final today = DateTime.now();
                                  if (_selectedBirthDate!.isAfter(today)) {
                                    return 'La fecha de nacimiento no puede ser después de hoy';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Dirección
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: 'Dirección (opcional)',
                                  prefixIcon: Icon(Icons.location_on, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                maxLines: 2,
                                validator: (value) {
                                  // Si hay contenido, debe tener al menos 10 caracteres
                                  if (value != null && value.isNotEmpty && value.length < 10) {
                                    return 'La dirección debe tener al menos 10 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Botón de registro
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
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          'Registrarse',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Enlace de login
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    '¿Ya tienes cuenta? Inicia sesión aquí',
                                    style: TextStyle(
                                      color: Color(0xff6C4DDC),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
