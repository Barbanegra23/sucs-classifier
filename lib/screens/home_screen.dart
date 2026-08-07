import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../main.dart' show toggleTheme;
import 'sucs_screen.dart';
import 'aashto_screen.dart';

/// Pantalla raíz de la app: selector entre los sistemas de
/// clasificación de suelos disponibles (SUCS / AASHTO).
///
/// Es la pantalla a la que `WelcomeScreen` navega al terminar el
/// splash. De acá en más, "home" significa literalmente esto: el
/// punto de entrada neutral desde el que se elige un sistema, no un
/// sistema en particular.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        top: false,
        child: Column(children: [
          // ── Header con marca ─────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                context.appColors.primary,
                context.appColors.primaryLight,
                context.appColors.headerAccentFade,
              ]),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 18),
            color: context.appColors.headerBg,
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo_sucs.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LINARE OBRAS CIVILES',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.1,
                        )),
                    SizedBox(height: 2),
                    Text('Clasificación de suelos',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Tooltip(
                message: context.isDark ? 'Modo claro' : 'Modo oscuro',
                child: InkWell(
                  onTap: toggleTheme,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      context.isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ]),
          ),

          // ── Selector ──────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '¿Qué sistema de clasificación\nnecesitás?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elegí un sistema para empezar a cargar los datos del suelo.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SystemCard(
                    titulo: 'Clasificador SUCS',
                    subtitulo: 'Sistema Unificado de Clasificación de Suelos',
                    norma: 'ASTM D2487',
                    detalle: '16 símbolos · Carta de Casagrande incluida',
                    color: context.appColors.primary,
                    icono: Icons.terrain_rounded,
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const SucsScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SystemCard(
                    titulo: 'Clasificador AASHTO',
                    subtitulo:
                        'American Association of State Highway and Transportation Officials',
                    norma: 'AASHTO M 145 / ASTM D3282',
                    detalle: '11 grupos · Índice de Grupo (GI)',
                    color: context.appColors.secondary,
                    icono: Icons.route_rounded,
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const AashtoScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String norma;
  final String detalle;
  final Color color;
  final IconData icono;
  final VoidCallback onTap;

  const _SystemCard({
    required this.titulo,
    required this.subtitulo,
    required this.norma,
    required this.detalle,
    required this.color,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.card,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: context.appColors.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textPrimary,
                      )),
                  const SizedBox(height: 3),
                  Text(subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.appColors.textSecondary,
                      )),
                  const SizedBox(height: 8),
                  Row(children: [
                    _Tag(text: norma, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(detalle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: context.appColors.textSecondary,
                          )),
                    ),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.appColors.textSecondary, size: 22),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
