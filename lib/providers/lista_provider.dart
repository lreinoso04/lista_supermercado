import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/db_service.dart';

class ListaProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  bool _isLoading = false;

  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;

  Future<void> cargarProductos() async {
    _isLoading = true;
    notifyListeners();

    _productos = await DBService.instance.readAllProductos();

    // Si es la primera vez y no hay nada, podemos cargar unos datos de prueba (opcional)
    // Para entornos reales suele empezar en blanco, lo dejaremos vacío.

    _isLoading = false;
    notifyListeners();
  }

  Future<void> agregarProducto(Producto p) async {
    final nuevoP = await DBService.instance.create(p);
    _productos.add(nuevoP);
    notifyListeners();
  }

  Future<void> toggleComprado(Producto p) async {
    p.comprado = !p.comprado;
    await DBService.instance.update(p);
    
    final index = _productos.indexWhere((item) => item.id == p.id);
    if (index != -1) {
      _productos[index] = p;
      notifyListeners();
    }
  }

  Future<void> eliminarProducto(Producto p) async {
    if (p.id != null) {
      await DBService.instance.delete(p.id!);
      _productos.removeWhere((item) => item.id == p.id);
      notifyListeners();
    }
  }
}
