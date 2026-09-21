import 'package:flutter/material.dart';
import '../core/theme.dart';

class CleanAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Color? borderColor;

  const CleanAvatar({
    super.key,
    required this.imageUrl,
    this.size = 50,
    this.borderColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: borderColor ?? AppTheme.primary.withValues(alpha: 0.3),
            width: 2),
        color: AppTheme.divider,
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.divider,
            child: const Icon(Icons.person, color: AppTheme.textLight, size: 24),
          ),
        ),
      ),
    );
  }
}