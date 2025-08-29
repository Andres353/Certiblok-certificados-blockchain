import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:frontend_app/screens/set_password_page.dart';
import '../header/HeaderRegisterStudent.dart'; // Importa tu header

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
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
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
      final ci = _ciController.text.trim();
      final institution = _institutionController.text.trim();
      final code = generateVerificationCode();

      try {
        final docRef = FirebaseFirestore.instance.collection('students').doc();
        _userId = docRef.id;

        await docRef.set({
          'fullName': fullName,
          'email': email,
          'ci': ci,
          'institution': institution,
          'createdAt': Timestamp.now(),
          'verificationCode': code,
          'isVerified': false,
          'role': 'student',
        });

        await sendEmail(
          name: fullName,
          email: email,
          message: 'Hola $fullName,\nTu código de verificación es: $code\n\nSi tú no solicitaste este registro, ignora este mensaje.',
        );

        setState(() => _codeSent = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso. Revisa tu correo para el código.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final doc = await FirebaseFirestore.instance.collection('students').doc(_userId).get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no encontrado')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final storedCode = doc.data()?['verificationCode'];
        if (storedCode == _verificationCodeController.text.trim()) {
          await FirebaseFirestore.instance.collection('students').doc(_userId).update({'isVerified': true});

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // HEADER
          const HeaderRegisterStudent(),

          // FORMULARIO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: !_codeSent
                  ? Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(labelText: 'Nombre completo'),
                            validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Correo electrónico'),
                            validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ciController,
                            decoration: const InputDecoration(labelText: 'Cédula de identidad'),
                            validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _institutionController,
                            decoration: const InputDecoration(labelText: 'Institución'),
                            validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registerStudent,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Registrar'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Form(
                      key: _codeFormKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Ingresa el código de verificación que recibiste en tu correo',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _verificationCodeController,
                            decoration: const InputDecoration(labelText: 'Código de verificación'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty ? 'Ingresa el código de verificación' : null,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyCode,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Verificar código'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
