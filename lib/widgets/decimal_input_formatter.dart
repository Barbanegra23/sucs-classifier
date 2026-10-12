import 'package:flutter/services.dart';

/// Acepta números decimales escritos con coma o con punto.
///
/// En Android/iOS con idioma español el teclado numérico suele mostrar
/// "," como separador decimal. El filtro anterior (`[0-9.]`) descartaba
/// la coma y el usuario no podía cargar decimales. Este formateador
/// convierte la coma en punto al escribir, así `double.tryParse` del
/// resto de la app sigue funcionando sin cambios, y rechaza cualquier
/// texto que no sea un número decimal no negativo (un solo separador).
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter();

  static final _valido = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text.replaceAll(',', '.');
    if (!_valido.hasMatch(texto)) return oldValue;
    // Mismo largo que el original: la selección/cursor no cambia.
    return newValue.copyWith(text: texto);
  }
}
