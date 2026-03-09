import 'dart:math' as math;
import 'package:flutter/material.dart';

class NeumorphicVisualizer extends StatefulWidget {
  final double balance;
  final double activity;

  const NeumorphicVisualizer({
    super.key,
    required this.balance,
    required this.activity,
  });

  @override
  State<NeumorphicVisualizer> createState() => _NeumorphicVisualizerState();
}

class _NeumorphicVisualizerState extends State<NeumorphicVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Weights for different frequency bands
  final List<double> _baseHeights = List.generate(20, (i) {
    // Parabolic distribution for a nice center-heavy look
    return 0.3 + 0.6 * (1.0 - (i - 10).abs() / 10.0);
  });

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
          size: const Size(double.infinity, 100),
          painter: _PremiumVisualizerPainter(
            animationValue: _controller.value,
            baseHeights: _baseHeights,
            balance: widget.balance,
            activity: widget.activity,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        );
      },
    );
  }
}

class _PremiumVisualizerPainter extends CustomPainter {
  final double animationValue;
  final List<double> baseHeights;
  final double balance;
  final double activity;
  final bool isDark;

  _PremiumVisualizerPainter({
    required this.animationValue,
    required this.baseHeights,
    required this.balance,
    required this.activity,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = baseHeights.length;
    final totalSpacing = size.width * 0.2;
    final barWidth = (size.width - totalSpacing) / barCount;
    final spacing = totalSpacing / (barCount + 1);

    final accentColor = const Color(0xFF66BB6A);
    final trackBaseColor = isDark
        ? const Color(0xFF0A1A0A)
        : const Color(0xFFE1EADD);

    for (int i = 0; i < barCount; i++) {
      final x = spacing + i * (barWidth + spacing);

      // Calculate dynamic height using sine waves for "organic" movement
      // Use i to offset waves so they don't move in sync
      final wave1 = math.sin((animationValue * 2 * math.pi) + (i * 0.5)) * 0.2;
      final wave2 = math.cos((animationValue * 4 * math.pi) + (i * 0.3)) * 0.1;

      // Activity increases the "chaos" of the movement
      final chaos = (activity / 2000).clamp(0.0, 0.4);
      final jitter = (math.sin(animationValue * 15 + i) * chaos);

      // Balance scales the overall magnitude
      final magnitude = (balance.abs() / 10000).clamp(0.5, 1.0);

      final currentHeightFactor =
          (baseHeights[i] * magnitude + wave1 + wave2 + jitter).clamp(0.1, 0.9);
      final h = size.height * currentHeightFactor;
      final y = (size.height - h) / 2;

      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 10, barWidth, size.height - 20),
        Radius.circular(barWidth / 2),
      );

      // 1. Draw Inset Track (The "Well")
      // Dark inner shadow (bottom-right)
      final darkShadowPaint = Paint()
        ..color = isDark
            ? Colors.black.withValues(alpha: 0.8)
            : Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      // Light inner shadow (top-left) - makes it look truly recessed
      final lightShadowPaint = Paint()
        ..color = isDark
            ? const Color(0xFF1B301B).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.save();
      canvas.clipRRect(trackRect);
      canvas.drawRRect(trackRect, Paint()..color = trackBaseColor);

      // Offset shadows to create depth
      canvas.drawRRect(trackRect.shift(const Offset(2, 2)), darkShadowPaint);
      canvas.drawRRect(trackRect.shift(const Offset(-1, -1)), lightShadowPaint);
      canvas.restore();

      // 2. Draw Active Bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        Radius.circular(barWidth / 2),
      );

      final barGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.8),
          accentColor,
          accentColor.withValues(alpha: 0.8),
        ],
      );

      final barPaint = Paint()
        ..shader = barGradient.createShader(barRect.outerRect)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.solid,
          isDark ? 4 : 2,
        ); // Glow effect

      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumVisualizerPainter oldDelegate) => true;
}
