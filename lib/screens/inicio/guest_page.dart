import 'package:flutter/material.dart';
import 'register_student.dart';
import 'register_inst.dart';
import '../../header/HeaderLogAs.dart'; // importa tu header

class GuestPage extends StatelessWidget {
  const GuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff6C4DDC), Color(0xff8A6FF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con animación del tecleo
            HeaderLogAs(),

            // Contenido principal con diseño mejorado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Tarjeta para Estudiante
                  _buildOptionCard(
                    context: context,
                    title: 'Estudiante',
                    subtitle: 'Soy un estudiante que desea recibir certificados digitales',
                    icon: Icons.school,
                    imageAsset: 'assets/images/graduado.png',
                    isPrimary: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterStudent()),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tarjeta para Institución
                  _buildOptionCard(
                    context: context,
                    title: 'Institución Educativa',
                    subtitle: 'Soy una institución que desea emitir certificados',
                    icon: Icons.business,
                    imageAsset: 'assets/images/institucion.png',
                    isPrimary: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterInst()),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xff6C4DDC).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xff6C4DDC),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Una vez registrado, podrás acceder a todas las funcionalidades de CertiBlock',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff6C4DDC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String imageAsset,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isPrimary ? Color(0xff6C4DDC).withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Contenedor del icono/imagen
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? Color(0xff6C4DDC).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPrimary 
                          ? Color(0xff6C4DDC).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Icono de fondo
                      Icon(
                        icon,
                        size: 32,
                        color: isPrimary 
                            ? Color(0xff6C4DDC).withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                      // Imagen superpuesta
                      Image.asset(
                        imageAsset,
                        height: 40,
                        width: 40,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Contenido de texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icono de flecha
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? Color(0xff6C4DDC)
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
