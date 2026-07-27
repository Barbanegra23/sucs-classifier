import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InputCard extends StatelessWidget {
  final String titulo;

  /// Texto descriptivo opcional debajo del título.
  /// Ej: "% pasa N°200 · % retenido N°4"
  final String? subtitulo;

  final List<Widget> children;

  const InputCard({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.appColors.secondary,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: TextStyle(
                fontSize: 11,
                color: context.appColors.secondary.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
