import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home_page.dart';
import '../../header/HeaderLogin.dart'; // tu header con los 3 layers
import 'login_with_institution.dart';

// ===================== LOGIN SCREEN =====================
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool isLoading = false;

  void login() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? role = await loginUser(emailCtrl.text, passwordCtrl.text);
      print('=== DEBUG LOGIN ===');
      print('Email: ${emailCtrl.text}');
      print('Rol retornado: $role');
      print('Tipo de rol: ${role.runtimeType}');
      
      if (role != null) {
        if (role == 'NEEDS_PASSWORD_CHANGE') {
          print('Usuario necesita cambiar contraseña - redirigiendo a login con contexto');
          // Redirigir al login con contexto para manejar cambio de contraseña
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginWithInstitution()),
          );
        } else {
          print('Navegando a HomePage con rol: $role');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(role: role)),
          );
        }
      } else {
        print('Rol es null - login falló');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Correo o contraseña incorrectos o usuario no registrado')),
        );
      }
    } catch (e) {
      print('Error en login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Headers de fondo
          Column(
            children: [
              HeaderHome(),
              
            ],
          ),

          // Contenido del login
          // Contenido del login
Positioned.fill(
  child: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      children: [
        const SizedBox(height: 180), // espacio para los headers

        // Imagen de perfil
        Center(
          child: CircleAvatar(
            radius: 50, // tamaño de la imagen
            backgroundImage: AssetImage('assets/images/perfil.png'),
          ),
        ),
        const SizedBox(height: 24),

        // Email
        TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Password
        TextField(
          controller: passwordCtrl,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 24),

        // Botón login
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6C4DDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading ? null : login,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    ),
  ),
),

        ],
      ),
    );
  }
}
