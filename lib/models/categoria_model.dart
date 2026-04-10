class CategoriaModel {
  int? id;
  String nombre;
  int colorValue;
  int iconCode;

  CategoriaModel({
    this.id,
    required this.nombre,
    required this.colorValue,
    required this.iconCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'colorValue': colorValue,
      'iconCode': iconCode,
    };
  }

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      colorValue: map['colorValue'] as int,
      iconCode: map['iconCode'] as int,
    );
  }
}
