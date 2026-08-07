import 'package:flutter/material.dart';
import '../../services/sucs_classifier.dart';
import '../../theme/app_colors.dart';
import '../input_card.dart';
import '../input_field.dart';
import 'info_text.dart';
import 'cu_cc_chip.dart';

/// Tarjeta de curva granulométrica (D10/D30/D60), solo relevante para
/// suelos gruesos. Cambia de estado según `p200val`:
///  - null                    → mensaje de espera
///  - < [limiteSueloFino]     → campos D10/D30/D60 + preview de Cu/Cc
///  - >= [limiteSueloFino]    → mensaje "no aplican" (suelo fino)
class GranulometriaSucsCard extends StatelessWidget {
  final double? p200val;
  final double limiteSueloFino;
  final TextEditingController d10;
  final TextEditingController d30;
  final TextEditingController d60;
  final FocusNode fnD10;
  final FocusNode fnD30;
  final FocusNode fnD60;
  final bool autoValidate;

  /// Se dispara al confirmar D60 (último campo del formulario completo).
  final VoidCallback onSubmitFinal;

  const GranulometriaSucsCard({
    super.key,
    required this.p200val,
    required this.limiteSueloFino,
    required this.d10,
    required this.d30,
    required this.d60,
    required this.fnD10,
    required this.fnD30,
    required this.fnD60,
    required this.autoValidate,
    required this.onSubmitFinal,
  });

  double? _parse(String v) => double.tryParse(v);

  @override
  Widget build(BuildContext context) {
    return InputCard(
      titulo: 'Curva granulométrica',
      subtitulo: 'D10 / D30 / D60 — solo suelos gruesos',
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
                  key: ValueKey('pending'),
                )
              : p200val! < limiteSueloFino
                  ? Column(
                      key: const ValueKey('grueso'),
                      children: [
                        InputField(
                          controller: d10,
                          label: 'D10 (mm)',
                          hintText: 'Ej: 0.15',
                          tooltip:
                              'Diámetro al 10% pasante. Es el diámetro más pequeño de la curva granulométrica.',
                          focusNode: fnD10,
                          nextFocusNode: fnD30,
                          autoValidate: autoValidate,
                          extraValidator: (d10v) {
                            final d30v = double.tryParse(d30.text);
                            final d60v = double.tryParse(d60.text);
                            if (d30v != null && d10v >= d30v) {
                              return 'D10 debe ser menor que D30 (${d30v.toStringAsFixed(3)} mm)';
                            }
                            if (d60v != null && d10v >= d60v) {
                              return 'D10 debe ser menor que D60 (${d60v.toStringAsFixed(3)} mm)';
                            }
                            return null;
                          },
                        ),
                        InputField(
                          controller: d30,
                          label: 'D30 (mm)',
                          hintText: 'Ej: 0.50',
                          tooltip:
                              'Diámetro al 30% pasante. Debe estar entre D10 y D60.',
                          focusNode: fnD30,
                          nextFocusNode: fnD60,
                          autoValidate: autoValidate,
                          extraValidator: (d30v) {
                            final d10v = double.tryParse(d10.text);
                            final d60v = double.tryParse(d60.text);
                            if (d10v != null && d30v <= d10v) {
                              return 'D30 debe ser mayor que D10 (${d10v.toStringAsFixed(3)} mm)';
                            }
                            if (d60v != null && d30v >= d60v) {
                              return 'D30 debe ser menor que D60 (${d60v.toStringAsFixed(3)} mm)';
                            }
                            return null;
                          },
                        ),
                        InputField(
                          controller: d60,
                          label: 'D60 (mm)',
                          hintText: 'Ej: 2.0',
                          tooltip:
                              'Diámetro al 60% pasante. Es el diámetro más grande de los tres.',
                          focusNode: fnD60,
                          onSubmit: onSubmitFinal,
                          autoValidate: autoValidate,
                          extraValidator: (d60v) {
                            final d10v = double.tryParse(d10.text);
                            final d30v = double.tryParse(d30.text);
                            if (d30v != null && d60v <= d30v) {
                              return 'D60 debe ser mayor que D30 (${d30v.toStringAsFixed(3)} mm)';
                            }
                            if (d10v != null && d60v <= d10v) {
                              return 'D60 debe ser mayor que D10 (${d10v.toStringAsFixed(3)} mm)';
                            }
                            return null;
                          },
                        ),
                        // Preview de Cu y Cc calculados
                        Builder(builder: (context) {
                          final d10v = _parse(d10.text);
                          final d30v = _parse(d30.text);
                          final d60v = _parse(d60.text);
                          if (d10v == null ||
                              d30v == null ||
                              d60v == null ||
                              d10v <= 0 ||
                              d60v <= 0) {
                            return const SizedBox.shrink();
                          }
                          final (cuPreview, ccPreview) =
                              calcularCuCc(d10: d10v, d30: d30v, d60: d60v);
                          if (cuPreview == null || ccPreview == null) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.appColors.primary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.appColors.primary
                                    .withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CuCcChip(
                                    label: 'Cu',
                                    value: cuPreview.toStringAsFixed(2)),
                                const SizedBox(width: 8),
                                CuCcChip(
                                    label: 'Cc',
                                    value: ccPreview.toStringAsFixed(3)),
                              ],
                            ),
                          );
                        }),
                      ],
                    )
                  : const InfoText(
                      'Suelo fino → Cu y Cc no aplican',
                      key: ValueKey('fino'),
                    ),
        ),
      ],
    );
  }
}
