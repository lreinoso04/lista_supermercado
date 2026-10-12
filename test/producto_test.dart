import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/models/producto.dart';

void main() {
  group('Producto & UUID Tests', () {
    test('Cada producto nuevo genera un UUID v4 válido y único', () {
      final p1 = Producto(nombre: 'Leche', categoria: 'Lácteos');
      final p2 = Producto(nombre: 'Pan', categoria: 'Panadería');

      expect(p1.uuid, isNotEmpty);
      expect(p2.uuid, isNotEmpty);
      expect(p1.uuid, isNot(equals(p2.uuid)));
      // Formato UUID v4: 8-4-4-4-12
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(p1.uuid), isTrue);
      expect(uuidRegex.hasMatch(p2.uuid), isTrue);
    });

    test('Serialización y deserialización toMap y fromMap preservan el UUID', () {
      final original = Producto(
        id: 42,
        uuid: '12345678-1234-4234-8234-123456789abc',
        nombre: 'Arroz',
        categoria: 'Granos',
        cantidad: 3,
        precioEstimado: 55.0,
      );

      final map = original.toMap();
      expect(map['uuid'], equals('12345678-1234-4234-8234-123456789abc'));

      final reconstruido = Producto.fromMap(map);
      expect(reconstruido.id, equals(42));
      expect(reconstruido.uuid, equals('12345678-1234-4234-8234-123456789abc'));
      expect(reconstruido.nombre, equals('Arroz'));
      expect(reconstruido.cantidad, equals(3));
      expect(reconstruido.precioEstimado, equals(55.0));
    });
  });
}
