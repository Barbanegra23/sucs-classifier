import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../main.dart' show toggleTheme;
import '../../screens/onboarding_screen.dart';
import '../../screens/aashto_screen.dart';
import '../header_widgets.dart';

/// Encabezado de HomeScreen: logo, título, botón de tema claro/oscuro
/// y botón de tutorial (onboarding), más la fila de stats
/// (ASTM D2487 / 16 símbolos / Casagrande).
///
/// Es autocontenido: no depende de ningún estado del formulario,
/// solo del tema global (`context.appColors` / `toggleTheme`) y de la
/// navegación hacia `OnboardingScreen`.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(children: [
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
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 14),
        color: context.appColors.headerBg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo_sucs.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLASIFICADOR SUCS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1.2,
                    )),
                SizedBox(height: 2),
                Text('Sistema Unificado de Clasificación · ASTM D2487',
                    style: TextStyle(
                        color: context.appColors.headerSubtitle,
                        fontSize: 10.5)),
              ],
            )),
            const SizedBox(width: 8),
            // Botón para ir a la clasificación AASHTO
            Tooltip(
              message: 'Clasificar por AASHTO',
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AashtoScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 280),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: Colors.white70, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botón tema claro/oscuro
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
            const SizedBox(width: 8),
            // Botón de ayuda
            Tooltip(
              message: 'Ver tutorial',
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const OnboardingScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 280),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Colors.white70, size: 18),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          const IntrinsicHeight(
            child: Row(children: [
              Expanded(
                  child:
                      HeaderStat(valor: 'ASTM D2487', etiqueta: 'Norma base')),
              HeaderDivider(),
              Expanded(
                  child: HeaderStat(
                      valor: '16 símbolos', etiqueta: 'GW · GP · CL · CH…')),
              HeaderDivider(),
              Expanded(
                  child: HeaderStat(
                      valor: 'Casagrande', etiqueta: 'Carta incluida')),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
