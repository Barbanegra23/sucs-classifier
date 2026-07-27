// Tests unitarios para la lógica de clasificación SUCS
// Ejecutar con: flutter test
//
// Cobertura:
//  Grupo 1  — Suelos finos (CL, ML, CH, MH)
//  Grupo 2  — Gravas (GW/GP/GW-GC/GW-GM/GP-GC/GP-GM/GC/GM)
//  Grupo 3  — Arenas (SW/SP/SW-SC/SW-SM/SP-SC/SP-SM/SC/SM)
//  Grupo 4  — Validaciones de datos inválidos
//  Grupo 5  — Línea A de Casagrande
//  Grupo 6  — Casos borde (límites exactos, pctGrava = 50, Cc límites…)
//  Grupo 7  — División por cero (fix: gruesos <= 0)
//  Grupo 8  — Zona de transición CL-ML
//  Grupo 9  — Helpers: esSueloFino()
//  Grupo 10 — colorDeSuelo() consistencia con AppColors
//  Grupo 11 — Casos reales de laboratorio

import 'package:flutter_test/flutter_test.dart';
import 'package:sucs_classifier/services/sucs_classifier.dart';
import 'package:sucs_classifier/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

SucsInput sueloFino({
  required double pasa200,
  required double ll,
  required double lp,
  double retenidoN4 = 0,
}) =>
    SucsInput(
      pasa200: pasa200,
      retenidoN4: retenidoN4,
      ll: ll,
      lp: lp,
      cu: 0,
      cc: 0,
    );

SucsInput sueloGrueso({
  required double pasa200,
  required double retenidoN4,
  required double ll,
  required double lp,
  required double cu,
  required double cc,
}) =>
    SucsInput(
      pasa200: pasa200,
      retenidoN4: retenidoN4,
      ll: ll,
      lp: lp,
      cu: cu,
      cc: cc,
    );

void main() {
  // ═══════════════════════════════════════════════════════════
  // GRUPO 1: SUELOS FINOS
  // ═══════════════════════════════════════════════════════════
  group('Suelos finos (pasa200 >= 50%)', () {
    group('Baja plasticidad (LL < 50)', () {
      test('CL — Arcilla de baja plasticidad (PI sobre Línea A)', () {
        final resultado =
            clasificarSuelo(sueloFino(pasa200: 70, ll: 35, lp: 20));
        expect(resultado.symbol, equals('CL'));
      });

      test('ML — Limo de baja plasticidad (PI bajo Línea A)', () {
        final resultado =
            clasificarSuelo(sueloFino(pasa200: 60, ll: 30, lp: 25));
        expect(resultado.symbol, equals('ML'));
      });
    });

    group('Alta plasticidad (LL >= 50)', () {
      test('CH — Arcilla de alta plasticidad (PI sobre Línea A)', () {
        final resultado =
            clasificarSuelo(sueloFino(pasa200: 80, ll: 70, lp: 30));
        expect(resultado.symbol, equals('CH'));
      });

      test('MH — Limo de alta plasticidad (PI bajo Línea A)', () {
        final resultado =
            clasificarSuelo(sueloFino(pasa200: 75, ll: 55, lp: 45));
        expect(resultado.symbol, equals('MH'));
      });
    });

    test('PI se calcula correctamente (LL - LP)', () {
      final resultado = clasificarSuelo(sueloFino(pasa200: 65, ll: 40, lp: 18));
      expect(resultado.pi, closeTo(22.0, 0.01));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 2: GRAVAS
  // ═══════════════════════════════════════════════════════════
  group('Gravas (pasa200 < 50%, R4 dominante)', () {
    test('GW — Grava bien graduada (pasa200 < 5%, Cu>=4, 1<=Cc<=3)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 6, cc: 2))
              .symbol,
          equals('GW'));
    });

    test('GP — Grava mal graduada (pasa200 < 5%, Cu<4)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 2, cc: 2))
              .symbol,
          equals('GP'));
    });

    test('GW-GC — Grava bien graduada con arcilla (zona dual, PI>LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 8, retenidoN4: 75, ll: 35, lp: 20, cu: 6, cc: 2))
              .symbol,
          equals('GW-GC'));
    });

    test('GW-GM — Grava bien graduada con limo (zona dual, PI<LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 8, retenidoN4: 75, ll: 30, lp: 25, cu: 6, cc: 2))
              .symbol,
          equals('GW-GM'));
    });

    test('GP-GC — Grava mal graduada con arcilla', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 8, retenidoN4: 75, ll: 35, lp: 20, cu: 2, cc: 0.5))
              .symbol,
          equals('GP-GC'));
    });

    test('GP-GM — Grava mal graduada con limo', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 8, retenidoN4: 75, ll: 30, lp: 25, cu: 2, cc: 0.5))
              .symbol,
          equals('GP-GM'));
    });

    test('GC — Grava arcillosa (pasa200 > 12%, PI > LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 20, retenidoN4: 70, ll: 35, lp: 20, cu: 5, cc: 2))
              .symbol,
          equals('GC'));
    });

    test('GM — Grava limosa (pasa200 > 12%, PI < LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 20, retenidoN4: 70, ll: 30, lp: 25, cu: 5, cc: 2))
              .symbol,
          equals('GM'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 3: ARENAS
  // ═══════════════════════════════════════════════════════════
  group('Arenas (pasa200 < 50%, arena dominante)', () {
    test('SW — Arena bien graduada (pasa200 < 5%, Cu>=6, 1<=Cc<=3)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 3, retenidoN4: 20, ll: 20, lp: 15, cu: 7, cc: 2))
              .symbol,
          equals('SW'));
    });

    test('SP — Arena mal graduada (pasa200 < 5%, Cu<6)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 3, retenidoN4: 20, ll: 20, lp: 15, cu: 3, cc: 2))
              .symbol,
          equals('SP'));
    });

    test('SW-SC — Arena bien graduada con arcilla (zona dual, PI>LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 9, retenidoN4: 20, ll: 35, lp: 20, cu: 7, cc: 2))
              .symbol,
          equals('SW-SC'));
    });

    test('SW-SM — Arena bien graduada con limo (zona dual, PI<LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 9, retenidoN4: 20, ll: 30, lp: 25, cu: 7, cc: 2))
              .symbol,
          equals('SW-SM'));
    });

    test('SP-SC — Arena mal graduada con arcilla', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 9, retenidoN4: 20, ll: 35, lp: 20, cu: 3, cc: 0.5))
              .symbol,
          equals('SP-SC'));
    });

    test('SP-SM — Arena mal graduada con limo', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 9, retenidoN4: 20, ll: 30, lp: 25, cu: 3, cc: 0.5))
              .symbol,
          equals('SP-SM'));
    });

    test('SC — Arena arcillosa (pasa200 > 12%, PI > LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 20, retenidoN4: 20, ll: 35, lp: 20, cu: 5, cc: 2))
              .symbol,
          equals('SC'));
    });

    test('SM — Arena limosa (pasa200 > 12%, PI < LineaA)', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 20, retenidoN4: 20, ll: 30, lp: 25, cu: 5, cc: 2))
              .symbol,
          equals('SM'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 4: VALIDACIONES
  // ═══════════════════════════════════════════════════════════
  group('Validaciones de datos inválidos', () {
    test('ERROR si LP > LL', () {
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 20, lp: 30)).symbol,
          equals('ERROR'));
    });

    test('ERROR si pasa200 > 100', () {
      expect(clasificarSuelo(sueloFino(pasa200: 110, ll: 30, lp: 15)).symbol,
          equals('ERROR'));
    });

    test('ERROR si pasa200 < 0', () {
      expect(clasificarSuelo(sueloFino(pasa200: -5, ll: 30, lp: 15)).symbol,
          equals('ERROR'));
    });

    test('ERROR si Cu = 0 en suelo grueso', () {
      expect(
          clasificarSuelo(sueloGrueso(
                  pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 0, cc: 2))
              .symbol,
          equals('ERROR'));
    });

    test('ERROR si LL < 0', () {
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: -5, lp: -10)).symbol,
          equals('ERROR'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 5: LÍNEA A DE CASAGRANDE
  // ═══════════════════════════════════════════════════════════
  group('Línea A de Casagrande', () {
    test('lineaA(50) = 21.9', () => expect(lineaA(50), closeTo(21.9, 0.01)));
    test('lineaA(20) = 0', () => expect(lineaA(20), closeTo(0.0, 0.01)));
    test('lineaA(70) = 36.5', () => expect(lineaA(70), closeTo(36.5, 0.01)));

    test('lineaA nunca devuelve negativo (LL < 20)', () {
      expect(lineaA(10), equals(0.0));
      expect(lineaA(0), equals(0.0));
      expect(lineaA(19.9), equals(0.0));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 6: CASOS BORDE
  // ═══════════════════════════════════════════════════════════
  group('Casos borde', () {
    test('pasa200 = 50% exacto → suelo fino (CL)', () {
      final r = clasificarSuelo(sueloFino(pasa200: 50, ll: 35, lp: 20));
      expect(r.symbol, equals('CL'));
    });

    test('pasa200 = 5% exacto → entra en zona dual (GW-GC)', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 5, retenidoN4: 75, ll: 35, lp: 20, cu: 6, cc: 2));
      expect(r.symbol, equals('GW-GC'));
    });

    test('pasa200 = 12% exacto → aún en zona dual (GW-GC)', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 12, retenidoN4: 70, ll: 35, lp: 20, cu: 6, cc: 2));
      expect(r.symbol, equals('GW-GC'));
    });

    test('LL = LP → PI = 0', () {
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 25, lp: 25)).pi,
          equals(0.0));
    });

    test('Límite grava/arena: pctGrava = 50% → GRAVA', () {
      // gruesos=98, R4=49 → pctGrava = (49/98)*100 = 50.0% → GRAVA
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 2, retenidoN4: 49, ll: 20, lp: 15, cu: 6, cc: 2));
      expect(r.symbol, startsWith('G'));
    });

    test('Límite grava/arena: pctGrava < 50% → ARENA', () {
      // gruesos=98, R4=48 → pctGrava = (48/98)*100 = 48.97% → ARENA
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 2, retenidoN4: 48, ll: 20, lp: 15, cu: 7, cc: 2));
      expect(r.symbol, startsWith('S'));
    });

    test('Cc = 1 exacto → bien graduada (GW)', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 6, cc: 1));
      expect(r.symbol, equals('GW'));
    });

    test('Cc = 3 exacto → bien graduada (GW)', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 6, cc: 3));
      expect(r.symbol, equals('GW'));
    });

    test('Cc = 3.01 → mal graduada (GP)', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 6, cc: 3.01));
      expect(r.symbol, equals('GP'));
    });

    test('Cu = 4 exacto en grava → bien graduada si Cc cumple', () {
      // Cu mínimo para grava: 4
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 4, cc: 2));
      expect(r.symbol, equals('GW'));
    });

    test('Cu = 3.99 en grava → mal graduada (GP)', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 3, retenidoN4: 80, ll: 20, lp: 15, cu: 3.99, cc: 2));
      expect(r.symbol, equals('GP'));
    });

    test('Cu = 6 exacto en arena → bien graduada si Cc cumple', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 3, retenidoN4: 20, ll: 20, lp: 15, cu: 6, cc: 2));
      expect(r.symbol, equals('SW'));
    });

    test('Cu = 5.99 en arena → mal graduada (SP)', () {
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 3, retenidoN4: 20, ll: 20, lp: 15, cu: 5.99, cc: 2));
      expect(r.symbol, equals('SP'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 7: DIVISIÓN POR CERO — fix crítico (gruesos <= 0)
  // ═══════════════════════════════════════════════════════════
  group('División por cero — guard de gruesos <= 0', () {
    test('pi nunca es NaN con pasa200 = 99.9 (suelo fino extremo)', () {
      final r = clasificarSuelo(sueloFino(pasa200: 99.9, ll: 60, lp: 25));
      expect(r.pi.isNaN, isFalse);
      expect(r.pi.isInfinite, isFalse);
      expect(r.symbol, equals('CH'));
    });

    test('pi nunca es NaN con pasa200 = 49.9 (suelo grueso máximo de finos)',
        () {
      // gruesos = 50.1 → no hay división por cero
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 49.9, retenidoN4: 30, ll: 30, lp: 25, cu: 5, cc: 2));
      expect(r.pi.isNaN, isFalse);
      expect(r.pi.isInfinite, isFalse);
    });

    test('pasa200 = 100 → se clasifica como suelo fino (nunca llega a dividir)',
        () {
      // p200=100 >= 50 → rama de suelo fino; el guard de gruesos<=0
      // es una defensa en profundidad que nunca debería activarse
      // en condiciones normales, pero el resultado no debe ser NaN.
      final r = clasificarSuelo(SucsInput(
        pasa200: 100,
        retenidoN4: 0,
        ll: 30,
        lp: 20,
        cu: 5,
        cc: 2,
      ));
      expect(r.pi.isNaN, isFalse);
      expect(r.pi.isInfinite, isFalse);
      expect(r.symbol, isNot(equals('NaN')));
    });

    test('Resultado de clasificación nunca contiene NaN o Infinity en el PI',
        () {
      // Barrido de 5 valores extremos de pasa200
      final valores = [0.0, 1.0, 49.0, 50.0, 99.0];
      for (final p200 in valores) {
        final r = p200 < 50
            ? clasificarSuelo(sueloGrueso(
                pasa200: p200, retenidoN4: 10, ll: 25, lp: 18, cu: 4, cc: 2))
            : clasificarSuelo(sueloFino(pasa200: p200, ll: 35, lp: 20));
        expect(r.pi.isNaN, isFalse, reason: 'NaN con pasa200=$p200');
        expect(r.pi.isInfinite, isFalse, reason: 'Infinity con pasa200=$p200');
      }
    });
  });

  // GRUPO 8: ZONA DE TRANSICIÓN CL-ML
  //
  // ASTM D2487: CL-ML requiere DOS condiciones simultáneas:
  //   1. PI entre 4 y 7 (inclusive)
  //   2. PI ≥ Línea A  →  PI ≥ 0.73 * (LL - 20)
  //
  // Consecuencia práctica: lineaA(LL) ≤ 7 solo cuando LL ≲ 29.6.
  // Para LL ≥ 30 la Línea A ya supera 7.3, haciendo imposible
  // que un PI en [4,7] quede encima de ella. La zona CL-ML
  // existe únicamente para LL bajos (típicamente LL < 30).
  // ═══════════════════════════════════════════════════════════
  group('Zona de transición CL-ML', () {
    test('CL-ML con LL=25, PI=5 (centro de zona)', () {
      // lineaA(25) = 3.65; PI=5 ∈ [4,7] y 5 ≥ 3.65 → CL-ML
      expect(clasificarSuelo(sueloFino(pasa200: 65, ll: 25, lp: 20)).symbol,
          equals('CL-ML'));
    });

    test('CL-ML con LL=22 (límite inferior de LL práctico)', () {
      // lineaA(22) = 1.46; PI=4 ∈ [4,7] y 4 ≥ 1.46 → CL-ML
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 22, lp: 18)).symbol,
          equals('CL-ML'));
    });

    test('CL-ML con LL=29 (límite superior de LL práctico)', () {
      // lineaA(29) = 6.57; PI=7 ∈ [4,7] y 7 ≥ 6.57 → CL-ML
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 29, lp: 22)).symbol,
          equals('CL-ML'));
    });

    test('CL-ML con PI=4 (límite inferior de PI)', () {
      // lineaA(25) = 3.65; PI=4 ∈ [4,7] y 4 ≥ 3.65 → CL-ML
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 25, lp: 21)).symbol,
          equals('CL-ML'));
    });

    test('CL-ML con PI=7 (límite superior de PI)', () {
      // lineaA(29) = 6.57; PI=7 ∈ [4,7] y 7 ≥ 6.57 → CL-ML
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 29, lp: 22)).symbol,
          equals('CL-ML'));
    });

    test('NO es CL-ML si PI=5 pero LL=35 (Línea A supera el PI) → ML', () {
      // lineaA(35) = 10.95; PI=5 < 10.95 → punto bajo Línea A → ML
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 35, lp: 30)).symbol,
          equals('ML'));
    });

    test('NO es CL-ML si PI=10 (fuera del rango PI > 7) → CL', () {
      // LL=30, LP=20 → PI=10, lineaA=7.3 → PI>7 → no CL-ML; PI≥A → CL
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 30, lp: 20)).symbol,
          equals('CL'));
    });

    test('NO es CL-ML si PI=2 (PI < 4) → ML', () {
      // LL=25, PI=2 < 4 → no entra en zona CL-ML; lineaA(25)=3.65 → PI<A → ML
      expect(clasificarSuelo(sueloFino(pasa200: 60, ll: 25, lp: 23)).symbol,
          equals('ML'));
    });

    test('NO es CL-ML si LL > 50 → MH', () {
      // LL=55, LP=51 → PI=4 pero lineaA(55)=25.55 >> 4 → bajo Línea A → MH
      final r = clasificarSuelo(sueloFino(pasa200: 60, ll: 55, lp: 51));
      expect(r.symbol, isNot(equals('CL-ML')));
      expect(r.symbol, equals('MH'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 9: HELPER esSueloFino()
  // ═══════════════════════════════════════════════════════════
  group('esSueloFino()', () {
    for (final s in ['CL', 'CH', 'ML', 'MH', 'CL-ML']) {
      test('$s es suelo fino', () => expect(esSueloFino(s), isTrue));
    }
    for (final s in [
      'GW',
      'GP',
      'GM',
      'GC',
      'GW-GC',
      'GW-GM',
      'GP-GC',
      'GP-GM',
      'SW',
      'SP',
      'SM',
      'SC',
      'SW-SC',
      'SW-SM',
      'SP-SC',
      'SP-SM',
      'ERROR'
    ]) {
      test('$s NO es suelo fino', () => expect(esSueloFino(s), isFalse));
    }
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 10: colorDeSuelo() — consistencia con AppColors (Fix 2)
  // ═══════════════════════════════════════════════════════════
  group('colorDeSuelo() — consistencia con AppColors', () {
    test('CL → soilClay',
        () => expect(colorDeSuelo('CL'), equals(AppColors.soilClay)));
    test('CH → soilClay',
        () => expect(colorDeSuelo('CH'), equals(AppColors.soilClay)));
    test('CL-ML → soilClay',
        () => expect(colorDeSuelo('CL-ML'), equals(AppColors.soilClay)));
    test('ML → soilSilt',
        () => expect(colorDeSuelo('ML'), equals(AppColors.soilSilt)));
    test('MH → soilSilt',
        () => expect(colorDeSuelo('MH'), equals(AppColors.soilSilt)));
    test('GW → soilGravel',
        () => expect(colorDeSuelo('GW'), equals(AppColors.soilGravel)));
    test('GP → soilGravel',
        () => expect(colorDeSuelo('GP'), equals(AppColors.soilGravel)));
    test('GW-GC → soilGravel',
        () => expect(colorDeSuelo('GW-GC'), equals(AppColors.soilGravel)));
    test('GP-GM → soilGravel',
        () => expect(colorDeSuelo('GP-GM'), equals(AppColors.soilGravel)));
    test('SW → soilSand',
        () => expect(colorDeSuelo('SW'), equals(AppColors.soilSand)));
    test('SP → soilSand',
        () => expect(colorDeSuelo('SP'), equals(AppColors.soilSand)));
    test('SP-SC → soilSand',
        () => expect(colorDeSuelo('SP-SC'), equals(AppColors.soilSand)));
    test('SW-SM → soilSand',
        () => expect(colorDeSuelo('SW-SM'), equals(AppColors.soilSand)));
    test('ERROR → soilError',
        () => expect(colorDeSuelo('ERROR'), equals(AppColors.soilError)));
    test('símbolo desconocido → soilError',
        () => expect(colorDeSuelo('XYZ'), equals(AppColors.soilError)));

    // Regresión: AppColors tiene 4 colores distintos de suelo
    test('soilClay != soilSilt',
        () => expect(AppColors.soilClay, isNot(equals(AppColors.soilSilt))));
    test('soilClay != soilGravel',
        () => expect(AppColors.soilClay, isNot(equals(AppColors.soilGravel))));
    test('soilGravel != soilSand',
        () => expect(AppColors.soilGravel, isNot(equals(AppColors.soilSand))));
    test('soilError != soilClay',
        () => expect(AppColors.soilError, isNot(equals(AppColors.soilClay))));
  });

  // ═══════════════════════════════════════════════════════════
  // GRUPO 11: CASOS REALES DE LABORATORIO
  // ═══════════════════════════════════════════════════════════
  group('Casos reales de laboratorio', () {
    test('M-1 — Arcilla típica de pampa argentina (CL)', () {
      // LL=42, LP=22 → PI=20; lineaA(42)=16.06 → PI>A → CL
      final r = clasificarSuelo(sueloFino(pasa200: 85, ll: 42, lp: 22));
      expect(r.symbol, equals('CL'));
      expect(r.pi, closeTo(20.0, 0.01));
    });

    test('M-2 — Limo de baja plasticidad (ML)', () {
      // LL=38, LP=32 → PI=6; lineaA(38)=13.14 → PI<A → ML
      final r = clasificarSuelo(sueloFino(pasa200: 72, ll: 38, lp: 32));
      expect(r.symbol, equals('ML'));
    });

    test('M-3 — Grava mal graduada de río (GP)', () {
      // pasa200=1%, R4=82% → pctGrava=82.8%; Cu=2.5<4 → GP
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 1, retenidoN4: 82, ll: 18, lp: 14, cu: 2.5, cc: 1.8));
      expect(r.symbol, equals('GP'));
    });

    test('M-4 — Arena limosa de médano (SP-SM)', () {
      // pasa200=8%, zona dual; pctGrava=5.4% → ARENA
      // PI=3; lineaA(25)=3.65 → PI<A → limoso; Cu=3.5<6 → SP-SM
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 8, retenidoN4: 5, ll: 25, lp: 22, cu: 3.5, cc: 1.2));
      expect(r.symbol, equals('SP-SM'));
    });

    test('M-5 — Arcilla montmorillonita expansiva (CH)', () {
      // LL=80, LP=35 → PI=45; lineaA(80)=43.8 → PI>A → CH
      final r = clasificarSuelo(sueloFino(pasa200: 95, ll: 80, lp: 35));
      expect(r.symbol, equals('CH'));
    });

    test('M-6 — Grava arcillosa de terraplén (GC)', () {
      // pasa200=18%>12%; R4=72% → GRAVA; PI=14; lineaA(32)=8.76 → GC
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 18, retenidoN4: 72, ll: 32, lp: 18, cu: 8, cc: 1.5));
      expect(r.symbol, equals('GC'));
    });

    test('M-7 — Arena arcillosa de subrasante (SC)', () {
      // pasa200=25%>12%; pctGrava<50% → ARENA; PI=18; lineaA(38)=13.14 → SC
      final r = clasificarSuelo(sueloGrueso(
          pasa200: 25, retenidoN4: 10, ll: 38, lp: 20, cu: 5, cc: 1.8));
      expect(r.symbol, equals('SC'));
    });
  });
}
