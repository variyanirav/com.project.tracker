import 'package:flutter/material.dart';

/// Icon widget with sizing and tap support
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  const AppIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).iconTheme.color;
    final child = Icon(icon, size: size, color: iconColor);

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: child),
      );
    }

    return child;
  }
}
