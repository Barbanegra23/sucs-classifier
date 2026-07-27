import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/typewriter_text.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeLogo;
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeBottom;
  late final Animation<Offset> _slideBottom;

  // Evita que el usuario tap mientras la navegación async está en curso.
  bool _navegando = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeLogo = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _fadeTitle = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOut),
    );
    _fadeBottom = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    );
    _slideBottom = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Navegación ──────────────────────────────────────────────

  /// Navega directo a HomeScreen. El tutorial es siempre opcional.
  void _navegar() {
    if (_navegando) return;
    setState(() => _navegando = true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// Abre el tutorial directamente, sin verificar si ya fue visto.
  void _abrirTutorial() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navegar,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Foto de fondo
            Image.asset(
              'assets/images/welcome_bg.jpg',
              fit: BoxFit.cover,
            ),

            // Overlay gradiente
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x22000000),
                    Color(0xCC0D1F22),
                    Color(0xEE0D1F22),
                  ],
                  stops: [0.0, 0.30, 0.62, 1.0],
                ),
              ),
            ),

            // Contenido
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo en la parte superior
                  FadeTransition(
                    opacity: _fadeLogo,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/images/logo_sucs.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.layers_rounded,
                                    color: context.appColors.primaryLight,
                                    size: 13),
                                SizedBox(width: 6),
                                Text(
                                  'SUCS · ASTM D2487',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Título grande
                  FadeTransition(
                    opacity: _fadeTitle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.appColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TypewriterText(
                            text: 'CLASIFICADOR\nDE SUELOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              height: 1.08,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            letterDelayMs: 38,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sistema Unificado de Clasificación',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Sección inferior
                  FadeTransition(
                    opacity: _fadeBottom,
                    child: SlideTransition(
                      position: _slideBottom,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clasificación precisa según ASTM D2487. '
                              'Ingresá Atterberg y granulometría para '
                              'obtener el símbolo SUCS al instante.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 13.5,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                _StatChip(
                                  value: '16',
                                  label: 'Símbolos',
                                  icon: Icons.category_rounded,
                                ),
                                const SizedBox(width: 10),
                                _StatChip(
                                  value: 'ASTM',
                                  label: 'Norma',
                                  icon: Icons.verified_rounded,
                                ),
                                const SizedBox(width: 10),
                                _StatChip(
                                  value: 'PDF',
                                  label: 'Exportar',
                                  icon: Icons.picture_as_pdf_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Botón principal
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _navegando ? null : _navegar,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          context.appColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      elevation: 10,
                                      shadowColor: context.appColors.primary
                                          .withValues(alpha: 0.55),
                                    ),
                                    child: _navegando
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Clasificar suelo',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded,
                                                  size: 17),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Botón secundario — tutorial
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _abrirTutorial,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(
                                          color: Colors.white24, width: 1),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.school_outlined, size: 15),
                                        SizedBox(width: 7),
                                        Text(
                                          'Ver tutorial',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Center(
                              child: Text(
                                'o tocá en cualquier parte',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
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

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.appColors.primaryLight, size: 17),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
