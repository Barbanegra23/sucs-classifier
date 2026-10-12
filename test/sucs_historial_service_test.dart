import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sucs_classifier/services/sucs_historial_service.dart';
import 'package:sucs_classifier/services/sucs_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatosMuestra', () {
    test('toJson/fromJson hace round-trip completo', () {
      final original = DatosMuestra(
        nombre: 'Muestra 1',
        ubicacion: 'Ruta 14 km 32',
        profundidad: '1.5 m',
        operador: 'J. Perez',
        notas: 'Suelo húmedo al momento del ensayo',
        fechaHora: DateTime(2026, 3, 15, 10, 30),
        proyectoId: 'p1',
        proyectoNombre: 'Obra Vial Norte',
        expediente: 'EXP-2026-004',
      );

      final restaurado = DatosMuestra.fromJson(original.toJson());

      expect(restaurado.nombre, original.nombre);
      expect(restaurado.ubicacion, original.ubicacion);
      expect(restaurado.profundidad, original.profundidad);
      expect(restaurado.operador, original.operador);
      expect(restaurado.notas, original.notas);
      expect(restaurado.fechaHora, original.fechaHora);
      expect(restaurado.proyectoId, original.proyectoId);
      expect(restaurado.proyectoNombre, original.proyectoNombre);
      expect(restaurado.expediente, original.expediente);
    });

    test('fromJson con mapa vacío usa defaults sin explotar', () {
      final restaurado = DatosMuestra.fromJson({});
      expect(restaurado.nombre, '');
      expect(restaurado.ubicacion, '');
      expect(restaurado.tieneProyecto, isFalse);
    });

    test('resumenCorto solo incluye campos no vacíos, separados por " · "', () {
      final m = DatosMuestra(
        nombre: 'x',
        proyectoNombre: 'Obra Vial Norte',
        expediente: 'EXP-4',
        fechaHora: DateTime.now(),
      );
      expect(m.resumenCorto, 'Obra Vial Norte · Exp. EXP-4');
    });

    test('resumenCorto es vacío si no hay metadata cargada', () {
      final m = DatosMuestra(nombre: 'x', fechaHora: DateTime.now());
      expect(m.resumenCorto, '');
    });

    test('tieneProyecto refleja si proyectoId está seteado', () {
      final sinProyecto = DatosMuestra(nombre: 'x', fechaHora: DateTime.now());
      final conProyecto = DatosMuestra(
          nombre: 'x', fechaHora: DateTime.now(), proyectoId: 'abc');
      expect(sinProyecto.tieneProyecto, isFalse);
      expect(conProyecto.tieneProyecto, isTrue);
    });
  });

  group('EntradaHistorial', () {
    SucsResult resultado() => SucsResult('CL', 'Arcilla de baja plasticidad', 12.0);

    test('toJson/fromJson hace round-trip con cu/cc y muestra presentes', () {
      final original = EntradaHistorial(
        resultado: resultado(),
        ll: 32,
        lp: 20,
        pasa200: 60,
        retenidoN4: 5,
        cu: 4.5,
        cc: 1.2,
        muestra: DatosMuestra(nombre: 'M1', fechaHora: DateTime(2026, 1, 1)),
        nombre: 'legacy',
      );

      final restaurado = EntradaHistorial.fromJson(original.toJson());

      expect(restaurado.resultado.symbol, 'CL');
      expect(restaurado.resultado.pi, 12.0);
      expect(restaurado.ll, 32);
      expect(restaurado.lp, 20);
      expect(restaurado.pasa200, 60);
      expect(restaurado.retenidoN4, 5);
      expect(restaurado.cu, 4.5);
      expect(restaurado.cc, 1.2);
      expect(restaurado.tieneMetadata, isTrue);
      expect(restaurado.muestra!.nombre, 'M1');
    });

    test('toJson/fromJson round-trip sin cu/cc ni muestra (suelo fino)', () {
      final original = EntradaHistorial(
        resultado: resultado(),
        ll: 32,
        lp: 20,
        pasa200: 60,
        retenidoN4: 0,
      );

      final json = original.toJson();
      expect(json.containsKey('cu'), isFalse);
      expect(json.containsKey('cc'), isFalse);
      expect(json.containsKey('muestra'), isFalse);

      final restaurado = EntradaHistorial.fromJson(json);
      expect(restaurado.cu, isNull);
      expect(restaurado.cc, isNull);
      expect(restaurado.tieneMetadata, isFalse);
    });

    test('nombreDisplay prioriza muestra.nombre sobre el nombre legacy', () {
      final entrada = EntradaHistorial(
        resultado: resultado(),
        ll: 32,
        lp: 20,
        pasa200: 60,
        retenidoN4: 0,
        muestra: DatosMuestra(nombre: 'Nombre nuevo', fechaHora: DateTime.now()),
        nombre: 'Nombre legacy',
      );
      expect(entrada.nombreDisplay, 'Nombre nuevo');
    });

    test('nombreDisplay cae al nombre legacy si no hay metadata', () {
      final entrada = EntradaHistorial(
        resultado: resultado(),
        ll: 32,
        lp: 20,
        pasa200: 60,
        retenidoN4: 0,
        nombre: 'Nombre legacy',
      );
      expect(entrada.nombreDisplay, 'Nombre legacy');
    });

    test('nombreDisplay cae al nombre legacy si muestra.nombre está vacío', () {
      final entrada = EntradaHistorial(
        resultado: resultado(),
        ll: 32,
        lp: 20,
        pasa200: 60,
        retenidoN4: 0,
        muestra: DatosMuestra(nombre: '', fechaHora: DateTime.now()),
        nombre: 'Nombre legacy',
      );
      expect(entrada.nombreDisplay, 'Nombre legacy');
    });
  });

  group('SucsHistorialService', () {
    setUp(() {
      // Reinicia el almacenamiento simulado antes de cada test para que
      // no queden datos de un test filtrándose al siguiente.
      SharedPreferences.setMockInitialValues({});
    });

    EntradaHistorial muestra({String nombre = 'M'}) => EntradaHistorial(
          resultado: SucsResult('CL', 'Arcilla de baja plasticidad', 12.0),
          ll: 32,
          lp: 20,
          pasa200: 60,
          retenidoN4: 0,
          nombre: nombre,
        );

    test('cargar() sin datos previos devuelve lista vacía', () async {
      final lista = await SucsHistorialService.cargar();
      expect(lista, isEmpty);
    });

    test('guardar() + cargar() hace round-trip', () async {
      await SucsHistorialService.guardar([muestra(nombre: 'A'), muestra(nombre: 'B')]);
      final lista = await SucsHistorialService.cargar();
      expect(lista, hasLength(2));
      expect(lista[0].nombre, 'A');
      expect(lista[1].nombre, 'B');
    });

    test('cargar() con JSON corrupto no explota, devuelve lista vacía', () async {
      SharedPreferences.setMockInitialValues({'historial_muestras': 'esto no es json'});
      final lista = await SucsHistorialService.cargar();
      expect(lista, isEmpty);
    });

    test('agregar() inserta la muestra nueva al principio', () async {
      var lista = await SucsHistorialService.agregar([], muestra(nombre: 'primera'));
      lista = await SucsHistorialService.agregar(lista, muestra(nombre: 'segunda'));
      expect(lista.map((e) => e.nombre), ['segunda', 'primera']);

      // Confirma que además quedó persistido, no solo en memoria.
      final recargado = await SucsHistorialService.cargar();
      expect(recargado.map((e) => e.nombre), ['segunda', 'primera']);
    });

    test('agregar() respeta el tope de maxEntradas descartando la más vieja', () async {
      var lista = <EntradaHistorial>[];
      for (var i = 0; i < SucsHistorialService.maxEntradas + 1; i++) {
        lista = await SucsHistorialService.agregar(lista, muestra(nombre: 'm$i'));
      }
      expect(lista, hasLength(SucsHistorialService.maxEntradas));
      // La más nueva (la última agregada) debe seguir presente al principio...
      expect(lista.first.nombre, 'm${SucsHistorialService.maxEntradas}');
      // ...y la más vieja (la primera que se agregó, "m0") debe haber sido descartada.
      expect(lista.any((e) => e.nombre == 'm0'), isFalse);
    });

    test('eliminar() saca la entrada del índice dado y persiste el cambio', () async {
      var lista = await SucsHistorialService.agregar([], muestra(nombre: 'A'));
      lista = await SucsHistorialService.agregar(lista, muestra(nombre: 'B'));
      lista = await SucsHistorialService.agregar(lista, muestra(nombre: 'C'));
      // lista actual: [C, B, A]

      lista = await SucsHistorialService.eliminar(lista, 1); // saca 'B'
      expect(lista.map((e) => e.nombre), ['C', 'A']);

      final recargado = await SucsHistorialService.cargar();
      expect(recargado.map((e) => e.nombre), ['C', 'A']);
    });

    test('limpiar() deja el historial vacío', () async {
      await SucsHistorialService.guardar([muestra()]);
      await SucsHistorialService.limpiar();
      final lista = await SucsHistorialService.cargar();
      expect(lista, isEmpty);
    });

    test('actualizarNombre() modifica el nombre y persiste', () async {
      var lista = await SucsHistorialService.agregar([], muestra(nombre: 'Viejo'));
      await SucsHistorialService.actualizarNombre(lista, 0, 'Nuevo nombre');

      final recargado = await SucsHistorialService.cargar();
      expect(recargado[0].nombre, 'Nuevo nombre');
    });

    test('actualizarNombre() cambia el nombre VISIBLE cuando hay metadata',
        () async {
      // Bug anterior: solo cambiaba el nombre legacy, pero nombreDisplay
      // prioriza muestra.nombre → en pantalla seguía el nombre viejo.
      final conMeta = EntradaHistorial(
        resultado: SucsResult('CL', 'Arcilla de baja plasticidad', 12.0),
        ll: 32,
        lp: 20,
        pasa200: 60,
        retenidoN4: 0,
        nombre: 'Viejo',
        muestra: DatosMuestra(
          nombre: 'Viejo',
          ubicacion: 'Ruta 14',
          fechaHora: DateTime(2026, 1, 1),
        ),
      );
      final lista = await SucsHistorialService.agregar([], conMeta);
      await SucsHistorialService.actualizarNombre(lista, 0, 'Nuevo');

      expect(lista[0].nombreDisplay, 'Nuevo');
      final recargado = await SucsHistorialService.cargar();
      expect(recargado[0].nombreDisplay, 'Nuevo');
      // El resto de la metadata se conserva.
      expect(recargado[0].muestra!.ubicacion, 'Ruta 14');
      expect(recargado[0].muestra!.fechaHora, DateTime(2026, 1, 1));
    });

    test('cargar() descarta solo la entrada dañada y conserva las demás',
        () async {
      await SucsHistorialService.guardar(
          [muestra(nombre: 'A'), muestra(nombre: 'B')]);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('historial_muestras')!;
      // Inserta una entrada inválida (sin campos obligatorios) en el medio.
      final corrupto = raw.replaceFirst('},{', '},{"symbol":"CL"},{');
      await prefs.setString('historial_muestras', corrupto);

      final lista = await SucsHistorialService.cargar();
      expect(lista.map((e) => e.nombre), ['A', 'B']);
      // Y guarda una copia del JSON original por si hay que recuperarlo.
      expect(prefs.getString(SucsHistorialService.backupKey), corrupto);
    });

    test('JSON ilegible: se respalda antes de que un guardado lo pise',
        () async {
      SharedPreferences.setMockInitialValues(
          {'historial_muestras': 'esto no es json'});
      final lista = await SucsHistorialService.cargar();
      await SucsHistorialService.agregar(lista, muestra(nombre: 'nueva'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SucsHistorialService.backupKey),
          'esto no es json');
    });

    test('cargar() sin errores no crea respaldo', () async {
      await SucsHistorialService.guardar([muestra(nombre: 'A')]);
      await SucsHistorialService.cargar();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SucsHistorialService.backupKey), isNull);
    });

    test('fecha inválida en la metadata no hace fallar la entrada', () async {
      SharedPreferences.setMockInitialValues({
        'historial_muestras':
            '[{"symbol":"CL","description":"x","pi":12,"ll":32,"lp":20,'
                '"pasa200":60,"retenidoN4":0,"nombre":"A",'
                '"muestra":{"nombre":"A","fechaHora":"no-es-fecha"}}]',
      });
      final lista = await SucsHistorialService.cargar();
      expect(lista, hasLength(1));
      expect(lista[0].nombreDisplay, 'A');
    });
  });

  group('EntradaHistorial D10/D30/D60', () {
    test('round-trip con diámetros', () {
      final e = EntradaHistorial(
        resultado: SucsResult('SW', 'Arena bien graduada', 0),
        ll: 0,
        lp: 0,
        pasa200: 3,
        retenidoN4: 20,
        cu: 8,
        cc: 1.5,
        d10: 0.1,
        d30: 0.35,
        d60: 0.8,
      );
      final r = EntradaHistorial.fromJson(e.toJson());
      expect(r.d10, 0.1);
      expect(r.d30, 0.35);
      expect(r.d60, 0.8);
    });

    test('entradas viejas sin diámetros cargan con null', () {
      final r = EntradaHistorial.fromJson({
        'symbol': 'SW',
        'description': 'x',
        'pi': 0,
        'll': 0,
        'lp': 0,
        'pasa200': 3,
        'retenidoN4': 20,
        'cu': 8,
        'cc': 1.5,
      });
      expect(r.d10, isNull);
      expect(r.cu, 8);
    });
  });
}
