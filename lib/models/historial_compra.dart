import 'producto.dart';

class HistorialCompra {
  int? id;
  String uuid;
  String fecha;
  double total;
  int cantidadProductos;
  String? productosJson;
  String? pinLista;
  String? finalizadoPorNombre;

  HistorialCompra({
    this.id,
    String? uuid,
    required this.fecha,
    required this.total,
    required this.cantidadProductos,
    this.productosJson,
    this.pinLista,
    this.finalizadoPorNombre,
  }) : uuid = (uuid != null && uuid.isNotEmpty) ? uuid : Producto.generarUuid();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'fecha': fecha,
      'total': total,
      'cantidadProductos': cantidadProductos,
      'productosJson': productosJson,
      'pinLista': pinLista,
      'finalizadoPorNombre': finalizadoPorNombre,
    };
  }

  factory HistorialCompra.fromMap(Map<String, dynamic> map) {
    return HistorialCompra(
      id: map['id'] as int?,
      uuid: map['uuid'] as String?,
      fecha: map['fecha'] as String,
      total: (map['total'] as num).toDouble(),
      cantidadProductos: map['cantidadProductos'] as int,
      productosJson: map['productosJson'] as String?,
      pinLista: map['pinLista'] as String?,
      finalizadoPorNombre: map['finalizadoPorNombre'] as String?,
    );
  }
}
