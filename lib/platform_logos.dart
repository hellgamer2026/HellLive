import 'package:flutter/material.dart';

class GoogleOfficialLogo extends StatelessWidget {
  final double size;
  const GoogleOfficialLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.42;
    final strokeW = w * 0.19;

    Paint arcPaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Vermelho (Topo)
    canvas.drawArc(rect, -2.45, 1.85, false, arcPaint(const Color(0xFFEA4335)));
    // Amarelo (Esquerda)
    canvas.drawArc(rect, 2.35, 1.48, false, arcPaint(const Color(0xFFFBBC05)));
    // Verde (Inferior)
    canvas.drawArc(rect, 0.72, 1.63, false, arcPaint(const Color(0xFF34A853)));
    // Azul (Direita + Barra horizontal do G)
    canvas.drawArc(rect, -0.05, 0.77, false, arcPaint(const Color(0xFF4285F4)));

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.50, h * 0.41, w * 0.42, strokeW),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlatformGlassTile extends StatelessWidget {
  final String platform;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const PlatformGlassTile({
    super.key,
    required this.platform,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  Color _accentColor() {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return const Color(0xFF25F4EE);
      case 'twitch':
        return const Color(0xFF9146FF);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'kick':
      default:
        return const Color(0xFF53FC18);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(isActive ? 0.18 : 0.10),
              accent.withOpacity(isActive ? 0.22 : 0.06),
              const Color(0xFF060E24).withOpacity(0.88),
            ],
          ),
          border: Border.all(
            color: isActive ? accent : Colors.white.withOpacity(0.18),
            width: isActive ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive ? accent.withOpacity(0.35) : Colors.black.withOpacity(0.45),
              blurRadius: isActive ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 8,
              right: 8,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.white.withOpacity(0.45), Colors.transparent],
                  ),
                ),
              ),
            ),
            if (isActive)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.8), blurRadius: 6)],
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlatformBrandLogo(platform: platform, size: 38),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.92),
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
}
class PlatformBrandLogo extends StatelessWidget {
  final String platform;
  final double size;

  const PlatformBrandLogo({super.key, required this.platform, this.size = 34});

  @override
  Widget build(BuildContext context) {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF25F4EE).withOpacity(0.5), width: 1.3),
            boxShadow: [BoxShadow(color: const Color(0xFFFE2C55).withOpacity(0.25), blurRadius: 8)],
          ),
          child: CustomPaint(painter: _TikTokLogoPainter()),
        );
      case 'twitch':
        return Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            color: const Color(0xFF9146FF),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFF9146FF).withOpacity(0.4), blurRadius: 8)],
          ),
          child: CustomPaint(painter: _TwitchLogoPainter()),
        );
      case 'youtube':
        return Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFFFF0000).withOpacity(0.4), blurRadius: 8)],
          ),
          child: CustomPaint(painter: _YouTubeLogoPainter()),
        );
      case 'kick':
      default:
        return Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF53FC18).withOpacity(0.6), width: 1.3),
            boxShadow: [BoxShadow(color: const Color(0xFF53FC18).withOpacity(0.25), blurRadius: 8)],
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

    drawNote(const Color(0xFF25F4EE), -1.4, -1.1);
    drawNote(const Color(0xFFFE2C55), 1.4, 1.1);
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
