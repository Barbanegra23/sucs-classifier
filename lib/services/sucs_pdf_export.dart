import 'package:flutter/material.dart' show BuildContext, Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/sucs_classifier.dart';
import '../services/sucs_historial_service.dart' show DatosMuestra;
import 'dart:math' as math;
import '../logic/sucs_interpretation.dart';

// =============================================================
// PDF EXPORT — 2 páginas
//   Página 1: Portada  (símbolo, datos ingresados, muestra)
//   Página 2: Informe  (resumen, interpretación, recomendaciones, chart)
// =============================================================

class SucsPdfExport {
  static Future<void> exportar({
    required BuildContext context,
    required SucsResult resultado,
    required double pasa200,
    required double retenidoN4,
    required double ll,
    required double lp,
    double? cu,
    double? cc,
    double? d10,
    double? d30,
    double? d60,
    DatosMuestra? muestra,
  }) async {
    final pdf = pw.Document();

    // ── Colores ──────────────────────────────────────────────
    final headerColor = _toPdf(colorDeSuelo(resultado.symbol));
    final white = PdfColors.white;
    final textDark = PdfColor.fromInt(0xFF1A1A2E);
    final textGrey = PdfColor.fromInt(0xFF666666);
    final bgPage = PdfColor.fromInt(0xFFFAFAFA);
    final bgCard = PdfColor.fromInt(0xFFF5F5F5);

    // ── Datos derivados ──────────────────────────────────────
    final pi = resultado.pi;
    final lineaAval = (0.73 * (ll - 20)).clamp(0.0, 999.0);
    final sobreA = pi >= lineaAval;
    // Misma regla que el clasificador (PI < 4 → limoso aunque esté sobre A).
    final tipoFinos = clasificarFinos(ll, pi);
    final esGrueso = pasa200 < 50.0;
    final chips = _chips(resultado.symbol, pi);
    final resumen = SucsInterpretation.generarResumen(resultado.symbol, pi, ll);
    final interp =
        SucsInterpretation.interpretacionIngenieril(resultado.symbol);
    final recs = SucsInterpretation.generarRecomendaciones(
        resultado.symbol, pi, ll,
        d10: d10);
    final now = DateTime.now();
    final helvetica = PdfFont.helvetica(pdf.document);
    final nombreArchivo = muestra != null && muestra.nombre.isNotEmpty
        ? 'SUCS_${resultado.symbol}_${muestra.nombre.replaceAll(' ', '_')}'
        : 'SUCS_${resultado.symbol}';

    // ════════════════════════════════════════════════════════
    // PÁGINA ÚNICA — header compacto + franja de datos +
    // columna izquierda de texto + columna derecha de gráfico
    // ════════════════════════════════════════════════════════
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(
        children: [
          // ── Header compacto ──────────────────────────────
          pw.Container(
            width: double.infinity,
            color: headerColor,
            padding: const pw.EdgeInsets.fromLTRB(28, 16, 28, 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Símbolo
                pw.Text(
                  resultado.symbol,
                  style: pw.TextStyle(
                      color: white,
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(width: 14),
                pw.Container(
                    width: 1,
                    height: 26,
                    color: PdfColor(1, 1, 1, 0.35)),
                pw.SizedBox(width: 14),
                // Descripción + chips
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        resultado.description,
                        style: pw.TextStyle(
                            color: white,
                            fontSize: 11.5,
                            font: pw.Font.helveticaBold()),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: chips
                            .map((c) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColor(
                                      (headerColor.red + 0.25).clamp(0.0, 1.0),
                                      (headerColor.green + 0.25).clamp(0.0, 1.0),
                                      (headerColor.blue + 0.25).clamp(0.0, 1.0),
                                    ),
                                    borderRadius: const pw.BorderRadius.all(
                                        pw.Radius.circular(10)),
                                    border: pw.Border.all(
                                        color: PdfColor(1, 1, 1, 0.5),
                                        width: 0.5),
                                  ),
                                  child: pw.Text(c,
                                      style: pw.TextStyle(
                                          fontSize: 7.5,
                                          color: white,
                                          font: pw.Font.helveticaBold())),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                // Badge derecho: PI / Cu + norma + fecha
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(
                      (headerColor.red + 0.18).clamp(0.0, 1.0),
                      (headerColor.green + 0.18).clamp(0.0, 1.0),
                      (headerColor.blue + 0.18).clamp(0.0, 1.0),
                    ),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('CLASIFICACION SUCS',
                          style: pw.TextStyle(
                              fontSize: 6.5,
                              color: white,
                              letterSpacing: 0.8,
                              font: pw.Font.helveticaBold())),
                      pw.SizedBox(height: 4),
                      if (!esGrueso || pi > 0) ...[
                        pw.Text('PI = ${pi.toStringAsFixed(1)}',
                            style: pw.TextStyle(
                                fontSize: 13,
                                color: white,
                                font: pw.Font.helveticaBold())),
                        pw.Text(etiquetaFinos(tipoFinos).replaceAll(' (CL-ML)', ''),
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: white)),
                        pw.SizedBox(height: 4),
                      ],
                      pw.Text('ASTM D2487',
                          style: pw.TextStyle(
                              fontSize: 7,
                              color: white)),
                      pw.SizedBox(height: 2),
                      pw.Text(_formatFecha(now),
                          style: pw.TextStyle(
                              fontSize: 7,
                              color: white)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Franja de datos de entrada ────────────────────
          pw.Container(
            width: double.infinity,
            color: bgCard,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 7),
            child: pw.Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _datoChip('P200', '${pasa200.toStringAsFixed(1)} %',
                    textDark, textGrey),
                _datoChip('R4', '${retenidoN4.toStringAsFixed(1)} %',
                    textDark, textGrey),
                if (pasa200 >= 5.0) ...[
                  _datoChip('LL', ll.toStringAsFixed(0), textDark, textGrey),
                  _datoChip('LP', lp.toStringAsFixed(0), textDark, textGrey),
                  _datoChip('PI', pi.toStringAsFixed(1), headerColor, headerColor),
                ],
                if (cu != null)
                  _datoChip('Cu', cu.toStringAsFixed(2), headerColor, headerColor),
                if (cc != null)
                  _datoChip('Cc', cc.toStringAsFixed(3), textDark, textGrey),
                if (d10 != null)
                  _datoChip('D10', '${d10.toStringAsFixed(3)} mm', textDark, textGrey),
                if (d30 != null)
                  _datoChip('D30', '${d30.toStringAsFixed(3)} mm', textDark, textGrey),
                if (d60 != null)
                  _datoChip('D60', '${d60.toStringAsFixed(3)} mm', textDark, textGrey),
              ],
            ),
          ),

          // ── Cuerpo: 2 columnas ────────────────────────────
          pw.Expanded(
            child: pw.Container(
              color: bgPage,
              padding: const pw.EdgeInsets.fromLTRB(28, 14, 28, 0),
              child: pw.Column(
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // ── Columna izquierda: texto ──────────
                        pw.Expanded(
                          flex: 44,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Datos de la muestra
                              if (muestra != null) ...[
                                _secTitle('DATOS DE LA MUESTRA', headerColor),
                                pw.SizedBox(height: 6),
                                _buildMuestraCard(
                                  muestra: muestra,
                                  headerColor: headerColor,
                                  textDark: textDark,
                                  textGrey: textGrey,
                                  bgCard: bgCard,
                                ),
                                pw.SizedBox(height: 14),
                              ],

                              // Resumen
                              _secTitle('RESUMEN', headerColor),
                              pw.SizedBox(height: 4),
                              pw.Text(resumen,
                                  style: pw.TextStyle(
                                      fontSize: 9.5, color: textDark)),

                              pw.SizedBox(height: 14),

                              // Interpretación ingenieril
                              _secTitle(
                                  'INTERPRETACION INGENIERIL', headerColor),
                              pw.SizedBox(height: 4),
                              ...interp.map((item) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 4),
                                    child: pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          width: 4,
                                          height: 4,
                                          margin: const pw.EdgeInsets.only(
                                              top: 3, right: 6),
                                          decoration: pw.BoxDecoration(
                                            color: headerColor,
                                            shape: pw.BoxShape.circle,
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(item,
                                              style: pw.TextStyle(
                                                  fontSize: 9.5,
                                                  color: textDark)),
                                        ),
                                      ],
                                    ),
                                  )),

                              pw.SizedBox(height: 14),

                              // Recomendaciones
                              _secTitle('RECOMENDACIONES', headerColor),
                              pw.SizedBox(height: 4),
                              ...recs.map((r) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 4),
                                    child: pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text('- ',
                                            style: pw.TextStyle(
                                                fontSize: 9.5,
                                                color: headerColor,
                                                fontWeight:
                                                    pw.FontWeight.bold)),
                                        pw.Expanded(
                                          child: pw.Text(r,
                                              style: pw.TextStyle(
                                                  fontSize: 9.5,
                                                  color: textGrey)),
                                        ),
                                      ],
                                    ),
                                  )),

                              // ── Línea A (solo suelos finos) ──────
                              if (!esGrueso) ...[
                                pw.SizedBox(height: 14),
                                pw.Container(
                                  padding:
                                      const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                        left: pw.BorderSide(
                                            color: headerColor, width: 2)),
                                    color: PdfColor.fromInt(0xFFF8F8F8),
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      _secTitle('LINEA A', headerColor),
                                      pw.SizedBox(height: 5),
                                      pw.Text(
                                          'PI = 0.73 x (LL-20) = 0.73 x (${ll.toStringAsFixed(0)}-20) = ${lineaAval.toStringAsFixed(2)}',
                                          style: pw.TextStyle(
                                              fontSize: 8.5, color: textGrey)),
                                      pw.SizedBox(height: 6),
                                      pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          _datoChip('LL', ll.toStringAsFixed(0),
                                              textDark, textGrey),
                                          _datoChip('PI', pi.toStringAsFixed(1),
                                              textDark, textGrey),
                                          _datoChip('A',
                                              lineaAval.toStringAsFixed(2),
                                              textDark, textGrey),
                                        ],
                                      ),
                                      pw.SizedBox(height: 8),
                                      pw.Container(
                                        width: double.infinity,
                                        padding: const pw.EdgeInsets.symmetric(
                                            vertical: 5),
                                        decoration: pw.BoxDecoration(
                                          color: headerColor,
                                          borderRadius:
                                              const pw.BorderRadius.all(
                                                  pw.Radius.circular(5)),
                                        ),
                                        child: pw.Center(
                                          child: pw.Text(
                                            '${sobreA ? 'PI >= A' : 'PI < A'}${sobreA && pi < 4 ? ', PI < 4' : ''}  ->  ${etiquetaFinos(tipoFinos).replaceAll(' (CL-ML)', '')}',
                                            style: pw.TextStyle(
                                                fontSize: 8.5,
                                                color: white,
                                                font: pw.Font.helveticaBold()),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        pw.SizedBox(width: 20),

                        // ── Columna derecha: gráfico ──────────
                        pw.Expanded(
                          flex: 56,
                          child: esGrueso
                              ? _colGranulometria(
                                  resultado.symbol,
                                  headerColor,
                                  textDark,
                                  textGrey,
                                  pasa200,
                                  retenidoN4,
                                  d10,
                                  d30,
                                  d60,
                                  helvetica)
                              : _colCasagrande(
                                  resultado.symbol,
                                  headerColor,
                                  textDark,
                                  textGrey,
                                  ll,
                                  pi,
                                  helvetica),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  _buildFooter(textGrey: textGrey),
                ],
              ),
            ),
          ),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '$nombreArchivo.pdf',
    );
  }

  // ──────────────────────────────────────────────────────────
  // BLOQUE: MUESTRA (portada)
  // ──────────────────────────────────────────────────────────
  static pw.Widget _buildMuestraCard({
    required DatosMuestra muestra,
    required PdfColor headerColor,
    required PdfColor textDark,
    required PdfColor textGrey,
    required PdfColor bgCard,
  }) {
    final campos = <_MuestraCampo>[
      _MuestraCampo('Muestra', muestra.nombre),
      if (muestra.expediente.isNotEmpty)
        _MuestraCampo('Expediente / Obra', muestra.expediente),
      if (muestra.proyectoNombre.isNotEmpty)
        _MuestraCampo('Proyecto', muestra.proyectoNombre),
      if (muestra.ubicacion.isNotEmpty)
        _MuestraCampo('Ubicacion', muestra.ubicacion),
      if (muestra.profundidad.isNotEmpty)
        _MuestraCampo('Profundidad', muestra.profundidad),
      if (muestra.operador.isNotEmpty)
        _MuestraCampo('Operador', muestra.operador),
      _MuestraCampo('Fecha', _formatFecha(muestra.fechaHora)),
    ];

    // Dos columnas de campos
    final izq = <_MuestraCampo>[];
    final der = <_MuestraCampo>[];
    for (var i = 0; i < campos.length; i++) {
      if (i.isEven) {
        izq.add(campos[i]);
      } else {
        der.add(campos[i]);
      }
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgCard,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: headerColor, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Barra lateral
          pw.Container(
            width: 3,
            margin: const pw.EdgeInsets.only(right: 14),
            decoration: pw.BoxDecoration(
              color: headerColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
          ),
          // Columna izquierda
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  izq.map((c) => _campoMuestra(c, textDark, textGrey)).toList(),
            ),
          ),
          pw.SizedBox(width: 20),
          // Columna derecha
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  der.map((c) => _campoMuestra(c, textDark, textGrey)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _campoMuestra(
      _MuestraCampo campo, PdfColor textDark, PdfColor textGrey) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(campo.label.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 7,
                  color: textGrey,
                  letterSpacing: 0.5,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(campo.value,
              style: pw.TextStyle(
                  fontSize: 10,
                  color: textDark,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FOOTER
  // ──────────────────────────────────────────────────────────
  static pw.Widget _buildFooter({required PdfColor textGrey}) {
    return pw.Column(children: [
      pw.Divider(color: PdfColor.fromInt(0xFFDDDDDD)),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Clasificador SUCS  -  ASTM D2487 - USCS',
                style: pw.TextStyle(fontSize: 7.5, color: textGrey)),
            pw.Text('Pagina 1 de 1',
                style: pw.TextStyle(
                    fontSize: 7.5,
                    color: textGrey,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    ]);
  }

  // ──────────────────────────────────────────────────────────
  // DATO CHIP (franja de datos de entrada)
  // ──────────────────────────────────────────────────────────
  static pw.Widget _datoChip(
      String label, String valor, PdfColor labelColor, PdfColor valorColor) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ',
            style: pw.TextStyle(
                fontSize: 8,
                color: labelColor.shade(0.7),
                fontWeight: pw.FontWeight.bold)),
        pw.Text(valor,
            style: pw.TextStyle(
                fontSize: 9,
                color: valorColor,
                fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // COLUMNA DERECHA: CASAGRANDE (suelos finos)
  // ──────────────────────────────────────────────────────────
  static pw.Widget _colCasagrande(
    String simbolo,
    PdfColor headerColor,
    PdfColor textDark,
    PdfColor textGrey,
    double ll,
    double pi,
    PdfFont helvetica,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _secTitle('CARTA DE CASAGRANDE', headerColor),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Panel izquierdo: leyenda líneas + zonas ──────
            pw.SizedBox(
              width: 78,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _leyenda('Linea A', textDark),
                  pw.SizedBox(height: 5),
                  _leyenda('Linea U', PdfColor.fromInt(0xFF8B6914)),
                  pw.SizedBox(height: 5),
                  _leyenda(simbolo, headerColor, isPoint: true),
                  pw.SizedBox(height: 14),
                  _secTitle('ZONAS', headerColor),
                  pw.SizedBox(height: 5),
                  _zonaRow('CL',    'Arcilla baja plas.', PdfColor.fromInt(0xFF5B8DB8)),
                  pw.SizedBox(height: 3),
                  _zonaRow('CH',    'Arcilla alta plas.', PdfColor.fromInt(0xFFB8A05B)),
                  pw.SizedBox(height: 3),
                  _zonaRow('ML',    'Limo baja plas.',    PdfColor.fromInt(0xFF6BA368)),
                  pw.SizedBox(height: 3),
                  _zonaRow('MH',    'Limo alta plas.',    PdfColor.fromInt(0xFFB87A5B)),
                  pw.SizedBox(height: 3),
                  _zonaRow('CL-ML', 'Transicion',         PdfColor.fromInt(0xFF8B5B8B)),
                ],
              ),
            ),

            pw.SizedBox(width: 8),

            // ── Gráfico más ancho ────────────────────────────
            pw.Expanded(
              child: pw.Container(
                height: 270,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFEF5F0),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: headerColor, width: 0.5),
                ),
                child: pw.CustomPaint(
                  size: const PdfPoint(196, 270),
                  painter: (canvas, pdfSize) {
                    _drawCasagrande(canvas, pdfSize, ll, pi, simbolo,
                        headerColor, helvetica);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // COLUMNA DERECHA: GRANULOMETRÍA (suelos gruesos)
  // ──────────────────────────────────────────────────────────
  static pw.Widget _colGranulometria(
    String simbolo,
    PdfColor headerColor,
    PdfColor textDark,
    PdfColor textGrey,
    double pasa200,
    double retenidoN4,
    double? d10,
    double? d30,
    double? d60,
    PdfFont font,
  ) {
    double? cu;
    double? cc;
    if (d10 != null && d30 != null && d60 != null && d10 > 0 && d60 > 0) {
      (cu, cc) = calcularCuCc(d10: d10, d30: d30, d60: d60);
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _secTitle('CURVA GRANULOMETRICA', headerColor),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 270,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF8FAFB),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: headerColor, width: 0.5),
          ),
          child: pw.CustomPaint(
            size: const PdfPoint(270, 270),
            painter: (canvas, size) {
              _drawGranulometria(canvas, size, pasa200, retenidoN4, d10, d30,
                  d60, headerColor, font);
            },
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border:
                pw.Border(left: pw.BorderSide(color: headerColor, width: 2.5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _secTitle('DATOS GRANULOMETRICOS', headerColor),
              pw.SizedBox(height: 4),
              _granRow('% Pasa N200', '${pasa200.toStringAsFixed(1)}%',
                  textDark, textGrey),
              _granRow('% Ret. N4', '${retenidoN4.toStringAsFixed(1)}%',
                  textDark, textGrey),
              if (d10 != null)
                _granRow(
                    'D10', '${d10.toStringAsFixed(3)} mm', textDark, textGrey),
              if (d30 != null)
                _granRow(
                    'D30', '${d30.toStringAsFixed(3)} mm', textDark, textGrey),
              if (d60 != null)
                _granRow(
                    'D60', '${d60.toStringAsFixed(3)} mm', textDark, textGrey),
              if (cu != null)
                _granRow('Cu = D60/D10', cu.toStringAsFixed(2), headerColor,
                    headerColor),
              if (cc != null)
                _granRow('Cc = D30^2/(D10*D60)', cc.toStringAsFixed(2),
                    headerColor, headerColor),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // CURVA GRANULOMETRICA (CustomPaint, escala log)
  // ──────────────────────────────────────────────────────────
  static void _drawGranulometria(
    PdfGraphics canvas,
    PdfPoint size,
    double pasa200,
    double retenidoN4,
    double? d10,
    double? d30,
    double? d60,
    PdfColor accent,
    PdfFont font,
  ) {
    const padL = 28.0, padB = 22.0, padR = 8.0, padT = 8.0;
    final plotW = size.x - padL - padR;
    final plotH = size.y - padB - padT;
    const logMin = -3.0, logMax = 2.0;

    double px(double diam) {
      final log = math.log(diam) / math.ln10;
      return padL + ((log - logMin) / (logMax - logMin)) * plotW;
    }

    double py(double pct) => padB + (pct / 100) * plotH;

    canvas
      ..setFillColor(PdfColor.fromInt(0xFFF8FAFB))
      ..drawRect(0, 0, size.x, size.y)
      ..fillPath();

    final xFino = px(0.075);
    canvas
      ..setFillColor(PdfColor.fromInt(0xFFE8F0F8))
      ..drawRect(padL, padB, xFino - padL, plotH)
      ..fillPath();
    canvas
      ..setFillColor(PdfColor.fromInt(0xFFF3EDE6))
      ..drawRect(xFino, padB, plotW - (xFino - padL), plotH)
      ..fillPath();
    canvas
      ..setStrokeColor(PdfColor.fromInt(0xFF9999AA))
      ..setLineWidth(0.8)
      ..moveTo(xFino, padB)
      ..lineTo(xFino, padB + plotH)
      ..strokePath();

    for (final diam in [0.425, 2.0, 4.75, 19.0]) {
      final x = px(diam);
      if (x < padL || x > padL + plotW) continue;
      canvas
        ..setStrokeColor(PdfColor.fromInt(0xFFCCCCCC))
        ..setLineWidth(0.4)
        ..moveTo(x, padB)
        ..lineTo(x, padB + plotH)
        ..strokePath();
    }

    canvas.setStrokeColor(PdfColor.fromInt(0xFFDDDDDD));
    canvas.setLineWidth(0.5);
    for (var pct = 0; pct <= 100; pct += 10) {
      canvas
        ..moveTo(padL, py(pct.toDouble()))
        ..lineTo(padL + plotW, py(pct.toDouble()))
        ..strokePath();
    }

    canvas
      ..setStrokeColor(PdfColor.fromInt(0xFF888888))
      ..setLineWidth(0.8)
      ..drawRect(padL, padB, plotW, plotH)
      ..strokePath();

    for (var pct = 0; pct <= 100; pct += 20) {
      canvas
        ..setFillColor(PdfColor.fromInt(0xFF666666))
        ..drawString(font, 5.5, '$pct', 2, py(pct.toDouble()) - 2);
    }

    final tamicesLabel = [
      (0.075, 'N200'),
      (0.425, 'N40'),
      (2.0, 'N10'),
      (4.75, 'N4'),
      (19.0, '3/4"'),
    ];
    for (final (diam, label) in tamicesLabel) {
      final x = px(diam);
      if (x < padL || x > padL + plotW) continue;
      canvas
        ..setFillColor(PdfColor.fromInt(0xFF666666))
        ..drawString(font, 5.0, label, x - 8, padB - 11);
    }

    canvas
      ..setFillColor(PdfColor.fromInt(0xFF888888))
      ..drawString(font, 5.5, '% Pasa', 2, py(55))
      ..drawString(font, 5.5, 'Diametro (mm)', padL + plotW / 2 - 20, 2);

    final puntos = <(double, double)>[];
    puntos.add((0.075, pasa200));
    puntos.add((4.75, 100 - retenidoN4));
    if (100 - retenidoN4 < 100) puntos.add((75.0, 100.0));
    if (d10 != null && d10 > 0) puntos.add((d10, 10));
    if (d30 != null && d30 > 0) puntos.add((d30, 30));
    if (d60 != null && d60 > 0) puntos.add((d60, 60));
    if (d10 != null && d10 > 0 && d10 > 0.2) {
      final dMid = math.sqrt(0.075 * d10);
      final pMid = (pasa200 + 10) / 2;
      puntos.add((dMid, pMid));
    }
    puntos.sort((a, b) => a.$1.compareTo(b.$1));

    final screenX = puntos.map((p) => px(p.$1)).toList();
    final screenY = puntos.map((p) => py(p.$2)).toList();
    final ptN = screenX.length;

    final tgX = List.filled(ptN, 0.0);
    final tgY = List.filled(ptN, 0.0);
    for (int i = 0; i < ptN; i++) {
      final prev = i > 0 ? i - 1 : 0;
      final next = i < ptN - 1 ? i + 1 : ptN - 1;
      tgX[i] = (screenX[next] - screenX[prev]) / 2;
      tgY[i] = (screenY[next] - screenY[prev]) / 2;
    }

    canvas.setFillColor(PdfColor(accent.red, accent.green, accent.blue, 0.10));
    canvas.moveTo(screenX[0], padB);
    canvas.lineTo(screenX[0], screenY[0]);
    for (int i = 0; i < ptN - 1; i++) {
      canvas.curveTo(
        screenX[i] + tgX[i] / 3,
        screenY[i] + tgY[i] / 3,
        screenX[i + 1] - tgX[i + 1] / 3,
        screenY[i + 1] - tgY[i + 1] / 3,
        screenX[i + 1],
        screenY[i + 1],
      );
    }
    canvas.lineTo(screenX[ptN - 1], padB);
    canvas.closePath();
    canvas.fillPath();

    canvas
      ..setStrokeColor(accent)
      ..setLineWidth(1.8);
    canvas.moveTo(screenX[0], screenY[0]);
    for (int i = 0; i < ptN - 1; i++) {
      canvas.curveTo(
        screenX[i] + tgX[i] / 3,
        screenY[i] + tgY[i] / 3,
        screenX[i + 1] - tgX[i + 1] / 3,
        screenY[i + 1] - tgY[i + 1] / 3,
        screenX[i + 1],
        screenY[i + 1],
      );
    }
    canvas.strokePath();

    for (final (d, p) in puntos) {
      canvas
        ..setFillColor(accent)
        ..drawEllipse(px(d), py(p), 3, 3)
        ..fillPath()
        ..setStrokeColor(PdfColors.white)
        ..setLineWidth(1)
        ..drawEllipse(px(d), py(p), 3, 3)
        ..strokePath();
    }

    void drawDashed(double diam, String label) {
      if (diam <= 0) return;
      final x = px(diam);
      if (x < padL || x > padL + plotW) return;
      canvas.setStrokeColor(PdfColor.fromInt(0xFF2F4F54));
      canvas.setLineWidth(0.7);
      var y = padB.toDouble();
      bool on = true;
      while (y < padB + plotH) {
        final seg = on ? 4.0 : 3.0;
        if (on) {
          canvas.moveTo(x, y);
          canvas.lineTo(x, math.min(y + seg, padB + plotH));
          canvas.strokePath();
        }
        y += seg;
        on = !on;
      }
      canvas
        ..setFillColor(PdfColor.fromInt(0xFF2F4F54))
        ..drawString(font, 5.5, label, x + 2, padB + plotH - 10);
    }

    if (d10 != null && d10 > 0) drawDashed(d10, 'D10');
    if (d30 != null && d30 > 0) drawDashed(d30, 'D30');
    if (d60 != null && d60 > 0) drawDashed(d60, 'D60');
  }

  // ──────────────────────────────────────────────────────────
  // CARTA DE CASAGRANDE (CustomPaint)
  // ──────────────────────────────────────────────────────────
  static void _drawCasagrande(
    PdfGraphics canvas,
    PdfPoint size,
    double ll,
    double pi,
    String simbolo,
    PdfColor accent,
    PdfFont font,
  ) {
    const minX = 0.0, maxX = 100.0, minY = 0.0, maxY = 70.0;
    const padL = 28.0, padB = 20.0, padR = 8.0, padT = 8.0;
    final plotW = size.x - padL - padR;
    final plotH = size.y - padB - padT;

    double px(double x) => padL + (x - minX) / (maxX - minX) * plotW;
    double py(double y) => padB + (y - minY) / (maxY - minY) * plotH;

    canvas
      ..setFillColor(PdfColor.fromInt(0xFFFEF5F0))
      ..drawRect(0, 0, size.x, size.y)
      ..fillPath();

    canvas
      ..setStrokeColor(PdfColor.fromInt(0xFFDDDDDD))
      ..setLineWidth(0.3);
    for (var xi = 0; xi <= 100; xi += 10) {
      canvas
        ..moveTo(px(xi.toDouble()), py(minY))
        ..lineTo(px(xi.toDouble()), py(maxY))
        ..strokePath();
    }
    for (var yi = 0; yi <= 70; yi += 10) {
      canvas
        ..moveTo(px(minX), py(yi.toDouble()))
        ..lineTo(px(maxX), py(yi.toDouble()))
        ..strokePath();
    }

    canvas
      ..setStrokeColor(PdfColor.fromInt(0xFF2F4F54))
      ..setLineWidth(1.2);
    bool firstA = true;
    for (double x = 0; x <= 100; x += 1) {
      final y = (0.73 * (x - 20)).clamp(0.0, maxY);
      if (firstA) {
        canvas.moveTo(px(x), py(y));
        firstA = false;
      } else {
        canvas.lineTo(px(x), py(y));
      }
    }
    canvas.strokePath();

    canvas
      ..setStrokeColor(PdfColor.fromInt(0xFF8B6914))
      ..setLineWidth(0.8);
    bool firstU = true;
    for (double x = 0; x <= 100; x += 1) {
      final y = (0.9 * (x - 8)).clamp(0.0, maxY);
      if (firstU) {
        canvas.moveTo(px(x), py(y));
        firstU = false;
      } else {
        canvas.lineTo(px(x), py(y));
      }
    }
    canvas.strokePath();

    canvas
      ..setStrokeColor(PdfColor.fromInt(0xFF999999))
      ..setLineWidth(0.5)
      ..moveTo(px(50), py(minY))
      ..lineTo(px(50), py(maxY))
      ..strokePath();

    // ── Etiquetas de zonas ─────────────────────────────
    void zoneLabel(String text, double lx, double lpi, PdfColor color) {
      canvas
        ..setFillColor(color)
        ..drawString(font, 6, text, px(lx), py(lpi));
    }
    zoneLabel('CL',    28, 20,  PdfColor.fromInt(0xFF5B8DB8));
    zoneLabel('CH',    65, 42,  PdfColor.fromInt(0xFFB8A05B));
    zoneLabel('ML',    28,  2,  PdfColor.fromInt(0xFF6BA368));
    zoneLabel('MH',    65,  8,  PdfColor.fromInt(0xFFB87A5B));
    zoneLabel('CL-ML', 20,  5,  PdfColor.fromInt(0xFF8B5B8B));

    canvas
      ..setStrokeColor(PdfColor.fromInt(0xFF555555))
      ..setLineWidth(0.8)
      ..drawRect(px(minX), py(minY), plotW, plotH)
      ..strokePath();

    for (var xi = 0; xi <= 100; xi += 20) {
      canvas
        ..setFillColor(PdfColor.fromInt(0xFF666666))
        ..drawString(font, 5.5, '$xi', px(xi.toDouble()) - 4, padB - 12);
    }
    canvas
      ..setFillColor(PdfColor.fromInt(0xFF888888))
      ..drawString(font, 5.5, 'Limite Liquido (LL)', px(30), padB - 12);

    for (var yi = 0; yi <= 60; yi += 10) {
      canvas
        ..setFillColor(PdfColor.fromInt(0xFF666666))
        ..drawString(font, 5.5, '$yi', 2, py(yi.toDouble()) - 2);
    }
    canvas
      ..setFillColor(PdfColor.fromInt(0xFF888888))
      ..drawString(font, 5.5, 'IP', 2, py(35));

    canvas
      ..setFillColor(PdfColor.fromInt(0xFF999999))
      ..drawString(font, 5.5, 'LL=50', px(50) + 2, py(maxY) - 9);

    final dotX = px(ll.clamp(minX, maxX));
    final dotY = py(pi.clamp(minY, maxY));
    canvas
      ..setFillColor(accent)
      ..drawEllipse(dotX, dotY, 5, 5)
      ..fillPath()
      ..setStrokeColor(PdfColors.white)
      ..setLineWidth(1.5)
      ..drawEllipse(dotX, dotY, 5, 5)
      ..strokePath();
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────
  static pw.Widget _zonaRow(String simbolo, String nombre, PdfColor color) =>
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 14,
            height: 8,
            decoration: pw.BoxDecoration(
              color: color.shade(0.3),
              border: pw.Border.all(color: color, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            child: pw.Center(
              child: pw.Text(
                simbolo,
                style: pw.TextStyle(
                    fontSize: 4.5,
                    color: color,
                    font: pw.Font.helveticaBold()),
              ),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(nombre,
              style: pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFF555555))),
        ],
      );

  static pw.Widget _secTitle(String text, PdfColor color) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      );

  static pw.Widget _granRow(String label, String value, PdfColor labelColor,
          PdfColor valueColor) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          children: [
            pw.Expanded(
                child: pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: labelColor,
                        fontWeight: pw.FontWeight.bold))),
            pw.Text(value, style: pw.TextStyle(fontSize: 8, color: valueColor)),
          ],
        ),
      );

  static pw.Widget _leyenda(String label, PdfColor color,
          {bool isPoint = false}) =>
      pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (isPoint)
            pw.Container(
              width: 8,
              height: 8,
              decoration:
                  pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
            )
          else
            pw.Container(width: 14, height: 2, color: color),
          pw.SizedBox(width: 4),
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8, color: PdfColor.fromInt(0xFF616161))),
        ],
      );

  static List<String> _chips(String simbolo, double pi) {
    final base = simbolo.split('-').first;
    final esDual = simbolo.contains('-') && simbolo != 'CL-ML';
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

    if (esDual) {
      chips.add('Simbolo dual');
    }

    if (simbolo == 'CL-ML') {
      chips.add('Zona de transicion');
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
      chips.add('Baja cohesion');
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
      chips.add('No plastico');
    }

    return chips;
  }

  static String _formatFecha(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}  $h:$min';
  }

  static PdfColor _toPdf(Color c) => PdfColor.fromInt(c.toARGB32());
}

// ─────────────────────────────────────────────────────────────
// DATA CLASSES AUXILIARES
// ─────────────────────────────────────────────────────────────

class _MuestraCampo {
  final String label;
  final String value;
  const _MuestraCampo(this.label, this.value);
}
