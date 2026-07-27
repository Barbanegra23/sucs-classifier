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
  // Validación extra para suelos gruesos
  if (cu <= 0) {
    return SucsResult('ERROR', 'Datos inválidos: Cu debe ser mayor que 0', 0);
  }

  // Porcentaje de gruesos totales
  final gruesos = 100 - p200;

  // Guardia: si gruesos es 0 o negativo no podemos calcular pctGrava.
  // En la práctica ya fue filtrado por p200 >= 50 arriba, pero como
  // defensa ante valores límite (p200 = 100 con suelo grueso) lo
  // manejamos explícitamente.
  if (gruesos <= 0) {
    return SucsResult('ERROR',
        'Datos inválidos: % pasa 200 = 100 en suelo grueso es imposible', 0);
  }

  // Porcentaje de grava dentro de los gruesos
  final pctGrava = (r4 / gruesos) * 100;

  if (pctGrava >= 50) {
    return _clasificarGrava(p200, ll, pi, cu, cc);
  } else {
    return _clasificarArena(p200, ll, pi, cu, cc);
  }
}

// ─────────────────────────────────────────────────────────────
// SUELOS FINOS
// ─────────────────────────────────────────────────────────────

SucsResult _clasificarSueloFino(double ll, double pi) {
  final a = lineaA(ll);

  // ── CL-ML: zona de transición ASTM D2487 ──────────────────
  // Condiciones exactas según norma:
  //   • PI entre 4 y 7  (inclusive)
  //   • PI ≥ Línea A  (sobre o sobre la línea)
  // No hay restricción de LL en la norma — el límite LL 30–50
  // era una simplificación incorrecta del código anterior.
  // Casos borde:
  //   • PI = 4 exacto y sobre Línea A → CL-ML
  //   • PI = 7 exacto y sobre Línea A → puede ser CL también;
  //     ASTM D2487 indica que si PI > 7 y sobre A → CL directo.
  if (pi >= 4 && pi <= 7 && pi >= a) {
    return SucsResult('CL-ML', 'Arcilla limosa — zona de transición', pi);
  }

  if (ll < 50) {
    // Baja plasticidad (LL < 50)
    // PI > 0 es requisito: con PI=0 (no plástico) y LineaA=0,
    // "pi >= a" sería 0>=0=true → CL incorrecto. Debe ir a ML.
    if (pi > 0 && pi >= a) {
      return SucsResult('CL', 'Arcilla de baja plasticidad', pi);
    } else {
      return SucsResult('ML', 'Limo de baja plasticidad', pi);
    }
  } else {
    // Alta plasticidad (LL ≥ 50)
    if (pi > 0 && pi >= a) {
      return SucsResult('CH', 'Arcilla de alta plasticidad', pi);
    } else {
      return SucsResult('MH', 'Limo de alta plasticidad (limo elástico)', pi);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// GRAVAS
// ─────────────────────────────────────────────────────────────

SucsResult _clasificarGrava(
    double p200, double ll, double pi, double cu, double cc) {
  final a = lineaA(ll);
  final bienGraduada = cu >= 4 && cc >= 1 && cc <= 3;

  if (p200 < 5) {
    // Limpia: solo Cu y Cc deciden
    if (bienGraduada) {
      return SucsResult('GW', 'Grava bien graduada', pi);
    } else {
      return SucsResult('GP', 'Grava mal graduada', pi);
    }
  } else if (p200 <= 12) {
    // Zona dual: graduación + plasticidad de finos
    // PI > 0 evita que finos no plásticos (PI=0) se traten como
    // arcillosos cuando LineaA también es 0.
    final esArcillosa = pi > 0 && pi >= a;
    if (bienGraduada) {
      return esArcillosa
          ? SucsResult('GW-GC', 'Grava bien graduada con arcilla', pi)
          : SucsResult('GW-GM', 'Grava bien graduada con limo', pi);
    } else {
      return esArcillosa
          ? SucsResult('GP-GC', 'Grava mal graduada con arcilla', pi)
          : SucsResult('GP-GM', 'Grava mal graduada con limo', pi);
    }
  } else {
    // p200 > 12%: plasticidad de finos decide
    if (pi > 0 && pi >= a) {
      return SucsResult('GC', 'Grava arcillosa', pi);
    } else {
      return SucsResult('GM', 'Grava limosa', pi);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// ARENAS
// ─────────────────────────────────────────────────────────────

SucsResult _clasificarArena(
    double p200, double ll, double pi, double cu, double cc) {
  final a = lineaA(ll);
  final bienGraduada = cu >= 6 && cc >= 1 && cc <= 3;

  if (p200 < 5) {
    // Limpia
    if (bienGraduada) {
      return SucsResult('SW', 'Arena bien graduada', pi);
    } else {
      return SucsResult('SP', 'Arena mal graduada', pi);
    }
  } else if (p200 <= 12) {
    // Zona dual
    // PI > 0 evita que finos no plásticos (PI=0) se traten como
    // arcillosos cuando LineaA también es 0.
    final esArcillosa = pi > 0 && pi >= a;
    if (bienGraduada) {
      return esArcillosa
          ? SucsResult('SW-SC', 'Arena bien graduada con arcilla', pi)
          : SucsResult('SW-SM', 'Arena bien graduada con limo', pi);
    } else {
      return esArcillosa
          ? SucsResult('SP-SC', 'Arena mal graduada con arcilla', pi)
          : SucsResult('SP-SM', 'Arena mal graduada con limo', pi);
    }
  } else {
    // p200 > 12%
    if (pi > 0 && pi >= a) {
      return SucsResult('SC', 'Arena arcillosa', pi);
    } else {
      return SucsResult('SM', 'Arena limosa', pi);
    }
  }
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
    final esGrava = fracGrava > fracArena;
    pasos.add(PasoClasificacion(
      numero: '2',
      titulo: esGrava ? 'Fracción dominante: Grava' : 'Fracción dominante: Arena',
      detalle: esGrava
          ? 'R4 = ${retenidoN4.toStringAsFixed(1)} % > Arena = ${fracArena.toStringAsFixed(1)} % → G'
          : 'Arena = ${fracArena.toStringAsFixed(1)} % > R4 = ${retenidoN4.toStringAsFixed(1)} % → S',
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
        final umbralCu = esGrava ? 4.0 : 6.0;
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

    if (zonaFinos != 'limpia' && pasa200 >= 5) {
      final aVal = lineaA(ll);
      final esArcillosa = pi > 0 && pi >= aVal;
      pasos.add(PasoClasificacion(
        numero: zonaFinos == 'dual' ? '5' : '4',
        titulo: 'Tipo de finos',
        detalle: 'PI = ${pi.toStringAsFixed(1)}'
            '  Línea A (LL=${ll.toStringAsFixed(0)}) = ${aVal.toStringAsFixed(2)}'
            '${esArcillosa ? '  → Arcilloso (PI ≥ A)' : '  → Limoso (PI < A)'}',
        cumple: esArcillosa,
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

    // ── Zona CL-ML ───────────────────────────────────────
    final enZonaCLML = pi >= 4 && pi <= 7 && pi >= aVal;
    if (enZonaCLML || resultado.symbol == 'CL-ML') {
      pasos.add(PasoClasificacion(
        numero: '4',
        titulo: 'Zona de transición CL-ML',
        detalle: 'PI = ${pi.toStringAsFixed(1)} entre 4 y 7 ✓'
            '  y  PI (${pi.toStringAsFixed(1)}) ≥ Línea A (${aVal.toStringAsFixed(2)}) ✓'
            '  → Ambas condiciones simultáneas → CL-ML',
        cumple: true,
      ));
    } else {
      final sobreA = pi >= aVal;
      pasos.add(PasoClasificacion(
        numero: '4',
        titulo: sobreA ? 'Posición: sobre Línea A → Arcilla' : 'Posición: bajo Línea A → Limo',
        detalle: 'PI = ${pi.toStringAsFixed(1)} ${sobreA ? '≥' : '<'} Línea A (${aVal.toStringAsFixed(2)})'
            ' → ${sobreA ? 'C' : 'M'}',
        cumple: sobreA,
      ));

      // ── Alta o baja plasticidad ──────────────────────
      pasos.add(PasoClasificacion(
        numero: '5',
        titulo: ll < 50 ? 'Baja plasticidad (LL < 50)' : 'Alta plasticidad (LL ≥ 50)',
        detalle: 'LL = ${ll.toStringAsFixed(0)} ${ll < 50 ? '<' : '≥'} 50'
            ' → ${sobreA ? (ll < 50 ? 'CL' : 'CH') : (ll < 50 ? 'ML' : 'MH')}',
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
