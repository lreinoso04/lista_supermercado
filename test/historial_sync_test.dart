import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/models/historial_compra.dart';
import 'package:lista_supermercado/providers/lista_provider.dart';

void main() {
  group('HistorialCompra Model & Sync Tests', () {
    test('HistorialCompra genera UUID por defecto si no se le proporciona', () {
      final h = HistorialCompra(
        fecha: '2026-10-02T10:00:00.000',
        total: 25.50,
        cantidadProductos: 3,
      );

      expect(h.uuid, isNotEmpty);
      expect(h.uuid.length, 36); // UUID v4 format xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      expect(h.fecha, '2026-10-02T10:00:00.000');
      expect(h.total, 25.50);
      expect(h.cantidadProductos, 3);
    });

    test('HistorialCompra serializa y deserializa con campos nuevos (uuid, pinLista, finalizadoPorNombre)', () {
      final original = HistorialCompra(
        id: 10,
        uuid: 'custom-uuid-1234-5678',
        fecha: '2026-10-02T11:00:00.000',
        total: 105.75,
        cantidadProductos: 5,
        productosJson: jsonEncode([{'nombre': 'Arroz', 'cantidad': 2}]),
        pinLista: 'ABC123',
        finalizadoPorNombre: 'Carlos Marquez',
      );

      final map = original.toMap();
      expect(map['uuid'], 'custom-uuid-1234-5678');
      expect(map['pinLista'], 'ABC123');
      expect(map['finalizadoPorNombre'], 'Carlos Marquez');

      final deserializado = HistorialCompra.fromMap(map);
      expect(deserializado.id, 10);
      expect(deserializado.uuid, 'custom-uuid-1234-5678');
      expect(deserializado.pinLista, 'ABC123');
      expect(deserializado.finalizadoPorNombre, 'Carlos Marquez');
      expect(deserializado.total, 105.75);
    });

    test('HistorialCompra maneja retrocompatibilidad para registros antiguos sin UUID', () {
      final mapaAntiguo = {
        'id': 1,
        'fecha': '2026-09-01T12:00:00.000',
        'total': 15.0,
        'cantidadProductos': 2,
        'productosJson': '[]',
      };

      final h = HistorialCompra.fromMap(mapaAntiguo);
      expect(h.id, 1);
      expect(h.uuid, isNotEmpty);
      expect(h.pinLista, isNull);
      expect(h.finalizadoPorNombre, isNull);
    });

    test('ListaProvider tiene isSyncingHistorial en false inicialmente', () {
      final provider = ListaProvider();
      expect(provider.isSyncingHistorial, isFalse);
    });
  });
}
