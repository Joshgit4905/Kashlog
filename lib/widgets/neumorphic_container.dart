import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isPressed;
  final Color? color;
  final double blurRadius;
  final Offset offset;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(4),
    this.isPressed = false,
    this.color,
    this.blurRadius = 12,
    this.offset = const Offset(6, 6),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        color ?? (isDark ? AppColors.darkCard : AppColors.lightCard);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? []
            : [
                // Darker shadow for bottom-right
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.1),
                  offset: offset,
                  blurRadius: blurRadius,
                ),
                // Lighter shadow for top-left
                BoxShadow(
                  color: isDark
                      ? const Color(0xFF1B2E1B).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.8),
                  offset: Offset(-offset.dx, -offset.dy),
                  blurRadius: blurRadius,
                ),
              ],
      ),
      child: child,
    );
  }
}
