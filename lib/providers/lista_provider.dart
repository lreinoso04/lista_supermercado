import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/historial_compra.dart';
import '../services/db_service.dart';

class ListaProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Producto> _catalogo = [];
  bool _isLoading = false;

  List<Producto> get productos => _productos;
  List<Producto> get catalogo => _catalogo;
  bool get isLoading => _isLoading;

  double get gastoTotal {
    return _productos
        .where((p) => p.comprado)
        .fold(0.0, (sum, p) => sum + (p.precioEstimado * p.cantidad));
  }

  Future<void> cargarListas() async {
    _isLoading = true;
    notifyListeners();

    _productos = await DBService.instance.readAllProductos();
    _catalogo = await DBService.instance.readAllCatalogo();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> agregarProducto(Producto p) async {
    final nuevoP = await DBService.instance.create(p);
    _productos.add(nuevoP);
    await _upsertCatalogo(nuevoP);
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

  Future<void> actualizarProducto(Producto p) async {
    await DBService.instance.update(p);
    final index = _productos.indexWhere((item) => item.id == p.id);
    if (index != -1) {
      _productos[index] = p;
      await _upsertCatalogo(p);
      notifyListeners();
    }
  }

  Future<void> _upsertCatalogo(Producto p) async {
    await DBService.instance.upsertCatalogo(p);
    _catalogo = await DBService.instance.readAllCatalogo();
  }

  Future<void> agregarAlCatalogoDirecto(Producto p) async {
    await DBService.instance.upsertCatalogo(p);
    _catalogo = await DBService.instance.readAllCatalogo();
    notifyListeners();
  }

  Future<void> eliminarProducto(Producto p) async {
    if (p.id != null) {
      await DBService.instance.delete(p.id!);
      _productos.removeWhere((item) => item.id == p.id);
      notifyListeners();
    }
  }

  Future<void> reiniciarLista() async {
    _isLoading = true;
    notifyListeners();
    for (var p in _productos) {
      if (p.comprado) {
        p.comprado = false;
        await DBService.instance.update(p);
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> vaciarListaDesdeCero() async {
    _isLoading = true;
    notifyListeners();
    await DBService.instance.deleteAllProductos();
    _productos.clear();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> terminarCompra() async {
    if (_productos.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    final comprados = _productos.where((p) => p.comprado).toList();
    if (comprados.isNotEmpty) {
      double total = comprados.fold(0.0, (sum, p) => sum + (p.precioEstimado * p.cantidad));
      int cantidad = comprados.fold(0, (sum, p) => sum + p.cantidad);
      final fecha = DateTime.now().toIso8601String();

      await DBService.instance.createHistorial(HistorialCompra(
        fecha: fecha,
        total: total,
        cantidadProductos: cantidad,
      ));
    }

    // Al terminar agregaremos todos al catálogo de nuevo por seguridad
    for (var p in _productos) {
      await DBService.instance.upsertCatalogo(p);
    }
    _catalogo = await DBService.instance.readAllCatalogo();

    // Vaciar lista actual
    await DBService.instance.deleteAllProductos();
    _productos.clear();

    _isLoading = false;
    notifyListeners();
  }
}
