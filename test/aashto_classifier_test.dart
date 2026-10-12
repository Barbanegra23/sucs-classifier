// Tests unitarios para la clasificación AASHTO (M 145 / ASTM D3282).
// Todos los valores de Índice de Grupo (GI) están calculados a mano con
// la fórmula de la norma para poder verificarlos línea por línea:
//
//   GI = (F-35)·[0.2 + 0.005·(LL-40)] + 0.01·(F-15)·(PI-10)
//
// donde F = % que pasa el tamiz N°200. Para A-2-6/A-2-7 se usa solo el
// término de PI: GI = 0.01·(F-15)·(PI-10). Para A-1-a/A-1-b/A-2-4/A-2-5/
// A-3, el GI es 0 por definición de la norma.

import 'package:flutter_test/flutter_test.dart';
import 'package:sucs_classifier/services/aashto_classifier.dart';

void main() {
  group('Materiales granulares (≤35% pasa N°200)', () {
    test('A-1-a: fragmentos de piedra, grava y arena bien graduada', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 40, pasa40: 25, pasa200: 10, ll: 20, lp: 17)); // PI=3
      expect(r.grupo, 'A-1-a');
      expect(r.gi, 0);
      expect(r.symbol, 'A-1-a(0)');
      expect(r.tipoMaterial, contains('granular'));
    });

    test('A-1-b: se activa cuando P10>50 tira a A-1-a pero P40/P200/PI OK',
        () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 60, pasa40: 25, pasa200: 10, ll: 20, lp: 17)); // PI=3
      expect(r.grupo, 'A-1-b');
      expect(r.gi, 0);
    });

    test('A-3: arena fina no plástica, requiere P40≥51', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 90, pasa40: 60, pasa200: 5, ll: 25, lp: 25)); // PI=0 (NP)
      expect(r.grupo, 'A-3');
      expect(r.gi, 0);
      expect(r.pi, 0);
    });

    test('P40=50 (límite) cae en A-1-b, no en A-3, por orden de la tabla',
        () {
      // A-1-b se evalúa antes que A-3 en la norma: si cumple A-1-b,
      // gana A-1-b aunque también sea NP.
      final r = clasificarAashto(
          AashtoInput(pasa10: 90, pasa40: 50, pasa200: 8, ll: 25, lp: 25));
      expect(r.grupo, 'A-1-b');
    });

    test('P40=51 (justo arriba del límite de A-1-b) sí cae en A-3', () {
      final r = clasificarAashto(
          AashtoInput(pasa10: 90, pasa40: 51, pasa200: 8, ll: 25, lp: 25));
      expect(r.grupo, 'A-3');
    });

    test('A-2-4: grava/arena limosa, LL≤40 y PI≤10', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 70, pasa40: 70, pasa200: 30, ll: 35, lp: 27)); // PI=8
      expect(r.grupo, 'A-2-4');
      expect(r.gi, 0);
    });

    test('A-2-5: grava/arena limosa, LL≥41 y PI≤10', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 70, pasa40: 70, pasa200: 25, ll: 45, lp: 36)); // PI=9
      expect(r.grupo, 'A-2-5');
      expect(r.gi, 0);
    });

    test('A-2-6: grava/arena arcillosa, LL≤40 y PI≥11 — GI con fórmula parcial',
        () {
      // GI = 0.01*(25-15)*(16-10) = 0.6 → redondea a 1
      final r = clasificarAashto(AashtoInput(
          pasa10: 70, pasa40: 70, pasa200: 25, ll: 35, lp: 19)); // PI=16
      expect(r.grupo, 'A-2-6');
      expect(r.gi, 1);
      expect(r.symbol, 'A-2-6(1)');
    });

    test('A-2-7: grava/arena arcillosa, LL≥41 y PI≥11', () {
      // GI = 0.01*(25-15)*(16-10) = 0.6 → redondea a 1
      final r = clasificarAashto(AashtoInput(
          pasa10: 70, pasa40: 70, pasa200: 25, ll: 45, lp: 29)); // PI=16
      expect(r.grupo, 'A-2-7');
      expect(r.gi, 1);
    });

    test('P200 exactamente 35 sigue considerándose material granular', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 70, pasa40: 70, pasa200: 35, ll: 35, lp: 27)); // PI=8
      expect(r.tipoMaterial, contains('granular'));
      expect(r.grupo, 'A-2-4');
    });
  });

  group('Materiales limo-arcillosos (>35% pasa N°200)', () {
    test('A-4: suelo limoso, LL≤40 y PI≤10', () {
      // GI = 15*(0.2+0.005*(35-40)) + 0.01*35*(8-10)
      //    = 15*0.175 + 0.35*(-2) = 2.625 - 0.7 = 1.925 → redondea a 2
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 50, ll: 35, lp: 27)); // PI=8
      expect(r.grupo, 'A-4');
      expect(r.gi, 2);
      expect(r.tipoMaterial, contains('limo-arcilloso'));
    });

    test('A-5: suelo limoso elástico, LL≥41 y PI≤10', () {
      // GI = 15*(0.2+0.005*5) + 0.35*(-1) = 15*0.225 - 0.35 = 3.375-0.35=3.025 → 3
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 50, ll: 45, lp: 36)); // PI=9
      expect(r.grupo, 'A-5');
      expect(r.gi, 3);
    });

    test('A-6: suelo arcilloso, LL≤40 y PI≥11', () {
      // GI = 25*(0.2-0.05) + 0.45*5 = 3.75 + 2.25 = 6.0
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 60, ll: 30, lp: 15)); // PI=15
      expect(r.grupo, 'A-6');
      expect(r.gi, 6);
    });

    test('A-7-5: LL≥41, PI≥11 y PI ≤ LL-30 (bajo la Línea A extendida)', () {
      // GI = 25*0.25 + 0.45*5 = 6.25+2.25 = 8.5 → redondea a 9
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 60, ll: 50, lp: 35)); // PI=15
      expect(r.grupo, 'A-7-5');
      expect(r.gi, 9);
    });

    test('A-7-6: LL≥41, PI≥11 y PI > LL-30 (sobre la Línea A extendida)', () {
      // GI = 25*0.25 + 0.45*15 = 6.25+6.75 = 13.0
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 60, ll: 50, lp: 25)); // PI=25
      expect(r.grupo, 'A-7-6');
      expect(r.gi, 13);
    });

    test('GI nunca es negativo — se reporta como 0 aunque la fórmula dé negativo',
        () {
      // GI = 1*(0.2-0.075) + 0.21*(-9) = 0.125 - 1.89 = -1.765 → clamp a 0
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 36, ll: 25, lp: 24)); // PI=1
      expect(r.grupo, 'A-4');
      expect(r.gi, 0);
    });

    test('P200 apenas sobre 35 (35.5) se considera limo-arcilloso', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 35.5, ll: 35, lp: 27)); // PI=8
      expect(r.tipoMaterial, contains('limo-arcilloso'));
      expect(r.grupo, 'A-4');
    });
  });

  group('Índice de Plasticidad (PI)', () {
    test('PI se calcula como LL - LP', () {
      final r = clasificarAashto(
          AashtoInput(pasa10: 95, pasa40: 90, pasa200: 50, ll: 40, lp: 25));
      expect(r.pi, 15);
    });

    test('LP > LL (dato inconsistente o suelo NP) da PI=0, no negativo', () {
      final r = clasificarAashto(
          AashtoInput(pasa10: 95, pasa40: 90, pasa200: 50, ll: 20, lp: 25));
      expect(r.pi, 0);
    });
  });

  group('Descripciones y calificación como subrasante', () {
    test('grupos A-1/A-2/A-3 se describen como material granular excelente/bueno',
        () {
      final r = clasificarAashto(
          AashtoInput(pasa10: 40, pasa40: 25, pasa200: 10, ll: 20, lp: 17));
      expect(r.calificacionSubrasante, contains('Excelente'));
    });

    test('grupos A-4 a A-7 empeoran la calificación a medida que sube el GI',
        () {
      final bajo = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 50, ll: 35, lp: 27)); // GI=2
      final alto = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 60, ll: 50, lp: 25)); // GI=13
      expect(bajo.calificacionSubrasante, isNot(alto.calificacionSubrasante));
    });

    test('el símbolo final incluye el GI entre paréntesis', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 60, ll: 50, lp: 25)); // A-7-6(13)
      expect(r.symbol, 'A-7-6(13)');
    });
  });

  group('Valores decimales entre umbrales (antes caían en A-7)', () {
    test('LL=40.5, PI=8, F=50 → A-5 (no A-7-5)', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 50, ll: 40.5, lp: 32.5));
      expect(r.grupo, 'A-5');
    });
    test('LL=30, PI=10.5, F=50 → A-6 (no A-7-6)', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 50, ll: 30, lp: 19.5));
      expect(r.grupo, 'A-6');
    });
    test('LL=40.5, PI=10.5, F=50 → A-7 (ambos altos)', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 50, ll: 40.5, lp: 30));
      expect(r.grupo, startsWith('A-7'));
    });
    test('LL=40.5, PI=8, F=30 → A-2-5 (no A-2-7)', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 80, pasa40: 60, pasa200: 30, ll: 40.5, lp: 32.5));
      expect(r.grupo, 'A-2-5');
    });
    test('LL=30, PI=10.5, F=30 → A-2-6 (no A-2-7)', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 80, pasa40: 60, pasa200: 30, ll: 30, lp: 19.5));
      expect(r.grupo, 'A-2-6');
    });
    test('LL=40 exacto, PI=10 exacto → A-4 (límites inclusivos)', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 95, pasa40: 90, pasa200: 50, ll: 40, lp: 30));
      expect(r.grupo, 'A-4');
    });
    test('A-3 con P40 = 50.5 (antes no entraba por exigir ≥ 51)', () {
      final r = clasificarAashto(AashtoInput(
          pasa10: 90, pasa40: 50.5, pasa200: 5, ll: 0, lp: 0));
      expect(r.grupo, 'A-3');
    });
  });
}
