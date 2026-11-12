import 'package:flutter/material.dart';

class PlatformBrandLogo extends StatelessWidget {
  final String platform;
  final double size;

  const PlatformBrandLogo({super.key, required this.platform, this.size = 24});

  @override
  Widget build(BuildContext context) {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Container(
          width: size + 10,
          height: size + 10,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: CustomPaint(painter: _TikTokLogoPainter()),
        );
      case 'twitch':
        return Container(
          width: size + 10,
          height: size + 10,
          decoration: BoxDecoration(
            color: const Color(0xFF9146FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(painter: _TwitchLogoPainter()),
        );
      case 'youtube':
        return Container(
          width: size + 10,
          height: size + 10,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(painter: _YouTubeLogoPainter()),
        );
      case 'kick':
      default:
        return Container(
          width: size + 10,
          height: size + 10,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E0F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF53FC18).withOpacity(0.4)),
          ),
          child: CustomPaint(painter: _KickLogoPainter()),
        );
    }
  }
}

class _TikTokLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void drawNote(Color color, double dx, double dy) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.11
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(w * 0.56 + dx, h * 0.24 + dy)
        ..lineTo(w * 0.56 + dx, h * 0.64 + dy)
        ..arcToPoint(Offset(w * 0.34 + dx, h * 0.66 + dy), radius: Radius.circular(w * 0.13), clockwise: true)
        ..arcToPoint(Offset(w * 0.48 + dx, h * 0.50 + dy), radius: Radius.circular(w * 0.13), clockwise: true);
      canvas.drawPath(path, p);
      final flag = Path()
        ..moveTo(w * 0.56 + dx, h * 0.25 + dy)
        ..quadraticBezierTo(w * 0.62 + dx, h * 0.37 + dy, w * 0.73 + dx, h * 0.37 + dy);
      canvas.drawPath(flag, p);
    }

    drawNote(const Color(0xFF25F4EE), -1.3, -1.0);
    drawNote(const Color(0xFFFE2C55), 1.3, 1.0);
    drawNote(Colors.white, 0, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TwitchLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final white = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final purple = Paint()..color = const Color(0xFF9146FF)..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(w * 0.26, h * 0.22)
      ..lineTo(w * 0.78, h * 0.22)
      ..lineTo(w * 0.78, h * 0.58)
      ..lineTo(w * 0.62, h * 0.72)
      ..lineTo(w * 0.48, h * 0.72)
      ..lineTo(w * 0.38, h * 0.82)
      ..lineTo(w * 0.38, h * 0.72)
      ..lineTo(w * 0.26, h * 0.72)
      ..close();
    canvas.drawPath(body, white);

    canvas.drawRect(Rect.fromLTWH(w * 0.45, h * 0.35, w * 0.07, h * 0.18), purple);
    canvas.drawRect(Rect.fromLTWH(w * 0.61, h * 0.35, w * 0.07, h * 0.18), purple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _YouTubeLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final white = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final play = Path()
      ..moveTo(w * 0.40, h * 0.30)
      ..lineTo(w * 0.70, h * 0.50)
      ..lineTo(w * 0.40, h * 0.70)
      ..close();
    canvas.drawPath(play, white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KickLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final green = Paint()..color = const Color(0xFF53FC18)..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.22, w * 0.15, h * 0.56), green);
    canvas.drawRect(Rect.fromLTWH(w * 0.43, h * 0.43, w * 0.12, h * 0.14), green);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.22, w * 0.15, h * 0.21), green);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.57, w * 0.15, h * 0.21), green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
