# SUCS Classifier

Clasificador de suelos según el **Sistema Unificado de Clasificación de Suelos (SUCS / USCS)**, basado en la norma **ASTM D2487**. Desarrollado por **LINARE Obras Civiles** como herramienta de campo y oficina para clasificación rápida de suelos en obras de ingeniería civil.

## Funcionalidad

- Clasificación completa de suelos finos (CL, CH, ML, MH, CL-ML) y gruesos (GW, GP, GM, GC, SW, SP, SM, SC), incluyendo símbolos duales (GW-GM, SP-SC, etc.) según ASTM D2487.
- Cálculo automático de Cu (coeficiente de uniformidad) y Cc (coeficiente de curvatura) a partir de D10, D30 y D60.
- Carta de plasticidad de Casagrande (Línea A y Línea U) graficada para suelos finos.
- Curva granulométrica estimada para suelos gruesos.
- Interpretación geotécnica automática: comportamiento esperado, recomendaciones de uso (pavimentos, compactación, drenaje) y permeabilidad estimada (Hazen) cuando corresponde.
- Historial local de muestras clasificadas, con metadata de proyecto/obra, edición de nombre y exportación.
- Exportación de informes a **PDF** (ficha técnica con gráfico incluido) y del historial completo a **CSV**.
- Tema claro / oscuro.
- Tutorial interactivo (onboarding) con explicación de cada parámetro de entrada.

## Stack técnico

- **Flutter** (SDK ^3.6.0)
- [`fl_chart`](https://pub.dev/packages/fl_chart) — gráficos base de la carta de Casagrande
- [`google_fonts`](https://pub.dev/packages/google_fonts) — tipografía Inter
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) — persistencia local del historial
- [`pdf`](https://pub.dev/packages/pdf) + [`printing`](https://pub.dev/packages/printing) — generación y exportación de informes
- [`path_provider`](https://pub.dev/packages/path_provider) — acceso al sistema de archivos en mobile/desktop

## Estructura del proyecto

```
lib/
├── models/      → Modelos de datos (SucsInput, SucsResult)
├── services/    → Lógica de clasificación, exportación PDF/CSV, persistencia del historial
├── logic/       → Interpretación geotécnica y generación de recomendaciones
├── screens/     → Pantallas principales (bienvenida, onboarding, clasificador)
├── widgets/     → Componentes reutilizables (inputs, gráficos, diálogos, panel de historial)
└── theme/       → Paleta de colores con soporte claro/oscuro
```

## Cómo correrlo

```bash
flutter pub get
flutter run
```

## Tests

El motor de clasificación cuenta con una suite de tests unitarios que cubre casos límite de la norma (zona CL-ML, umbrales de Cu/Cc para grava vs. arena, validaciones cruzadas, etc.). También hay cobertura para la interpretación geotécnica (`soil_interpretation.dart`) y la persistencia del historial (`historial_service.dart`, incluyendo compatibilidad con formato legacy y el tope de 50 muestras):

```bash
flutter test
```

## Alcance y limitaciones

Esta herramienta está pensada como apoyo rápido de campo/oficina y no reemplaza el ensayo de laboratorio completo ni el juicio profesional del ingeniero geotécnico. No clasifica suelos orgánicos (OL, OH, Pt), ya que esto requiere comparar el límite líquido seco al horno vs. sin secar, dato no disponible en una clasificación de campo. La curva granulométrica que se grafica es una aproximación construida a partir de los parámetros índice (P200, R4, D10/D30/D60), no la curva completa de un ensayo de tamices.

## Licencia

Todos los derechos reservados. Ver [LICENSE](LICENSE). El código es de acceso público a modo de portfolio profesional; cualquier otro uso requiere autorización.