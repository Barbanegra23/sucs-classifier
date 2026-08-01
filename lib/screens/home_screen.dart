import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sucs_classifier.dart';
import '../theme/app_colors.dart';
import '../widgets/result_section.dart';
import '../widgets/guardar_muestra_dialog.dart';
import '../widgets/historial_panel.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/tamices_card.dart';
import '../widgets/home/atterberg_card.dart';
import '../widgets/home/granulometria_card.dart';
import '../services/historial_service.dart';

// =============================================================
// CONSTANTES
// =============================================================

/// Porcentaje de pasa 200 que separa suelo fino de grueso (ASTM D2487).
const double _kLimiteSueloFino = 50.0;

// =============================================================
// HOME SCREEN
// =============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Controllers ───────────────────────────────────────────
  final _pasa200 = TextEditingController();
  final _retenidoN4 = TextEditingController();
  final _ll = TextEditingController();
  final _lp = TextEditingController();
  final _d10 = TextEditingController();
  final _d30 = TextEditingController();
  final _d60 = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── FocusNodes ────────────────────────────────────────────
  final _fnPasa200 = FocusNode();
  final _fnRetenidoN4 = FocusNode();
  final _fnLL = FocusNode();
  final _fnLP = FocusNode();
  final _fnD10 = FocusNode();
  final _fnD30 = FocusNode();
  final _fnD60 = FocusNode();

  // ── Estado ────────────────────────────────────────────────
  SucsResult? resultado;
  bool _autoValidate = false;
  final List<EntradaHistorial> _historial = [];
  final GlobalKey _resultadoKey = GlobalKey();
  final _scrollCtrl = ScrollController();
  bool _resultadoFueraDeVista = false;

  /// Posición del resultado: true = debajo del viewport, false = encima.
  bool _resultadoPorDebajo = true;

  /// Muestra el FAB ↑ cuando el usuario scrolleó lo suficiente
  /// como para que el formulario esté fuera de vista.
  bool _mostrarFab = false;

  _EstadoFormulario? _estadoAnterior;

  // ── Getters ───────────────────────────────────────────────
  bool get _esSueloGrueso {
    final v = double.tryParse(_pasa200.text);
    return v != null && v < _kLimiteSueloFino;
  }

  bool get _necesitaAtterberg {
    final v = double.tryParse(_pasa200.text);
    if (v == null) return true;
    return v >= 5.0;
  }

  double? _parse(String v) => double.tryParse(v);

  Future<void> _cargarHistorial() async {
    final guardado = await HistorialService.cargar();
    if (mounted) setState(() => _historial.addAll(guardado));
  }

  // ── Ciclo de vida ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Delay para no interrumpir la animación de entrada.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fnPasa200.requestFocus();
    });

    _cargarHistorial();

    for (final c in [_pasa200, _retenidoN4, _ll, _lp, _d10, _d30, _d60]) {
      c.addListener(() => setState(() {}));
    }

    _ll.addListener(() {
      if (_autoValidate) _formKey.currentState?.validate();
    });

    _pasa200.addListener(() {
      if (_autoValidate) _formKey.currentState?.validate();
    });

    _scrollCtrl.addListener(_actualizarVisibilidadResultado);
  }

  @override
  void dispose() {
    for (final c in [_pasa200, _retenidoN4, _ll, _lp, _d10, _d30, _d60]) {
      c.dispose();
    }
    for (final f in [
      _fnPasa200,
      _fnRetenidoN4,
      _fnLL,
      _fnLP,
      _fnD10,
      _fnD30,
      _fnD60
    ]) {
      f.dispose();
    }
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Lógica principal ──────────────────────────────────────

  void _actualizarVisibilidadResultado() {
    if (resultado == null) return;
    final ctx = _resultadoKey.currentContext;
    if (ctx == null) return;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return;
    final box = renderObject;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;

    final porDebajo = pos.dy > screenH;
    final porArriba = pos.dy + box.size.height < 0;
    final fueraDeVista = porDebajo || porArriba;

    // FAB de "ir arriba": visible cuando el usuario scrolleó > 220px
    // (el formulario ya no está en pantalla).
    final mostrarFab = _scrollCtrl.hasClients && _scrollCtrl.offset > 220;

    if (fueraDeVista != _resultadoFueraDeVista ||
        porDebajo != _resultadoPorDebajo ||
        mostrarFab != _mostrarFab) {
      setState(() {
        _resultadoFueraDeVista = fueraDeVista;
        _resultadoPorDebajo = porDebajo;
        _mostrarFab = mostrarFab;
      });
    }
  }

  void _irAlResultado() {
    final ctx = _resultadoKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  void _irArriba() {
    _scrollCtrl.animateTo(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  Future<void> clasificar() async {
    try {
      if (!_esSueloGrueso) {
        _d10.clear();
        _d30.clear();
        _d60.clear();
      }

      final p200 = _parse(_pasa200.text);
      final r4 = _parse(_retenidoN4.text);
      final ll = _parse(_ll.text);
      final lp = _parse(_lp.text);
      final d10 = _parse(_d10.text);
      final d30 = _parse(_d30.text);
      final d60 = _parse(_d60.text);

      double? cu;
      double? cc;
      if (_esSueloGrueso) {
        if (d10 == null || d30 == null || d60 == null || d10 <= 0 || d60 <= 0) {
          throw Exception('Campos incompletos');
        }
        (cu, cc) = calcularCuCc(d10: d10, d30: d30, d60: d60);
      }

      if ([p200, r4].contains(null) ||
          (_necesitaAtterberg && [ll, lp].contains(null))) {
        throw Exception('Campos incompletos');
      }

      final result = clasificarSuelo(SucsInput(
        pasa200: p200!,
        retenidoN4: r4!,
        ll: _necesitaAtterberg ? ll! : 0,
        lp: _necesitaAtterberg ? lp! : 0,
        cu: cu ?? 0,
        cc: cc ?? 0,
      ));

      if (!mounted) return;

      // Feedback háptico al clasificar
      HapticFeedback.mediumImpact();

      setState(() => resultado = result);
      WidgetsBinding.instance.addPostFrameCallback((_) => _irAlResultado());
    } catch (e, stack) {
      debugPrint('Error en clasificación: $e');
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Revisá los datos ingresados'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _guardarMuestra() async {
    if (resultado == null) return;

    final datos = await GuardarMuestraDialog.mostrar(
      context,
      simbolo: resultado!.symbol,
      descripcion: resultado!.description,
    );
    if (datos == null || !mounted) return;

    final p200 = _parse(_pasa200.text) ?? 0;
    final r4 = _parse(_retenidoN4.text) ?? 0;
    final ll = _parse(_ll.text) ?? 0;
    final lp = _parse(_lp.text) ?? 0;
    double? cu;
    double? cc;
    if (_esSueloGrueso) {
      final d10v = _parse(_d10.text);
      final d30v = _parse(_d30.text);
      final d60v = _parse(_d60.text);
      if (d10v != null &&
          d30v != null &&
          d60v != null &&
          d10v > 0 &&
          d60v > 0) {
        (cu, cc) = calcularCuCc(d10: d10v, d30: d30v, d60: d60v);
      }
    }

    final entrada = EntradaHistorial(
      resultado: resultado!,
      ll: ll,
      lp: lp,
      pasa200: p200,
      retenidoN4: r4,
      cu: cu,
      cc: cc,
      muestra: datos,
      nombre: datos.nombre,
    );

    final actualizado = await HistorialService.agregar(_historial, entrada);
    if (!mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _historial
        ..clear()
        ..addAll(actualizado);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('Muestra "${datos.nombre}" guardada'),
      ]),
      backgroundColor: context.appColors.primary,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _confirmarLimpiar() async {
    final hayDatos =
        _pasa200.text.isNotEmpty || _ll.text.isNotEmpty || resultado != null;
    if (!hayDatos) return;
    _limpiar();
  }

  void _mostrarSnackbarLimpiado() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.delete_sweep_rounded, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Text('Formulario limpiado'),
        ]),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: context.appColors.primaryLight,
          onPressed: _deshacerLimpiar,
        ),
      ),
    );
  }

  void _limpiar() {
    // Guarda snapshot del formulario (el historial NO se toca)
    _estadoAnterior = _EstadoFormulario(
      pasa200: _pasa200.text,
      retenidoN4: _retenidoN4.text,
      ll: _ll.text,
      lp: _lp.text,
      d10: _d10.text,
      d30: _d30.text,
      d60: _d60.text,
      resultado: resultado,
      historial: List.from(_historial),
    );

    HapticFeedback.heavyImpact();

    setState(() {
      for (final c in [_pasa200, _retenidoN4, _ll, _lp, _d10, _d30, _d60]) {
        c.clear();
      }
      resultado = null;
      _autoValidate = false;
      _resultadoFueraDeVista = false;
      // ✅ El historial de muestras guardadas NO se modifica.
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.reset();
      _fnPasa200.requestFocus();
    });

    _mostrarSnackbarLimpiado();
  }

  void _deshacerLimpiar() {
    final e = _estadoAnterior;
    if (e == null) return;
    setState(() {
      _pasa200.text = e.pasa200;
      _retenidoN4.text = e.retenidoN4;
      _ll.text = e.ll;
      _lp.text = e.lp;
      _d10.text = e.d10;
      _d30.text = e.d30;
      _d60.text = e.d60;
      resultado = e.resultado;
      _estadoAnterior = null;
    });
  }

  Future<void> _clasificarConValidacion() async {
    setState(() => _autoValidate = true);
    if (_formKey.currentState?.validate() ?? false) await clasificar();
  }

  Future<void> _editarNombreMuestra(EntradaHistorial entrada) async {
    final ctrl = TextEditingController(text: entrada.nombre);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nombre de muestra'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: M-1, Sondeo 3, Calicata A…',
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nuevo != null && nuevo.isNotEmpty) {
      final idx = _historial.indexOf(entrada);
      if (idx >= 0) {
        await HistorialService.actualizarNombre(_historial, idx, nuevo);
      }
      if (mounted) setState(() => entrada.nombre = nuevo);
    }
    ctrl.dispose();
  }

  // ── Mensaje de campos faltantes ───────────────────────────

  String _mensajeCamposFaltantes() {
    if (_pasa200.text.isEmpty || _retenidoN4.text.isEmpty) {
      return 'Completá los datos de tamices para continuar';
    }
    if (_necesitaAtterberg && (_ll.text.isEmpty || _lp.text.isEmpty)) {
      return 'Completá los límites de Atterberg (LL y LP)';
    }
    if (_esSueloGrueso &&
        (_d10.text.isEmpty || _d30.text.isEmpty || _d60.text.isEmpty)) {
      return 'Completá D10, D30 y D60 para suelo grueso';
    }
    return '';
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p200val = double.tryParse(_pasa200.text);
    final llVal = double.tryParse(_ll.text) ?? 0;
    final lpVal = double.tryParse(_lp.text) ?? 0;
    final d10Val = double.tryParse(_d10.text);
    final d30Val = double.tryParse(_d30.text);
    final d60Val = double.tryParse(_d60.text);
    final double? cuVal = (d10Val != null && d60Val != null && d10Val > 0)
        ? d60Val / d10Val
        : null;
    final double? ccVal = (d10Val != null &&
            d30Val != null &&
            d60Val != null &&
            d10Val > 0 &&
            d60Val > 0)
        ? (d30Val * d30Val) / (d10Val * d60Val)
        : null;

    // Historial a mostrar (excluye la entrada más reciente si corresponde
    // al resultado actual ya guardado).
    final historialVisible =
        _historial.skip(resultado != null ? 1 : 0).toList();

    return Scaffold(
      backgroundColor: context.appColors.background,
      // FAB ↑ — aparece al scrollear más de 220px hacia abajo.
      floatingActionButton: _mostrarFab
          ? FloatingActionButton.small(
              onPressed: _irArriba,
              backgroundColor: context.appColors.primary,
              elevation: 6,
              shape: const CircleBorder(),
              tooltip: 'Volver al formulario',
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 24,
              ),
            )
          : null,
      body: Stack(children: [
        // ── Contenido principal ───────────────────────────
        Column(children: [
          const HomeHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // ── TAMICES ───────────────────────────────
                  TamicesCard(
                    pasa200: _pasa200,
                    retenidoN4: _retenidoN4,
                    fnPasa200: _fnPasa200,
                    fnRetenidoN4: _fnRetenidoN4,
                    fnNext: _fnLL,
                    autoValidate: _autoValidate,
                  ),

                  // ── LÍMITES DE ATTERBERG ──────────────────
                  AtterbergCard(
                    p200val: p200val,
                    ll: _ll,
                    lp: _lp,
                    fnLL: _fnLL,
                    fnLP: _fnLP,
                    fnSiguiente: _esSueloGrueso ? _fnD10 : null,
                    onSubmitFinal:
                        _esSueloGrueso ? null : _clasificarConValidacion,
                    autoValidate: _autoValidate,
                  ),

                  // ── CURVA GRANULOMÉTRICA (D10/D30/D60) ────
                  GranulometriaCard(
                    p200val: p200val,
                    limiteSueloFino: _kLimiteSueloFino,
                    d10: _d10,
                    d30: _d30,
                    d60: _d60,
                    fnD10: _fnD10,
                    fnD30: _fnD30,
                    fnD60: _fnD60,
                    autoValidate: _autoValidate,
                    onSubmitFinal: _clasificarConValidacion,
                  ),

                  const SizedBox(height: 10),
                  _buildBotones(context),

                  // ── HISTORIAL ─────────────────────────────
                  // Visible cuando hay al menos 1 muestra guardada.
                  if (historialVisible.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    HistorialPanel(
                      historial: historialVisible,
                      onTap: (e) => setState(() => resultado = e.resultado),
                      onEditarNombre: _editarNombreMuestra,
                      onEliminar: (e) async {
                        final idx = _historial.indexOf(e);
                        if (idx < 0) return;
                        final actualizado =
                            await HistorialService.eliminar(_historial, idx);
                        if (mounted) {
                          setState(() => _historial
                            ..clear()
                            ..addAll(actualizado));
                        }
                      },
                    ),
                  ],

                  // ── RESULTADO ─────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: resultado != null
                        ? Column(
                            key: _resultadoKey,
                            children: [
                              const SizedBox(height: 20),
                              ResultSection(
                                resultado: resultado!,
                                ll: llVal,
                                pasa200: p200val ?? 0,
                                retenidoN4:
                                    double.tryParse(_retenidoN4.text) ?? 0,
                                lp: lpVal,
                                cu: cuVal,
                                cc: ccVal,
                                d10: double.tryParse(_d10.text),
                                d30: double.tryParse(_d30.text),
                                d60: double.tryParse(_d60.text),
                                // Botones integrados en la barra inferior del card.
                                onGuardar: resultado!.symbol != 'ERROR'
                                    ? _guardarMuestra
                                    : null,
                                onIrArriba: _irArriba,
                              ),
                              const SizedBox(height: 20),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ]),
              ),
            ),
          ),
        ]),

        // ── Chip flotante (posicionado en la dirección correcta) ──
        // Aparece cuando el resultado está fuera de la vista.
        // Si el resultado está debajo → chip en la parte inferior.
        // Si el resultado está encima → chip en la parte superior (bajo el header).
        if (resultado != null && _resultadoFueraDeVista)
          _resultadoPorDebajo
              ? Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: _ChipFlotante(
                    resultado: resultado!,
                    porDebajo: true,
                    onTap: _irAlResultado,
                  ),
                )
              : Positioned(
                  top: MediaQuery.of(context).padding.top + _kHeaderHeight + 8,
                  left: 0,
                  right: 0,
                  child: _ChipFlotante(
                    resultado: resultado!,
                    porDebajo: false,
                    onTap: _irAlResultado,
                  ),
                ),
      ]),
    );
  }

  // ── Builders ──────────────────────────────────────────────

  Widget _buildBotones(BuildContext context) {
    final camposBase = _pasa200.text.isNotEmpty && _retenidoN4.text.isNotEmpty;
    final atterbergOk =
        !_necesitaAtterberg || (_ll.text.isNotEmpty && _lp.text.isNotEmpty);
    final granOk = !_esSueloGrueso ||
        (_d10.text.isNotEmpty && _d30.text.isNotEmpty && _d60.text.isNotEmpty);
    final habilitado = camposBase && atterbergOk && granOk;
    final mensajeFaltante = _mensajeCamposFaltantes();

    return Column(
      children: [
        Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: habilitado ? _clasificarConValidacion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              child: const Text('Clasificar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _confirmarLimpiar,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: context.appColors.secondary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Limpiar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.secondary,
                  )),
            ),
          ),
        ]),
        // Hint cuando el botón está deshabilitado
        if (!habilitado && mensajeFaltante.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              mensajeFaltante,
              style: const TextStyle(color: Colors.grey, fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// Altura aproximada del header para posicionar el chip flotante superior.
const double _kHeaderHeight = 120.0;

// =============================================================
// WIDGETS AUXILIARES
// =============================================================

class _ChipFlotante extends StatelessWidget {
  final SucsResult resultado;
  final bool porDebajo;
  final VoidCallback onTap;

  const _ChipFlotante({
    required this.resultado,
    required this.porDebajo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorDeSuelo(resultado.symbol);
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14)
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              porDebajo
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              resultado.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              porDebajo
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 18,
            ),
          ]),
        ),
      ),
    );
  }
}

class _EstadoFormulario {
  final String pasa200;
  final String retenidoN4;
  final String ll;
  final String lp;
  final String d10;
  final String d30;
  final String d60;
  final SucsResult? resultado;
  final List<EntradaHistorial> historial;

  const _EstadoFormulario({
    required this.pasa200,
    required this.retenidoN4,
    required this.ll,
    required this.lp,
    required this.d10,
    required this.d30,
    required this.d60,
    required this.resultado,
    required this.historial,
  });
}
