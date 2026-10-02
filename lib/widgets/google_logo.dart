import 'package:flutter/material.dart';

/// Un widget ligero que dibuja el logotipo oficial de Google utilizando CustomPainter.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Colores oficiales del isotipo de Google
    final red = Paint()..color = const Color(0xFFEA4335);
    final blue = Paint()..color = const Color(0xFF4285F4);
    final green = Paint()..color = const Color(0xFF34A853);
    final yellow = Paint()..color = const Color(0xFFFBBC05);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Arco Rojo (Superior)
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -2.356, 1.571, false)
      ..close();
    canvas.drawPath(redPath, red);

    // Arco Amarillo (Izquierdo)
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -3.927, 1.571, false)
      ..close();
    canvas.drawPath(yellowPath, yellow);

    // Arco Verde (Inferior)
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 0.785, 1.571, false)
      ..close();
    canvas.drawPath(greenPath, green);

    // Arco Azul (Derecho)
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -0.785, 1.571, false)
      ..close();
    canvas.drawPath(bluePath, blue);

    // Centro blanco recortado
    final innerWhite = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.58, innerWhite);

    // Barra azul horizontal derecha
    final barRect = Rect.fromLTRB(
      center.dx,
      center.dy - radius * 0.22,
      w,
      center.dy + radius * 0.22,
    );
    canvas.drawRect(barRect, blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
