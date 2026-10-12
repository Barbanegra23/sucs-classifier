import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sucs_classifier.dart';
import '../widgets/sucs_casagrande_chart.dart';
import '../widgets/sucs_granulometria_chart.dart';
import '../widgets/typewriter_text.dart';
import '../logic/sucs_interpretation.dart';
import '../services/sucs_pdf_export.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// COLORES DE COMPOSICIÓN (torta)
// ─────────────────────────────────────────────────────────────
const _colorGrava = Color(0xFF8D6748);
const _colorArena = Color(0xFFF0A500);
// Finos usa el color del suelo (se pasa en runtime)

// =============================================================
// RESULT SECTION
// =============================================================
class SucsResultSection extends StatefulWidget {
  final SucsResult resultado;
  final double ll;
  final double pasa200;
  final double retenidoN4;
  final double lp;
  final double? cu;
  final double? cc;
  final double? d10;
  final double? d30;
  final double? d60;
  final VoidCallback? onGuardar;
  final VoidCallback? onIrArriba;

  const SucsResultSection({
    super.key,
    required this.resultado,
    required this.ll,
    required this.pasa200,
    required this.retenidoN4,
    required this.lp,
    this.cu,
    this.cc,
    this.d10,
    this.d30,
    this.d60,
    this.onGuardar,
    this.onIrArriba,
  });

  @override
  State<SucsResultSection> createState() => _SucsResultSectionState();
}

class _SucsResultSectionState extends State<SucsResultSection> {
  final _expandido = <String, bool>{
    'composicion': true,
    'resumen': true,
    'interpretacion': true,
    'recomendaciones': true,
    'chart': false,
    'memoria': false,
  };

  // ── Helpers ──────────────────────────────────────────────

  List<String> _chips(String simbolo, double pi) {
    final base = simbolo.split('-').first;
    final esDual = simbolo.contains('-');
    final segundo = esDual ? simbolo.split('-').last : null;
    final chips = <String>[];
    if (simbolo == 'CL-ML') {
      chips.add('Arcilla limosa');
    } else if (['CL', 'CH'].contains(base)) {
      chips.add('Arcilla');
    } else if (['ML', 'MH'].contains(base)) {
      chips.add('Limo');
    } else if (['GW', 'GP', 'GM', 'GC'].contains(base)) {
      chips.add('Grava');
    } else if (['SW', 'SP', 'SM', 'SC'].contains(base)) {
      chips.add('Arena');
    }
    if (esDual && simbolo != 'CL-ML') {
      chips.add('Símbolo dual');
    }
    if (simbolo == 'CL-ML') {
      chips.add('Zona de transición');
    } else if (['CL', 'ML'].contains(base)) {
      chips.add('Baja plasticidad');
    } else if (['CH', 'MH'].contains(base)) {
      chips.add('Alta plasticidad');
    } else if (['GW', 'SW'].contains(base)) {
      chips.add('Bien graduado');
    } else if (['GP', 'SP'].contains(base)) {
      chips.add('Mal graduado');
    }
    if (simbolo == 'CL-ML') {
      chips.add('Comportamiento mixto');
    } else if (['CL', 'CH'].contains(base)) {
      chips.add('Cohesivo');
    } else if (['ML', 'MH'].contains(base)) {
      chips.add('Baja cohesión');
    } else if (['GC-GM', 'SC-SM'].contains(simbolo)) {
      chips.add('Con limo y arcilla');
    } else if (['GM', 'SM'].contains(segundo)) {
      chips.add('Con limo');
    } else if (['GC', 'SC'].contains(segundo)) {
      chips.add('Con arcilla');
    } else if (['GW', 'GP', 'SW', 'SP'].contains(base) && !esDual) {
      chips.add('Granular');
    } else if (['GM', 'SM'].contains(base)) {
      chips.add('Con limo');
    } else if (['GC', 'SC'].contains(base)) {
      chips.add('Con arcilla');
    }
    if (pi > 20) {
      chips.add('PI elevado');
    }
    if (pi == 0) {
      chips.add('No plástico');
    }
    return chips;
  }

  List<PuntoGranulometrico> _puntosGranulo() {
    final pts = <PuntoGranulometrico>[
      PuntoGranulometrico(0.075, widget.pasa200),
      PuntoGranulometrico(4.75, 100 - widget.retenidoN4),
    ];
    if (100 - widget.retenidoN4 < 100) pts.add(PuntoGranulometrico(50.0, 100));
    if (widget.d10 != null && widget.d10! > 0) {
      pts.add(PuntoGranulometrico(widget.d10!, 10));
    }
    if (widget.d30 != null && widget.d30! > 0) {
      pts.add(PuntoGranulometrico(widget.d30!, 30));
    }
    if (widget.d60 != null && widget.d60! > 0) {
      pts.add(PuntoGranulometrico(widget.d60!, 60));
    }
    return pts;
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => _expandido[key] = !(_expandido[key] ?? true));
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final res = widget.resultado;
    final color = colorDeSuelo(res.symbol);
    final esFino = esSueloFino(res.symbol);
    final esGrueso = !esFino && res.symbol != 'ERROR';
    final chips = _chips(res.symbol, res.pi);

    final resumen =
        SucsInterpretation.generarResumen(res.symbol, res.pi, widget.ll);
    final interpretacion =
        SucsInterpretation.interpretacionIngenieril(res.symbol);
    final recomendaciones = SucsInterpretation.generarRecomendaciones(
        res.symbol, res.pi, widget.ll,
        d10: widget.d10);

    // Composición granulométrica
    final grava = widget.retenidoN4.clamp(0, 100).toDouble();
    final finos = widget.pasa200.clamp(0, 100).toDouble();
    final arena = (100 - grava - finos).clamp(0, 100).toDouble();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ─────────────────────────────────────
          _buildHeader(color, res),

          // ── CUERPO ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips + Editar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: chips
                            .map((c) => _Chip(label: c, color: color))
                            .toList(),
                      ),
                    ),
                    if (widget.onIrArriba != null) ...[
                      const SizedBox(width: 8),
                      _EditarDatosBtn(onTap: widget.onIrArriba!),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // ── 1. COMPOSICIÓN (torta) ────────────────
                _SeccionCard(
                  titulo: 'Composición granulométrica',
                  icono: Icons.pie_chart_rounded,
                  color: color,
                  expandido: _expandido['composicion'] ?? true,
                  onToggle: () => _toggle('composicion'),
                  child: _PieComposicion(
                    grava: grava,
                    arena: arena,
                    finos: finos,
                    colorFinos: color,
                  ),
                ),

                const SizedBox(height: 8),

                // ── 2. RESUMEN ────────────────────────────
                _SeccionCard(
                  titulo: 'Resumen',
                  icono: Icons.description_rounded,
                  color: color,
                  expandido: _expandido['resumen'] ?? true,
                  onToggle: () => _toggle('resumen'),
                  child: Text(
                    resumen,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.65,
                        color: context.appColors.textPrimary),
                  ),
                ),

                const SizedBox(height: 8),

                // ── 3. INTERPRETACIÓN ─────────────────────
                _SeccionCard(
                  titulo: 'Interpretación ingenieril',
                  icono: Icons.engineering_rounded,
                  color: color,
                  expandido: _expandido['interpretacion'] ?? true,
                  onToggle: () => _toggle('interpretacion'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: interpretacion
                        .map((e) => _BulletItem(text: e, color: color))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // ── 4. RECOMENDACIONES ────────────────────
                _SeccionCard(
                  titulo: 'Recomendaciones',
                  icono: Icons.construction_rounded,
                  color: color,
                  expandido: _expandido['recomendaciones'] ?? true,
                  onToggle: () => _toggle('recomendaciones'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recomendaciones
                        .map((e) => _BulletItem(text: e, color: color))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // ── 5. GRÁFICO ────────────────────────────
                if (esFino || esGrueso)
                  _SeccionCard(
                    titulo:
                        esFino ? 'Carta de Casagrande' : 'Curva granulométrica',
                    icono: esFino
                        ? Icons.scatter_plot_rounded
                        : Icons.show_chart_rounded,
                    color: color,
                    expandido: _expandido['chart'] ?? false,
                    onToggle: () => _toggle('chart'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: esFino
                          ? SucsCasagrandeChart(
                              ll: widget.ll,
                              pi: res.pi,
                              suelo: res.symbol,
                            )
                          : SucsGranulometriaChart(
                              colorSuelo: color,
                              d10: widget.d10,
                              d30: widget.d30,
                              d60: widget.d60,
                              puntos: _puntosGranulo(),
                            ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── 6. MEMORIA DE CLASIFICACIÓN ───────────
                _SeccionCard(
                  titulo: 'Memoria de clasificación',
                  icono: Icons.calculate_outlined,
                  color: color,
                  expandido: _expandido['memoria'] ?? false,
                  onToggle: () => _toggle('memoria'),
                  child: _MemoriaClasificacion(
                    pasos: generarMemoria(
                      resultado: res,
                      pasa200: widget.pasa200,
                      retenidoN4: widget.retenidoN4,
                      ll: widget.ll,
                      lp: widget.lp,
                      cu: widget.cu,
                      cc: widget.cc,
                      d10: widget.d10,
                      d30: widget.d30,
                      d60: widget.d60,
                    ),
                    color: color,
                  ),
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),

          // ── BARRA DE ACCIONES ───────────────────────────
          _buildActionBar(color, res),
        ],
      ),
    );
  }

  // ── Sub-builders ────────────────────────────────────────

  Widget _buildHeader(Color color, SucsResult res) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypewriterText(
            text: res.symbol,
            letterDelayMs: 90,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            res.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          // Badges de datos ingresados
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InputBadge(
                  label: 'P200',
                  value: '${widget.pasa200.toStringAsFixed(1)}%'),
              _InputBadge(
                  label: 'R4',
                  value: '${widget.retenidoN4.toStringAsFixed(1)}%'),
              if (widget.pasa200 >= 5.0) ...[
                _InputBadge(label: 'LL', value: widget.ll.toStringAsFixed(0)),
                _InputBadge(label: 'LP', value: widget.lp.toStringAsFixed(0)),
                _InputBadge(
                  label: 'IP',
                  value: res.pi.toStringAsFixed(1),
                  highlight: res.pi > 20,
                ),
              ],
              if (widget.cu != null)
                _InputBadge(label: 'Cu', value: widget.cu!.toStringAsFixed(2)),
              if (widget.cc != null)
                _InputBadge(label: 'Cc', value: widget.cc!.toStringAsFixed(3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(Color color, SucsResult res) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ExportPdfButton(
              resultado: res,
              pasa200: widget.pasa200,
              retenidoN4: widget.retenidoN4,
              ll: widget.ll,
              lp: widget.lp,
              cu: widget.cu,
              cc: widget.cc,
              d10: widget.d10,
              d30: widget.d30,
              d60: widget.d60,
              colorSuelo: color,
            ),
          ),
          if (widget.onGuardar != null && res.symbol != 'ERROR') ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onGuardar,
                icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                label: const Text('Guardar',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(
                      color: color.withValues(alpha: 0.45), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================
// TARJETA DE SECCIÓN (reemplaza SeccionColapsable)
// =============================================================
class _SeccionCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final bool expandido;
  final VoidCallback onToggle;
  final Widget child;

  const _SeccionCard({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.expandido,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icono, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color:
                            expandido ? color : color.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expandido ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: color.withValues(alpha: expandido ? 0.7 : 0.4),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido animado ───────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: expandido
                ? Column(
                    children: [
                      Divider(height: 1, color: color.withValues(alpha: 0.1)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: child,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// GRÁFICO DE TORTA — COMPOSICIÓN GRANULOMÉTRICA
// =============================================================
class _PieComposicion extends StatefulWidget {
  final double grava;
  final double arena;
  final double finos;
  final Color colorFinos;

  const _PieComposicion({
    required this.grava,
    required this.arena,
    required this.finos,
    required this.colorFinos,
  });

  @override
  State<_PieComposicion> createState() => _PieComposicionState();
}

class _PieComposicionState extends State<_PieComposicion> {
  int? _tocado;

  @override
  Widget build(BuildContext context) {
    final secciones = <_SeccionTorta>[
      if (widget.grava >= 0.5)
        _SeccionTorta(
          valor: widget.grava,
          label: 'Grava',
          color: _colorGrava,
        ),
      if (widget.arena >= 0.5)
        _SeccionTorta(
          valor: widget.arena,
          label: 'Arena',
          color: _colorArena,
        ),
      if (widget.finos >= 0.5)
        _SeccionTorta(
          valor: widget.finos,
          label: 'Finos',
          color: widget.colorFinos,
        ),
    ];

    if (secciones.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 150,
      child: Row(
        children: [
          // Torta
          Expanded(
            flex: 5,
            child: fl.PieChart(
              fl.PieChartData(
                pieTouchData: fl.PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _tocado = null;
                        return;
                      }
                      _tocado = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: secciones.asMap().entries.map((entry) {
                  final i = entry.key;
                  final sec = entry.value;
                  final activo = _tocado == i;
                  return fl.PieChartSectionData(
                    value: sec.valor,
                    title: sec.valor >= 8
                        ? '${sec.valor.toStringAsFixed(1)}%'
                        : '',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    color: sec.color,
                    radius: activo ? 65 : 55,
                    borderSide: activo
                        ? BorderSide(
                            color: sec.color.withValues(alpha: 0.6), width: 3)
                        : BorderSide.none,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 28,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Leyenda
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: secciones.map((sec) => _LeyendaItem(sec: sec)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionTorta {
  final double valor;
  final String label;
  final Color color;
  const _SeccionTorta(
      {required this.valor, required this.label, required this.color});
}

class _LeyendaItem extends StatelessWidget {
  final _SeccionTorta sec;
  const _LeyendaItem({required this.sec});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: sec.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sec.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  '${sec.valor.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: sec.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// WIDGETS AUXILIARES
// =============================================================

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _InputBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _InputBadge(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      );
}

class _EditarDatosBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _EditarDatosBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_upward_rounded, size: 11, color: Colors.grey),
              SizedBox(width: 4),
              Text('Editar',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 8),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}

// =============================================================
// BOTÓN EXPORTAR PDF
// =============================================================
class _ExportPdfButton extends StatefulWidget {
  final SucsResult resultado;
  final double pasa200, retenidoN4, ll, lp;
  final double? cu, cc, d10, d30, d60;
  final Color colorSuelo;

  const _ExportPdfButton({
    required this.resultado,
    required this.pasa200,
    required this.retenidoN4,
    required this.ll,
    required this.lp,
    this.cu,
    this.cc,
    this.d10,
    this.d30,
    this.d60,
    required this.colorSuelo,
  });

  @override
  State<_ExportPdfButton> createState() => _ExportPdfButtonState();
}

class _ExportPdfButtonState extends State<_ExportPdfButton> {
  bool _exportando = false;

  Future<void> _exportar() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    HapticFeedback.lightImpact();
    try {
      await SucsPdfExport.exportar(
        context: context,
        resultado: widget.resultado,
        pasa200: widget.pasa200,
        retenidoN4: widget.retenidoN4,
        ll: widget.ll,
        lp: widget.lp,
        cu: widget.cu,
        cc: widget.cc,
        d10: widget.d10,
        d30: widget.d30,
        d60: widget.d60,
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colorSuelo;
    return OutlinedButton(
      onPressed: _exportando ? null : _exportar,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(
          color:
              _exportando ? c.withValues(alpha: 0.2) : c.withValues(alpha: 0.4),
        ),
        foregroundColor: c,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _exportando
            ? SizedBox(
                key: const ValueKey('loading'),
                height: 18,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(c),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Generando…',
                        style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              )
            : Row(
                key: const ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 17, color: c),
                  const SizedBox(width: 7),
                  Text('Exportar PDF',
                      style: TextStyle(
                          color: c, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
      ),
    );
  }
}

// =============================================================
// MEMORIA DE CLASIFICACIÓN
// Muestra los pasos de razonamiento que llevaron al resultado.
// =============================================================
class _MemoriaClasificacion extends StatelessWidget {
  final List<PasoClasificacion> pasos;
  final Color color;

  const _MemoriaClasificacion({
    required this.pasos,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pasos.map((paso) {
        final esFinal = paso.numero == '→';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número / indicador
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: BoxDecoration(
                  color: esFinal
                      ? color
                      : paso.cumple == true
                          ? color.withValues(alpha: 0.12)
                          : paso.cumple == false
                              ? Colors.red.withValues(alpha: 0.10)
                              : colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: esFinal
                        ? color
                        : paso.cumple == true
                            ? color.withValues(alpha: 0.5)
                            : paso.cumple == false
                                ? Colors.red.withValues(alpha: 0.4)
                                : colors.border,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    esFinal ? '✓' : paso.numero,
                    style: TextStyle(
                      fontSize: esFinal ? 11 : 10,
                      fontWeight: FontWeight.bold,
                      color: esFinal
                          ? Colors.white
                          : paso.cumple == true
                              ? color
                              : paso.cumple == false
                                  ? Colors.red
                                  : colors.textSecondary,
                    ),
                  ),
                ),
              ),

              // Título + detalle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paso.titulo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: esFinal ? color : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paso.detalle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                        height: 1.45,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
