import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HeaderLogAs extends StatelessWidget {
  const HeaderLogAs({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.35, // altura total del header
      width: double.infinity,
      child: Stack(
        children: [
          // Fondo morado (capa inferior)
          SizedBox.expand(
            child: CustomPaint(
              painter: _HeaderPainterMorado(),
            ),
          ),

          // Fondo naranja (capa superior pero más abajo)
          SizedBox.expand(
            child: CustomPaint(
              painter: _HeaderPainterNaranja(),
            ),
          ),

          // Texto animado en el centro superior
         Positioned(
  top: screenHeight * 0.08, // menos margen desde arriba, más centrado
  left: 0,
  right: 0,
  child: Center(
    child: FittedBox(
      fit: BoxFit.scaleDown, // ajusta el texto al ancho disponible
      child: DefaultTextStyle(
        style: GoogleFonts.lato(
          textStyle: const TextStyle(
            fontSize: 28, // un poco más pequeño
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0, // menos espacio entre letras
          ),
        ),
        child: AnimatedTextKit(
          animatedTexts: [
            TyperAnimatedText(
              'BIENVENIDO',
              speed: const Duration(milliseconds: 120),
            ),
          ],
          repeatForever: false,
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
        ),
      ),
    ),
  ),
),

        ],
      ),
    );
  }
}

// ==================== PAINTER MORADO ====================
class _HeaderPainterMorado extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xff6C4DDC), const Color(0xff8A6FF1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.5, size.height, size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== PAINTER NARANJA ====================
class _HeaderPainterNaranja extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color.fromARGB(255, 140, 9, 247), const Color(0xffFFB374)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.9); // más abajo que el morado
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 1.1, size.width, size.height * 0.9);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
