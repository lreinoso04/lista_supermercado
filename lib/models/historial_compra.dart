class HistorialCompra {
  int? id;
  String fecha;
  double total;
  int cantidadProductos;

  HistorialCompra({
    this.id,
    required this.fecha,
    required this.total,
    required this.cantidadProductos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'total': total,
      'cantidadProductos': cantidadProductos,
    };
  }

  factory HistorialCompra.fromMap(Map<String, dynamic> map) {
    return HistorialCompra(
      id: map['id'] as int?,
      fecha: map['fecha'] as String,
      total: (map['total'] as num).toDouble(),
      cantidadProductos: map['cantidadProductos'] as int,
    );
  }
}
