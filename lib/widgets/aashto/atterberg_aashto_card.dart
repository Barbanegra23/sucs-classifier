import 'package:flutter/material.dart';
import '../input_card.dart';
import '../input_field.dart';

/// Tarjeta de límites de Atterberg para AASHTO. A diferencia de la
/// versión de SUCS, siempre se muestra completa: AASHTO necesita LL y
/// PI incluso para los subgrupos granulares (A-1, A-3), así que no hay
/// un estado "no aplica" condicionado al % de finos.
class AtterbergAashtoCard extends StatelessWidget {
  final TextEditingController ll;
  final TextEditingController lp;
  final FocusNode fnLL;
  final FocusNode fnLP;
  final VoidCallback onSubmitFinal;
  final bool autoValidate;

  const AtterbergAashtoCard({
    super.key,
    required this.ll,
    required this.lp,
    required this.fnLL,
    required this.fnLP,
    required this.onSubmitFinal,
    required this.autoValidate,
  });

  @override
  Widget build(BuildContext context) {
    return InputCard(
      titulo: 'Límites de Atterberg',
      subtitulo: 'LL y LP — si el suelo es no plástico (NP), cargá LP = LL',
      children: [
        InputField(
          controller: ll,
          label: 'LL — Límite Líquido',
          hintText: 'Ej: 45',
          tooltip:
              'Límite Líquido: contenido de humedad (%) con el que el suelo pasa de estado plástico a líquido.',
          autoValidate: autoValidate,
          focusNode: fnLL,
          nextFocusNode: fnLP,
        ),
        InputField(
          controller: lp,
          label: 'LP — Límite Plástico',
          hintText: 'Ej: 20 (si es NP, igual a LL)',
          tooltip:
              'Límite Plástico. Si el suelo no tiene plasticidad (NP), cargá el mismo valor que LL para que el PI calculado sea 0.',
          autoValidate: autoValidate,
          extraValidator: (lpVal) {
            final llVal = double.tryParse(ll.text);
            if (llVal != null && lpVal > llVal) {
              return 'LP no puede ser mayor que LL';
            }
            return null;
          },
          focusNode: fnLP,
          onSubmit: onSubmitFinal,
        ),
      ],
    );
  }
}
