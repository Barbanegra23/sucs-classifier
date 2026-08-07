import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../header_widgets.dart';

/// Encabezado de AashtoScreen. Incluye un botón de "volver" (esta
/// pantalla se llega vía `Navigator.push` desde el selector
/// SUCS/AASHTO, no es la pantalla raíz) y no tiene botón de tema ni
/// de tutorial — el tema es global (afecta a toda la app aunque el
/// switch viva en SucsHeader) y el tutorial es contenido específico
/// de SUCS, así que no aplica acá.
class AashtoHeader extends StatelessWidget {
  const AashtoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(children: [
      Container(
        height: 4,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            context.appColors.secondary,
            context.appColors.primaryLight,
            context.appColors.headerAccentFade,
          ]),
        ),
      ),
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(8, topPadding + 6, 16, 14),
        color: context.appColors.headerBg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              tooltip: 'Volver',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CLASIFICADOR AASHTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      )),
                  const SizedBox(height: 2),
                  Text('AASHTO M 145 · ASTM D3282',
                      style: TextStyle(
                          color: context.appColors.headerSubtitle,
                          fontSize: 10.5)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          const IntrinsicHeight(
            child: Row(children: [
              Expanded(
                  child: HeaderStat(
                      valor: 'AASHTO M 145', etiqueta: 'Norma base')),
              HeaderDivider(),
              Expanded(
                  child: HeaderStat(
                      valor: '7 grupos', etiqueta: 'A-1 · A-2 · … · A-7')),
              HeaderDivider(),
              Expanded(
                  child:
                      HeaderStat(valor: 'GI', etiqueta: 'Índice de grupo')),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
