import 'package:flutter/material.dart';

class HeaderHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.35, // 35% de la pantalla
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
    final paint = Paint()
      ..color = const Color(0xff373851)
      ..style = PaintingStyle.fill
      ..strokeWidth = 5;

    final path = Path();
    path.lineTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.62,
        size.width * 0.6, size.height * 0.45);
    path.quadraticBezierTo(
        size.width * 0.8, size.height * 0.35, size.width, size.height * 0.39);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HeaderHomeNaranja extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.12, // 12% de la pantalla
      width: double.infinity,
      child: CustomPaint(
        painter: _HeaderPainterNaranja(),
      ),
    );
  }
}

class _HeaderPainterNaranja extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(0, 255, 255, 255)
      ..style = PaintingStyle.fill
      ..strokeWidth = 5;

    final path = Path();
    path.moveTo(size.width * 0.7, 0);
    path.quadraticBezierTo(
        size.width * 0.7, size.height * 1.0, size.width, size.height * 1.0);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HeaderHomeMorado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.08, // 8% de la pantalla
      width: double.infinity,
      child: CustomPaint(
        painter: _HeaderPainterMorado(),
      ),
    );
  }
}

class _HeaderPainterMorado extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(0, 255, 255, 255)
      ..style = PaintingStyle.fill
      ..strokeWidth = 5;

    final path = Path();
    path.moveTo(size.width * 0.3, 0);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.8,
        size.width * 0.6, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.6, size.width, size.height * 1);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
