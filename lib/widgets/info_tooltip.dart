import 'package:flutter/material.dart';

/// Tooltip personalizado con fondo semitransparente y animación de entrada.
/// Se muestra al tocar el ícono ⓘ y desaparece al tocar fuera o después de 4s.
class InfoTooltip extends StatefulWidget {
  final String message;

  const InfoTooltip({super.key, required this.message});

  @override
  State<InfoTooltip> createState() => _InfoTooltipState();
}

class _InfoTooltipState extends State<InfoTooltip>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Controlador de animación: 220ms de duración
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Fade: de 0 (invisible) a 1 (visible)
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    // Slide: sube levemente desde abajo al aparecer
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showTooltip() {
    // Si ya hay uno visible, lo cerramos
    if (_overlayEntry != null) {
      _animController.reverse().then((_) => _removeOverlay());
      return;
    }

    // Obtenemos la posición del ícono en pantalla
    final renderBox = context.findRenderObject() as RenderBox;
    final iconPosition = renderBox.localToGlobal(Offset.zero);
    final iconSize = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    // Ancho máximo del globo
    const tooltipWidth = 260.0;

    // Calculamos la posición horizontal para no salirse de pantalla
    double left = iconPosition.dx + iconSize.width / 2 - tooltipWidth / 2;
    left = left.clamp(12.0, screenWidth - tooltipWidth - 12.0);

    // Posición vertical: encima del ícono
    final top = iconPosition.dy - 8;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fondo invisible que captura taps fuera del tooltip
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissTooltip,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

          // El globo de tooltip en sí
          Positioned(
            left: left,
            top: top,
            width: tooltipWidth,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _TooltipBubble(
                  message: widget.message,
                  onClose: _dismissTooltip,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();

    // Auto-cierre después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (_overlayEntry != null) _dismissTooltip();
    });
  }

  void _dismissTooltip() {
    _animController.reverse().then((_) => _removeOverlay());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showTooltip,
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: Color(0xFF3E6B70),
        ),
      ),
    );
  }
}

/// El globo visual del tooltip
class _TooltipBubble extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _TooltipBubble({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // Fondo semitransparente — color oscuro con 88% de opacidad
          color: const Color(0xFF2F4F54).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
