import 'package:flutter/material.dart';

/// Avatar widget showing initials or image
class AppAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const AppAvatar({
    super.key,
    required this.initials,
    this.size = 40.0,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor.withValues(alpha: 0.2),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: bgColor,
        ),
      ),
    );
  }
}
