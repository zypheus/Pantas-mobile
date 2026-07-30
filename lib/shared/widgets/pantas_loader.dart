import 'dart:math';
import 'package:flutter/material.dart';

/// A Flutter implementation of the pantasloader HTML canvas animation.
/// Draws an animated book with yellow pages fanning open from a navy spine,
/// with three dots below, looping every 1000ms.
class PantasLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const PantasLoader({
    super.key,
    this.size = 120,
    this.strokeWidth = 3.0,
  });

  @override
  State<PantasLoader> createState() => _PantasLoaderState();
}

class _PantasLoaderState extends State<PantasLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size * (340 / 580)),
          painter: _PantasLoaderPainter(
            progress: _controller.value,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _PantasLoaderPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _PantasLoaderPainter({
    required this.progress,
    required this.strokeWidth,
  });

  // Colors matching the HTML
  static const Color _gold = Color(0xFFFDBA2D);
  static const Color _navy = Color(0xFF05005A);

  // Geometry (scaled relative to the HTML canvas 580x340)
  static const double _W = 580;
  static const double _H = 340;
  static const double _SX = 290; // spine x
  static const double _SY = 236; // spine y
  static const double _BASE_Y = 240;
  static const double _BASE_H = 13;
  static const double _BASE_X1 = 110;
  static const double _BASE_X2 = 500;
  static const double _CLOSED = 100; // degrees

  // Stroke definitions (right side)
  static const List<_StrokeDef> _RIGHT = [
    _StrokeDef(angle: 13, len: 184, dl: 0.00),
    _StrokeDef(angle: 28, len: 200, dl: 0.16),
    _StrokeDef(angle: 46, len: 208, dl: 0.32),
    _StrokeDef(angle: 64, len: 194, dl: 0.48),
  ];

  // Left side: mirror angles
  static List<_StrokeDef> get _LEFT => _RIGHT
      .map((s) => _StrokeDef(
            angle: 180 - s.angle,
            len: s.len,
            dl: s.dl + 0.44,
          ))
      .toList();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.width / _W;
    canvas.scale(scale, scale);

    // Global fade in/out
    double ga = 1.0;
    if (progress < 0.05) {
      ga = progress / 0.05;
    } else if (progress > 0.90) {
      ga = (1.0 - (progress - 0.90) / 0.10).clamp(0.0, 1.0);
    }

    // LAYER 1: Closed book backdrop
    _drawClosedBook(canvas, (progress - 0.06) / 0.12, ga);

    // LAYER 2: Yellow page strokes (innermost first)
    for (int i = _RIGHT.length - 1; i >= 0; i--) {
      _drawStroke(canvas, _RIGHT[i], _rightProg(progress, _RIGHT[i].dl), ga);
    }
    for (int i = _LEFT.length - 1; i >= 0; i--) {
      _drawStroke(canvas, _LEFT[i], _leftProg(progress, _LEFT[i].dl), ga);
    }

    // LAYER 3: Navy base structure and dots
    double baseProg = _easeOut(((progress - 0.06) / 0.36).clamp(0.0, 1.0));
    _drawBase(canvas, baseProg, ga);

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, _StrokeDef s, double rawProg, double ga) {
    if (rawProg <= 0.005) return;
    double prog = rawProg.clamp(0.0, 1.0);

    double angleDeg = _lerp(_CLOSED, s.angle.toDouble(), prog);
    double rad = angleDeg * pi / 180;

    double tipX = _SX + s.len * cos(rad);
    double tipY = _SY - s.len * sin(rad);

    double bow = _lerp(0, 16, prog);
    double mx = (_SX + tipX) / 2;
    double my = (_SY + tipY) / 2 - bow;

    double currentBottomY = _lerp(_SY, _BASE_Y + _BASE_H + 48, prog);

    final paint = Paint()
      ..color = _gold.withOpacity(ga)
      ..strokeWidth = s.w.toDouble()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(_SX, currentBottomY);
    path.lineTo(_SX, _SY);
    path.quadraticBezierTo(mx, my, tipX, tipY);
    canvas.drawPath(path, paint);
  }

  void _drawClosedBook(Canvas canvas, double rawFrac, double ga) {
    double alpha = (1.0 - rawFrac * 2.4).clamp(0.0, 1.0);
    if (alpha < 0.02) return;

    double bx = _SX - 28;
    double bw = 48;
    double by = _SY - 148;
    double bh = 148;

    // Book body
    final bodyPaint = Paint()
      ..color = _gold.withOpacity(alpha * ga)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), bodyPaint);

    // Spine stripe
    final spinePaint = Paint()
      ..color = Color.fromRGBO(160, 98, 0, (0.30 * alpha * ga).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(bx, by, 9, bh), spinePaint);

    // Page lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity((0.20 * alpha * ga).clamp(0.0, 1.0))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < 8; i++) {
      double ly = by + bh * (i / 8);
      canvas.drawLine(Offset(bx + 7, ly), Offset(bx + bw, ly), linePaint);
    }
  }

  void _drawBase(Canvas canvas, double prog, double ga) {
    if (prog <= 0) return;
    prog = prog.clamp(0.0, 1.0);

    double hw = (_BASE_X2 - _BASE_X1) * 0.5 * prog;
    const double gap = 46;

    final basePaint = Paint()
      ..color = _navy.withOpacity(ga)
      ..style = PaintingStyle.fill;

    // Left bar
    canvas.drawRect(
      Rect.fromLTWH(_SX - hw, _BASE_Y, hw - 14, _BASE_H),
      basePaint,
    );
    // Right bar
    canvas.drawRect(
      Rect.fromLTWH(_SX + gap / 3, _BASE_Y, hw - gap / 2, _BASE_H),
      basePaint,
    );

    // Binding legs and dots
    if (prog > 0.55) {
      double a = ((prog - 0.55) / 0.30).clamp(0.0, 1.0);
      double dotAlpha = a * ga;

      final legPaint = Paint()
        ..color = _navy.withOpacity(dotAlpha)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final dotPaint = Paint()
        ..color = _navy.withOpacity(dotAlpha)
        ..style = PaintingStyle.fill;

      double B = _BASE_Y + _BASE_H;

      // Left curve
      final leftPath = Path();
      leftPath.moveTo(_SX - 14, _BASE_Y + _BASE_H / 2);
      leftPath.cubicTo(
        _SX - 14, B + 8,
        _SX - 25, B + 20,
        _SX - 30, B + 34,
      );
      canvas.drawPath(leftPath, legPaint);

      // Right curve
      final rightPath = Path();
      rightPath.moveTo(_SX + 14, _BASE_Y + _BASE_H / 2);
      rightPath.cubicTo(
        _SX + 14, B + 8,
        _SX + 25, B + 20,
        _SX + 30, B + 34,
      );
      canvas.drawPath(rightPath, legPaint);

      // Left dot
      canvas.drawCircle(Offset(_SX - 30, B + 44), 10, dotPaint);
      // Right dot
      canvas.drawCircle(Offset(_SX + 30, B + 44), 10, dotPaint);
      // Center dot
      canvas.drawCircle(Offset(_SX, B + 48), 10, dotPaint);
    }
  }

  double _rightProg(double f, double dl) {
    double start = 0.08 + dl * 0.38;
    return _easeOut(((f - start) / 0.24).clamp(0.0, 1.0));
  }

  double _leftProg(double f, double dl) {
    double start = 0.40 + dl * 0.36;
    return _easeOut(((f - start) / 0.24).clamp(0.0, 1.0));
  }

  double _easeOut(double t) {
    return 1.0 - pow(1.0 - t.clamp(0.0, 1.0), 3).toDouble();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _PantasLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StrokeDef {
  final double angle;
  final double len;
  final double w;
  final double dl;

  const _StrokeDef({
    required this.angle,
    required this.len,
    this.w = 17,
    required this.dl,
  });
}