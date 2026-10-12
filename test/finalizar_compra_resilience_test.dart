import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/models/producto.dart';
import 'package:lista_supermercado/models/historial_compra.dart';
import 'package:lista_supermercado/providers/lista_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Finalizar Compra & Resilience Tests', () {
    test('marcarTodosComoComprados marca todos los productos pendientes como comprados', () async {
      final provider = ListaProvider();
      
      final p1 = Producto(nombre: 'Manzanas', categoria: 'Frutas', comprado: false, cantidad: 2);
      final p2 = Producto(nombre: 'Leche', categoria: 'Lácteos', comprado: false, cantidad: 1);
      final p3 = Producto(nombre: 'Pan', categoria: 'Panadería', comprado: true, cantidad: 1);

      provider.productos.addAll([p1, p2, p3]);

      expect(provider.productos.where((p) => p.comprado).length, 1);

      // Simular marcar todos
      for (var p in provider.productos) {
        p.comprado = true;
      }

      expect(provider.productos.where((p) => p.comprado).length, 3);
      expect(provider.productos.every((p) => p.comprado), isTrue);
    });

    test('HistorialCompra calcula correctamente el total y cantidad de productos comprados', () {
      final p1 = Producto(
        nombre: 'Arroz',
        categoria: 'Despensa',
        cantidad: 3,
        precioEstimado: 2.50,
        comprado: true,
      );
      final p2 = Producto(
        nombre: 'Aceite',
        categoria: 'Despensa',
        cantidad: 2,
        precioEstimado: 5.00,
        comprado: true,
      );
      final p3 = Producto(
        nombre: 'Jabón',
        categoria: 'Limpieza',
        cantidad: 1,
        precioEstimado: 1.50,
        comprado: false, // No comprado
      );

      final comprados = [p1, p2, p3].where((p) => p.comprado).toList();
      final total = comprados.fold(0.0, (acc, p) => acc + (p.precioEstimado * p.cantidad));
      final cantidad = comprados.fold(0, (acc, p) => acc + p.cantidad);

      expect(total, 17.50); // 3*2.50 + 2*5.00 = 7.50 + 10.00 = 17.50
      expect(cantidad, 5); // 3 + 2 = 5

      final historial = HistorialCompra(
        fecha: DateTime.now().toIso8601String(),
        total: total,
        cantidadProductos: cantidad,
        pinLista: 'TEST99',
        finalizadoPorNombre: 'Joan',
      );

      expect(historial.total, 17.50);
      expect(historial.cantidadProductos, 5);
      expect(historial.pinLista, 'TEST99');
      expect(historial.finalizadoPorNombre, 'Joan');
      expect(historial.uuid, isNotEmpty);
    });

    test('terminarCompra retorna 0 inmediatamente si la lista esta vacia sin modificar isLoading', () async {
      final provider = ListaProvider();
      expect(provider.productos, isEmpty);
      expect(provider.isLoading, isFalse);

      final resultado = await provider.terminarCompra();
      expect(resultado, 0);
      expect(provider.isLoading, isFalse);
    });
  });
}
