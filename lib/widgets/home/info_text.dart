import 'package:flutter/material.dart';

/// Texto informativo simple usado como placeholder dentro de las
/// tarjetas del formulario (ej: "Ingresá % pasa 200 para continuar").
class InfoText extends StatelessWidget {
  final String texto;
  const InfoText(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(texto, style: const TextStyle(color: Colors.grey)),
      );
}
