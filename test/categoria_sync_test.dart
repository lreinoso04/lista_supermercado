import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/models/categoria_model.dart';
import 'package:lista_supermercado/models/producto.dart';

void main() {
  group('CategoriaModel & Category Sync Tests', () {
    test('CategoriaModel serializa y deserializa preservando icono y color', () {
      final original = CategoriaModel(
        id: 3,
        nombre: 'Mascotas',
        colorValue: 0xFFFF9800,
        iconCode: 58712,
      );

      final map = original.toMap();
      expect(map['nombre'], 'Mascotas');
      expect(map['colorValue'], 0xFFFF9800);
      expect(map['iconCode'], 58712);

      final deserializado = CategoriaModel.fromMap(map);
      expect(deserializado.id, 3);
      expect(deserializado.nombre, 'Mascotas');
      expect(deserializado.colorValue, 0xFFFF9800);
      expect(deserializado.iconCode, 58712);
    });

    test('Comparación de categorías es insensible a mayúsculas y espacios', () {
      final cat1 = 'Frutas y Verduras';
      final cat2 = '  frutas y verduras  ';

      expect(cat1.trim().toLowerCase(), cat2.trim().toLowerCase());
    });

    test('Producto conserva categoría asignada para listas compartidas', () {
      final p = Producto(
        nombre: 'Alimento para gatos',
        categoria: 'Mascotas',
        precioEstimado: 12.50,
        cantidad: 2,
      );

      final map = p.toMap();
      expect(map['categoria'], 'Mascotas');
      expect(map['precioEstimado'], 12.50);
      expect(map['cantidad'], 2);

      final p2 = Producto.fromMap(map);
      expect(p2.categoria, 'Mascotas');
    });
  });
}
