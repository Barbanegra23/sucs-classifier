import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Muestra un valor y su etiqueta en las stats del header
class HeaderStat extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const HeaderStat({super.key, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            color: colors.headerStatValue,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          etiqueta,
          style: TextStyle(
            color: colors.headerStatLabel,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Divisor vertical entre las stats del header
class HeaderDivider extends StatelessWidget {
  const HeaderDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white10,
    );
  }
}
