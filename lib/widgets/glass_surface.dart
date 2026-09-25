import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A frosted, translucent panel used over gradient/hero backgrounds —
/// gives depth without resorting to flat drop-shadow cards everywhere.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double opacity;
  final double blur;
  final Color tint;
  final Border? border;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppTheme.radiusLg,
    this.opacity = 0.12,
    this.blur = 18,
    this.tint = Colors.white,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: tint.withValues(alpha: opacity + 0.08), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Soft dotted mesh painted behind hero sections for depth — cheap,
/// static, and never distracts from the numbers on top of it.
class MeshDots extends StatelessWidget {
  final Color color;
  const MeshDots({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MeshDotsPainter(color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _MeshDotsPainter extends CustomPainter {
  final Color color;
  const _MeshDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.09);
    const spacing = 22.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MeshDotsPainter oldDelegate) => oldDelegate.color != color;
}
