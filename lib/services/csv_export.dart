import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'historial_service.dart';

// =============================================================
// CSV EXPORT SERVICE
//
// Exporta el historial completo de muestras como archivo CSV.
// Usa solo dependencias ya presentes en el proyecto (printing,
// path_provider) para evitar conflictos de versiones.
//
// Estrategia por plataforma:
//   - Web:     descarga directa vía Printing.sharePdf
//   - Móvil / Desktop: guarda en Documents y muestra la ruta
//
// Columnas: N°, Nombre, Símbolo SUCS, Descripción, PI,
//           LL, LP, %Pasa200, %RetN4, Cu, Cc
// =============================================================

class CsvExport {
  CsvExport._();

  static const _headers = [
    'N°',
    'Nombre',
    'Símbolo SUCS',
    'Descripción',
    'PI',
    'LL',
    'LP',
    '% Pasa 200',
    '% Ret. N°4',
    'Cu',
    'Cc',
  ];

  /// Genera y exporta el CSV con el historial completo.
  static Future<void> exportar({
    required BuildContext context,
    required List<EntradaHistorial> historial,
  }) async {
    if (historial.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No hay muestras en el historial para exportar.'),
        ));
      }
      return;
    }

    try {
      final contenido = _generarCsv(historial);
      final bytes = Uint8List.fromList(utf8.encode(contenido));
      final nombreArchivo = 'sucs_historial_${_timestamp()}.csv';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$nombreArchivo');
        await file.writeAsBytes(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('CSV guardado en:\n${file.path}'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ));
        }
      }
    } catch (e, stack) {
      debugPrint('Error exportando CSV: $e');
      debugPrintStack(stackTrace: stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  static String _generarCsv(List<EntradaHistorial> historial) {
    final buf = StringBuffer();
    buf.write('\uFEFF'); // BOM UTF-8 para Excel
    buf.writeln(_headers.map(_escapar).join(','));
    for (var i = 0; i < historial.length; i++) {
      final e = historial[i];
      buf.writeln([
        (i + 1).toString(),
        e.nombreDisplay.isEmpty ? 'Muestra ${i + 1}' : e.nombreDisplay,
        e.resultado.symbol,
        e.resultado.description,
        e.resultado.pi.toStringAsFixed(2),
        e.ll.toStringAsFixed(2),
        e.lp.toStringAsFixed(2),
        e.pasa200.toStringAsFixed(2),
        e.retenidoN4.toStringAsFixed(2),
        e.cu?.toStringAsFixed(2) ?? '-',
        e.cc?.toStringAsFixed(3) ?? '-',
      ].map(_escapar).join(','));
    }
    return buf.toString();
  }

  static String _escapar(String valor) {
    if (!valor.contains(',') && !valor.contains('"') && !valor.contains('\n')) {
      return valor;
    }
    return '"${valor.replaceAll('"', '""')}"';
  }

  static String _timestamp() {
    final n = DateTime.now();
    return '${n.year}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}'
        '_${n.hour.toString().padLeft(2, '0')}'
        '${n.minute.toString().padLeft(2, '0')}';
  }
}
