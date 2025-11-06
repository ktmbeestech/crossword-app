import 'package:flutter/material.dart';

class GlowingWordWidgets extends StatefulWidget {
  final double width;
  final double height;
  const GlowingWordWidgets({super.key, this.width = 220, this.height = 140});

  @override
  State<GlowingWordWidgets> createState() => _GlowingWordWidgetsState();
}

class _GlowingWordWidgetsState extends State<GlowingWordWidgets> with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _animationScale;
  late Animation<double> _glowOpacity;




  @override
  void initState() {
    super.initState();

    // Initialize controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize animations
    _animationScale = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _glowOpacity = Tween<double>(begin: 0.1, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animationScale,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: CustomPaint(
              painter: _OvalGlowPainter(
                glowOpacity: _glowOpacity.value,
                phase: _animationController.value,
              ),
              child: Center(
                child: Text(
                  'Word\nExplorer',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OvalGlowPainter extends CustomPainter {
  final double glowOpacity;
  final double phase; // 0..1, used to rotate the sweep gradient for shimmer
  _OvalGlowPainter({required this.glowOpacity, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ovalRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Background fill with subtle gradient clipped to oval
    final clipPath = Path()..addOval(ovalRect);
    canvas.save();
    canvas.clipPath(clipPath);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF131A4F), Color(0xFF0B1037)],
      ).createShader(rect);
    canvas.drawOval(ovalRect, bgPaint);

    // Mirror-like radial highlight inside the oval
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.6),
        radius: 0.9,
        colors: [Colors.white.withOpacity(0.18), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawOval(ovalRect, highlightPaint);
    canvas.restore();

    // Outer glow (blurred stroke)
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 16);
    canvas.drawOval(ovalRect.deflate(5), glowPaint);

    // Shimmering ring using a rotating sweep gradient
    final sweep = SweepGradient(
      colors: [
        Colors.white.withOpacity(0.10),
        const Color(0xFFBFD4FF).withOpacity(0.45),
        Colors.white.withOpacity(0.85), // specular peak
        const Color(0xFFD6E6FF).withOpacity(0.35),
        Colors.white.withOpacity(0.10),
      ],
      stops: const [0.00, 0.25, 0.40, 0.60, 1.00],
      // rotate around based on phase for subtle movement
      transform: GradientRotation(phase * 6.283185307179586),
    ).createShader(ovalRect);

    final ringPaint = Paint()
      ..shader = sweep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawOval(ovalRect.deflate(2), ringPaint);

    // Add a couple of soft highlight arcs to enhance shine
    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final rectDef = ovalRect.deflate(3);
    // short arc at ~10 o'clock
    canvas.drawArc(rectDef, -2.4 + phase * 0.1, 0.7, false, arcPaint);
    // short arc at ~4 o'clock
    canvas.drawArc(rectDef, 0.6 + phase * 0.1, 0.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _OvalGlowPainter oldDelegate) {
    return oldDelegate.glowOpacity != glowOpacity || oldDelegate.phase != phase;
  }
}
