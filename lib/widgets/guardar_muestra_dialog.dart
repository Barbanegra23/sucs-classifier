import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sucs_classifier/services/historial_service.dart';
import 'package:sucs_classifier/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// COLORES
// Migrado a context.appColors para soportar modo claro/oscuro.
// Mapeo: _teal → secondary · _tealDark → textPrimary ·
// _tealLight → textSecondary · _orange → primary.
// _tealFill / _tealBorder no tienen equivalente directo en el
// tema, así que se derivan como variantes con alpha de
// `secondary` para conservar la identidad visual verde-azulada
// propia de este diálogo (distinta del naranja del formulario
// principal) en ambos temas.
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// MODELO LOCAL — sin depender de proyectos_service.dart
// ─────────────────────────────────────────────────────────────
class _Proyecto {
  final String id;
  String nombre;

  _Proyecto({required this.id, required this.nombre});

  String get fechaCorta {
    // El id es un timestamp en milisegundos
    final ms = int.tryParse(id);
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'nombre': nombre, 'fechaCreacion': id};

  factory _Proyecto.fromJson(Map<String, dynamic> j) => _Proyecto(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
      );
}

// ─────────────────────────────────────────────────────────────
// SERVICIO LOCAL DE PROYECTOS
// Misma clave que ProyectosService para compatibilidad
// ─────────────────────────────────────────────────────────────
class _ProyectosLocal {
  static const _key = 'proyectos_v1';

  static Future<List<_Proyecto>> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista
          .map((e) => _Proyecto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<_Proyecto>> crear(
      List<_Proyecto> actual, String nombre) async {
    final nuevo = _Proyecto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre.trim(),
    );
    final actualizado = [nuevo, ...actual];
    await _guardar(actualizado);
    return actualizado;
  }

  static Future<void> _guardar(List<_Proyecto> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(lista.map((p) => p.toJson()).toList()));
  }
}

// ─────────────────────────────────────────────────────────────
// DIÁLOGO
// ─────────────────────────────────────────────────────────────
class GuardarMuestraDialog extends StatefulWidget {
  final String simbolo;
  final String descripcion;

  const GuardarMuestraDialog({
    super.key,
    required this.simbolo,
    required this.descripcion,
  });

  static Future<DatosMuestra?> mostrar(
    BuildContext context, {
    required String simbolo,
    required String descripcion,
  }) {
    return showDialog<DatosMuestra>(
      context: context,
      barrierDismissible: true,
      builder: (_) => GuardarMuestraDialog(
        simbolo: simbolo,
        descripcion: descripcion,
      ),
    );
  }

  @override
  State<GuardarMuestraDialog> createState() => _GuardarMuestraDialogState();
}

class _GuardarMuestraDialogState extends State<GuardarMuestraDialog> {
  // ── Formulario ────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _ubic = TextEditingController();
  final _prof = TextEditingController();
  final _oper = TextEditingController();
  final _notas = TextEditingController();
  final _expte = TextEditingController();
  final _fnNombre = FocusNode();

  // ── Proyectos ─────────────────────────────────────────────
  List<_Proyecto> _proyectos = [];
  String? _seleccionadoId;
  bool _cargando = true;
  bool _proyectoExpandido = false;

  _Proyecto? get _proyectoSeleccionado =>
      _proyectos.where((p) => p.id == _seleccionadoId).firstOrNull;

  // ── Ciclo de vida ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _cargarProyectos();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fnNombre.requestFocus());
  }

  Future<void> _cargarProyectos() async {
    final lista = await _ProyectosLocal.cargar();
    if (!mounted) return;
    setState(() {
      _proyectos = lista;
      _cargando = false;
      if (lista.isNotEmpty) _proyectoExpandido = true;
    });
  }

  @override
  void dispose() {
    for (final c in [_nombre, _ubic, _prof, _oper, _notas, _expte]) {
      c.dispose();
    }
    _fnNombre.dispose();
    super.dispose();
  }

  // ── Acciones ─────────────────────────────────────────────
  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final p = _proyectoSeleccionado;
    Navigator.of(context).pop(DatosMuestra(
      nombre: _nombre.text.trim(),
      ubicacion: _ubic.text.trim(),
      profundidad: _prof.text.trim(),
      operador: _oper.text.trim(),
      notas: _notas.text.trim(),
      fechaHora: DateTime.now(),
      proyectoId: p?.id ?? '',
      proyectoNombre: p?.nombre ?? '',
      expediente: _expte.text.trim(),
    ));
  }

  Future<void> _crearProyecto() async {
    final colors = context.appColors;
    final teal = colors.secondary;
    final tealLight = colors.textSecondary;
    final tealFill = colors.secondary.withValues(alpha: 0.08);

    final ctrl = TextEditingController();
    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nuevo proyecto',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ej: Obra Av. San Martín…',
            hintStyle: TextStyle(
                color: tealLight.withValues(alpha: 0.6), fontSize: 13),
            filled: true,
            fillColor: tealFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: teal, width: 1.5),
            ),
          ),
          onSubmitted: (v) =>
              Navigator.pop(ctx, v.trim().isEmpty ? null : v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: tealLight)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              Navigator.pop(ctx, v.isEmpty ? null : v);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (nuevo == null || nuevo.isEmpty || !mounted) return;
    final actualizado = await _ProyectosLocal.crear(_proyectos, nuevo);
    if (!mounted) return;
    setState(() {
      _proyectos = actualizado;
      _seleccionadoId = actualizado.first.id;
      _proyectoExpandido = true;
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final teal = colors.secondary;
    final tealLight = colors.textSecondary;
    final tealBorder = colors.secondary.withValues(alpha: 0.35);
    final orange = colors.primary;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                const _Divider(),
                const SizedBox(height: 18),

                // 1. Nombre (requerido)
                _NombreField(controller: _nombre, focusNode: _fnNombre),
                const SizedBox(height: 14),

                // 2. Campos opcionales
                _Campo(
                  controller: _ubic,
                  label: 'Ubicación / Referencia',
                  hint: 'Ej: Sector A, Km 3.5…',
                  icon: Icons.location_on_rounded,
                  opcional: true,
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _Campo(
                      controller: _prof,
                      label: 'Profundidad',
                      hint: 'Ej: 1.50 m',
                      icon: Icons.straighten_rounded,
                      opcional: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Campo(
                      controller: _oper,
                      label: 'Operador',
                      hint: 'Ej: J. Pérez',
                      icon: Icons.person_rounded,
                      opcional: true,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                _Campo(
                  controller: _expte,
                  label: 'N° Expediente / Obra',
                  hint: 'Ej: EXP-2024-003',
                  icon: Icons.tag_rounded,
                  opcional: true,
                ),
                const SizedBox(height: 10),
                _Campo(
                  controller: _notas,
                  label: 'Notas / Observaciones',
                  hint: 'Color, olor, condición de humedad…',
                  icon: Icons.notes_rounded,
                  opcional: true,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onSubmit: _guardar,
                ),

                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 13, color: tealLight),
                  const SizedBox(width: 6),
                  Text(
                    'Fecha: ${_formatFecha(DateTime.now())}',
                    style: TextStyle(color: tealLight, fontSize: 11.5),
                  ),
                ]),

                const SizedBox(height: 18),
                const _Divider(),
                const SizedBox(height: 14),

                // 3. Proyecto (colapsable)
                _ProyectoSection(
                  expandido: _proyectoExpandido,
                  onToggle: () =>
                      setState(() => _proyectoExpandido = !_proyectoExpandido),
                  cargando: _cargando,
                  proyectos: _proyectos
                      .map((p) => _DatosP(
                          id: p.id, nombre: p.nombre, fechaCorta: p.fechaCorta))
                      .toList(),
                  seleccionadoId: _seleccionadoId,
                  onSeleccionado: (id) => setState(() => _seleccionadoId = id),
                  onCrearNuevo: _crearProyecto,
                ),

                const SizedBox(height: 20),
                const _Divider(),
                const SizedBox(height: 16),

                // Botones
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: tealBorder, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancelar',
                          style: TextStyle(
                              color: teal, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        shadowColor: orange.withValues(alpha: 0.4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_add_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Guardar',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.appColors;
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.bookmark_add_rounded,
            color: Colors.white, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guardar muestra',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            Text(
              '${widget.simbolo} · ${widget.descripcion}',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child:
              Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
        ),
      ),
    ]);
  }

  String _formatFecha(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}  $h:$min';
  }
}

// ─────────────────────────────────────────────────────────────
// TIPO LOCAL PARA WIDGETS PRIVADOS
// ─────────────────────────────────────────────────────────────
class _DatosP {
  final String id;
  final String nombre;
  final String fechaCorta;
  const _DatosP(
      {required this.id, required this.nombre, required this.fechaCorta});
}

// ─────────────────────────────────────────────────────────────
// WIDGETS PRIVADOS — solo usan tipos locales y primitivos
// ─────────────────────────────────────────────────────────────

class _ProyectoSection extends StatelessWidget {
  final bool expandido;
  final VoidCallback onToggle;
  final bool cargando;
  final List<_DatosP> proyectos;
  final String? seleccionadoId;
  final ValueChanged<String?> onSeleccionado;
  final VoidCallback onCrearNuevo;

  const _ProyectoSection({
    required this.expandido,
    required this.onToggle,
    required this.cargando,
    required this.proyectos,
    required this.seleccionadoId,
    required this.onSeleccionado,
    required this.onCrearNuevo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final teal = colors.secondary;
    final tealDark = colors.textPrimary;
    final tealLight = colors.textSecondary;
    final tealBorder = colors.secondary.withValues(alpha: 0.35);

    final nombreSel = proyectos
        .where((p) => p.id == seleccionadoId)
        .map((p) => p.nombre)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: expandido ? teal : tealBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text('PROYECTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.9,
                    color: expandido ? teal : tealLight,
                  )),
              const SizedBox(width: 8),
              Text(
                nombreSel ?? 'sin asignar',
                style: TextStyle(
                  fontSize: 11,
                  color: nombreSel != null
                      ? tealDark
                      : tealLight.withValues(alpha: 0.6),
                  fontStyle: nombreSel == null ? FontStyle.italic : null,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: expandido ? 0.0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: tealLight.withValues(alpha: expandido ? 0.8 : 0.5),
                  size: 20,
                ),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: expandido
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: cargando
                      ? Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: teal),
                          ),
                        )
                      : _ListaProyectos(
                          proyectos: proyectos,
                          seleccionadoId: seleccionadoId,
                          onSeleccionado: onSeleccionado,
                          onCrearNuevo: onCrearNuevo,
                        ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

class _ListaProyectos extends StatelessWidget {
  final List<_DatosP> proyectos;
  final String? seleccionadoId;
  final ValueChanged<String?> onSeleccionado;
  final VoidCallback onCrearNuevo;

  const _ListaProyectos({
    required this.proyectos,
    required this.seleccionadoId,
    required this.onSeleccionado,
    required this.onCrearNuevo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final teal = colors.secondary;
    final tealFill = colors.secondary.withValues(alpha: 0.08);
    final tealBorder = colors.secondary.withValues(alpha: 0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpcionP(
          label: 'Sin proyecto',
          sublabel: 'Guardar sin asociar a ninguna obra',
          icon: Icons.inbox_rounded,
          seleccionado: seleccionadoId == null,
          onTap: () => onSeleccionado(null),
        ),
        ...proyectos.map((p) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _OpcionP(
                label: p.nombre,
                sublabel: 'Creado el ${p.fechaCorta}',
                icon: Icons.folder_rounded,
                seleccionado: seleccionadoId == p.id,
                onTap: () => onSeleccionado(p.id),
              ),
            )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onCrearNuevo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tealFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tealBorder),
            ),
            child: Row(children: [
              Icon(Icons.add_rounded, color: teal, size: 18),
              const SizedBox(width: 10),
              Text('Nuevo proyecto…',
                  style: TextStyle(
                      color: teal, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OpcionP extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionP({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final teal = colors.secondary;
    final tealLight = colors.textSecondary;
    final tealFill = colors.secondary.withValues(alpha: 0.08);
    final tealBorder = colors.secondary.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: seleccionado ? tealFill : colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado ? teal : tealBorder.withValues(alpha: 0.5),
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: seleccionado ? teal : tealLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          seleccionado ? FontWeight.bold : FontWeight.normal,
                      color: colors.textPrimary,
                    )),
                Text(sublabel,
                    style: TextStyle(
                        fontSize: 11, color: tealLight.withValues(alpha: 0.8))),
              ],
            ),
          ),
          if (seleccionado)
            Icon(Icons.check_circle_rounded, color: teal, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOMBRE FIELD
// ─────────────────────────────────────────────────────────────
class _NombreField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _NombreField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final teal = colors.secondary;
    final tealDark = colors.textPrimary;
    final tealLight = colors.textSecondary;
    final tealFill = colors.secondary.withValues(alpha: 0.08);
    final tealBorder = colors.secondary.withValues(alpha: 0.35);
    final orange = colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Nombre de muestra',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: tealDark)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('requerido',
                style: TextStyle(
                    fontSize: 10, color: orange, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          maxLength: 30,
          style: TextStyle(
              color: tealDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'El nombre es obligatorio'
              : null,
          decoration: InputDecoration(
            hintText: 'Ej: M-1, Calicata C-3, Sondeo S-01…',
            hintStyle: TextStyle(
                color: tealLight.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.normal),
            prefixIcon: Icon(Icons.label_rounded, size: 20, color: teal),
            filled: true,
            fillColor: tealFill,
            counterStyle: TextStyle(color: tealLight, fontSize: 11),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tealBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: teal, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CAMPO GENÉRICO
// ─────────────────────────────────────────────────────────────
class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool opcional;
  final int maxLines;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmit;

  const _Campo({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.opcional = false,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final teal = colors.secondary;
    final tealDark = colors.textPrimary;
    final tealLight = colors.textSecondary;
    final tealFill = colors.secondary.withValues(alpha: 0.08);
    final tealBorder = colors.secondary.withValues(alpha: 0.35);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
      style: TextStyle(color: tealDark, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: opcional ? '$label  (opcional)' : label,
        hintText: hint,
        hintStyle:
            TextStyle(color: tealLight.withValues(alpha: 0.5), fontSize: 13),
        labelStyle: TextStyle(
          color: tealLight.withValues(alpha: opcional ? 0.7 : 1.0),
          fontSize: 12.5,
        ),
        prefixIcon: Icon(icon, size: 18, color: teal),
        filled: true,
        fillColor: tealFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tealBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: teal, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: context.appColors.secondary.withValues(alpha: 0.18),
      );
}
