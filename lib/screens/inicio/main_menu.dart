import 'package:flutter/material.dart';
import 'login_with_institution.dart';
import 'guest_page.dart';
import 'student_registration.dart';
import '../../header/HeaderHome.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Breakpoint más estándar y responsive
            final isWeb = constraints.maxWidth > 600;
            
            return Stack(
              children: [
                // Contenido principal (sin botones web)
                Column(
                  children: [
                    // Headers fijos como fondo
                    HeaderHome(),
                    
                    // Contenido principal con scroll
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // Logo
                            _buildLogo(),
                            const SizedBox(height: 24),

                            // Título principal
                            _buildMainTitle(),
                            const SizedBox(height: 12),

                            // Descripción principal
                            _buildDescription(),
                            const SizedBox(height: 40),

                            // Botones según plataforma
                            if (!isWeb) // Solo mostrar botones móviles cuando NO sea web
                              _buildMobileButtons(context),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // BOTONES WEB: posicionados absolutamente (solo web)
                if (isWeb) _buildWebNavigationButtons(context),
              ],
            );
          },
        ),
      ),
    );
  }

  // Método para construir el logo
  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Image.asset(
        'assets/images/logodegrado.PNG',
        width: 250,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  // Método para construir el título principal
  Widget _buildMainTitle() {
    return const Text(
      'Bienvenido a Certiblock',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Color(0xff2E2F44),
      ),
      textAlign: TextAlign.center,
    );
  }

  // Método para construir la descripción
  Widget _buildDescription() {
    return const Text(
      'Esta plataforma permite registrar y validar certificados académicos a través de la tecnología Blockchain, garantizando seguridad y trazabilidad.',
      style: TextStyle(fontSize: 16, color: Colors.black54),
      textAlign: TextAlign.center,
    );
  }


  // Método para construir botones móviles
  Widget _buildMobileButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6C4DDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: Colors.black26,
            ),
            onPressed: () => _navigateToLogin(context),
            child: const Text(
              'Iniciar Sesión',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xff6C4DDC), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _navigateToRegister(context),
            child: const Text(
              'Registrarse',
              style: TextStyle(fontSize: 18, color: Color(0xff6C4DDC)),
            ),
          ),
        ),
      ],
    );
  }

  // Método para construir botones de navegación web (posicionados absolutamente)
  Widget _buildWebNavigationButtons(BuildContext context) {
    return Positioned(
      top: 20.0,
      right: 24.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 200, 190, 233),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: Colors.black26,
            ),
            onPressed: () => _navigateToLogin(context),
            child: const Text('Iniciar Sesión'),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xff6C4DDC), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _navigateToRegister(context),
            child: const Text(
              'Registrarse',
              style: TextStyle(color: Color(0xff6C4DDC)),
            ),
          ),
        ],
      ),
    );
  }

  // Método para navegar al login
  void _navigateToLogin(BuildContext context) {
    print('=== NAVEGACIÓN: Iniciar Sesión ===');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginWithInstitution()),
    );
  }

  // Método para navegar al registro (ambos tipos van al mismo lugar)
  void _navigateToRegister(BuildContext context) {
    print('=== NAVEGACIÓN: Registro ===');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GuestPage()),
    );
  }
}
