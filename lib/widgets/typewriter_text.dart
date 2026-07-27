import 'package:flutter/material.dart';

/// Muestra un texto letra por letra con efecto typewriter.
/// Cada vez que cambia [text] la animación se reinicia desde cero.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Tiempo entre cada letra en milisegundos
  final int letterDelayMs;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.letterDelayMs = 80,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _initAnimation(widget.text);
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el texto cambió (nuevo resultado), reinicia la animación
    if (oldWidget.text != widget.text) {
      _controller.dispose();
      _initAnimation(widget.text);
    }
  }

  void _initAnimation(String text) {
    final totalMs = text.length * widget.letterDelayMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    // Anima un entero de 0 hasta la cantidad de letras del texto
    _charCount = IntTween(begin: 0, end: text.length).animate(
      CurvedAnimation(
        parent: _controller,
        // easeIn: arranca lento y acelera — se siente más natural
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, _) {
        // Mostramos solo los primeros N caracteres según el progreso
        final visibleText = widget.text.substring(0, _charCount.value);
        return Text(visibleText, style: widget.style);
      },
    );
  }
}
