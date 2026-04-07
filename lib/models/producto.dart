class Producto {
  int? id;
  String nombre;
  String categoria;
  int cantidad;
  bool comprado;
  String prioridad; // Alta / Media / Baja

  Producto({
    this.id,
    required this.nombre,
    required this.categoria,
    this.cantidad = 1,
    this.comprado = false,
    this.prioridad = 'Media',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'comprado': comprado ? 1 : 0,
      'prioridad': prioridad,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String,
      cantidad: map['cantidad'] as int,
      comprado: map['comprado'] == 1,
      prioridad: map['prioridad'] as String,
    );
  }
}
