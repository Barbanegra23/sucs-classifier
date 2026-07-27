import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter/material.dart';

// Carta de Casagrande.
// Las zonas se dibujan con un CustomPainter superpuesto cuya función
// de proyección usa exactamente los mismos reserved-sizes que fl_chart,
// eliminando el desfase entre sombreado y líneas.

class CasagrandeChart extends StatelessWidget {
  final double ll;
  final double pi;
  final String suelo;

  const CasagrandeChart({
    super.key,
    required this.ll,
    required this.pi,
    required this.suelo,
  });

  // ── Colores ──────────────────────────────────────────────────
  static const Color _dark      = Color(0xFF2F4F54);
  static const Color _lineaUCol = Color(0xFF8B6914);
  static const Color _colCL    = Color(0xFF4A7C9E);
  static const Color _colCH    = Color(0xFFB8860B);
  static const Color _colML    = Color(0xFF5A7A5A);
  static const Color _colMH    = Color(0xFFA0522D);
  static const Color _colCLML  = Color(0xFFE5662A);
  static const Color _axis     = Color(0xFF555555);

  // ── Parámetros del gráfico ───────────────────────────────────
  static const double _minX = 0, _maxX = 100, _minY = 0, _maxY = 70;

  // Estos valores deben coincidir EXACTAMENTE con los reservedSize
  // y axisNameSize declarados en FlTitlesData más abajo.
  static const double _reservedLeft   = 28;
  static const double _axisNameLeft   = 16; // axisNameSize del eje Y
  static const double _reservedBottom = 22;
  static const double _axisNameBottom = 16; // axisNameSize del eje X
  static const double _containerPad   = 8;  // padding del Container que envuelve LineChart
  static const double _padTop         = 12; // padding top del Container

  // Padding total desde el borde del Stack hasta el área de plot
  static const double _plotPadLeft   = _containerPad + _axisNameLeft + _reservedLeft;
  static const double _plotPadBottom = _containerPad + _axisNameBottom + _reservedBottom;
  static const double _plotPadTop    = _padTop;
  static const double _plotPadRight  = 16;

  // ── Fórmulas SUCS ────────────────────────────────────────────
  static double _lineaA(double x) => x < 20 ? 0 : 0.73 * (x - 20);
  static double _lineaU(double x) => x < 8  ? 0 : 0.9  * (x - 8);

  List<fl.FlSpot> _spots(double Function(double) fn,
      {double from = 0, double to = 100}) {
    return List.generate(((to - from) / 0.5).round() + 1, (i) {
      final x = from + i * 0.5;
      final y = fn(x).clamp(0.0, _maxY);
      return fl.FlSpot(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leyenda
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            _LeyendaItem(color: _dark,      label: 'Línea A'),
            _LeyendaItem(color: _lineaUCol, label: 'Línea U', dashed: true),
            _LeyendaItem(color: _colCL,     label: 'CL/OL',  filled: true),
            _LeyendaItem(color: _colCH,     label: 'CH/OH',  filled: true),
            _LeyendaItem(color: _colML,     label: 'ML/OL',  filled: true),
            _LeyendaItem(color: _colMH,     label: 'MH/OH',  filled: true),
            _LeyendaItem(color: _colCLML,   label: 'CL-ML',  filled: true),
            _LeyendaItem(color: _dark,      label: suelo,     isPoint: true),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 300,
          child: LayoutBuilder(builder: (_, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final plotW = w - _plotPadLeft - _plotPadRight;
            final plotH = h - _plotPadTop - _plotPadBottom;

            // Funciones de proyección data → píxeles
            double px(double dataX) =>
                _plotPadLeft + (dataX - _minX) / (_maxX - _minX) * plotW;
            double py(double dataY) =>
                _plotPadTop + (1 - (dataY - _minY) / (_maxY - _minY)) * plotH;

            return Stack(children: [
              // ── fl_chart (ejes, grilla, líneas, punto) ──────
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF5F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.fromLTRB(
                    _containerPad, _padTop, _plotPadRight, _containerPad),
                child: fl.LineChart(fl.LineChartData(
                  minX: _minX, maxX: _maxX, minY: _minY, maxY: _maxY,
                  clipData: const fl.FlClipData.all(),
                  gridData: fl.FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => fl.FlLine(
                        color: _axis.withValues(alpha: 0.12), strokeWidth: 1),
                    getDrawingVerticalLine: (_) => fl.FlLine(
                        color: _axis.withValues(alpha: 0.12), strokeWidth: 1),
                  ),
                  titlesData: fl.FlTitlesData(
                    leftTitles: fl.AxisTitles(
                      axisNameWidget: const Text('PI',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      axisNameSize: _axisNameLeft,
                      sideTitles: fl.SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: _reservedLeft,
                        getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                            style:
                                const TextStyle(fontSize: 10, color: _axis)),
                      ),
                    ),
                    bottomTitles: fl.AxisTitles(
                      axisNameWidget: const Text('LL',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      axisNameSize: _axisNameBottom,
                      sideTitles: fl.SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: _reservedBottom,
                        getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                            style:
                                const TextStyle(fontSize: 10, color: _axis)),
                      ),
                    ),
                    topTitles: const fl.AxisTitles(
                        sideTitles: fl.SideTitles(showTitles: false)),
                    rightTitles: const fl.AxisTitles(
                        sideTitles: fl.SideTitles(showTitles: false)),
                  ),
                  borderData: fl.FlBorderData(
                      show: true,
                      border: Border.all(color: _axis, width: 1)),
                  lineBarsData: [
                    // Línea A
                    fl.LineChartBarData(
                      spots: _spots(_lineaA),
                      isCurved: false,
                      color: _dark,
                      barWidth: 2,
                      dotData: const fl.FlDotData(show: false),
                    ),
                    // Línea U
                    fl.LineChartBarData(
                      spots: _spots(_lineaU),
                      isCurved: false,
                      color: _lineaUCol,
                      barWidth: 1.5,
                      dashArray: [6, 4],
                      dotData: const fl.FlDotData(show: false),
                    ),
                    // Punto del suelo
                    fl.LineChartBarData(
                      spots: [fl.FlSpot(ll.clamp(_minX, _maxX), pi.clamp(_minY, _maxY))],
                      color: Colors.transparent,
                      dotData: fl.FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) =>
                            _SoilDotPainter(suelo: suelo, ll: ll, pi: pi),
                      ),
                    ),
                  ],
                  extraLinesData: fl.ExtraLinesData(
                    extraLinesOnTop: true,
                    verticalLines: [
                      fl.VerticalLine(
                        x: 50,
                        color: _axis.withValues(alpha: 0.45),
                        strokeWidth: 1.5,
                        dashArray: [4, 3],
                        label: fl.VerticalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) => 'LL=50',
                          style: const TextStyle(color: _axis, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  lineTouchData: fl.LineTouchData(
                    touchTooltipData: fl.LineTouchTooltipData(
                      tooltipBgColor: _dark.withValues(alpha: 0.85),
                      getTooltipItems: (spots) => spots.map((s) {
                        if (s.barIndex == 2) {
                          return fl.LineTooltipItem(
                            '$suelo\nLL=${ll.toStringAsFixed(1)}  PI=${pi.toStringAsFixed(1)}',
                            const TextStyle(
                                color: Colors.white, fontSize: 11),
                          );
                        }
                        return null;
                      }).toList(),
                    ),
                  ),
                )),
              ),

              // ── Zonas coloreadas (CustomPainter con misma proyección) ──
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: _ZonesPainter(
                      px: px,
                      py: py,
                      lineaA: _lineaA,
                      lineaU: _lineaU,
                      colCL: _colCL,
                      colCH: _colCH,
                      colML: _colML,
                      colMH: _colMH,
                      colCLML: _colCLML,
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ),

        const SizedBox(height: 8),
        const _ZoneLabels(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAINTER DE ZONAS
// Recibe las mismas funciones px/py que se calculan en el LayoutBuilder,
// por lo que siempre está perfectamente alineado con fl_chart.
// ─────────────────────────────────────────────────────────────
class _ZonesPainter extends CustomPainter {
  final double Function(double) px;
  final double Function(double) py;
  final double Function(double) lineaA;
  final double Function(double) lineaU;
  final Color colCL, colCH, colML, colMH, colCLML;

  static const double _maxY = 70;
  static const double _step = 0.5;

  const _ZonesPainter({
    required this.px,
    required this.py,
    required this.lineaA,
    required this.lineaU,
    required this.colCL,
    required this.colCH,
    required this.colML,
    required this.colMH,
    required this.colCLML,
  });

  void _zone(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill);
  }

  void _label(Canvas canvas, String text, double dataX, double dataY, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(px(dataX) - tp.width / 2, py(dataY) - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── ML: debajo de Línea A, LL ∈ [0, 50] ─────────────────────
    {
      final p = Path()
        ..moveTo(px(0), py(0));
      for (double x = 0; x <= 50; x += _step) {
        p.lineTo(px(x), py(lineaA(x).clamp(0, _maxY)));
      }
      p..lineTo(px(50), py(0))
       ..close();
      _zone(canvas, p, colML);
      _label(canvas, 'ML\nu OL', 35, 5, colML);
    }

    // ── MH: debajo de Línea A, LL ∈ [50, 100] ───────────────────
    {
      final p = Path()
        ..moveTo(px(50), py(0));
      for (double x = 50; x <= 100; x += _step) {
        p.lineTo(px(x), py(lineaA(x).clamp(0, _maxY)));
      }
      p..lineTo(px(100), py(0))
       ..close();
      _zone(canvas, p, colMH);
      _label(canvas, 'MH\nu OH', 75, 8, colMH);
    }

    // ── CL: entre Línea A y Línea U, LL ∈ [0, 50] ───────────────
    {
      final p = Path()
        ..moveTo(px(8), py(0));
      // Sube por Línea U de LL=8 a LL=50
      for (double x = 8; x <= 50; x += _step) {
        p.lineTo(px(x), py(lineaU(x).clamp(0, _maxY)));
      }
      // Baja por Línea A de LL=50 a LL=20
      for (double x = 50; x >= 20; x -= _step) {
        p.lineTo(px(x), py(lineaA(x).clamp(0, _maxY)));
      }
      p..lineTo(px(20), py(0))
       ..lineTo(px(8), py(0))
       ..close();
      _zone(canvas, p, colCL);
      _label(canvas, 'CL\nu OL', 31, 16, colCL);
    }

    // ── CH: entre Línea A y Línea U, LL ∈ [50, 100] ─────────────
    {
      // Encuentra dónde Línea U sale del gráfico (PI >= 70)
      double llUmax = 100;
      for (double x = 50; x <= 100; x += _step) {
        if (lineaU(x) >= _maxY) { llUmax = x; break; }
      }
      final p = Path()
        ..moveTo(px(50), py(lineaA(50).clamp(0, _maxY)));
      // Sube por Línea U de LL=50 hasta donde sale
      for (double x = 50; x <= llUmax; x += _step) {
        p.lineTo(px(x), py(lineaU(x).clamp(0, _maxY)));
      }
      p..lineTo(px(llUmax), py(_maxY))
       ..lineTo(px(100), py(_maxY))
       ..lineTo(px(100), py(lineaA(100).clamp(0, _maxY)));
      // Baja por Línea A de LL=100 a LL=50
      for (double x = 100; x >= 50; x -= _step) {
        p.lineTo(px(x), py(lineaA(x).clamp(0, _maxY)));
      }
      p.close();
      _zone(canvas, p, colCH);
      _label(canvas, 'CH\nu OH', 72, 42, colCH);
    }

    // ── CL-ML: franja PI ∈ [4, 7], zona de transición ───────────
    // Límites horizontales: desde donde Línea A da PI=4 (LL≈25.5) hasta
    // donde da PI=7 (LL≈29.6), con techo en PI=7 y piso en PI=4.
    {
      // LL donde LineaA = 4: 0.73*(LL-20)=4 → LL=25.48
      // LL donde LineaA = 7: 0.73*(LL-20)=7 → LL=29.59
      const llA4 = 25.48, llA7 = 29.59;
      const llMin = 12.0; // intersección Línea A con PI=0 es LL=20, pero CL-ML empieza antes

      final p = Path()
        ..moveTo(px(llMin), py(4));
      // Borde superior: PI=7 constante de LL=llMin a LL=llA7
      for (double x = llMin; x <= llA7; x += _step) {
        p.lineTo(px(x), py(7));
      }
      // Borde derecho: sigue Línea A de PI=7 a PI=4 (de LL=29.59 a LL=25.48)
      for (double x = llA7; x >= llA4; x -= _step) {
        p.lineTo(px(x), py(lineaA(x).clamp(0, _maxY)));
      }
      // Borde inferior: PI=4 constante de LL=llA4 a LL=llMin
      for (double x = llA4; x >= llMin; x -= _step) {
        p.lineTo(px(x), py(4));
      }
      p.close();

      canvas.drawPath(p,
          Paint()
            ..color = colCLML.withValues(alpha: 0.40)
            ..style = PaintingStyle.fill);
      canvas.drawPath(p,
          Paint()
            ..color = colCLML.withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      _label(canvas, 'CL-ML', 20, 5.5, colCLML);
    }
  }

  @override
  bool shouldRepaint(_ZonesPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// PAINTER DEL PUNTO
// ─────────────────────────────────────────────────────────────
class _SoilDotPainter extends fl.FlDotPainter {
  final String suelo;
  final double ll;
  final double pi;
  static const Color _color = Color(0xFF2F4F54);

  const _SoilDotPainter(
      {required this.suelo, required this.ll, required this.pi});

  @override
  void draw(Canvas canvas, fl.FlSpot spot, Offset center) {
    canvas.drawCircle(center, 6,
        Paint()
          ..color = _color
          ..style = PaintingStyle.fill);
    canvas.drawCircle(center, 6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final tp = TextPainter(
      text: TextSpan(
          text: suelo,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();

    const pad = 5.0;
    final rect = Rect.fromLTWH(
        center.dx + 8, center.dy - 26, tp.width + pad * 2, tp.height + pad * 2);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = _color);
    tp.paint(canvas, Offset(rect.left + pad, rect.top + pad));

    final coord = TextPainter(
      text: TextSpan(
        text: '(${ll.toStringAsFixed(1)}, ${pi.toStringAsFixed(1)})',
        style: const TextStyle(color: _color, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    coord.paint(canvas, Offset(center.dx + 8, center.dy + 8));
  }

  @override
  Size getSize(fl.FlSpot _) => const Size(90, 50);
  @override
  Color get mainColor => _color;
  @override
  List<Object?> get props => [suelo, ll, pi];
  @override
  _SoilDotPainter lerp(fl.FlDotPainter a, fl.FlDotPainter b, double t) => this;
}

// ─────────────────────────────────────────────────────────────
// LEYENDA
// ─────────────────────────────────────────────────────────────
class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  final bool filled;
  final bool isPoint;

  const _LeyendaItem({
    required this.color,
    required this.label,
    this.dashed = false,
    this.filled = false,
    this.isPoint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPoint)
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle))
        else if (filled)
          Container(
              width: 16,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)))
        else
          Container(width: 16, height: 2.5, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ETIQUETAS DE ZONAS
// ─────────────────────────────────────────────────────────────
class _ZoneLabels extends StatelessWidget {
  const _ZoneLabels();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 10, color: Color(0xFF555555));
    return Wrap(
      spacing: 16,
      runSpacing: 2,
      children: const [
        Text('CL/OL — Arcilla baja plas. (LL<50, PI>A)', style: style),
        Text('CH/OH — Arcilla alta plas. (LL≥50, PI>A)', style: style),
        Text('ML/OL — Limo baja plas. (LL<50, PI<A)',    style: style),
        Text('MH/OH — Limo alta plas. (LL≥50, PI<A)',    style: style),
        Text('CL-ML — Zona transición (PI∈[4,7])',       style: style),
      ],
    );
  }
}
