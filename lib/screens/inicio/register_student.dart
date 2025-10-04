import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:frontend_app/screens/inicio/set_password_page.dart';
import '../../services/student_id_generator.dart';

class RegisterStudent extends StatefulWidget {
  const RegisterStudent({super.key});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  final _formKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  late String _userId;

  String generateVerificationCode() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
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
      final code = generateVerificationCode();

      try {
        // Verificar si el email ya existe
        final existingQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este email ya está registrado'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Generar ID de estudiante único automáticamente
        final studentId = await StudentIdGenerator.generateStudentId();

        final docRef = FirebaseFirestore.instance.collection('users').doc();
        _userId = docRef.id;

        await docRef.set({
          'fullName': fullName,
          'email': email,
          'studentId': studentId,
          'phone': phone,
          'createdAt': Timestamp.now(),
          'verificationCode': code,
          'isVerified': false,
          'role': 'student',
          'mustChangePassword': false,
          'isTemporaryPassword': false,
          'status': 'active',
        });

        await sendEmail(
          name: fullName,
          email: email,
          message: 'Hola $fullName,\n\nTu código de verificación es: $code\n\nTu ID de estudiante es: $studentId\n\nSi tú no solicitaste este registro, ignora este mensaje.\n\n¡Bienvenido a nuestra plataforma educativa!',
        );

        setState(() => _codeSent = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registro exitoso. Revisa tu correo para el código de verificación.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no encontrado')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final storedCode = doc.data()?['verificationCode'];
        if (storedCode == _verificationCodeController.text.trim()) {
          await FirebaseFirestore.instance.collection('users').doc(_userId).update({'isVerified': true});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verificación exitosa. Redirigiendo...')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SetPasswordPage(userId: _userId)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código incorrecto')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
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
                  child: !_codeSent
                      ? Form(
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
                                    return 'El nombre es obligatorio';
                                  }
                                  if (value.length < 2) {
                                    return 'El nombre debe tener al menos 2 caracteres';
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
                                  if (!value.contains('@') || !value.contains('.')) {
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
                                  labelText: 'Teléfono (Opcional)',
                                  prefixIcon: Icon(Icons.phone, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  hintText: 'Ej: +57 300 123 4567',
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 32),
                              
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
                        )
                      : Form(
                          key: _codeFormKey,
                          child: Column(
                            children: [
                              Icon(
                                Icons.mark_email_read,
                                size: 64,
                                color: Color(0xff6C4DDC),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Verificación de Email',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff2E2F44),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Hemos enviado un código de verificación a tu correo electrónico',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 32),
                              TextFormField(
                                controller: _verificationCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Código de Verificación *',
                                  prefixIcon: Icon(Icons.security, color: Color(0xff6C4DDC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  hintText: 'Ingresa el código de 6 dígitos',
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa el código de verificación';
                                  }
                                  if (value.length != 6) {
                                    return 'El código debe tener 6 dígitos';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _verifyCode,
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
                                          'Verificar Código',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() => _codeSent = false);
                                },
                                child: Text(
                                  'Cambiar email',
                                  style: TextStyle(
                                    color: Color(0xff6C4DDC),
                                    fontWeight: FontWeight.w500,
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
