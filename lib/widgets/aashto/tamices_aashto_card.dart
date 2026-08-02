import 'package:flutter/material.dart';
import '../input_card.dart';
import '../input_field.dart';

/// Tarjeta de tamices para AASHTO: % que pasa N°10, N°40 y N°200.
/// A diferencia de SUCS (que usa % retenido N°4), AASHTO trabaja con
/// % pasante en tres tamices distintos.
class TamicesAashtoCard extends StatelessWidget {
  final TextEditingController pasa10;
  final TextEditingController pasa40;
  final TextEditingController pasa200;
  final FocusNode fnPasa10;
  final FocusNode fnPasa40;
  final FocusNode fnPasa200;
  final FocusNode fnNext;
  final bool autoValidate;

  const TamicesAashtoCard({
    super.key,
    required this.pasa10,
    required this.pasa40,
    required this.pasa200,
    required this.fnPasa10,
    required this.fnPasa40,
    required this.fnPasa200,
    required this.fnNext,
    required this.autoValidate,
  });

  @override
  Widget build(BuildContext context) {
    return InputCard(
      titulo: 'Tamices',
      subtitulo: '% pasa N°10  ·  N°40  ·  N°200',
      children: [
        InputField(
          controller: pasa10,
          label: '% Pasa N°10',
          hintText: '0 – 100',
          tooltip:
              'Porcentaje del suelo que pasa el tamiz N°10 (2,00mm). Usado para distinguir el subgrupo A-1-a.',
          autoValidate: autoValidate,
          focusNode: fnPasa10,
          nextFocusNode: fnPasa40,
          extraValidator: (v) {
            if (v > 100) return '% pasa N°10 no puede superar 100';
            return null;
          },
        ),
        InputField(
          controller: pasa40,
          label: '% Pasa N°40',
          hintText: '0 – 100',
          tooltip:
              'Porcentaje del suelo que pasa el tamiz N°40 (0,425mm).',
          autoValidate: autoValidate,
          focusNode: fnPasa40,
          nextFocusNode: fnPasa200,
          extraValidator: (v) {
            if (v > 100) return '% pasa N°40 no puede superar 100';
            final p10 = double.tryParse(pasa10.text);
            if (p10 != null && v > p10) {
              return '% pasa N°40 no puede ser mayor que % pasa N°10';
            }
            return null;
          },
        ),
        InputField(
          controller: pasa200,
          label: '% Pasa N°200',
          hintText: '0 – 100',
          tooltip:
              'Porcentaje del suelo que pasa el tamiz N°200 (0,075mm). Define si el material es granular (≤35%) o limo-arcilloso (>35%).',
          autoValidate: autoValidate,
          focusNode: fnPasa200,
          nextFocusNode: fnNext,
          extraValidator: (v) {
            if (v > 100) return '% pasa N°200 no puede superar 100';
            final p40 = double.tryParse(pasa40.text);
            if (p40 != null && v > p40) {
              return '% pasa N°200 no puede ser mayor que % pasa N°40';
            }
            return null;
          },
        ),
      ],
    );
  }
}
