import 'package:flutter/material.dart';
import '../../services/aashto_classifier.dart';
import '../../theme/app_colors.dart';

/// Muestra el resultado de la clasificación AASHTO: símbolo con GI,
/// descripción, tipo de material, PI y calificación como subrasante.
///
/// Nota de alcance: a diferencia del resultado de SUCS, esta primera
/// versión no incluye gráfico de curva granulométrica ni exportación
/// a PDF — se agregan más adelante si hace falta.
class AashtoResultCard extends StatelessWidget {
  final AashtoResult resultado;

  const AashtoResultCard({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final color = colorDeGrupoAashto(resultado.grupo);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner con el símbolo ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultado.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resultado.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                        label: 'PI', value: resultado.pi.toStringAsFixed(1)),
                    _StatChip(label: 'GI', value: resultado.gi.toString()),
                  ],
                ),
              ],
            ),
          ),

          // ── Detalle ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetalleRow(
                  icono: Icons.category_outlined,
                  etiqueta: 'Tipo de material',
                  valor: resultado.tipoMaterial,
                ),
                const SizedBox(height: 12),
                _DetalleRow(
                  icono: Icons.foundation_outlined,
                  etiqueta: 'Calificación como subrasante',
                  valor: resultado.calificacionSubrasante,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: context.appColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El Índice de Grupo (GI) indica la calidad relativa dentro '
                          'del grupo: cuanto más alto, peor comportamiento esperado '
                          'como subrasante. Se reporta entre paréntesis junto al '
                          'símbolo, ej. "${resultado.symbol}".',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.appColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetalleRow extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  const _DetalleRow(
      {required this.icono, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: context.appColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
