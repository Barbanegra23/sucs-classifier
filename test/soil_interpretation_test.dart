import 'package:flutter_test/flutter_test.dart';
import 'package:sucs_classifier/logic/soil_interpretation.dart';

void main() {
  group('generarResumen()', () {
    test('CL-ML devuelve el texto fijo de zona de transición', () {
      final r = SoilInterpretation.generarResumen('CL-ML', 5, 32);
      expect(r, contains('zona de transición'));
      expect(r, contains('cohesivo-friccional'));
    });

    test('identifica tipo Arcilla para CL y CH', () {
      expect(SoilInterpretation.generarResumen('CL', 15, 30), contains('Arcilla'));
      expect(SoilInterpretation.generarResumen('CH', 30, 60), contains('Arcilla'));
    });

    test('identifica tipo Limo para ML y MH', () {
      expect(SoilInterpretation.generarResumen('ML', 2, 25), contains('Limo'));
      expect(SoilInterpretation.generarResumen('MH', 10, 60), contains('Limo'));
    });

    test('identifica tipo Grava para símbolos G*', () {
      for (final s in ['GW', 'GP', 'GM', 'GC']) {
        expect(SoilInterpretation.generarResumen(s, 10, 30), contains('Grava'),
            reason: 'símbolo $s debería mapear a Grava');
      }
    });

    test('identifica tipo Arena para símbolos S*', () {
      for (final s in ['SW', 'SP', 'SM', 'SC']) {
        expect(SoilInterpretation.generarResumen(s, 10, 30), contains('Arena'),
            reason: 'símbolo $s debería mapear a Arena');
      }
    });

    test('símbolo desconocido cae en tipo genérico "Suelo"', () {
      expect(SoilInterpretation.generarResumen('ZZ', 5, 30), contains('Suelo'));
    });

    test('baja plasticidad para CL/ML/SM/SC', () {
      for (final s in ['CL', 'ML', 'SM', 'SC']) {
        expect(SoilInterpretation.generarResumen(s, 8, 30), contains('baja plasticidad'));
      }
    });

    test('alta plasticidad para CH/MH', () {
      for (final s in ['CH', 'MH']) {
        expect(SoilInterpretation.generarResumen(s, 30, 60), contains('alta plasticidad'));
      }
    });

    test('gravas/arenas limpias bien graduadas (GW/SW) con PI bajo son granulares', () {
      final r = SoilInterpretation.generarResumen('GW', 3, 20);
      expect(r, contains('no cohesivo'));
    });

    test('símbolo dual sobre la Línea A menciona influencia arcillosa', () {
      // LL=30 → Línea A = 0.73*(30-20) = 7.3. PI=10 > 7.3 → arcillosa.
      final r = SoilInterpretation.generarResumen('GW-GC', 10, 30);
      expect(r, contains('influencia arcillosa'));
    });

    test('símbolo dual bajo la Línea A menciona influencia limosa', () {
      // Base GW/SW/GP/SP con PI<7 se clasifica como "granular limpio" ANTES
      // de mirar si es dual (ver esGranularLimpio en el código) — por eso
      // acá uso PI=8, para evitar esa rama y sí llegar a comparar contra
      // la Línea A. LL=35 → Línea A = 0.73*(35-20) = 10.95. PI=8 < 10.95 → limosa.
      final r = SoilInterpretation.generarResumen('GW-GM', 8, 35);
      expect(r, contains('influencia limosa'));
    });

    test('agrega "potencialmente expansivo" cuando PI>20 y sobre Línea A', () {
      // LL=60 → Línea A = 29.2. PI=35 > 29.2 y > 20 → expansivo.
      final r = SoilInterpretation.generarResumen('CH', 35, 60);
      expect(r, contains('potencialmente expansivo'));
    });

    test('agrega "altamente compresible" cuando LL>70', () {
      final r = SoilInterpretation.generarResumen('CH', 30, 75);
      expect(r, contains('altamente compresible'));
    });

    test('agrega "de baja cohesión" cuando PI<4', () {
      final r = SoilInterpretation.generarResumen('ML', 2, 25);
      expect(r, contains('baja cohesión'));
    });

    test('no agrega condiciones extra cuando no se cumple ninguna', () {
      // PI=10, LL=30 → Línea A=7.3 → no expansivo (PI<20), LL<70, PI>=4
      final r = SoilInterpretation.generarResumen('CL', 10, 30);
      expect(r, isNot(contains('expansivo')));
      expect(r, isNot(contains('compresible')));
      expect(r, isNot(contains('baja cohesión')));
    });
  });

  group('generarRecomendaciones()', () {
    test('GW sin d10 da recomendación genérica de drenaje', () {
      final rec = SoilInterpretation.generarRecomendaciones('GW', 0, 20);
      expect(rec, isNotEmpty);
      expect(rec.any((r) => r.contains('drenaje libre')), isTrue);
    });

    test('GW con d10 calcula permeabilidad de Hazen', () {
      final rec = SoilInterpretation.generarRecomendaciones('GW', 0, 20, d10: 0.5);
      expect(rec.any((r) => r.contains('Hazen') && r.contains('0.2500')), isTrue);
    });

    test('SW también usa la rama de graduación buena (comparte case con GW)', () {
      final rec = SoilInterpretation.generarRecomendaciones('SW', 0, 20, d10: 1.0);
      expect(rec.any((r) => r.contains('Hazen')), isTrue);
    });

    test('GP advierte sobre gradación pobre', () {
      final rec = SoilInterpretation.generarRecomendaciones('GP', 0, 20);
      expect(rec.any((r) => r.contains('gradación pobre')), isTrue);
    });

    test('GM incluye control de humedad y drenaje', () {
      final rec = SoilInterpretation.generarRecomendaciones('GM', 5, 25);
      expect(rec.any((r) => r.contains('humedad')), isTrue);
      expect(rec.any((r) => r.contains('drenaje')), isTrue);
    });

    test('SM incluye advertencia de licuefacción (a diferencia de GM)', () {
      final rec = SoilInterpretation.generarRecomendaciones('SM', 5, 25);
      expect(rec.any((r) => r.contains('licuefacción')), isTrue);
    });

    test('CL con PI>12 sugiere evaluar minerales expansivos', () {
      final rec = SoilInterpretation.generarRecomendaciones('CL', 13, 35);
      expect(rec.any((r) => r.contains('montmorillonita') || r.contains('expansiv')), isTrue);
    });

    test('CL con PI<=12 no sugiere evaluar minerales expansivos', () {
      final rec = SoilInterpretation.generarRecomendaciones('CL', 10, 30);
      expect(rec.any((r) => r.contains('montmorillonita')), isFalse);
    });

    test('CL con PI>17 sugiere estabilización con cal', () {
      final rec = SoilInterpretation.generarRecomendaciones('CL', 18, 35);
      expect(rec.any((r) => r.contains('cal')), isTrue);
    });

    test('CH con LL>70 agrega estudio de consolidación', () {
      final rec = SoilInterpretation.generarRecomendaciones('CH', 35, 75);
      expect(rec.any((r) => r.contains('consolidación')), isTrue);
    });

    test('CH con LL<=70 no agrega estudio de consolidación', () {
      final rec = SoilInterpretation.generarRecomendaciones('CH', 30, 60);
      expect(rec.any((r) => r.contains('consolidación')), isFalse);
    });

    test('CL-ML da recomendaciones específicas de ventana de compactación', () {
      final rec = SoilInterpretation.generarRecomendaciones('CL-ML', 5, 32);
      expect(rec.any((r) => r.contains('Ventana de compactación')), isTrue);
    });

    test('símbolos duales de grava/arena tienen recomendaciones propias', () {
      for (final s in [
        'GW-GC', 'GW-GM', 'GP-GC', 'GP-GM',
        'SW-SC', 'SW-SM', 'SP-SC', 'SP-SM',
      ]) {
        final rec = SoilInterpretation.generarRecomendaciones(s, 10, 30);
        expect(rec, isNotEmpty, reason: '$s debería tener recomendaciones propias');
      }
    });

    test('símbolo desconocido cae en recomendación genérica por defecto', () {
      final rec = SoilInterpretation.generarRecomendaciones('ZZ', 5, 30);
      expect(rec, isNotEmpty);
      expect(rec.any((r) => r.contains('Controlar contenido de humedad')), isTrue);
    });
  });

  group('interpretacionIngenieril()', () {
    test('devuelve lista no vacía para cada símbolo simple conocido', () {
      const simbolos = [
        'GW', 'GP', 'GM', 'GC',
        'SW', 'SP', 'SM', 'SC',
        'ML', 'MH', 'CL', 'CH',
      ];
      for (final s in simbolos) {
        final r = SoilInterpretation.interpretacionIngenieril(s);
        expect(r, isNotEmpty, reason: '$s debería tener interpretación');
      }
    });

    test('CL-ML tiene interpretación especial de zona de transición', () {
      final r = SoilInterpretation.interpretacionIngenieril('CL-ML');
      expect(r.any((l) => l.contains('transicional')), isTrue);
    });

    test('símbolos duales devuelven su interpretación propia, no la del símbolo base', () {
      // Regresión: "GW-GC".split("-").first == "GW", así que si el chequeo
      // por símbolo dual no tiene prioridad sobre el chequeo por `base`,
      // este test detecta que se coló la interpretación de la grava simple.
      const casos = {
        'GW-GC': 'arcillosos',
        'GW-GM': 'limosos',
        'GP-GC': 'arcillosos',
        'GP-GM': 'limosos',
        'SW-SC': 'arcillosos',
        'SW-SM': 'limosos',
        'SP-SC': 'arcillosos',
        'SP-SM': 'limosos',
      };
      casos.forEach((simbolo, palabraClave) {
        final r = SoilInterpretation.interpretacionIngenieril(simbolo);
        expect(r, isNotEmpty, reason: '$simbolo debería tener interpretación propia');
        expect(
          r.any((linea) => linea.contains(palabraClave)),
          isTrue,
          reason: '$simbolo debería mencionar "$palabraClave" en su interpretación específica, '
              'no devolver la del símbolo base',
        );
      });
    });

    test('símbolo desconocido devuelve mensaje genérico de fallback', () {
      final r = SoilInterpretation.interpretacionIngenieril('ZZ');
      expect(r, hasLength(1));
      expect(r.first, contains('consultar ensayos adicionales'));
    });
  });
}
