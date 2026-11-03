import 'dart:math';
import 'package:flutter/material.dart';



class BellRingsPage extends StatefulWidget {
  const BellRingsPage({super.key});

  @override
  State<BellRingsPage> createState() => _BellRingsPageState();
}

class _BellRingsPageState extends State<BellRingsPage>
    with TickerProviderStateMixin {
  late AnimationController _swingController;
  late AnimationController _rippleController;
  late AnimationController _glowController;

  late Animation<double> _swingAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _glowAnim;

  bool _isRinging = false;
  int _ringCount = 0;

  @override
  void initState() {
    super.initState();

    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swingAnim = Tween<double>(begin: -0.35, end: 0.35).animate(
      CurvedAnimation(parent: _swingController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _swingController.addStatusListener((status) {
      if (_isRinging) {
        if (status == AnimationStatus.completed) {
          _swingController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _ringCount++;
          if (_ringCount < 6) {
            _swingController.forward();
            _rippleController.forward(from: 0.0);
          } else {
            setState(() {
              _isRinging = false;
              _ringCount = 0;
            });
            _glowController.reverse();
          }
        }
      }
    });
  }

  void _ringBell() {
    if (_isRinging) return;
    setState(() {
      _isRinging = true;
      _ringCount = 0;
    });
    _swingController.forward();
    _rippleController.forward(from: 0.0);
    _glowController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _swingController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1208),
      body: Stack(
        children: [
          // Background texture gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color.fromARGB(255, 12, 78, 93),
                  Color.fromARGB(255, 132, 161, 166),
                ],
              ),
            ),
          ),

          // Decorative grid lines
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GridPainter(),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  'RING THE BELL',
                  style: TextStyle(
                    color: Color(0xFFD4A843),
                    fontSize: 13,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Notify the World',
                  style: TextStyle(
                    color: Color(0xFFF5E6C8),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 64),

                // Bell with ripple
                GestureDetector(
                  onTap: _ringBell,
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple rings
                        AnimatedBuilder(
                          animation: _rippleAnim,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(240, 240),
                              painter: _RipplePainter(_rippleAnim.value),
                            );
                          },
                        ),

                        // Glow behind bell
                        AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (context, _) {
                            return Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4A843)
                                        .withOpacity(0.45 * _glowAnim.value),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Bell swing
                        AnimatedBuilder(
                          animation: _swingAnim,
                          builder: (context, child) {
                            return Transform(
                              alignment: Alignment.topCenter,
                              transform: Matrix4.rotationZ(
                                _isRinging ? _swingAnim.value * 0.25 : 0,
                              ),
                              child: child,
                            );
                          },
                          child: CustomPaint(
                            size: const Size(120, 120),
                            painter: _BellPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Tap hint
                AnimatedOpacity(
                  opacity: _isRinging ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFD4A843).withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'TAP TO RING',
                        style: TextStyle(
                          color: Color(0xFFD4A843),
                          fontSize: 11,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                AnimatedOpacity(
                  opacity: _isRinging ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Text(
                    '🔔  DING DONG!',
                    style: TextStyle(
                      color: Color(0xFFF5E6C8),
                      fontSize: 22,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom ornament
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ornamentDash(),
                const SizedBox(width: 12),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD4A843),
                  ),
                ),
                const SizedBox(width: 12),
                _ornamentDash(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ornamentDash() => Container(
        width: 60,
        height: 1,
        color: const Color(0xFFD4A843).withOpacity(0.4),
      );
}

// ─── Bell Painter 
class _BellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Bell body gradient
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [Color(0xFFF0C254), Color(0xFFC8861A)],
      ).createShader(Rect.fromLTWH(cx - 50, cy - 50, 100, 100));

    final highlightPaint = Paint()
      ..color = const Color(0xFFFFF4CC).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = const Color(0xFFAA6A10)
      ..style = PaintingStyle.fill;

    final clapperPaint = Paint()
      ..color = const Color(0xFF8B4A0A)
      ..style = PaintingStyle.fill;

    final hanger = Paint()
      ..color = const Color(0xFFD4A843)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Hanger loop
    canvas.drawLine(Offset(cx, cy - 54), Offset(cx, cy - 44), hanger);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 54), width: 16, height: 14),
      pi,
      pi,
      false,
      hanger,
    );

    // Bell body (rounded trapezoid via path)
    final bell = Path();
    bell.moveTo(cx - 10, cy - 44);
    bell.cubicTo(cx - 42, cy - 30, cx - 54, cy + 4, cx - 50, cy + 30);
    bell.lineTo(cx + 50, cy + 30);
    bell.cubicTo(cx + 54, cy + 4, cx + 42, cy - 30, cx + 10, cy - 44);
    bell.close();
    canvas.drawPath(bell, bodyPaint);

    // Highlight
    final highlight = Path();
    highlight.moveTo(cx - 8, cy - 40);
    highlight.cubicTo(cx - 28, cy - 22, cx - 34, cy, cx - 26, cy + 18);
    highlight.cubicTo(cx - 16, cy + 4, cx - 14, cy - 16, cx - 6, cy - 38);
    highlight.close();
    canvas.drawPath(highlight, highlightPaint);

    // Rim
    final rim = Path();
    rim.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 52, cy + 28, 104, 12),
      const Radius.circular(6),
    ));
    canvas.drawPath(rim, rimPaint);

    // Clapper
    canvas.drawCircle(Offset(cx, cy + 30), 7, clapperPaint);
    canvas.drawLine(Offset(cx, cy + 4), Offset(cx, cy + 30), clapperPaint..strokeWidth = 4..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Ripple Painter 
class _RipplePainter extends CustomPainter {
  final double progress;
  _RipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final delay = i * 0.25;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final radius = 70 + t * 90;
      final opacity = (1.0 - t) * 0.5;
      final paint = Paint()
        ..color = const Color(0xFFD4A843).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}

// ─── Grid Painter 
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843).withOpacity(0.04)
      ..strokeWidth = 1;

    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}