import 'package:flutter/material.dart';

class HeaderHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.35, // altura total del header
      width: double.infinity,
      child: CustomPaint(
        painter: _HeaderHomePainter(),
      ),
    );
  }
}

class _HeaderHomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ================= Header principal =================
    final paintPrincipal = Paint()
      ..color = const Color(0xff373851)
      ..style = PaintingStyle.fill;

    final pathPrincipal = Path();
    pathPrincipal.lineTo(0, size.height * 0.6);
    pathPrincipal.quadraticBezierTo(
        size.width * 0.2, size.height * 0.62, size.width * 0.6, size.height * 0.45);
    pathPrincipal.quadraticBezierTo(
        size.width * 0.8, size.height * 0.35, size.width, size.height * 0.38);
    pathPrincipal.lineTo(size.width, 0);
    canvas.drawPath(pathPrincipal, paintPrincipal);

    // ================= Header naranja =================
    final paintNaranja = Paint()
      ..color = const Color(0xffED6948)
      ..style = PaintingStyle.fill;

    final pathNaranja = Path();
    pathNaranja.moveTo(0, size.height * 0.5);
    pathNaranja.quadraticBezierTo(
        size.width * 0.9, size.height * 0.55, size.width, size.height * 0.42);
    pathNaranja.lineTo(size.width, 0);
    pathNaranja.lineTo(0, 0);
    canvas.drawPath(pathNaranja, paintNaranja);

    // ================= Header morado =================
    final paintMorado = Paint()
      ..color = const Color(0xff6C4DDC)
      ..style = PaintingStyle.fill;

    final pathMorado = Path();
    pathMorado.moveTo(0, size.height * 0.55);
    pathMorado.quadraticBezierTo(
        size.width * 0.3, size.height * 0.35, size.width, size.height * 0.45);
    pathMorado.lineTo(size.width, 0);
    pathMorado.lineTo(0, 0);
    canvas.drawPath(pathMorado, paintMorado);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
