import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/aashto_classifier.dart';
import '../services/aashto_pdf_export.dart';
import '../theme/app_colors.dart';
import '../widgets/aashto/aashto_header.dart';
import '../widgets/aashto/tamices_aashto_card.dart';
import '../widgets/aashto/atterberg_aashto_card.dart';
import '../widgets/aashto/aashto_result_card.dart';

/// Pantalla de clasificación AASHTO (M 145 / ASTM D3282).
///
/// Cubre la clasificación completa (grupos A-1 a A-7 + Índice de
/// Grupo) con su propio formulario, y exportación a PDF. A diferencia
/// de HomeScreen (SUCS) todavía no tiene historial de muestras
/// guardadas — se puede sumar más adelante siguiendo el mismo patrón
/// que ya existe para SUCS.
class AashtoScreen extends StatefulWidget {
  const AashtoScreen({super.key});

  @override
  State<AashtoScreen> createState() => _AashtoScreenState();
}

class _AashtoScreenState extends State<AashtoScreen> {
  // ── Controllers ───────────────────────────────────────────
  final _pasa10 = TextEditingController();
  final _pasa40 = TextEditingController();
  final _pasa200 = TextEditingController();
  final _ll = TextEditingController();
  final _lp = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── FocusNodes ────────────────────────────────────────────
  final _fnPasa10 = FocusNode();
  final _fnPasa40 = FocusNode();
  final _fnPasa200 = FocusNode();
  final _fnLL = FocusNode();
  final _fnLP = FocusNode();

  // ── Estado ────────────────────────────────────────────────
  AashtoResult? _resultado;
  bool _autoValidate = false;
  bool _exportando = false;
  final GlobalKey _resultadoKey = GlobalKey();

  @override
  void dispose() {
    _pasa10.dispose();
    _pasa40.dispose();
    _pasa200.dispose();
    _ll.dispose();
    _lp.dispose();
    _fnPasa10.dispose();
    _fnPasa40.dispose();
    _fnPasa200.dispose();
    _fnLL.dispose();
    _fnLP.dispose();
    super.dispose();
  }

  void _clasificar() {
    setState(() => _autoValidate = true);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    final input = AashtoInput(
      pasa10: double.parse(_pasa10.text),
      pasa40: double.parse(_pasa40.text),
      pasa200: double.parse(_pasa200.text),
      ll: double.parse(_ll.text),
      lp: double.parse(_lp.text),
    );

    setState(() => _resultado = clasificarAashto(input));

    // Baja el scroll hasta el resultado en el próximo frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultadoKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _limpiar() {
    setState(() {
      _pasa10.clear();
      _pasa40.clear();
      _pasa200.clear();
      _ll.clear();
      _lp.clear();
      _resultado = null;
      _autoValidate = false;
    });
    _fnPasa10.requestFocus();
  }

  Future<void> _exportarPdf() async {
    if (_exportando || _resultado == null) return;
    setState(() => _exportando = true);
    HapticFeedback.lightImpact();
    try {
      await AashtoPdfExport.exportar(
        context: context,
        resultado: _resultado!,
        pasa10: double.parse(_pasa10.text),
        pasa40: double.parse(_pasa40.text),
        pasa200: double.parse(_pasa200.text),
        ll: double.parse(_ll.text),
        lp: double.parse(_lp.text),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Widget _buildExportButton(Color color) {
    return OutlinedButton(
      onPressed: _exportando ? null : _exportarPdf,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: color.withValues(alpha: _exportando ? 0.2 : 0.4)),
        foregroundColor: color,
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
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Generando…',
                        style: TextStyle(
                            color: color,
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
                  Icon(Icons.picture_as_pdf_rounded, size: 17, color: color),
                  const SizedBox(width: 7),
                  Text('Exportar PDF',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(children: [
            const AashtoHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  TamicesAashtoCard(
                    pasa10: _pasa10,
                    pasa40: _pasa40,
                    pasa200: _pasa200,
                    fnPasa10: _fnPasa10,
                    fnPasa40: _fnPasa40,
                    fnPasa200: _fnPasa200,
                    fnNext: _fnLL,
                    autoValidate: _autoValidate,
                  ),
                  AtterbergAashtoCard(
                    ll: _ll,
                    lp: _lp,
                    fnLL: _fnLL,
                    fnLP: _fnLP,
                    onSubmitFinal: _clasificar,
                    autoValidate: _autoValidate,
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _limpiar,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Limpiar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: context.appColors.secondary),
                          foregroundColor: context.appColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _clasificar,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Clasificar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ]),
                  if (_resultado != null) ...[
                    const SizedBox(height: 16),
                    KeyedSubtree(
                      key: _resultadoKey,
                      child: AashtoResultCard(resultado: _resultado!),
                    ),
                    const SizedBox(height: 12),
                    _buildExportButton(colorDeGrupoAashto(_resultado!.grupo)),
                  ],
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
