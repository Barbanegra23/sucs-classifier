import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Chip de texto "Cu = 4.20" / "Cc = 1.30" usado en el preview de
/// la curva granulométrica antes de clasificar.
class CuCcChip extends StatelessWidget {
  final String label;
  final String value;
  const CuCcChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label = ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.appColors.primary,
              letterSpacing: 0.3,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
