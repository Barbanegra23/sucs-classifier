import 'package:flutter/material.dart' show BuildContext, Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'aashto_classifier.dart';

// =============================================================
// PDF EXPORT AASHTO — 1 página
//   Header con símbolo + descripción
//   Franja de datos ingresados
//   Columna izquierda: detalle del resultado (tipo, GI, subrasante)
//   Columna derecha: tabla de referencia de los 11 grupos AASHTO,
//   con el grupo obtenido resaltado
// =============================================================

class AashtoPdfExport {
  static Future<void> exportar({
    required BuildContext context,
    required AashtoResult resultado,
    required double pasa10,
    required double pasa40,
    required double pasa200,
    required double ll,
    required double lp,
  }) async {
    final pdf = pw.Document();

    // ── Colores ──────────────────────────────────────────────
    final headerColor = _toPdf(colorDeGrupoAashto(resultado.grupo));
    final white = PdfColors.white;
    final textDark = PdfColor.fromInt(0xFF1A1A2E);
    final textGrey = PdfColor.fromInt(0xFF666666);
    final bgCard = PdfColor.fromInt(0xFFF5F5F5);

    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final nombreArchivo = 'AASHTO_${resultado.symbol.replaceAll(RegExp(r'[()]'), '')}';

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(
        children: [
          // ── Header ────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            color: headerColor,
            padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  resultado.symbol,
                  style: pw.TextStyle(
                      color: white,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(width: 16),
                pw.Container(
                    width: 1, height: 30, color: PdfColor(1, 1, 1, 0.35)),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        resultado.description,
                        style: pw.TextStyle(
                            color: white,
                            fontSize: 12.5,
                            fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        resultado.tipoMaterial,
                        style: pw.TextStyle(
                            color: PdfColor(1, 1, 1, 0.85), fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('CLASIFICADOR AASHTO',
                        style: pw.TextStyle(
                            color: PdfColor(1, 1, 1, 0.85),
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('AASHTO M 145 · ASTM D3282',
                        style: pw.TextStyle(
                            color: PdfColor(1, 1, 1, 0.7), fontSize: 7.5)),
                  ],
                ),
              ],
            ),
          ),

          // ── Franja de datos ingresados ───────────────────
          pw.Container(
            width: double.infinity,
            color: bgCard,
            padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            child: pw.Wrap(
              spacing: 22,
              runSpacing: 6,
              children: [
                _datoChip('% Pasa N°10', '${pasa10.toStringAsFixed(1)}%',
                    textGrey, textDark),
                _datoChip('% Pasa N°40', '${pasa40.toStringAsFixed(1)}%',
                    textGrey, textDark),
                _datoChip('% Pasa N°200', '${pasa200.toStringAsFixed(1)}%',
                    textGrey, textDark),
                _datoChip('LL', ll.toStringAsFixed(1), textGrey, textDark),
                _datoChip('LP', lp.toStringAsFixed(1), textGrey, textDark),
                _datoChip(
                    'PI', resultado.pi.toStringAsFixed(1), textGrey, textDark),
                _datoChip('Fecha', fecha, textGrey, textDark),
              ],
            ),
          ),

          // ── Cuerpo: dos columnas ──────────────────────────
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(28, 18, 28, 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Columna izquierda: detalle del resultado
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _secTitle('RESULTADO', headerColor),
                        pw.SizedBox(height: 8),
                        _filaDetalle('Grupo AASHTO', resultado.grupo, textDark,
                            textGrey),
                        _filaDetalle('Índice de Grupo (GI)',
                            resultado.gi.toString(), textDark, textGrey),
                        _filaDetalle('Tipo de material',
                            resultado.tipoMaterial, textDark, textGrey),
                        _filaDetalle('Calificación como subrasante',
                            resultado.calificacionSubrasante, textDark,
                            textGrey),
                        pw.SizedBox(height: 14),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: bgCard,
                            borderRadius:
                                const pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Text(
                            'El Índice de Grupo (GI) indica la calidad relativa '
                            'dentro del grupo asignado: cuanto más alto, peor '
                            'comportamiento esperado como subrasante. Se calcula '
                            'a partir del % que pasa el tamiz N°200, el Límite '
                            'Líquido y el Índice de Plasticidad, según la fórmula '
                            'de la norma AASHTO M 145 / ASTM D3282.',
                            style: pw.TextStyle(
                                fontSize: 8.5, color: textGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Columna derecha: tabla de referencia de grupos
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _secTitle('TABLA DE GRUPOS AASHTO', headerColor),
                        pw.SizedBox(height: 8),
                        _tablaGrupos(resultado.grupo, headerColor, textDark,
                            textGrey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildFooter(textGrey: textGrey),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '$nombreArchivo.pdf',
    );
  }

  // ──────────────────────────────────────────────────────────
  // TABLA DE REFERENCIA DE GRUPOS AASHTO
  // ──────────────────────────────────────────────────────────
  static const _grupos = [
    ('A-1-a', 'Granular', '—', '≤6'),
    ('A-1-b', 'Granular', '—', '≤6'),
    ('A-3', 'Granular', '—', 'NP'),
    ('A-2-4', 'Granular', '≤40', '≤10'),
    ('A-2-5', 'Granular', '≥41', '≤10'),
    ('A-2-6', 'Granular', '≤40', '≥11'),
    ('A-2-7', 'Granular', '≥41', '≥11'),
    ('A-4', 'Limo-arcilloso', '≤40', '≤10'),
    ('A-5', 'Limo-arcilloso', '≥41', '≤10'),
    ('A-6', 'Limo-arcilloso', '≤40', '≥11'),
    ('A-7-5/7-6', 'Limo-arcilloso', '≥41', '≥11'),
  ];

  static pw.Widget _tablaGrupos(String grupoActual, PdfColor headerColor,
      PdfColor textDark, PdfColor textGrey) {
    // El resultado puede ser "A-7-5" o "A-7-6"; ambos se muestran
    // agrupados como "A-7-5/7-6" en la tabla de referencia.
    final grupoParaComparar =
        grupoActual.startsWith('A-7') ? 'A-7-5/7-6' : grupoActual;

    pw.Widget celda(String texto, {bool header = false, bool activo = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(
          texto,
          style: pw.TextStyle(
            fontSize: 7.8,
            color: activo
                ? PdfColors.white
                : (header ? textDark : textGrey),
            fontWeight:
                (header || activo) ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2.8),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(1.3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
          children: [
            celda('Grupo', header: true),
            celda('Material', header: true),
            celda('LL', header: true),
            celda('IP', header: true),
          ],
        ),
        for (final (grupo, material, llTxt, piTxt) in _grupos)
          pw.TableRow(
            decoration: grupo == grupoParaComparar
                ? pw.BoxDecoration(color: headerColor)
                : null,
            children: [
              celda(grupo, activo: grupo == grupoParaComparar),
              celda(material, activo: grupo == grupoParaComparar),
              celda(llTxt, activo: grupo == grupoParaComparar),
              celda(piTxt, activo: grupo == grupoParaComparar),
            ],
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS DE ESTILO
  // ──────────────────────────────────────────────────────────
  static pw.Widget _secTitle(String text, PdfColor color) => pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 10.5, color: color, fontWeight: pw.FontWeight.bold),
      );

  static pw.Widget _filaDetalle(
      String etiqueta, String valor, PdfColor textDark, PdfColor textGrey) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(etiqueta, style: pw.TextStyle(fontSize: 8, color: textGrey)),
          pw.SizedBox(height: 2),
          pw.Text(valor,
              style: pw.TextStyle(
                  fontSize: 11.5,
                  color: textDark,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

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
                fontSize: 9, color: valorColor, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildFooter({required PdfColor textGrey}) {
    return pw.Column(children: [
      pw.Divider(color: PdfColor.fromInt(0xFFDDDDDD)),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Clasificador AASHTO  -  AASHTO M 145 - ASTM D3282',
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

  static PdfColor _toPdf(Color c) => PdfColor.fromInt(c.toARGB32());
}
