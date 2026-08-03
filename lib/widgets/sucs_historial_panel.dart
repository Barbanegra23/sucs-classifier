import 'package:flutter/material.dart';
import '../services/sucs_csv_export.dart';
import '../services/sucs_historial_service.dart';
import '../services/sucs_classifier.dart';
import '../theme/app_colors.dart';
import 'confirm_dialog.dart';

// =============================================================
// HISTORIAL PANEL
// Widget colapsable que muestra las últimas clasificaciones
// guardadas. Cada fila muestra símbolo, nombre de muestra,
// LL/LP/PI y fecha. Tocar carga el resultado; mantener pulsado
// abre el diálogo para renombrar; el botón × elimina la entrada
// (con confirmación previa). El botón de exportar en la cabecera
// descarga el historial completo como CSV.
// =============================================================

class SucsHistorialPanel extends StatefulWidget {
  final List<EntradaHistorial> historial;
  final void Function(EntradaHistorial) onTap;
  final void Function(EntradaHistorial) onEditarNombre;
  final void Function(EntradaHistorial) onEliminar;

  const SucsHistorialPanel({
    super.key,
    required this.historial,
    required this.onTap,
    required this.onEditarNombre,
    required this.onEliminar,
  });

  @override
  State<SucsHistorialPanel> createState() => _SucsHistorialPanelState();
}

class _SucsHistorialPanelState extends State<SucsHistorialPanel> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cabecera(
          cantidad: widget.historial.length,
          expandido: _expandido,
          onToggle: () => setState(() => _expandido = !_expandido),
          onExportar: widget.historial.isEmpty
              ? null
              : () => SucsCsvExport.exportar(
                    context: context,
                    historial: widget.historial,
                  ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _ListaEntradas(
            historial: widget.historial,
            onTap: widget.onTap,
            onEditarNombre: widget.onEditarNombre,
            onEliminar: widget.onEliminar,
          ),
          crossFadeState:
              _expandido ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Cabecera con título, badge de cantidad, exportar CSV y toggle
// ─────────────────────────────────────────────────────────────
class _Cabecera extends StatelessWidget {
  final int cantidad;
  final bool expandido;
  final VoidCallback onToggle;
  final VoidCallback? onExportar;

  const _Cabecera({
    required this.cantidad,
    required this.expandido,
    required this.onToggle,
    this.onExportar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Text(
              'HISTORIAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.secondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$cantidad',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              expandido ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: colors.secondary,
            ),
          ]),
        ),
      ),
      if (onExportar != null) ...[
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onExportar,
          behavior: HitTestBehavior.opaque,
          child: Tooltip(
            message: 'Exportar historial a CSV',
            child: Icon(
              Icons.file_download_outlined,
              size: 18,
              color: colors.secondary,
            ),
          ),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Lista de chips de historial
// ─────────────────────────────────────────────────────────────
class _ListaEntradas extends StatelessWidget {
  final List<EntradaHistorial> historial;
  final void Function(EntradaHistorial) onTap;
  final void Function(EntradaHistorial) onEditarNombre;
  final void Function(EntradaHistorial) onEliminar;

  const _ListaEntradas({
    required this.historial,
    required this.onTap,
    required this.onEditarNombre,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: historial
            .map((e) => _EntradaChip(
                  entrada: e,
                  onTap: () => onTap(e),
                  onLongPress: () => onEditarNombre(e),
                  onEliminar: () => onEliminar(e),
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chip individual de una entrada del historial
// ─────────────────────────────────────────────────────────────
class _EntradaChip extends StatelessWidget {
  final EntradaHistorial entrada;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEliminar;

  const _EntradaChip({
    required this.entrada,
    required this.onTap,
    required this.onLongPress,
    required this.onEliminar,
  });

  Future<void> _confirmarEliminar(BuildContext context) async {
    final nombre = entrada.nombreDisplay;
    final descripcion = nombre.isNotEmpty
        ? 'Se eliminará "$nombre" (${entrada.resultado.symbol}) del historial. '
            'Esta acción no se puede deshacer.'
        : 'Se eliminará esta muestra (${entrada.resultado.symbol}) del historial. '
            'Esta acción no se puede deshacer.';
    final confirmado = await ConfirmDialog.mostrar(
      context,
      titulo: '¿Eliminar del historial?',
      descripcion: descripcion,
      labelConfirmar: 'Eliminar',
      icono: Icons.delete_outline_rounded,
    );
    if (confirmado) onEliminar();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorDeSuelo(entrada.resultado.symbol);
    final nombre = entrada.nombreDisplay;
    final fecha = entrada.muestra?.fechaHora;
    final resumen = entrada.muestra?.resumenCorto ?? '';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          // Indicador de color
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),

          // Contenido principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Símbolo + nombre
                Row(children: [
                  Text(
                    entrada.resultado.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                  if (nombre.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        nombre,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),

                // LL / LP / PI — solo cuando finos >= 5 %
                if (entrada.pasa200 >= 5.0)
                  Text(
                    'LL=${entrada.ll.toStringAsFixed(0)}  '
                    'LP=${entrada.lp.toStringAsFixed(0)}  '
                    'PI=${entrada.resultado.pi.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  )
                else if (entrada.cu != null)
                  Text(
                    'Cu=${entrada.cu!.toStringAsFixed(2)}  '
                    '${entrada.cc != null ? 'Cc=${entrada.cc!.toStringAsFixed(3)}' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),

                // Resumen de ubicación / proyecto
                if (resumen.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    resumen,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Fecha + botón eliminar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (fecha != null)
                Text(
                  '${fecha.day.toString().padLeft(2, '0')}/'
                  '${fecha.month.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.5),
                  ),
                ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _confirmarEliminar(context),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: color.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
