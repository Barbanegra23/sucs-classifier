class SucsInterpretation {
  // 🧠 RESUMEN INTELIGENTE
  static String generarResumen(String simbolo, double pi, double ll) {
    final base = simbolo.split("-").first;
    final a = 0.73 * (ll - 20);
    final esDual = simbolo.contains("-");

    final esGranularLimpio = ["GW", "GP", "SW", "SP"].contains(base) && pi < 7;

    String tipo;

    if (simbolo == "CL-ML") {
      return "Arcilla limosa de baja plasticidad, en la zona de transición de la carta de Casagrande. Comportamiento transicional cohesivo-friccional: cohesión baja con alta sensibilidad al agua. Ventana de compactación muy estrecha. Requiere ensayos complementarios para caracterización precisa en obra.";
    }

    if (["CL", "CH"].contains(base)) {
      tipo = "Arcilla";
    } else if (["ML", "MH"].contains(base)) {
      tipo = "Limo";
    } else if (["GW", "GP", "GM", "GC"].contains(base)) {
      tipo = "Grava";
    } else if (["SW", "SP", "SM", "SC"].contains(base)) {
      tipo = "Arena";
    } else {
      tipo = "Suelo";
    }

    String plast;

    if (["CL", "ML", "SM", "SC"].contains(base)) {
      plast = "de baja plasticidad";
    } else if (["CH", "MH"].contains(base)) {
      plast = "de alta plasticidad";
    } else {
      plast = "granular";
    }

    String comportamiento;

    if (esGranularLimpio) {
      comportamiento = "comportamiento no cohesivo (granular)";
    } else if (esDual) {
      comportamiento = pi > a
          ? "comportamiento mixto con influencia arcillosa"
          : "comportamiento mixto con influencia limosa";
    } else {
      comportamiento = pi > a
          ? "comportamiento cohesivo (arcilloso)"
          : "comportamiento limoso";
    }

    List<String> condiciones = [];

    final esArcilloso = pi > a;

    if (esArcilloso && pi > 20) {
      condiciones.add("potencialmente expansivo");
    }
    if (ll > 70) condiciones.add("altamente compresible");
    if (pi < 4) condiciones.add("de baja cohesión");

    String extra = condiciones.isNotEmpty ? ", ${condiciones.join(" y ")}" : "";

    return "$tipo $plast, con $comportamiento$extra.";
  }

  // 🛠 RECOMENDACIONES (específicas por símbolo)
  static List<String> generarRecomendaciones(
      String simbolo, double pi, double ll,
      {double? d10}) {
    // Se switchea sobre `simbolo` completo (no sobre su `base` sin sufijo
    // dual): "CL-ML".split("-").first == "CL", así que switchear por base
    // hacía que los casos "CL-ML" y los 8 símbolos duales de grava/arena
    // fueran inalcanzables — un suelo GW-GC recibía las recomendaciones
    // de GW simple. Los casos de símbolo simple (ej. "GW", "SW") siguen
    // funcionando igual porque, sin sufijo dual, simbolo == base.
    List<String> rec = [];

    switch (simbolo) {
      case "GW":
      case "SW":
        rec.add("Material apto para bases y sub-bases de pavimentos");
        if (d10 != null && d10 > 0) {
          final k = 1.0 * d10 * d10;
          rec.add(
              "Permeabilidad estimada Hazen: k ~ ${k.toStringAsFixed(4)} cm/s  (k = C·D10², C≈1, válido para D10 entre 0.1-3 mm)");
        } else {
          rec.add(
              "Excelente drenaje libre - permeabilidad estimada Hazen: k ~ C * D10^2 (cm/s), con C≈1 para D10 en mm");
        }
        rec.add("Verificar densidad relativa en campo (ensayo de cono o SPT)");
        break;

      case "GP":
      case "SP":
        rec.add(
            "Verificar compactación — gradación pobre puede generar vacíos");
        rec.add("Considerar mezcla con material bien graduado");
        break;

      case "GM":
        rec.add("Controlar contenido de humedad en compactación");
        rec.add("Sensible a saturación — prever drenaje adecuado");
        rec.add(
            "Verificar permeabilidad — los finos limosos reducen el drenaje libre");
        break;

      case "SM":
        rec.add("Controlar contenido de humedad en compactación");
        rec.add("Sensible a saturación — prever drenaje adecuado");
        rec.add("Evaluar potencial de licuefacción en zonas sísmicas");
        break;

      case "GC":
      case "SC":
        rec.add("Compactar con control estricto de humedad");
        rec.add("Posible variación volumétrica con cambios de humedad");
        rec.add("Evaluar expansión si PI > 15");
        break;

      case "ML":
        rec.add("Alta sensibilidad a la humedad — evitar saturación");
        rec.add("Baja resistencia al corte en estado húmedo");
        rec.add("Compactar en la cara seca de la curva Proctor");
        break;

      case "MH":
        rec.add("Muy sensible a cambios de humedad");
        rec.add("Alta compresibilidad — evaluar asentamientos");
        rec.add("Requiere estabilización si se usa como subrasante");
        break;

      case "CL-ML":
        rec.add(
            "Ventana de compactación muy estrecha — controlar humedad con precision: variaciones de 1-2 % respecto al optimo alteran criticamente el comportamiento");
        rec.add(
            "Diseño crítico de drenaje y subdrenaje: la fracción limosa potencia la ascensión capilar — evitar saturación de la subrasante");
        rec.add(
            "Riesgo de bombeo de finos (pumping) bajo tránsito pesado con agua libre — factor clave en diseño de pavimentos");
        rec.add(
            "Estabilización mixta cal + cemento más eficiente que cal sola: menor fracción arcillosa disponible para la reacción puzolánica");
        rec.add("No usar como subrasante sin estudio de CBR saturado previo");
        break;

      case "CL":
        rec.add(
            "Compactar cerca del óptimo Proctor — del lado seco si se busca mayor resistencia inicial, del lado húmedo si se prioriza control de expansión");
        rec.add("Controlar expansión libre antes del uso en obra");
        rec.add(
            "Sensible a desecación (fisuras superficiales) y a saturación (pérdida de resistencia no drenada)");
        if (pi > 12) {
          rec.add(
              "Puede contener minerales expansivos (montmorillonita/ilita) — evaluar hinchamiento con ensayo libre antes de diseño de subrasante");
        }
        if (pi > 17) {
          rec.add(
              "PI elevado — considerar estabilización con cal (2–4 %) para mejorar trabajabilidad y reducir plasticidad");
        }
        break;

      case "CH":
        rec.add("Alta plasticidad — evitar usar como relleno sin tratamiento");
        rec.add(
            "Estabilización con cal (2–4 %) es el tratamiento estándar para reducir PI y mejorar trabajabilidad en obra");
        rec.add(
            "Evaluar también cemento Portland si se requiere resistencia a corto plazo");
        rec.add("Monitorear asentamientos si soporta cargas estructurales");
        rec.add(
            "En subrasantes viales: diseñar con CBR de hinchamiento — no usar CBR sin saturar");
        if (ll > 70) {
          rec.add(
              "Suelo altamente compresible — requiere estudio especial de consolidación");
        }
        break;

      // ── SÍMBOLOS DUALES ─────────────────────────────
      case "GW-GC":
        rec.add(
            "Grava bien graduada con finos arcillosos — buena estabilidad general");
        rec.add(
            "Controlar contenido de humedad: los finos arcillosos son sensibles");
        rec.add("Apto para bases de pavimento con control de compactación");
        rec.add("Evaluar expansión si PI > 15");
        break;

      case "GW-GM":
        rec.add(
            "Grava bien graduada con finos limosos — comportamiento mayormente granular");
        rec.add(
            "Prever drenaje adecuado: los finos limosos son sensibles a saturación");
        rec.add("Buena aptitud para bases y sub-bases con control de humedad");
        break;

      case "GP-GC":
        rec.add(
            "Grava mal graduada con finos arcillosos — gradación deficiente");
        rec.add(
            "Compactar con control estricto de humedad por presencia de arcilla");
        rec.add(
            "Considerar mejoramiento granulométrico antes de uso estructural");
        rec.add("Posible variación volumétrica con cambios de humedad");
        break;

      case "GP-GM":
        rec.add(
            "Grava mal graduada con finos limosos — doble limitación granulométrica");
        rec.add(
            "Alta sensibilidad a saturación por combinación de mala gradación y limos");
        rec.add("Prever drenaje y evitar saturación en obra");
        rec.add("Evaluar estabilización si se usa en subrasante");
        break;

      case "SW-SC":
        rec.add(
            "Arena bien graduada con finos arcillosos — buena estabilidad mecánica");
        rec.add(
            "Compactar cerca del óptimo Proctor: los finos arcillosos aumentan la cohesión aparente");
        rec.add(
            "Permeabilidad reducida respecto a SW limpia — prever subdrenaje en bases de pavimento");
        rec.add(
            "Controlar PI de los finos: si supera 15, evaluar expansión con ensayo de hinchamiento");
        break;

      case "SW-SM":
        rec.add(
            "Arena bien graduada con finos limosos — buena gradación con sensibilidad hídrica");
        rec.add(
            "Prever drenaje adecuado — los finos limosos son muy sensibles a saturación");
        rec.add("Compactar en la cara seca de la curva Proctor");
        rec.add("Evaluar potencial de licuefacción en zonas sísmicas");
        break;

      case "SP-SC":
        rec.add(
            "Arena mal graduada con finos arcillosos — gradación deficiente con cohesión parcial");
        rec.add(
            "La cohesión de los finos puede enmascarar la inestabilidad de la gradación");
        rec.add("Controlar compactación — riesgo de vacíos por mala gradación");
        rec.add("Monitorear cambios volumétricos con variaciones de humedad");
        break;

      case "SP-SM":
        rec.add(
            "Arena mal graduada con finos limosos — combinación de alto riesgo hídrico");
        rec.add(
            "Muy sensible a saturación — implementar drenaje desde etapa de diseño");
        rec.add(
            "Evaluar potencial de licuefacción en zonas sísmicas con detalle");
        rec.add("Considerar mejoramiento del suelo antes de uso estructural");
        break;

      default:
        rec.add("Controlar contenido de humedad");
        rec.add("Verificar comportamiento en campo antes de uso estructural");
    }

    return rec;
  }

  // 🔬 INTERPRETACIÓN INGENIERIL
  static List<String> interpretacionIngenieril(String simbolo) {
    final base = simbolo.split("-").first;

    // 🔀 SÍMBOLOS DUALES (deben chequearse ANTES que los símbolos base:
    // "GW-GC".split("-").first == "GW", así que si el chequeo por `base`
    // fuera primero, todo símbolo dual caería en la interpretación del
    // símbolo simple y esta rama quedaría muerta — ver commit que corrige esto).
    if (simbolo == "GW-GC") {
      return [
        "Grava bien graduada con finos arcillosos",
        "Alta estabilidad mecánica con cohesión adicional por arcilla",
        "Permeabilidad media — los finos arcillosos reducen el drenaje libre",
        "Posible variación volumétrica moderada ante cambios de humedad",
      ];
    }
    if (simbolo == "GW-GM") {
      return [
        "Grava bien graduada con finos limosos",
        "Buena estabilidad granular con sensibilidad hídrica por los limos",
        "Permeabilidad media — menor que GW limpia",
        "Susceptible a pérdida de resistencia si se satura",
      ];
    }
    if (simbolo == "GP-GC") {
      return [
        "Grava mal graduada con finos arcillosos",
        "Gradación deficiente con cohesión parcial por arcilla",
        "Comportamiento poco predecible bajo carga",
        "Baja permeabilidad — los finos obturan los vacíos",
      ];
    }
    if (simbolo == "GP-GM") {
      return [
        "Grava mal graduada con finos limosos",
        "Doble limitación: mala gradación y sensibilidad hídrica",
        "Alta vulnerabilidad a saturación",
        "Permeabilidad media a baja e irregular",
      ];
    }
    if (simbolo == "SW-SC") {
      return [
        "Arena bien graduada con finos arcillosos (5–12% pasa N°200)",
        "Buena distribución granulométrica con cohesión real aportada por la arcilla",
        "Permeabilidad menor que SW limpia — los finos reducen el drenaje",
        "Resistencia al corte incrementada por cohesión — favorable para bases",
        "Monitorear PI de los finos: valores altos indican riesgo de expansión",
      ];
    }
    if (simbolo == "SW-SM") {
      return [
        "Arena bien graduada con finos limosos (5–12% pasa N°200)",
        "Buena gradación granulométrica con sensibilidad hídrica por los limos",
        "Permeabilidad media — menor que SW limpia",
        "Cohesión aparente (por capilaridad) — se pierde al saturarse",
        "Evaluar potencial de licuefacción en zonas sísmicas",
      ];
    }
    if (simbolo == "SP-SC") {
      return [
        "Arena mal graduada con finos arcillosos",
        "Gradación deficiente — vacíos irregulares con cohesión parcial",
        "La cohesión de los finos puede enmascarar inestabilidad de gradación",
        "Baja permeabilidad — los finos arcillosos obturan los poros",
      ];
    }
    if (simbolo == "SP-SM") {
      return [
        "Arena mal graduada con finos limosos",
        "Combinación de mayor riesgo: mala gradación y limos sensibles al agua",
        "Alta susceptibilidad a licuefacción en zonas sísmicas",
        "Permeabilidad media a baja e irregular",
      ];
    }

    // 🪨 GRAVAS
    if (base == "GW") {
      return [
        "Buena distribución granulométrica",
        "Alta estabilidad mecánica",
        "Excelente comportamiento en compactación",
        "Baja compresibilidad",
      ];
    }
    if (base == "GP") {
      return [
        "Mala distribución granulométrica",
        "Posibles vacíos mal distribuidos",
        "Comportamiento poco predecible en compactación",
        "Permeabilidad alta pero irregular",
      ];
    }
    if (base == "GM") {
      return [
        "Presencia de finos limosos",
        "Menor cohesión que suelos arcillosos",
        "Sensibilidad a la humedad",
        "Permeabilidad media a baja",
      ];
    }
    if (base == "GC") {
      return [
        "Presencia de finos arcillosos",
        "Mayor cohesión respecto a GM",
        "Posible variación volumétrica con humedad",
        "Baja permeabilidad",
      ];
    }

    // 🟡 ARENAS
    if (base == "SW") {
      return [
        "Buena gradación granulométrica",
        "Alta permeabilidad controlada",
        "Buen comportamiento estructural",
        "Estable bajo cargas estáticas",
      ];
    }
    if (base == "SP") {
      return [
        "Mala gradación (arena uniforme o brecha)",
        "Baja estabilidad relativa",
        "Requiere control estricto de compactación",
        "Alta permeabilidad",
      ];
    }
    if (base == "SM") {
      return [
        "Arena con finos limosos",
        "Cohesión aparente por humedad",
        "Susceptible a pérdida de resistencia al saturarse",
        "Riesgo de licuefacción en zonas sísmicas",
      ];
    }
    if (base == "SC") {
      return [
        "Arena con finos arcillosos",
        "Cohesión real por presencia de arcilla",
        "Posible cambio volumétrico",
        "Permeabilidad baja",
      ];
    }

    // ⚪ LIMOS
    if (base == "ML") {
      return [
        "Baja cohesión",
        "Alta sensibilidad a la humedad",
        "Posible pérdida de resistencia al saturarse",
        "Comportamiento capaz de fluir en estado saturado",
      ];
    }
    if (base == "MH") {
      return [
        "Alta compresibilidad",
        "Muy sensible a variaciones de humedad",
        "Resistencia al corte baja",
        "Difícil de compactar en condiciones húmedas",
      ];
    }

    // 🔶 ZONA DE TRANSICIÓN
    if (simbolo == "CL-ML") {
      return [
        "Comportamiento transicional cohesivo-friccional — cohesión baja e inconsistente",
        "Ventana de compactación extremadamente estrecha: curva Proctor 'picuda' por el componente limoso",
        "Pérdida brusca de resistencia no drenada ante saturación o carga dinámica",
        "Alta ascensión capilar por la fracción limosa — crítico en subrasantes con napa superficial",
        "Riesgo de bombeo de finos bajo tránsito pesado con presencia de agua libre",
      ];
    }

    // 🟤 ARCILLAS
    if (base == "CL") {
      return [
        "Compresibilidad moderada",
        "Capacidad portante media — depende fuertemente del contenido de humedad",
        "Alta sensibilidad a desecación (fisuras) y saturación (pérdida de soporte)",
        "Bajo a moderado potencial de expansión — puede contener minerales arcillosos expansivos",
        "Posibles deformaciones moderadas bajo carga",
      ];
    }
    if (base == "CH") {
      return [
        "Muy alta compresibilidad — asentamientos importantes esperables",
        "Baja capacidad portante, especialmente en estado saturado",
        "Gran sensibilidad a cambios de humedad — ciclos de hinchamiento y retracción",
        "Alto potencial expansivo — requiere ensayo de hinchamiento libre",
        "Resistencia no drenada baja — no confiar en valores en seco",
      ];
    }

    return ["Comportamiento general del suelo — consultar ensayos adicionales"];
  }
}
