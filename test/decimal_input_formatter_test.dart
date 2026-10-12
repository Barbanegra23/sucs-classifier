import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sucs_classifier/widgets/decimal_input_formatter.dart';

TextEditingValue _escribir(String anterior, String nuevo) =>
    const DecimalInputFormatter().formatEditUpdate(
      TextEditingValue(
          text: anterior,
          selection: TextSelection.collapsed(offset: anterior.length)),
      TextEditingValue(
          text: nuevo,
          selection: TextSelection.collapsed(offset: nuevo.length)),
    );

void main() {
  group('DecimalInputFormatter', () {
    test('la coma se convierte en punto', () {
      expect(_escribir('12', '12,').text, '12.');
      expect(_escribir('12,', '12,5').text, '12.5');
      expect(double.tryParse(_escribir('12', '12,5').text), 12.5);
    });

    test('el punto se acepta igual que antes', () {
      expect(_escribir('12', '12.5').text, '12.5');
    });

    test('rechaza un segundo separador', () {
      expect(_escribir('12.5', '12.5,').text, '12.5');
      expect(_escribir('12.5', '12.5.').text, '12.5');
    });

    test('rechaza letras y signo negativo', () {
      expect(_escribir('12', '12a').text, '12');
      expect(_escribir('', '-').text, '');
    });

    test('pegar "0,075" queda como 0.075', () {
      expect(_escribir('', '0,075').text, '0.075');
    });

    test('permite borrar todo', () {
      expect(_escribir('12', '').text, '');
    });

    test('mantiene la posición del cursor', () {
      final r = _escribir('12', '12,');
      expect(r.selection.baseOffset, 3);
    });
  });
}
