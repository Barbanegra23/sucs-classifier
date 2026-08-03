import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// =============================================================
// CURVA GRANULOMÉTRICA
// Grafica el % que pasa (eje Y) vs diámetro de partícula en mm
// (eje X, escala logarítmica). Muestra zonas de grava, arena
// gruesa, arena media, arena fina y finos. Incluye marcadores
// D10, D30 y D60 cuando están disponibles.
//
// NOTA SOBRE TEMA: el fondo del gráfico, ejes, grilla, marcadores
// D10/D30/D60 y textos de leyenda se resuelven desde
// context.appColors (soporte claro/oscuro). La paleta de colores
// de las zonas de clasificación (Arcilla/Limo/Arena.../Grava) se
// mantiene fija a propósito: es una paleta deliberadamente más
// variada que los 4 colores de resultado (soilClay/soilSilt/etc.)
// y, al dibujarse con alpha bajo (0.07–0.35), conserva buena
// legibilidad sobre fondo claro u oscuro sin necesidad de
// adaptarse por tema.
// =============================================================

/// Un punto en la curva: diámetro (mm) y % que pasa.
class PuntoGranulometrico {
  final double diametroMm;
  final double porcentajePasa;
  const PuntoGranulometrico(this.diametroMm, this.porcentajePasa);
}

class SucsGranulometriaChart extends StatelessWidget {
  final List<PuntoGranulometrico> puntos;
  final double? d10;
  final double? d30;
  final double? d60;
  final Color colorSuelo;

  const SucsGranulometriaChart({
    super.key,
    required this.puntos,
    required this.colorSuelo,
    this.d10,
    this.d30,
    this.d60,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Leyenda(colorSuelo: colorSuelo, d10: d10, d30: d30, d60: d60),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(builder: (_, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _GranulometriaPainter(
                  puntos: puntos,
                  d10: d10,
                  d30: d30,
                  d60: d60,
                  colorSuelo: colorSuelo,
                  axisColor: colors.textSecondary,
                  gridColor: colors.divider,
                  accentColor: colors.secondary,
                  labelBg: colors.card,
                  chartBg: colors.surface,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        const _ZonasLabels(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAINTER PRINCIPAL
// ─────────────────────────────────────────────────────────────
class _GranulometriaPainter extends CustomPainter {
  final List<PuntoGranulometrico> puntos;
  final double? d10;
  final double? d30;
  final double? d60;
  final Color colorSuelo;

  // Colores dependientes del tema (resueltos por el widget padre,
  // que sí tiene BuildContext — CustomPainter.paint() no lo tiene).
  final Color axisColor;
  final Color gridColor;
  final Color accentColor;
  final Color labelBg;
  final Color chartBg;

  // Rango del eje X en log10 (0.001 mm a 100 mm)
  static const double _logMin = -3.0; // log10(0.001)
  static const double _logMax = 2.0; // log10(100)

  // Padding interno del área de plot
  static const double _padLeft = 42;
  static const double _padRight = 12;
  static const double _padTop = 12;
  static const double _padBottom = 36;

  // Tamices estándar (diámetro mm, etiqueta)
  static const List<(double, String)> _tamices = [
    (0.001, ''),
    (0.002, '0.002'), // límite arcilla/limo
    (0.005, ''),
    (0.01, '0.01'),
    (0.02, ''),
    (0.05, '0.05'),
    (0.075, 'N200'), // límite fino/grueso
    (0.1, ''),
    (0.2, ''),
    (0.425, 'N40'),
    (0.85, ''),
    (2.0, 'N10'),
    (4.75, 'N4'),
    (9.5, '3/8"'),
    (19.0, '3/4"'),
    (25.4, '1"'),
    (50.0, '2"'),
    (100.0, ''),
  ];

  // Líneas Y (%)
  static const List<double> _gridY = [
    0,
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100
  ];

  const _GranulometriaPainter({
    required this.puntos,
    required this.colorSuelo,
    required this.axisColor,
    required this.gridColor,
    required this.accentColor,
    required this.labelBg,
    required this.chartBg,
    this.d10,
    this.d30,
    this.d60,
  });

  // Proyección X: diámetro mm → píxel
  double _px(double diam, double plotW) {
    final log = math.log(diam) / math.ln10;
    return _padLeft + ((log - _logMin) / (_logMax - _logMin)) * plotW;
  }

  // Proyección Y: % pasa → píxel
  double _py(double pct, double plotH) {
    return _padTop + (1 - pct / 100) * plotH;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _padLeft - _padRight;
    final plotH = size.height - _padTop - _padBottom;

    _dibujarZonas(canvas, size, plotW, plotH);
    _dibujarGrid(canvas, size, plotW, plotH);
    _dibujarEjes(canvas, size, plotW, plotH);
    _dibujarCurva(canvas, plotW, plotH);
    _dibujarDiametrosCaracteristicos(canvas, plotW, plotH);
  }

  // ── Zonas de clasificación ─────────────────────────────────
  // Paleta fija a propósito — ver nota de tema al inicio del archivo.
  void _dibujarZonas(Canvas canvas, Size size, double plotW, double plotH) {
    final zonas = [
      // (dMin mm, dMax mm, color, label, labelY%)
      (0.001, 0.002, const Color(0xFFC5794A), 'Arcilla', 65.0),
      (0.002, 0.075, const Color(0xFFB8AA60), 'Limo', 65.0),
      (0.075, 0.425, const Color(0xFF7FA86E), 'A. fina', 65.0),
      (0.425, 2.0, const Color(0xFF6E8FA8), 'A. media', 65.0),
      (2.0, 4.75, const Color(0xFF7A72A8), 'A. gruesa', 65.0),
      (4.75, 100.0, const Color(0xFF7A9A7A), 'Grava', 65.0),
    ];

    for (final (dMin, dMax, color, label, labelY) in zonas) {
      final x1 = _px(dMin, plotW);
      final x2 = _px(dMax, plotW);
      final y1 = _padTop.toDouble();
      final y2 = _padTop + plotH;

      // Fondo de zona
      canvas.drawRect(
        Rect.fromLTRB(x1, y1, x2, y2),
        Paint()..color = color.withValues(alpha: 0.07),
      );

      // Borde derecho de zona
      canvas.drawLine(
        Offset(x2, y1),
        Offset(x2, y2),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );

      // Etiqueta de zona (solo si hay espacio)
      final zoneW = x2 - x1;
      if (zoneW > 28) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        if (tp.width < zoneW - 4) {
          tp.paint(
            canvas,
            Offset(
              x1 + (zoneW - tp.width) / 2,
              _py(labelY, plotH) - tp.height / 2,
            ),
          );
        }
      }
    }
  }

  // ── Grilla ─────────────────────────────────────────────────
  void _dibujarGrid(Canvas canvas, Size size, double plotW, double plotH) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.7;

    for (final pct in _gridY) {
      final y = _py(pct.toDouble(), plotH);
      canvas.drawLine(Offset(_padLeft, y), Offset(_padLeft + plotW, y), paint);
    }
  }

  // ── Ejes + etiquetas ───────────────────────────────────────
  void _dibujarEjes(Canvas canvas, Size size, double plotW, double plotH) {
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.2;

    // Borde del plot
    canvas.drawRect(
      Rect.fromLTWH(_padLeft, _padTop, plotW, plotH),
      Paint()
        ..color = axisColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Etiquetas Y
    for (final pct in _gridY) {
      final y = _py(pct.toDouble(), plotH);
      final tp = TextPainter(
        text: TextSpan(
          text: '${pct.toInt()}',
          style: TextStyle(color: axisColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_padLeft - tp.width - 4, y - tp.height / 2));
    }

    // Etiqueta eje Y
    final yLabel = TextPainter(
      text: TextSpan(
        text: '% Pasa',
        style: TextStyle(
            color: axisColor, fontSize: 9, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(10, _padTop + plotH / 2 + yLabel.width / 2);
    canvas.rotate(-math.pi / 2);
    yLabel.paint(canvas, Offset.zero);
    canvas.restore();

    // Etiquetas X (tamices)
    for (final (diam, label) in _tamices) {
      if (label.isEmpty) continue;
      final x = _px(diam, plotW);
      if (x < _padLeft || x > _padLeft + plotW) continue;

      // tick
      canvas.drawLine(
        Offset(x, _padTop + plotH),
        Offset(x, _padTop + plotH + 4),
        axisPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: axisColor, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, _padTop + plotH + 6 + tp.width);
      canvas.rotate(-math.pi / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Etiqueta eje X
    final xLabel = TextPainter(
      text: TextSpan(
        text: 'Diámetro (mm)',
        style: TextStyle(
            color: axisColor, fontSize: 9, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabel.paint(
      canvas,
      Offset(
        _padLeft + (plotW - xLabel.width) / 2,
        size.height - 10,
      ),
    );
  }

  // ── Curva granulométrica ───────────────────────────────────
  void _dibujarCurva(Canvas canvas, double plotW, double plotH) {
    if (puntos.isEmpty) return;

    final sorted = [...puntos]
      ..sort((a, b) => a.diametroMm.compareTo(b.diametroMm));

    // Coordenadas de pantalla
    final xs = sorted
        .where((p) => p.diametroMm > 0)
        .map((p) => _px(p.diametroMm, plotW))
        .toList();
    final ys = sorted
        .where((p) => p.diametroMm > 0)
        .map((p) => _py(p.porcentajePasa, plotH))
        .toList();
    final n = xs.length;
    if (n < 2) return;

    // Tangentes Catmull-Rom en espacio de pantalla
    final tx = List.filled(n, 0.0);
    final ty = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final prev = i > 0 ? i - 1 : 0;
      final next = i < n - 1 ? i + 1 : n - 1;
      tx[i] = (xs[next] - xs[prev]) / 2;
      ty[i] = (ys[next] - ys[prev]) / 2;
    }

    // Construir path de la curva con cúbicas de Bézier
    final path = Path()..moveTo(xs[0], ys[0]);
    for (int i = 0; i < n - 1; i++) {
      path.cubicTo(
        xs[i] + tx[i] / 3,
        ys[i] + ty[i] / 3,
        xs[i + 1] - tx[i + 1] / 3,
        ys[i + 1] - ty[i + 1] / 3,
        xs[i + 1],
        ys[i + 1],
      );
    }

    // Sombra debajo de la curva (mismo path + cierre al fondo)
    final fillPath = Path.from(path);
    fillPath.lineTo(xs[n - 1], _padTop + plotH);
    fillPath.lineTo(xs[0], _padTop + plotH);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()..color = colorSuelo.withValues(alpha: 0.12),
    );

    // Línea de la curva
    canvas.drawPath(
      path,
      Paint()
        ..color = colorSuelo
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Puntos
    for (final p in sorted) {
      if (p.diametroMm <= 0) continue;
      final x = _px(p.diametroMm, plotW);
      final y = _py(p.porcentajePasa, plotH);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = colorSuelo);
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = chartBg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  // ── D10, D30, D60 ─────────────────────────────────────────
  void _dibujarDiametrosCaracteristicos(
      Canvas canvas, double plotW, double plotH) {
    for (final (d, label) in [(d10, 'D₁₀'), (d30, 'D₃₀'), (d60, 'D₆₀')]) {
      if (d == null || d <= 0) continue;
      final x = _px(d, plotW);
      if (x < _padLeft || x > _padLeft + plotW) continue;

      // Línea vertical punteada
      _dashLine(
        canvas,
        Offset(x, _padTop),
        Offset(x, _padTop + plotH),
        color: accentColor.withValues(alpha: 0.6),
      );

      // Etiqueta
      final tp = TextPainter(
        text: TextSpan(
          text: '$label\n${d.toStringAsFixed(3)}mm',
          style: TextStyle(
            color: accentColor,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      final bgRect = Rect.fromLTWH(
        x - tp.width / 2 - 3,
        _padTop + 4,
        tp.width + 6,
        tp.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        Paint()..color = labelBg.withValues(alpha: 0.92),
      );
      tp.paint(canvas, Offset(x - tp.width / 2, _padTop + 6));
    }
  }

  void _dashLine(Canvas canvas, Offset p1, Offset p2,
      {required Color color, double dashLen = 5, double gapLen = 3}) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len;
    final uy = dy / len;
    double pos = 0;
    bool drawing = true;
    while (pos < len) {
      final seg =
          drawing ? math.min(dashLen, len - pos) : math.min(gapLen, len - pos);
      if (drawing) {
        canvas.drawLine(
          Offset(p1.dx + ux * pos, p1.dy + uy * pos),
          Offset(p1.dx + ux * (pos + seg), p1.dy + uy * (pos + seg)),
          Paint()
            ..color = color
            ..strokeWidth = 1.2,
        );
      }
      pos += seg;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_GranulometriaPainter old) =>
      old.puntos != puntos ||
      old.d10 != d10 ||
      old.d30 != d30 ||
      old.d60 != d60 ||
      old.axisColor != axisColor ||
      old.gridColor != gridColor ||
      old.accentColor != accentColor ||
      old.labelBg != labelBg ||
      old.chartBg != chartBg ||
      old.colorSuelo != colorSuelo;
}

// ─────────────────────────────────────────────────────────────
// LEYENDA
// ─────────────────────────────────────────────────────────────
class _Leyenda extends StatelessWidget {
  final Color colorSuelo;
  final double? d10, d30, d60;
  const _Leyenda({required this.colorSuelo, this.d10, this.d30, this.d60});

  @override
  Widget build(BuildContext context) {
    final accent = context.appColors.secondary;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _LegItem(color: colorSuelo, label: 'Curva acumulada'),
        if (d10 != null)
          _LegItem(
              color: accent,
              label: 'D₁₀ = ${d10!.toStringAsFixed(3)} mm',
              dashed: true),
        if (d30 != null)
          _LegItem(
              color: accent,
              label: 'D₃₀ = ${d30!.toStringAsFixed(3)} mm',
              dashed: true),
        if (d60 != null)
          _LegItem(
              color: accent,
              label: 'D₆₀ = ${d60!.toStringAsFixed(3)} mm',
              dashed: true),
      ],
    );
  }
}

class _LegItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegItem(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 18,
        height: dashed ? 2 : 3,
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : color,
          border: dashed
              ? Border(bottom: BorderSide(color: color, width: 2))
              : null,
        ),
      ),
      const SizedBox(width: 5),
      Text(label,
          style:
              TextStyle(fontSize: 10, color: context.appColors.textSecondary)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// ETIQUETAS DE ZONAS
// ─────────────────────────────────────────────────────────────
class _ZonasLabels extends StatelessWidget {
  const _ZonasLabels();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 10, color: context.appColors.textSecondary);
    return Wrap(
      spacing: 14,
      runSpacing: 2,
      children: [
        Text('< 0.002 mm — Arcilla', style: style),
        Text('0.002–0.075 mm — Limo', style: style),
        Text('0.075–0.425 mm — Arena fina', style: style),
        Text('0.425–2 mm — Arena media', style: style),
        Text('2–4.75 mm — Arena gruesa', style: style),
        Text('> 4.75 mm — Grava', style: style),
      ],
    );
  }
}
