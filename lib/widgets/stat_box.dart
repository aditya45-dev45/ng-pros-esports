import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.valueColor
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ],
    );
  }
}