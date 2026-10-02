import 'dart:math';

class Producto {
  int? id;
  String uuid;
  String nombre;
  String categoria;
  int cantidad;
  bool comprado;
  String prioridad; // Alta / Media / Baja
  double precioEstimado;
  String tipoLista;

  Producto({
    this.id,
    String? uuid,
    required this.nombre,
    required this.categoria,
    this.cantidad = 1,
    this.comprado = false,
    this.prioridad = 'Media',
    this.precioEstimado = 0.0,
    this.tipoLista = 'supermercado',
  }) : uuid = (uuid != null && uuid.isNotEmpty) ? uuid : generarUuid();

  static String generarUuid() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // RFC 4122 Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10xx
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'nombre': nombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'comprado': comprado ? 1 : 0,
      'prioridad': prioridad,
      'precioEstimado': precioEstimado,
      'tipoLista': tipoLista,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      uuid: map['uuid'] as String?,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String,
      cantidad: map['cantidad'] as int,
      comprado: map['comprado'] == 1,
      prioridad: map['prioridad'] as String,
      precioEstimado: (map['precioEstimado'] ?? 0.0).toDouble(),
      tipoLista: map['tipoLista'] as String? ?? 'supermercado',
    );
  }
}

