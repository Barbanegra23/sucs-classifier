import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Diálogo de confirmación reutilizable.
/// Devuelve true si el usuario confirma, false si cancela.
class ConfirmDialog extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String labelConfirmar;
  final IconData icono;

  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.descripcion,
    this.labelConfirmar = "Confirmar",
    this.icono = Icons.warning_amber_rounded,
  });

  /// Método estático para mostrar el diálogo fácilmente
  static Future<bool> mostrar(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    String labelConfirmar = "Confirmar",
    IconData icono = Icons.warning_amber_rounded,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => ConfirmDialog(
        titulo: titulo,
        descripcion: descripcion,
        labelConfirmar: labelConfirmar,
        icono: icono,
      ),
    );
    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: colors.primary, size: 28),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              titulo,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.headerBg,
              ),
            ),
            const SizedBox(height: 8),

            // Descripción
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancelar",
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      labelConfirmar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
