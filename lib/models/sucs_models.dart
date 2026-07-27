/// Datos de entrada para la clasificación SUCS
class SucsInput {
  final double pasa200;    // % que pasa el tamiz N°200
  final double retenidoN4; // % retenido en tamiz N°4
  final double ll;         // Límite líquido
  final double lp;         // Límite plástico
  final double cu;         // Coeficiente de uniformidad
  final double cc;         // Coeficiente de curvatura

  SucsInput({
    required this.pasa200,
    required this.retenidoN4,
    required this.ll,
    required this.lp,
    required this.cu,
    required this.cc,
  });
}

/// Resultado de la clasificación SUCS
class SucsResult {
  final String symbol;      // Símbolo SUCS (ej: "CL", "GW-GM")
  final String description; // Descripción del suelo
  final double pi;          // Índice de plasticidad calculado

  SucsResult(this.symbol, this.description, this.pi);
}
