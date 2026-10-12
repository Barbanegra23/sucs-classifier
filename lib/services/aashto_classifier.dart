import 'package:flutter/material.dart' show Color;
import '../models/aashto_models.dart';
import '../theme/app_colors.dart' show AppColors;

export '../models/aashto_models.dart';

// ─────────────────────────────────────────────────────────────
// CLASIFICACIÓN AASHTO (AASHTO M 145 / ASTM D3282)
//
// Procedimiento estándar: se evalúan los grupos de izquierda a
// derecha en la tabla de la norma (A-1-a → A-1-b → A-3 → A-2-4 →
// A-2-5 → A-2-6 → A-2-7 → A-4 → A-5 → A-6 → A-7-5/A-7-6) y se
// toma el PRIMERO que cumpla todos los criterios.
//
// Referencia de la tabla (valores límite):
//                A-1-a  A-1-b  A-3   A-2-4/5/6/7  A-4   A-5   A-6   A-7
// % pasa N°10      ≤50    -     -         -         -     -     -     -
// % pasa N°40      ≤30   ≤50   ≥51        -         -     -     -     -
// % pasa N°200     ≤15   ≤25   ≤10       ≤35       >35   >35   >35   >35
// LL                -     -     -    A-2-4/6:≤40 / A-2-5/7:≥41  ≤40   ≥41   ≤40   ≥41
// IP               ≤6    ≤6    NP   A-2-4/5:≤10 / A-2-6/7:≥11   ≤10   ≤10   ≥11   ≥11
// ─────────────────────────────────────────────────────────────

/// Calcula el Índice de Plasticidad. Si el resultado es ≤0 (suelo no
/// plástico / NP), devuelve 0.
double _calcularPI(double ll, double lp) {
  final pi = ll - lp;
  return pi < 0 ? 0 : pi;
}

/// Índice de Grupo (GI), redondeado al entero más cercano, mínimo 0.
///
/// Fórmula completa (A-4 a A-7):
///   GI = (F-35)·[0.2 + 0.005·(LL-40)] + 0.01·(F-15)·(PI-10)
/// donde F = % que pasa el tamiz N°200.
///
/// Para A-2-6 y A-2-7 se usa solo el término de PI:
///   GI = 0.01·(F-15)·(PI-10)
///
/// Para A-1-a, A-1-b, A-2-4, A-2-5 y A-3, el GI es siempre 0 por
/// definición de la norma (son materiales lo bastante buenos como
/// para no calcularlo).
int _calcularGI(String grupo, double f200, double ll, double pi) {
  double gi;
  switch (grupo) {
    case 'A-1-a':
    case 'A-1-b':
    case 'A-2-4':
    case 'A-2-5':
    case 'A-3':
      gi = 0;
      break;
    case 'A-2-6':
    case 'A-2-7':
      gi = 0.01 * (f200 - 15) * (pi - 10);
      break;
    default:
      gi = (f200 - 35) * (0.2 + 0.005 * (ll - 40)) +
          0.01 * (f200 - 15) * (pi - 10);
  }
  if (gi < 0 || gi.isNaN) gi = 0;
  return gi.round();
}

String _descripcion(String grupo) {
  switch (grupo) {
    case 'A-1-a':
      return 'Fragmentos de piedra, grava y arena';
    case 'A-1-b':
      return 'Grava y arena gruesa';
    case 'A-3':
      return 'Arena fina';
    case 'A-2-4':
    case 'A-2-5':
      return 'Grava y arena limosa';
    case 'A-2-6':
    case 'A-2-7':
      return 'Grava y arena arcillosa';
    case 'A-4':
      return 'Suelo limoso';
    case 'A-5':
      return 'Suelo limoso elástico';
    case 'A-6':
      return 'Suelo arcilloso';
    case 'A-7-5':
    case 'A-7-6':
      return 'Suelo arcilloso';
    default:
      return 'Suelo sin clasificar';
  }
}

String _tipoMaterial(String grupo) {
  return ['A-1-a', 'A-1-b', 'A-2-4', 'A-2-5', 'A-2-6', 'A-2-7', 'A-3']
          .contains(grupo)
      ? 'Material granular (≤35% pasa N°200)'
      : 'Material limo-arcilloso (>35% pasa N°200)';
}

String _calificacionSubrasante(String grupo, int gi) {
  if (['A-1-a', 'A-1-b', 'A-3'].contains(grupo)) return 'Excelente a bueno';
  if (['A-2-4', 'A-2-5', 'A-2-6', 'A-2-7'].contains(grupo)) {
    return 'Bueno a regular';
  }
  // A-4 a A-7: la calidad baja a medida que sube el GI
  if (gi <= 4) return 'Regular';
  if (gi <= 8) return 'Regular a malo';
  return 'Malo';
}

AashtoResult clasificarAashto(AashtoInput input) {
  final p10 = input.pasa10;
  final p40 = input.pasa40;
  final p200 = input.pasa200;
  final ll = input.ll;
  final pi = _calcularPI(input.ll, input.lp);

  String grupo;

  // Los límites de la tabla (≤40 / ≥41, ≤10 / ≥11, ≥51) están
  // pensados para valores enteros. Para que un LL = 40.5 o un
  // PI = 10.5 no caigan en un hueco, se compara siempre contra el
  // umbral inferior con ">" (LL > 40 equivale a "≥ 41").
  final llAlto = ll > 40;
  final piAlto = pi > 10;

  if (p200 <= 35) {
    // ── MATERIALES GRANULARES ──────────────────────────────
    if (p10 <= 50 && p40 <= 30 && p200 <= 15 && pi <= 6) {
      grupo = 'A-1-a';
    } else if (p40 <= 50 && p200 <= 25 && pi <= 6) {
      grupo = 'A-1-b';
    } else if (p40 > 50 && p200 <= 10 && pi == 0) {
      grupo = 'A-3';
    } else if (!llAlto && !piAlto) {
      grupo = 'A-2-4';
    } else if (llAlto && !piAlto) {
      grupo = 'A-2-5';
    } else if (!llAlto && piAlto) {
      grupo = 'A-2-6';
    } else {
      grupo = 'A-2-7';
    }
  } else {
    // ── MATERIALES LIMO-ARCILLOSOS (>35% pasa N°200) ───────
    if (!llAlto && !piAlto) {
      grupo = 'A-4';
    } else if (llAlto && !piAlto) {
      grupo = 'A-5';
    } else if (!llAlto && piAlto) {
      grupo = 'A-6';
    } else {
      // LL > 40 y PI > 10 → A-7-5 o A-7-6 según PI vs LL − 30
      grupo = (pi <= ll - 30) ? 'A-7-5' : 'A-7-6';
    }
  }

  final gi = _calcularGI(grupo, p200, ll, pi);

  return AashtoResult(
    symbol: '$grupo($gi)',
    grupo: grupo,
    gi: gi,
    description: _descripcion(grupo),
    tipoMaterial: _tipoMaterial(grupo),
    calificacionSubrasante: _calificacionSubrasante(grupo, gi),
    pi: pi,
  );
}

/// Color asociado a cada grupo AASHTO, en la misma línea visual que
/// [colorDeSuelo] en el clasificador SUCS: colores más "sólidos" para
/// los materiales granulares (mejor comportamiento como subrasante) y
/// más apagados para los limo-arcillosos.

Color colorDeGrupoAashto(String grupo) {
  if (['A-1-a', 'A-1-b', 'A-3'].contains(grupo)) {
    return AppColors.soilGravel;
  } else if (['A-2-4', 'A-2-5', 'A-2-6', 'A-2-7'].contains(grupo)) {
    return AppColors.soilSand;
  } else if (['A-4', 'A-5'].contains(grupo)) {
    return AppColors.soilSilt;
  } else if (['A-6', 'A-7-5', 'A-7-6'].contains(grupo)) {
    return AppColors.soilClay;
  }
  return AppColors.soilError;
}
