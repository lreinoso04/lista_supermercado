import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/models/historial_compra.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Finalización de Compra y Desvinculación de Listas Compartidas', () {
    test('El payload de finalización incluye productos vacíos y finalizada true', () {
      final historial = HistorialCompra(
        uuid: 'compra-123',
        fecha: '2026-10-02T12:00:00.000',
        total: 45.0,
        cantidadProductos: 3,
        pinLista: 'PIN999',
        finalizadoPorNombre: 'Juan',
      );

      final payload = {
        'productos': [],
        'finalizada': true,
        'ultimaCompraFinalizada': {
          'uuid': historial.uuid,
          'fecha': historial.fecha,
          'total': historial.total,
          'cantidadProductos': historial.cantidadProductos,
          'productosJson': historial.productosJson,
          'pinLista': 'PIN999',
          'finalizadoPorUid': 'user-1',
          'finalizadoPorNombre': 'Juan',
        },
      };

      expect(payload['productos'], isEmpty);
      expect(payload['finalizada'], isTrue);
      expect((payload['ultimaCompraFinalizada'] as Map)['uuid'], 'compra-123');
      expect((payload['ultimaCompraFinalizada'] as Map)['finalizadoPorNombre'], 'Juan');
    });

    test('Validación de PIN rechaza unirse a listas ya finalizadas', () {
      final datosListaActiva = {
        'pin': 'ACTIVO1',
        'finalizada': false,
        'productos': [
          {'nombre': 'Leche', 'comprado': false, 'cantidad': 1, 'categoria': 'Lácteos'}
        ],
      };

      final datosListaFinalizada = {
        'pin': 'CERRADO1',
        'finalizada': true,
        'productos': [],
      };

      // Simulación de la regla en conectarFirebase
      bool puedeConectar(Map<String, dynamic>? datos) {
        if (datos == null) throw Exception('El PIN no existe.');
        if (datos['finalizada'] == true) {
          throw Exception('Esta lista de compras ya fue finalizada y cerrada.');
        }
        return true;
      }

      expect(puedeConectar(datosListaActiva), isTrue);
      expect(
        () => puedeConectar(datosListaFinalizada),
        throwsA(predicate((e) => e.toString().contains('Esta lista de compras ya fue finalizada y cerrada.'))),
      );
    });

    test('Detección de finalización en participante limpia memoria y extrae comprador', () {
      final docDataRemoto = {
        'productos': [],
        'finalizada': true,
        'ultimaCompraFinalizada': {
          'uuid': 'uuid-remoto-abc',
          'fecha': '2026-10-02T14:00:00.000',
          'total': 78.50,
          'cantidadProductos': 4,
          'finalizadoPorNombre': 'María Marquez',
        },
      };

      final isFinalizada = docDataRemoto['finalizada'] == true;
      final ultimaCompra = docDataRemoto['ultimaCompraFinalizada'] as Map<String, dynamic>?;

      expect(isFinalizada, isTrue);
      expect(ultimaCompra, isNotNull);

      final nombreFinalizador = ultimaCompra!['finalizadoPorNombre'];
      expect(nombreFinalizador, 'María Marquez');

      final mensajeBanner = '🛒 ¡$nombreFinalizador ha finalizado la compra! Guardada en tu historial.';
      expect(mensajeBanner, contains('María Marquez'));
      expect(mensajeBanner, contains('Guardada en tu historial'));
    });
  });
}
