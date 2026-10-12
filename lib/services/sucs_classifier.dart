import 'package:flutter/material.dart';
import '../models/sucs_models.dart';
import '../theme/app_colors.dart';

export '../models/sucs_models.dart';

// ─────────────────────────────────────────────────────────────
// LÍNEA A DE CASAGRANDE
// ─────────────────────────────────────────────────────────────

/// Devuelve el PI mínimo de la Línea A para un LL dado.
/// Fórmula: PI = 0.73 * (LL - 20), mínimo 0.
double lineaA(double ll) {
  final val = 0.73 * (ll - 20);
  return val < 0 ? 0 : val;
}

// ─────────────────────────────────────────────────────────────
// CLASIFICACIÓN DE LOS FINOS (carta de plasticidad)
// ─────────────────────────────────────────────────────────────

/// Tipo de finos según la carta de plasticidad (ASTM D2487, Fig. 4):
///   • arcilla        → PI > 7 y sobre/en la Línea A          (CL / CH)
///   • arcillaLimosa  → 4 ≤ PI ≤ 7 y sobre/en la Línea A      (CL-ML)
///   • limo           → PI < 4 o bajo la Línea A              (ML / MH)
enum TipoFinos { arcilla, arcillaLimosa, limo }

/// Única fuente de verdad para decidir si los finos son arcillosos,
/// limosos o de la zona CL-ML. La usan el clasificador, la memoria
/// de cálculo y el PDF.
TipoFinos clasificarFinos(double ll, double pi) {
  final a = lineaA(ll);
  if (pi < a || pi < 4) return TipoFinos.limo;
  if (pi <= 7) return TipoFinos.arcillaLimosa;
  return TipoFinos.arcilla;
}

/// Texto corto para UI / PDF.
String etiquetaFinos(TipoFinos t) => switch (t) {
      TipoFinos.arcilla => 'Arcilloso',
      TipoFinos.arcillaLimosa => 'Limo-arcilloso (CL-ML)',
      TipoFinos.limo => 'Limoso',
    };

// ─────────────────────────────────────────────────────────────
// FUNCIÓN PRINCIPAL DE CLASIFICACIÓN
// ─────────────────────────────────────────────────────────────

SucsResult clasificarSuelo(SucsInput input) {
  final p200 = input.pasa200;
  final r4 = input.retenidoN4;
  final ll = input.ll;
  final lp = input.lp;
  final cu = input.cu;
  final cc = input.cc;
  final pi = ll - lp;

  // ── Validaciones ────────────────────────────────────────────
  if (p200 < 0 || p200 > 100) {
    return SucsResult('ERROR', 'Datos inválidos: % pasa 200 fuera de rango', 0);
  }
  if (r4 < 0 || r4 > 100) {
    return SucsResult(
        'ERROR', 'Datos inválidos: % retenido N°4 fuera de rango', 0);
  }
  if (ll < 0 || lp < 0) {
    return SucsResult(
        'ERROR', 'Datos inválidos: límites de Atterberg negativos', 0);
  }
  if (lp > ll) {
    return SucsResult(
        'ERROR', 'Datos inválidos: LP no puede ser mayor que LL', 0);
  }

  // Validación cruzada: retenidoN4 + pasa200 no puede superar 100%.
  // Si R4=60% y P200=60%, el suelo contendría 120% de material — imposible.
  if (r4 + p200 > 100) {
    return SucsResult(
      'ERROR',
      'Datos inválidos: % retenido N°4 + % pasa 200 supera 100% '
          '(${(r4 + p200).toStringAsFixed(1)}%). '
          'Revisá los valores granulométricos.',
      0,
    );
  }

  // ── SUELOS FINOS (pasa N°200 ≥ 50%) ─────────────────────────
  if (p200 >= 50) {
    return _clasificarSueloFino(ll, pi);
  }

  // ── SUELOS GRUESOS (pasa N°200 < 50%) ───────────────────────
  // Cu/Cc solo intervienen con menos de 12% de finos. Con > 12% la
  // clasificación depende únicamente de la plasticidad de los finos.
  if (p200 <= 12 && cu <= 0) {
    return SucsResult('ERROR', 'Datos inválidos: Cu debe ser mayor que 0', 0);
  }

  if (esGrava(pasa200: p200, retenidoN4: r4)) {
    return _clasificarGrava(p200, ll, pi, cu, cc);
  } else {
    return _clasificarArena(p200, ll, pi, cu, cc);
  }
}

/// ASTM D2487: es GRAVA si MÁS del 50% de la fracción gruesa queda
/// retenida en el tamiz N°4. Con exactamente 50% es ARENA.
/// Equivale a comparar R4 contra la fracción arena (100 − P200 − R4).
bool esGrava({required double pasa200, required double retenidoN4}) {
  final arena = 100 - pasa200 - retenidoN4;
  return retenidoN4 > arena;
}

// ─────────────────────────────────────────────────────────────
// SUELOS FINOS
// ─────────────────────────────────────────────────────────────

SucsResult _clasificarSueloFino(double ll, double pi) {
  final finos = clasificarFinos(ll, pi);

  // CL-ML: 4 ≤ PI ≤ 7 y sobre/en la Línea A. Solo es posible con
  // LL < ~29.6 (donde la Línea A todavía está por debajo de PI = 7).
  if (finos == TipoFinos.arcillaLimosa) {
    return SucsResult('CL-ML', 'Arcilla limosa — zona de transición', pi);
  }

  final esArcilla = finos == TipoFinos.arcilla;
  if (ll < 50) {
    // CL exige PI > 7 y sobre la Línea A. Con PI < 4 es ML aunque
    // el punto quede sobre la Línea A (LL < 25.5).
    return esArcilla
        ? SucsResult('CL', 'Arcilla de baja plasticidad', pi)
        : SucsResult('ML', 'Limo de baja plasticidad', pi);
  } else {
    return esArcilla
        ? SucsResult('CH', 'Arcilla de alta plasticidad', pi)
        : SucsResult('MH', 'Limo de alta plasticidad (limo elástico)', pi);
  }
}

// ─────────────────────────────────────────────────────────────
// GRAVAS
// ─────────────────────────────────────────────────────────────

SucsResult _clasificarGrava(
    double p200, double ll, double pi, double cu, double cc) {
  final bienGraduada = cu >= 4 && cc >= 1 && cc <= 3;

  if (p200 < 5) {
    // Limpia: solo Cu y Cc deciden
    return bienGraduada
        ? SucsResult('GW', 'Grava bien graduada', pi)
        : SucsResult('GP', 'Grava mal graduada', pi);
  }

  final finos = clasificarFinos(ll, pi);

  if (p200 <= 12) {
    // Zona dual (5–12%). Según el diagrama de flujo de ASTM D2487,
    // finos CL, CH o CL-ML → segundo símbolo GC; ML o MH → GM.
    final esArcillosa = finos != TipoFinos.limo;
    if (bienGraduada) {
      return esArcillosa
          ? SucsResult('GW-GC', 'Grava bien graduada con arcilla', pi)
          : SucsResult('GW-GM', 'Grava bien graduada con limo', pi);
    } else {
      return esArcillosa
          ? SucsResult('GP-GC', 'Grava mal graduada con arcilla', pi)
          : SucsResult('GP-GM', 'Grava mal graduada con limo', pi);
    }
  }

  // p200 > 12%: plasticidad de finos decide
  return switch (finos) {
    TipoFinos.arcilla => SucsResult('GC', 'Grava arcillosa', pi),
    TipoFinos.arcillaLimosa =>
      SucsResult('GC-GM', 'Grava limo-arcillosa', pi),
    TipoFinos.limo => SucsResult('GM', 'Grava limosa', pi),
  };
}

// ─────────────────────────────────────────────────────────────
// ARENAS
// ─────────────────────────────────────────────────────────────

SucsResult _clasificarArena(
    double p200, double ll, double pi, double cu, double cc) {
  final bienGraduada = cu >= 6 && cc >= 1 && cc <= 3;

  if (p200 < 5) {
    return bienGraduada
        ? SucsResult('SW', 'Arena bien graduada', pi)
        : SucsResult('SP', 'Arena mal graduada', pi);
  }

  final finos = clasificarFinos(ll, pi);

  if (p200 <= 12) {
    // Zona dual (5–12%): finos CL, CH o CL-ML → SC; ML o MH → SM.
    final esArcillosa = finos != TipoFinos.limo;
    if (bienGraduada) {
      return esArcillosa
          ? SucsResult('SW-SC', 'Arena bien graduada con arcilla', pi)
          : SucsResult('SW-SM', 'Arena bien graduada con limo', pi);
    } else {
      return esArcillosa
          ? SucsResult('SP-SC', 'Arena mal graduada con arcilla', pi)
          : SucsResult('SP-SM', 'Arena mal graduada con limo', pi);
    }
  }

  // p200 > 12%
  return switch (finos) {
    TipoFinos.arcilla => SucsResult('SC', 'Arena arcillosa', pi),
    TipoFinos.arcillaLimosa =>
      SucsResult('SC-SM', 'Arena limo-arcillosa', pi),
    TipoFinos.limo => SucsResult('SM', 'Arena limosa', pi),
  };
}

// ─────────────────────────────────────────────────────────────
// HELPERS DE UI
// ─────────────────────────────────────────────────────────────

/// Devuelve true si el símbolo corresponde a un suelo fino
/// (para mostrar la Carta de Casagrande).
bool esSueloFino(String simbolo) {
  return ['CL', 'CH', 'ML', 'MH', 'CL-ML'].contains(simbolo);
}

/// Color representativo del tipo de suelo para la UI.
/// Usa las constantes de [AppColors] como única fuente de verdad
/// para evitar colores duplicados y desincronizados.
Color colorDeSuelo(String simbolo) {
  final base = simbolo.split('-').first;
  if (['CL', 'CH'].contains(base) || simbolo == 'CL-ML') {
    return AppColors.soilClay; // Arcillas — marrón
  } else if (['ML', 'MH'].contains(base)) {
    return AppColors.soilSilt; // Limos — dorado oscuro
  } else if (['GW', 'GP', 'GM', 'GC'].contains(base)) {
    return AppColors.soilGravel; // Gravas — azul acero
  } else if (['SW', 'SP', 'SM', 'SC'].contains(base)) {
    return AppColors.soilSand; // Arenas — verde oliva
  } else {
    return AppColors.soilError; // Error — rojo
  }
}

// ─────────────────────────────────────────────────────────────
// HELPERS GRANULOMÉTRICOS
// ─────────────────────────────────────────────────────────────

/// Calcula Cu (coeficiente de uniformidad) y Cc (coeficiente de
/// curvatura) a partir de los diámetros D10, D30 y D60 de la curva
/// granulométrica.
///
///   Cu = D60 / D10
///   Cc = D30² / (D10 × D60)
///
/// Única fuente de verdad para esta fórmula: úsese siempre esta
/// función en vez de recalcularla inline para evitar que el
/// formulario, el guardado y el resumen queden desincronizados.
/// Devuelve (null, null) si D10 o D60 son inválidos (evita
/// división por cero).
(double?, double?) calcularCuCc({
  required double d10,
  required double d30,
  required double d60,
}) {
  if (d10 <= 0 || d60 <= 0) return (null, null);
  final cu = d60 / d10;
  final cc = (d30 * d30) / (d10 * d60);
  return (cu, cc);
}

// ─────────────────────────────────────────────────────────────
// MEMORIA DE CLASIFICACIÓN
// Genera los pasos de razonamiento que llevaron al resultado,
// para mostrarlos al usuario como sección colapsable.
// ─────────────────────────────────────────────────────────────

class PasoClasificacion {
  final String numero;
  final String titulo;
  final String detalle;
  final bool? cumple; // true=✓  false=✗  null=informativo

  const PasoClasificacion({
    required this.numero,
    required this.titulo,
    required this.detalle,
    this.cumple,
  });
}

List<PasoClasificacion> generarMemoria({
  required SucsResult resultado,
  required double pasa200,
  required double retenidoN4,
  required double ll,
  required double lp,
  double? cu,
  double? cc,
  double? d10,
  double? d30,
  double? d60,
}) {
  final pi = resultado.pi;
  final pasos = <PasoClasificacion>[];

  // ── Paso 1: tipo de suelo ──────────────────────────────
  final esGrueso = pasa200 < 50.0;
  pasos.add(PasoClasificacion(
    numero: '1',
    titulo: 'Tipo de suelo',
    detalle: esGrueso
        ? 'P200 = ${pasa200.toStringAsFixed(1)} % < 50 % → Suelo grueso'
        : 'P200 = ${pasa200.toStringAsFixed(1)} % ≥ 50 % → Suelo fino',
  ));

  if (esGrueso) {
    // ── Grueso: grava o arena ────────────────────────────
    final fracGrava = retenidoN4;
    final fracArena = 100 - pasa200 - retenidoN4;
    final grava = esGrava(pasa200: pasa200, retenidoN4: retenidoN4);
    pasos.add(PasoClasificacion(
      numero: '2',
      titulo: grava ? 'Fracción dominante: Grava' : 'Fracción dominante: Arena',
      detalle: grava
          ? 'R4 = ${fracGrava.toStringAsFixed(1)} % > Arena = ${fracArena.toStringAsFixed(1)} % → G'
          : 'Arena = ${fracArena.toStringAsFixed(1)} % ≥ R4 = ${fracGrava.toStringAsFixed(1)} % → S'
              '${fracArena == fracGrava ? '  (grava requiere MÁS del 50 % de la fracción gruesa)' : ''}',
    ));

    // ── Zona de finos ────────────────────────────────────
    final zonaFinos = pasa200 < 5
        ? 'limpia'
        : pasa200 <= 12
            ? 'dual'
            : 'con finos';
    pasos.add(PasoClasificacion(
      numero: '3',
      titulo: 'Zona de finos',
      detalle: pasa200 < 5
          ? 'P200 = ${pasa200.toStringAsFixed(1)} % < 5 % → limpia (criterio Cu/Cc)'
          : pasa200 <= 12
              ? 'P200 = ${pasa200.toStringAsFixed(1)} % entre 5–12 % → símbolo dual'
              : 'P200 = ${pasa200.toStringAsFixed(1)} % > 12 % → finos definen plasticidad',
    ));

    if (zonaFinos == 'limpia' || zonaFinos == 'dual') {
      if (cu != null && cc != null) {
        final umbralCu = grava ? 4.0 : 6.0;
        final bienGrad = cu >= umbralCu && cc >= 1 && cc <= 3;
        pasos.add(PasoClasificacion(
          numero: '4',
          titulo: 'Graduación',
          detalle: 'Cu = ${cu.toStringAsFixed(2)} '
              '(necesita ≥ ${umbralCu.toStringAsFixed(0)})  '
              'Cc = ${cc.toStringAsFixed(3)} (necesita 1–3)'
              '${bienGrad ? '  → Bien graduada' : '  → Mal graduada'}',
          cumple: bienGrad,
        ));
      }
    }

    if (zonaFinos != 'limpia') {
      final aVal = lineaA(ll);
      final finos = clasificarFinos(ll, pi);
      final String conclusion;
      if (zonaFinos == 'dual') {
        conclusion = finos == TipoFinos.limo
            ? '→ Finos ML/MH → segundo símbolo ${grava ? 'GM' : 'SM'}'
            : '→ Finos ${finos == TipoFinos.arcillaLimosa ? 'CL-ML' : 'CL/CH'} → segundo símbolo ${grava ? 'GC' : 'SC'}';
      } else {
        conclusion = switch (finos) {
          TipoFinos.arcilla => '→ Finos CL/CH → ${grava ? 'GC' : 'SC'}',
          TipoFinos.arcillaLimosa =>
            '→ Finos CL-ML (4 ≤ PI ≤ 7) → ${grava ? 'GC-GM' : 'SC-SM'}',
          TipoFinos.limo => '→ Finos ML/MH → ${grava ? 'GM' : 'SM'}',
        };
      }
      pasos.add(PasoClasificacion(
        numero: zonaFinos == 'dual' ? '5' : '4',
        titulo: 'Tipo de finos',
        detalle: 'PI = ${pi.toStringAsFixed(1)}'
            '  Línea A (LL=${ll.toStringAsFixed(0)}) = ${aVal.toStringAsFixed(2)}'
            '${pi < 4 ? '  PI < 4' : ''}  $conclusion',
        cumple: finos != TipoFinos.limo,
      ));
    }
  } else {
    // ── Fino: plasticidad ────────────────────────────────
    pasos.add(PasoClasificacion(
      numero: '2',
      titulo: 'Índice de plasticidad',
      detalle: 'PI = LL − LP = ${ll.toStringAsFixed(0)} − ${lp.toStringAsFixed(0)} = ${pi.toStringAsFixed(1)}',
    ));

    final aVal = lineaA(ll);
    pasos.add(PasoClasificacion(
      numero: '3',
      titulo: 'Línea A',
      detalle: 'Línea A (LL=${ll.toStringAsFixed(0)}) = 0.73 × (${ll.toStringAsFixed(0)} − 20) = ${aVal.toStringAsFixed(2)}',
    ));

    final finos = clasificarFinos(ll, pi);
    final sobreA = pi >= aVal;

    if (finos == TipoFinos.arcillaLimosa) {
      pasos.add(PasoClasificacion(
        numero: '4',
        titulo: 'Zona de transición CL-ML',
        detalle: 'PI = ${pi.toStringAsFixed(1)} entre 4 y 7 ✓'
            '  y  PI (${pi.toStringAsFixed(1)}) ≥ Línea A (${aVal.toStringAsFixed(2)}) ✓'
            '  → Ambas condiciones simultáneas → CL-ML',
        cumple: true,
      ));
    } else {
      final esArcilla = finos == TipoFinos.arcilla;
      pasos.add(PasoClasificacion(
        numero: '4',
        titulo: esArcilla
            ? 'Posición: sobre Línea A y PI > 7 → Arcilla'
            : (sobreA
                ? 'PI < 4 → Limo (aunque esté sobre la Línea A)'
                : 'Posición: bajo Línea A → Limo'),
        detalle: 'PI = ${pi.toStringAsFixed(1)} ${sobreA ? '≥' : '<'} Línea A (${aVal.toStringAsFixed(2)})'
            '${sobreA && !esArcilla ? '  pero PI < 4' : ''}'
            ' → ${esArcilla ? 'C' : 'M'}',
        cumple: esArcilla,
      ));

      // ── Alta o baja plasticidad ──────────────────────
      pasos.add(PasoClasificacion(
        numero: '5',
        titulo: ll < 50 ? 'Baja plasticidad (LL < 50)' : 'Alta plasticidad (LL ≥ 50)',
        detalle: 'LL = ${ll.toStringAsFixed(0)} ${ll < 50 ? '<' : '≥'} 50'
            ' → ${esArcilla ? (ll < 50 ? 'CL' : 'CH') : (ll < 50 ? 'ML' : 'MH')}',
      ));
    }
  }

  // ── Resultado final ──────────────────────────────────
  pasos.add(PasoClasificacion(
    numero: '→',
    titulo: 'Resultado: ${resultado.symbol}',
    detalle: resultado.description,
    cumple: true,
  ));

  return pasos;
}
