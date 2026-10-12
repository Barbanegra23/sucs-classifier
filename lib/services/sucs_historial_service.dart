import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sucs_classifier.dart';

// =============================================================
// HISTORIAL SERVICE
// =============================================================

/// Metadata de la muestra ingresada al guardar.
class DatosMuestra {
  final String nombre;
  final String ubicacion;
  final String profundidad;
  final String operador;
  final String notas;
  final DateTime fechaHora;
  final String proyectoId;
  final String proyectoNombre;
  final String expediente; // N° de obra / expediente

  const DatosMuestra({
    required this.nombre,
    this.ubicacion = '',
    this.profundidad = '',
    this.operador = '',
    this.notas = '',
    required this.fechaHora,
    this.proyectoId = '',
    this.proyectoNombre = '',
    this.expediente = '',
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'ubicacion': ubicacion,
        'profundidad': profundidad,
        'operador': operador,
        'notas': notas,
        'fechaHora': fechaHora.toIso8601String(),
        'proyectoId': proyectoId,
        'proyectoNombre': proyectoNombre,
        'expediente': expediente,
      };

  factory DatosMuestra.fromJson(Map<String, dynamic> j) => DatosMuestra(
        nombre: j['nombre'] as String? ?? '',
        ubicacion: j['ubicacion'] as String? ?? '',
        profundidad: j['profundidad'] as String? ?? '',
        operador: j['operador'] as String? ?? '',
        notas: j['notas'] as String? ?? '',
        fechaHora: DateTime.tryParse(j['fechaHora'] as String? ?? '') ??
            DateTime.now(),
        proyectoId: j['proyectoId'] as String? ?? '',
        proyectoNombre: j['proyectoNombre'] as String? ?? '',
        expediente: j['expediente'] as String? ?? '',
      );

  /// Muestra solo los campos no vacíos como texto compacto.
  String get resumenCorto {
    final partes = <String>[];
    if (proyectoNombre.isNotEmpty) partes.add(proyectoNombre);
    if (expediente.isNotEmpty) partes.add('Exp. $expediente');
    if (ubicacion.isNotEmpty) partes.add(ubicacion);
    if (profundidad.isNotEmpty) partes.add('Prof. $profundidad');
    if (operador.isNotEmpty) partes.add(operador);
    return partes.join(' · ');
  }

  bool get tieneProyecto => proyectoId.isNotEmpty;

  DatosMuestra copyWith({String? nombre}) => DatosMuestra(
        nombre: nombre ?? this.nombre,
        ubicacion: ubicacion,
        profundidad: profundidad,
        operador: operador,
        notas: notas,
        fechaHora: fechaHora,
        proyectoId: proyectoId,
        proyectoNombre: proyectoNombre,
        expediente: expediente,
      );
}

/// Modelo de una muestra clasificada con metadata completa.
class EntradaHistorial {
  final SucsResult resultado;
  final double ll, lp, pasa200, retenidoN4;
  final double? cu, cc;

  /// Diámetros característicos (mm). Solo suelos gruesos; null en
  /// entradas guardadas antes de esta versión.
  final double? d10, d30, d60;

  /// Metadata de la muestra. Puede ser null si se guardó antes de esta versión.
  /// No es final para poder renombrar la muestra (ver [renombrar]).
  DatosMuestra? muestra;

  /// Compatibilidad hacia atrás: nombre suelto (versión anterior).
  String nombre;

  EntradaHistorial({
    required this.resultado,
    required this.ll,
    required this.lp,
    required this.pasa200,
    required this.retenidoN4,
    this.cu,
    this.cc,
    this.d10,
    this.d30,
    this.d60,
    this.muestra,
    this.nombre = '',
  });

  /// Cambia el nombre visible de la muestra. Actualiza tanto la metadata
  /// como el campo legacy, porque [nombreDisplay] prioriza
  /// `muestra.nombre`: cambiar solo `nombre` no se veía en pantalla.
  void renombrar(String nuevo) {
    nombre = nuevo;
    if (muestra != null) muestra = muestra!.copyWith(nombre: nuevo);
  }

  // ── Serialización ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'symbol': resultado.symbol,
        'description': resultado.description,
        'pi': resultado.pi,
        'll': ll,
        'lp': lp,
        'pasa200': pasa200,
        'retenidoN4': retenidoN4,
        if (cu != null) 'cu': cu,
        if (cc != null) 'cc': cc,
        if (d10 != null) 'd10': d10,
        if (d30 != null) 'd30': d30,
        if (d60 != null) 'd60': d60,
        'nombre': nombre,
        if (muestra != null) 'muestra': muestra!.toJson(),
      };

  factory EntradaHistorial.fromJson(Map<String, dynamic> json) =>
      EntradaHistorial(
        resultado: SucsResult(json['symbol'], json['description'],
            (json['pi'] as num).toDouble()),
        ll: (json['ll'] as num).toDouble(),
        lp: (json['lp'] as num).toDouble(),
        pasa200: (json['pasa200'] as num).toDouble(),
        retenidoN4: (json['retenidoN4'] as num).toDouble(),
        cu: json['cu'] != null ? (json['cu'] as num).toDouble() : null,
        cc: json['cc'] != null ? (json['cc'] as num).toDouble() : null,
        d10: (json['d10'] as num?)?.toDouble(),
        d30: (json['d30'] as num?)?.toDouble(),
        d60: (json['d60'] as num?)?.toDouble(),
        nombre: json['nombre'] as String? ?? '',
        muestra: json['muestra'] != null
            ? DatosMuestra.fromJson(json['muestra'] as Map<String, dynamic>)
            : null,
      );

  /// Nombre de display: usa muestra.nombre si existe, fallback a nombre legacy.
  String get nombreDisplay =>
      (muestra?.nombre.isNotEmpty == true) ? muestra!.nombre : nombre;

  bool get tieneMetadata => muestra != null;
}

/// Servicio de persistencia del historial.
class SucsHistorialService {
  static const _key = 'historial_muestras';

  /// Copia del JSON crudo cuando no se pudo leer completo. Evita que el
  /// próximo guardado pise para siempre las muestras que no se pudieron
  /// interpretar (antes, una sola entrada dañada vaciaba el historial y
  /// el siguiente `agregar` borraba todo lo anterior).
  static const backupKey = 'historial_muestras_backup';
  static const int maxEntradas = 50;

  static Future<List<EntradaHistorial>> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    List<dynamic> lista;
    try {
      lista = jsonDecode(raw) as List<dynamic>;
    } catch (e, stack) {
      debugPrint('Historial ilegible, se respalda en "$backupKey": $e');
      debugPrintStack(stackTrace: stack);
      await prefs.setString(backupKey, raw);
      return [];
    }

    // Cada entrada se interpreta por separado: una dañada no hace
    // perder las demás.
    final resultado = <EntradaHistorial>[];
    var fallidas = 0;
    for (final e in lista) {
      try {
        resultado.add(EntradaHistorial.fromJson(e as Map<String, dynamic>));
      } catch (err) {
        fallidas++;
        debugPrint('Entrada de historial descartada: $err');
      }
    }
    if (fallidas > 0) await prefs.setString(backupKey, raw);
    return resultado;
  }

  static Future<void> guardar(List<EntradaHistorial> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(lista.map((e) => e.toJson()).toList());
    await prefs.setString(_key, json);
  }

  static Future<List<EntradaHistorial>> agregar(
    List<EntradaHistorial> actual,
    EntradaHistorial nueva,
  ) async {
    final actualizado = [nueva, ...actual];
    if (actualizado.length > maxEntradas) actualizado.removeLast();
    await guardar(actualizado);
    return actualizado;
  }

  static Future<List<EntradaHistorial>> eliminar(
    List<EntradaHistorial> actual,
    int indice,
  ) async {
    final actualizado = [...actual]..removeAt(indice);
    await guardar(actualizado);
    return actualizado;
  }

  static Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> actualizarNombre(
    List<EntradaHistorial> actual,
    int indice,
    String nombre,
  ) async {
    actual[indice].renombrar(nombre);
    await guardar(actual);
  }
}
