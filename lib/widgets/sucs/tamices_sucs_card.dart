import 'package:flutter/material.dart';
import '../input_card.dart';
import '../input_field.dart';

/// Tarjeta de entrada de datos "Tamices": % pasa N°200 y % retenido N°4.
/// Determina si el suelo es fino o grueso (ASTM D2487).
class TamicesSucsCard extends StatelessWidget {
  final TextEditingController pasa200;
  final TextEditingController retenidoN4;
  final FocusNode fnPasa200;
  final FocusNode fnRetenidoN4;
  final FocusNode fnNext;
  final bool autoValidate;

  const TamicesSucsCard({
    super.key,
    required this.pasa200,
    required this.retenidoN4,
    required this.fnPasa200,
    required this.fnRetenidoN4,
    required this.fnNext,
    required this.autoValidate,
  });

  @override
  Widget build(BuildContext context) {
    return InputCard(
      titulo: 'Tamices',
      subtitulo: '% pasa N°200  ·  % retenido N°4',
      children: [
        InputField(
          controller: pasa200,
          label: '% Pasa N°200',
          hintText: '0 – 100',
          tooltip:
              'Porcentaje del suelo que pasa el tamiz N°200 (0,075mm). Determina si el suelo es grueso (< 50%) o fino (≥ 50%).',
          autoValidate: autoValidate,
          focusNode: fnPasa200,
          nextFocusNode: fnRetenidoN4,
          extraValidator: (v) {
            if (v > 100) return '% pasa 200 no puede superar 100';
            return null;
          },
        ),
        InputField(
          controller: retenidoN4,
          label: '% Retenido N°4',
          hintText: '0 – 100',
          tooltip:
              'Porcentaje del suelo que queda retenido en el tamiz N°4 (4,75mm). Permite distinguir entre grava y arena dentro de los suelos gruesos.',
          autoValidate: autoValidate,
          focusNode: fnRetenidoN4,
          nextFocusNode: fnNext,
          extraValidator: (r4) {
            if (r4 > 100) {
              return '% retenido N°4 no puede superar 100';
            }
            final p200 = double.tryParse(pasa200.text);
            if (p200 != null && r4 + p200 > 100) {
              return 'R4 + P200 = ${(r4 + p200).toStringAsFixed(1)}% > 100%';
            }
            return null;
          },
        ),
      ],
    );
  }
}
