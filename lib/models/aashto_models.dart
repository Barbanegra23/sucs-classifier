/// Datos de entrada para la clasificación AASHTO (M 145 / ASTM D3282)
class AashtoInput {
  final double pasa10; // % que pasa el tamiz N°10 (2.00mm)
  final double pasa40; // % que pasa el tamiz N°40 (0.425mm)
  final double pasa200; // % que pasa el tamiz N°200 (0.075mm)
  final double ll; // Límite líquido
  final double lp; // Límite plástico (si el suelo es NP, lp == ll)

  AashtoInput({
    required this.pasa10,
    required this.pasa40,
    required this.pasa200,
    required this.ll,
    required this.lp,
  });
}

/// Resultado de la clasificación AASHTO
class AashtoResult {
  final String symbol; // Símbolo AASHTO, ej: "A-6(9)" o "A-1-a(0)"
  final String
      grupo; // Símbolo sin el índice de grupo, ej: "A-6" (usado para lógica/UI)
  final int gi; // Índice de grupo (0 en adelante, redondeado)
  final String description; // Descripción del suelo
  final String tipoMaterial; // "Material granular" | "Material limo-arcilloso"
  final String
      calificacionSubrasante; // "Excelente a bueno" | "Regular a malo" etc.
  final double pi; // Índice de plasticidad calculado (0 si NP)

  AashtoResult({
    required this.symbol,
    required this.grupo,
    required this.gi,
    required this.description,
    required this.tipoMaterial,
    required this.calificacionSubrasante,
    required this.pi,
  });
}
