import 'package:flutter/material.dart';
import '../input_card.dart';
import '../input_field.dart';
import 'info_text.dart';

/// Tarjeta de límites de Atterberg (LL / LP). Cambia de estado según
/// `p200val`:
///  - null            → mensaje de espera ("completá % pasa 200 primero")
///  - < 5             → mensaje "no aplican" (finos insuficientes)
///  - >= 5            → campos LL / LP visibles
class AtterbergCard extends StatelessWidget {
  final double? p200val;
  final TextEditingController ll;
  final TextEditingController lp;
  final FocusNode fnLL;
  final FocusNode fnLP;

  /// Foco al que saltar al confirmar LP. Si el suelo es grueso, es el
  /// campo D10 de la tarjeta siguiente; si es fino, es null (no hay
  /// más campos y en su lugar se dispara [onSubmitFinal]).
  final FocusNode? fnSiguiente;

  /// Se dispara al confirmar LP cuando no hace falta pasar a D10/D30/D60
  /// (suelo fino) — normalmente clasifica directamente.
  final VoidCallback? onSubmitFinal;

  final bool autoValidate;

  const AtterbergCard({
    super.key,
    required this.p200val,
    required this.ll,
    required this.lp,
    required this.fnLL,
    required this.fnLP,
    required this.fnSiguiente,
    required this.onSubmitFinal,
    required this.autoValidate,
  });

  @override
  Widget build(BuildContext context) {
    return InputCard(
      titulo: 'Límites de Atterberg',
      subtitulo: p200val == null
          ? 'Completá % pasa N°200 primero'
          : p200val! < 5
              ? 'No aplican (finos < 5%)'
              : 'LL y LP — requeridos cuando finos ≥ 5%',
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: p200val == null
              ? const InfoText(
                  'Ingresá % pasa 200 para continuar',
                  key: ValueKey('atterberg_pending'),
                )
              : p200val! < 5
                  ? const InfoText(
                      'Con menos del 5% de finos los\n'
                      'límites de Atterberg no aplican',
                      key: ValueKey('atterberg_no_aplica'),
                    )
                  : Column(
                      key: const ValueKey('atterberg_campos'),
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
                          hintText: 'Ej: 20',
                          tooltip:
                              'Límite Plástico: contenido de humedad (%) con el que el suelo pasa de estado semisólido a plástico.',
                          autoValidate: autoValidate,
                          extraValidator: (lpVal) {
                            final llVal = double.tryParse(ll.text);
                            if (llVal != null && lpVal > llVal) {
                              return 'LP no puede ser mayor que LL';
                            }
                            return null;
                          },
                          focusNode: fnLP,
                          nextFocusNode: fnSiguiente,
                          onSubmit: fnSiguiente != null ? null : onSubmitFinal,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
