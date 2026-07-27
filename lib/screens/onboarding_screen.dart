import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

const _kOnboardingDone = 'onboarding_done_v1';

Future<bool> onboardingYaVisto() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> marcarOnboardingVisto() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ─────────────────────────────────────────────────────────────
// DATOS DE CADA PASO
// ─────────────────────────────────────────────────────────────
class _Paso {
  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;
  final List<_Item> items;

  const _Paso({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.items,
  });
}

class _Item {
  final String etiqueta;
  final String descripcion;
  final String? ejemplo;
  const _Item(this.etiqueta, this.descripcion, {this.ejemplo});
}

const _pasos = [
  _Paso(
    icono: Icons.layers_rounded,
    color: Color(0xFF2F4F54), // secondary — verde petróleo
    titulo: '¿Qué es SUCS?',
    subtitulo: 'El Sistema Unificado de Clasificación de Suelos (ASTM D2487) '
        'asigna un símbolo de 2 letras a cada suelo según su '
        'granulometría y plasticidad.',
    items: [
      _Item('G — Grava', 'Más del 50 % de gruesos retenidos en tamiz N°4',
          ejemplo: 'GW, GP, GM, GC'),
      _Item('S — Arena', 'Más del 50 % de gruesos pasan el tamiz N°4',
          ejemplo: 'SW, SP, SM, SC'),
      _Item(
          'M — Limo',
          'Suelo fino cuyo IP cae por debajo de la Línea A en la carta de plasticidad, o no es plástico.',
          ejemplo: 'ML, MH'),
      _Item(
          'C — Arcilla',
          'Suelo fino cuyo IP cae sobre o por encima de la Línea A en la carta de plasticidad.',
          ejemplo: 'CL, CH, CL-ML'),
    ],
  ),
  _Paso(
    icono: Icons.grain_rounded,
    color: Color(0xFF4A7C9E),
    titulo: 'Granulometría',
    subtitulo: 'Describe la distribución de tamaños de partículas. '
        'Se obtiene pasando el suelo por tamices de distintas aberturas.',
    items: [
      _Item(
          '% Pasa N°200',
          'Porcentaje del suelo que atraviesa el tamiz N°200 (0,075 mm). '
              'Separa suelo fino (≥ 50 %) de suelo grueso (< 50 %).',
          ejemplo: 'Ej: arena limpia → 3 %  |  arcilla → 92 %'),
      _Item(
          '% Retenido N°4',
          'Porcentaje que queda sobre el tamiz N°4 (4,75 mm). '
              'Indica la fracción de grava dentro de los gruesos.',
          ejemplo: 'Ej: grava → 65 %  |  arena pura → 0 %'),
    ],
  ),
  _Paso(
    icono: Icons.water_drop_outlined,
    color: Color(0xFFA0522D),
    titulo: 'Límites de Atterberg',
    subtitulo: 'Humedades límite que describen el comportamiento plástico '
        'de los suelos finos. Solo aplican cuando los finos ≥ 5 %.',
    items: [
      _Item(
          'LL — Límite Líquido',
          'Humedad (%) a la que el suelo pasa de estado plástico a líquido. '
              'Relacionado con la compresibilidad.',
          ejemplo: 'Arcilla blanda: 50–80 %  |  Arena: no aplica'),
      _Item('LP — Límite Plástico',
          'Humedad (%) a la que el suelo pasa de semisólido a plástico.',
          ejemplo: 'Típico: 15–30 %'),
      _Item(
          'IP — Índice de Plasticidad',
          'IP = LL − LP. Mide el rango plástico. '
              'Se calcula automáticamente; no es necesario ingresarlo.',
          ejemplo: 'IP < 7 → baja plasticidad  |  IP > 17 → alta'),
      _Item(
          'CL-ML — Zona de transición',
          'Existe una franja estrecha en la carta de plasticidad donde '
              'el suelo no puede clasificarse como arcilla ni como limo puro. '
              'Ocurre cuando IP está entre 4 y 7, y el punto cae sobre la Línea A. '
              'La norma exige verificar ambas condiciones simultáneamente — '
              'un error en el orden de las comprobaciones lo clasificaría mal '
              'como CL o ML en lugar de CL-ML.',
          ejemplo: 'LL=30, LP=24 → IP=6, Línea A=7.3 → IP<LineaA → CL-ML'),
    ],
  ),
  _Paso(
    icono: Icons.show_chart_rounded,
    color: Color(0xFF5A7A5A),
    titulo: 'Parámetros granulométricos',
    subtitulo: 'Diámetros obtenidos de la curva granulométrica. Solo para '
        'suelos gruesos. Cu y Cc se calculan automáticamente.',
    items: [
      _Item(
          'D10',
          'Diámetro al 10 % pasante (mm). Controla la permeabilidad '
              '(fórmula de Hazen: k ≈ C × D10², C≈1).',
          ejemplo: 'Arena fina: 0,1 mm  |  Grava: 2–5 mm'),
      _Item('D30', 'Diámetro al 30 % pasante. Debe estar entre D10 y D60.',
          ejemplo: 'Siempre: D10 < D30 < D60'),
      _Item('D60', 'Diámetro al 60 % pasante. Representa el tamaño dominante.',
          ejemplo: 'Arena media: 0,5 mm  |  Grava: 10–25 mm'),
      _Item(
          'Cu y Cc — Coeficientes',
          'Cu = D60/D10 (uniformidad). Cc = D30²/(D10×D60) (curvatura). '
              'La app los muestra en tiempo real mientras escribís.',
          ejemplo: 'GW: Cu ≥ 4  y  1 ≤ Cc ≤ 3'),
    ],
  ),
  _Paso(
    icono: Icons.check_circle_rounded,
    color: Color(0xFFE5662A), // primary — naranja LINARE
    titulo: '¡Todo listo!',
    subtitulo: 'Podés repasar este tutorial en cualquier momento desde '
        'el botón de ayuda (?) en la pantalla principal.',
    items: [
      _Item(
          'Clasificar',
          'Ingresá los datos y presioná "Clasificar". El símbolo SUCS '
              'aparece al instante junto con resumen e interpretación.'),
      _Item(
          'Exportar PDF',
          'El resultado incluye curva granulométrica, carta de '
              'Casagrande y recomendaciones de ingeniería.'),
      _Item(
          'Historial',
          'Las últimas 5 muestras quedan guardadas para '
              'comparación rápida.'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _pagina = 0;

  /// Controla si el hint "Deslizá →" ya se vio. Se oculta después
  /// del primer swipe o cuando el usuario avanza con el botón.
  bool _mostrarHintSwipe = true;

  void _siguiente() {
    setState(() => _mostrarHintSwipe = false);
    if (_pagina < _pasos.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _terminar();
    }
  }

  void _anterior() {
    _ctrl.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _terminar() async {
    await marcarOnboardingVisto();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pagina];
    final esUltimo = _pagina == _pasos.length - 1;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Barra superior ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots indicadores + hint swipe
                  Row(
                    children: [
                      // Dots
                      Row(
                        children: List.generate(_pasos.length, (i) {
                          final activo = i == _pagina;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            width: activo ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: activo
                                  ? paso.color
                                  : paso.color.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      // Hint de swipe — solo en página 0 y si no se vio aún
                      AnimatedOpacity(
                        opacity:
                            (_pagina == 0 && _mostrarHintSwipe) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(children: [
                            Icon(Icons.swipe_right_alt_rounded,
                                size: 14,
                                color: context.appColors.textPrimary
                                    .withValues(alpha: 0.35)),
                            const SizedBox(width: 4),
                            Text(
                              'deslizá',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.appColors.textPrimary
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  // Botón saltar
                  if (!esUltimo)
                    TextButton(
                      onPressed: _terminar,
                      child: Text(
                        'Saltar',
                        style: TextStyle(
                          color: context.appColors.textPrimary
                              .withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Contenido paginado ───────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() {
                  _pagina = i;
                  // Ocultar hint de swipe después del primer deslizamiento
                  if (i > 0) _mostrarHintSwipe = false;
                }),
                itemCount: _pasos.length,
                itemBuilder: (_, i) => _PasoPage(paso: _pasos[i]),
              ),
            ),

            // ── Botones de navegación ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                children: [
                  if (_pagina > 0)
                    OutlinedButton(
                      onPressed: _anterior,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appColors.textPrimary,
                        side: BorderSide(
                          color: context.appColors.textPrimary
                              .withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18),
                    ),
                  if (_pagina > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _siguiente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: paso.color,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: paso.color.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        esUltimo ? 'Empezar a clasificar' : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PÁGINA DE CADA PASO
// ─────────────────────────────────────────────────────────────
class _PasoPage extends StatelessWidget {
  final _Paso paso;
  const _PasoPage({required this.paso});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: paso.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(paso.icono, color: paso.color, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            paso.titulo,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            paso.subtitulo,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textPrimary.withValues(alpha: 0.62),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          ...paso.items.map((item) => _ItemCard(item: item, color: paso.color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA DE ITEM
// ─────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final _Item item;
  final Color color;
  const _ItemCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.etiqueta,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.descripcion,
            style: TextStyle(
              fontSize: 13,
              color: context.appColors.textPrimary.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
          if (item.ejemplo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 13, color: color.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.ejemplo!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.appColors.textPrimary
                            .withValues(alpha: 0.55),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
