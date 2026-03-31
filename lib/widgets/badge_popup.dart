import 'dart:math';
import 'package:flutter/material.dart';

class BadgePopup extends StatefulWidget {
  final String badgeName;
  final String badgeDescription;
  final String icon;
  final String colorPrimary;
  final String colorSecondary;
  final VoidCallback onDismiss;

  const BadgePopup({
    super.key,
    required this.badgeName,
    required this.badgeDescription,
    required this.icon,
    required this.colorPrimary,
    required this.colorSecondary,
    required this.onDismiss,
  });

  @override
  State<BadgePopup> createState() => _BadgePopupState();
}

Color _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class _BadgePopupState extends State<BadgePopup> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shineController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnim;
  late Animation<double> _shineAnim;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _shineAnim = CurvedAnimation(
      parent: _shineController,
      curve: Curves.easeInOut,
    );
    _particleAnim = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _shineController.repeat(reverse: true);
      _particleController.repeat();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shineController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // // Badge config per course
  // Map<String, dynamic> get _badgeConfig {
  //   switch (widget.courseId) {
  //     case 7:
  //       return {
  //         'icon': '🕌',
  //         'gradient': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
  //         'shine': const Color(0xFFFFFFAA),
  //         'glow': const Color(0xFFFFD700),
  //         'stars': [
  //           const Color(0xFFFFD700),
  //           const Color(0xFFFFF8DC),
  //           const Color(0xFFFFA500),
  //         ],
  //       };
  //     case 8:
  //       return {
  //         'icon': '📖',
  //         'gradient': [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
  //         'shine': const Color(0xFFAAFFAA),
  //         'glow': const Color(0xFF4CAF50),
  //         'stars': [
  //           const Color(0xFF4CAF50),
  //           const Color(0xFFE8F5E9),
  //           const Color(0xFF2E7D32),
  //         ],
  //       };
  //     default:
  //       return {
  //         'icon': '⭐',
  //         'gradient': [const Color(0xFF9C27B0), const Color(0xFF673AB7)],
  //         'shine': const Color(0xFFEEAAFF),
  //         'glow': const Color(0xFF9C27B0),
  //         'stars': [
  //           const Color(0xFF9C27B0),
  //           const Color(0xFFF3E5F5),
  //           const Color(0xFF673AB7),
  //         ],
  //       };
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final primary = _hexToColor(widget.colorPrimary);
    final secondary = _hexToColor(widget.colorSecondary);
    final gradientColors = [primary, secondary];
    final glowColor = primary;
    final starColors = [primary, Colors.white, secondary];

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss when tapping card
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Particle burst
                  AnimatedBuilder(
                    animation: _particleAnim,
                    builder: (_, __) => CustomPaint(
                      size: const Size(300, 300),
                      painter: _ParticlePainter(
                        progress: _particleAnim.value,
                        colors: starColors,
                      ),
                    ),
                  ),

                  // Main card
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: glowColor.withOpacity(0.2),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge medal
                        AnimatedBuilder(
                          animation: _shineAnim,
                          builder: (_, __) => Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Color.lerp(
                                    gradientColors[0],
                                    Colors.white,
                                    _shineAnim.value * 0.4,
                                  )!,
                                  gradientColors[0],
                                  gradientColors[1],
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withOpacity(
                                      0.4 + _shineAnim.value * 0.3),
                                  blurRadius: 20 + _shineAnim.value * 15,
                                  spreadRadius: 2 + _shineAnim.value * 4,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Shine sweep
                                AnimatedBuilder(
                                  animation: _shineAnim,
                                  builder: (_, __) => CustomPaint(
                                    size: const Size(120, 120),
                                    painter: _ShinePainter(
                                      progress: _shineAnim.value,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.icon,
                                  style: const TextStyle(fontSize: 52),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Rays
                        AnimatedBuilder(
                          animation: _shineAnim,
                          builder: (_, __) => CustomPaint(
                            size: const Size(160, 20),
                            painter: _RayPainter(
                              progress: _shineAnim.value,
                              color: gradientColors[0],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Badge unlocked label
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'BADGE UNLOCKED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          widget.badgeName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: gradientColors[1],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          widget.badgeDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Claim button
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              '🎉  Claim Badge',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Particle burst painter
class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _ParticlePainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42);
    final paint = Paint();

    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * pi + progress * pi;
      final distance = 80 + random.nextDouble() * 60;
      final radius = 3 + random.nextDouble() * 5;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      paint.color = colors[i % colors.length].withOpacity(opacity);

      final x = center.dx + cos(angle) * distance * progress;
      final y = center.dy + sin(angle) * distance * progress;

      canvas.drawCircle(Offset(x, y), radius * (1 - progress * 0.5), paint);

      // Star shapes
      if (i % 3 == 0) {
        paint.color = Colors.white.withOpacity(opacity * 0.8);
        canvas.drawCircle(
            Offset(x + 10, y - 10), radius * 0.5 * (1 - progress * 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// Shine sweep painter
class _ShinePainter extends CustomPainter {
  final double progress;
  _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.6 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.progress != progress;
}

// Ray painter
class _RayPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RayPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.4 * progress)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final start = Offset(
        center.dx + cos(angle) * 10,
        center.dy + sin(angle) * 10,
      );
      final end = Offset(
        center.dx + cos(angle) * (20 + progress * 15),
        center.dy + sin(angle) * (20 + progress * 15),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_RayPainter old) => old.progress != progress;
}
