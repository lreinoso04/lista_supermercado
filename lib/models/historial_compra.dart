class HistorialCompra {
  int? id;
  String fecha;
  double total;
  int cantidadProductos;
  String? productosJson;

  HistorialCompra({
    this.id,
    required this.fecha,
    required this.total,
    required this.cantidadProductos,
    this.productosJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'total': total,
      'cantidadProductos': cantidadProductos,
      'productosJson': productosJson,
    };
  }

  factory HistorialCompra.fromMap(Map<String, dynamic> map) {
    return HistorialCompra(
      id: map['id'] as int?,
      fecha: map['fecha'] as String,
      total: (map['total'] as num).toDouble(),
      cantidadProductos: map['cantidadProductos'] as int,
      productosJson: map['productosJson'] as String?,
    );
  }
}
