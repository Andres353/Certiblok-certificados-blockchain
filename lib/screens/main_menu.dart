import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'guest_page.dart';
import '../header/HeaderHome.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWeb = constraints.maxWidth > 800;

            return Stack(
              children: [
                // Headers fijos como fondo
                Column(
                  children: [
                    HeaderHome(),
                    HeaderHomeNaranja(),
                    HeaderHomeMorado(),
                  ],
                ),

                // BOTONES WEB: arriba a la derecha
                if (isWeb)
                  Positioned(
                    top: 20,
                    right: 24,
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GuestPage()),
                            );
                          },
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(color: Color(0xff6C4DDC)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Contenido principal con scroll
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: isWeb ? 40.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 180),

                        // Logo
                        Container(
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
                        ),
                        const SizedBox(height: 24),

                        // Título principal
                        const Text(
                          'Bienvenido a Certiblock',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E2F44),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Descripción principal
                        const Text(
                          'Esta plataforma permite registrar y validar certificados académicos a través de la tecnología Blockchain, garantizando seguridad y trazabilidad.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // MOBILE: botones abajo si no es web
                        if (!isWeb) ...[
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginScreen()),
                                );
                              },
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => GuestPage()),
                                );
                              },
                              child: const Text(
                                'Registrarse',
                                style: TextStyle(fontSize: 18, color: Color(0xff6C4DDC)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
