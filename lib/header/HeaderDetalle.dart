import 'package:flutter/material.dart';

class HeaderDetalle extends StatelessWidget 
{
  

  @override
  Widget build(BuildContext context)
  {
    return Container(
        height: 90,
        width: double.infinity,
        child: CustomPaint(
          painter: _HeaderNaraja(),
        ),
    );
  }
}

class _HeaderNaraja extends CustomPainter
{

  @override
  void paint(Canvas canvas, Size size) 
  {
      final paint = new Paint();

      paint.color = Color(0xffED6948);
      paint.style = PaintingStyle.fill;
      paint.strokeWidth = 5;

      final path = new Path();
      path.lineTo( 0, size.height * 1.0 );
      path.quadraticBezierTo( size.width * 0.2 , size.height *  1.0, size.width * 0.3 , size.height * 0.45 );
      path.lineTo( size.width * 0.4 , 0 );

      canvas.drawPath(path, paint);
  }
  
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class HeaderDetalleMorado extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return Container(
        height: 95,
        width: double.infinity,
        child: CustomPaint(
          painter: _HeaderPainterMorado(),
        ),
    );
  }
}

class _HeaderPainterMorado extends CustomPainter
{
  @override
  void paint(Canvas canvas, Size size)
  {
      final paint = new Paint();

      paint.color = Color(0xff6C4DDC);
      paint.style = PaintingStyle.fill;
      paint.strokeWidth = 5;

      final path = new Path();
      path.moveTo( size.width * 0.2 , 0);
      path.quadraticBezierTo( size.width * 0.3 , size.height * 0.8 , size.width * 0.6 , size.height * 0.7 );
      path.quadraticBezierTo( size.width * 0.9 , size.height * 0.6 , size.width , size.height * 1 );
      path.lineTo( size.width , 0);

      canvas.drawPath(path, paint);
  }
  
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;   
}