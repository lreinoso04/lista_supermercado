import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/historial_compra.dart';
import '../models/categoria_model.dart';
import '../services/db_service.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class ListaProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Producto> _catalogo = [];
  List<CategoriaModel> _categorias = [];
  bool _isLoading = false;
  String? _pinActual;
  StreamSubscription<List<Producto>>? _subFirebase;
  bool _isSyncing = false;

  List<Producto> get productos => _productos;
  List<Producto> get catalogo => _catalogo;
  List<CategoriaModel> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get pinActual => _pinActual;

  void _syncNube() async {
    if (_pinActual != null) {
      _isSyncing = true;
      await FirebaseService.instance.syncListaCompleta(_pinActual!, _productos);
      _isSyncing = false;
    }
  }

  Future<void> conectarFirebase(String pin) async {
    _isLoading = true;
    notifyListeners();
    try {
      final existe = await FirebaseService.instance.verificarPin(pin);
      if (!existe) throw Exception('El PIN no existe.');

      _pinActual = pin;
      _subFirebase?.cancel();
      _subFirebase = FirebaseService.instance.streamLista(pin).listen((remotos) async {
        if (_isSyncing) return;
        _productos.clear();
        
        await DBService.instance.deleteAllProductos();

        for (var p in remotos) {
          final nuevoP = await DBService.instance.create(p);
          _productos.add(nuevoP);
        }
        notifyListeners();
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> compartirListaEnNube() async {
    final pin = FirebaseService.instance.generarPin();
    _pinActual = pin;
    _syncNube();
    
    _subFirebase?.cancel();
    _subFirebase = FirebaseService.instance.streamLista(pin).listen((remotos) async {
        if (_isSyncing) return;
        _productos.clear();
        
        await DBService.instance.deleteAllProductos();

        for (var p in remotos) {
          final nuevoP = await DBService.instance.create(p);
          _productos.add(nuevoP);
        }
        notifyListeners();
    });
    notifyListeners();
    return pin;
  }

  void desconectarFirebase() {
    _pinActual = null;
    _subFirebase?.cancel();
    notifyListeners();
  }

  double get gastoTotal {
    return productos
        .where((p) => p.comprado)
        .fold(0.0, (sum, p) => sum + (p.precioEstimado * p.cantidad));
  }

  Future<void> cargarListas() async {
    _isLoading = true;
    notifyListeners();

    _productos = await DBService.instance.readAllProductos();
    _catalogo = await DBService.instance.readAllCatalogo();
    _categorias = await DBService.instance.readAllCategorias();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> agregarProducto(Producto p) async {
    final nuevoP = await DBService.instance.create(p);
    _productos.add(nuevoP);
    await _upsertCatalogo(nuevoP);
    notifyListeners();
    _syncNube();
  }

  Future<void> toggleComprado(Producto p) async {
    p.comprado = !p.comprado;
    await DBService.instance.update(p);
    
    final index = _productos.indexWhere((item) => item.id == p.id);
    if (index != -1) {
      _productos[index] = p;
      notifyListeners();
      _syncNube();
    }
  }

  Future<void> actualizarProducto(Producto p) async {
    await DBService.instance.update(p);
    final index = _productos.indexWhere((item) => item.id == p.id);
    if (index != -1) {
      _productos[index] = p;
      await _upsertCatalogo(p);
      notifyListeners();
      _syncNube();
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
      _syncNube();
    }
  }

  // --- CATEGORIAS ---
  Future<void> agregarCategoria(CategoriaModel c) async {
    final nueva = await DBService.instance.createCategoria(c);
    _categorias.add(nueva);
    notifyListeners();
  }

  Future<void> actualizarCategoria(CategoriaModel c) async {
    await DBService.instance.updateCategoria(c);
    final idx = _categorias.indexWhere((cat) => cat.id == c.id);
    if (idx != -1) {
      _categorias[idx] = c;
      notifyListeners();
    }
  }

  Future<void> eliminarCategoria(CategoriaModel c) async {
    if (c.id != null) {
      await DBService.instance.deleteCategoria(c.id!);
      _categorias.removeWhere((cat) => cat.id == c.id);
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
    _syncNube();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> vaciarListaDesdeCero() async {
    _isLoading = true;
    notifyListeners();
    final productosActuales = _productos.toList();
    for (var p in productosActuales) {
      await DBService.instance.delete(p.id!);
      _productos.removeWhere((item) => item.id == p.id);
    }
    _syncNube();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> terminarCompra() async {
    if (_productos.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    final comprados = productos.where((p) => p.comprado).toList();

    if (comprados.isNotEmpty) {
      double total = comprados.fold(0.0, (sum, p) => sum + (p.precioEstimado * p.cantidad));
      int cantidad = comprados.fold(0, (sum, p) => sum + p.cantidad);
      final fecha = DateTime.now().toIso8601String();

      await DBService.instance.createHistorial(HistorialCompra(
        fecha: fecha,
        total: total,
        cantidadProductos: cantidad,
        productosJson: jsonEncode(comprados.map((p) => p.toMap()).toList()),
      ));

      // Solo eliminamos de la base de datos de productos aquellos que se compraron
      for (var p in comprados) {
        await DBService.instance.upsertCatalogo(p);
        if (p.id != null) {
          await DBService.instance.delete(p.id!);
        }
      }
      
      _catalogo = await DBService.instance.readAllCatalogo();
      
      // Removemos los items procesados de la lista local
      _productos.removeWhere((item) => item.comprado);
      _syncNube();
    }

    _isLoading = false;
    notifyListeners();
  }

  String exportarListaBase64() {
    final pendientes = productos.where((p) => !p.comprado).toList();
    if (pendientes.isEmpty) return "";
    
    final jsonString = jsonEncode(pendientes.map((p) => p.toMap()).toList());
    final bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }

  Future<void> importarListaBase64(String textoPegado) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Extracción Inteligente del código Base64
      final parts = textoPegado.split(RegExp(r'\s+'));
      String base64Data = '';
      for (var w in parts) {
        if (w.length > base64Data.length && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(w)) {
           base64Data = w;
        }
      }
      if (base64Data.isEmpty) base64Data = textoPegado.trim();

      final bytes = base64Decode(base64Data);
      final jsonString = utf8.decode(bytes);
      final List<dynamic> decoded = jsonDecode(jsonString);

      for (var item in decoded) {
        final importedP = Producto.fromMap(item as Map<String, dynamic>);
        importedP.id = null; // Forza a SQLite a crear una nueva llave primaria
        importedP.comprado = false; 
        
        // Creación silente de categoría si no existe
        final catExists = _categorias.any((c) => c.nombre.toLowerCase().trim() == importedP.categoria.toLowerCase().trim());
        if (!catExists) {
            final nueva = CategoriaModel(nombre: importedP.categoria, colorValue: 0xFF8D6E63, iconCode: Icons.shopping_bag_outlined.codePoint);
            final inserted = await DBService.instance.createCategoria(nueva);
            _categorias.add(inserted);
        }

        // Suma Inteligente si ya existía el mismo producto
        final index = _productos.indexWhere((p) => p.nombre.toLowerCase().trim() == importedP.nombre.toLowerCase().trim());
        if (index != -1) {
          final pBase = _productos[index];
          pBase.cantidad += importedP.cantidad;
          await DBService.instance.update(pBase);
        } else {
          final nuevoP = await DBService.instance.create(importedP);
          _productos.add(nuevoP);
          await DBService.instance.upsertCatalogo(nuevoP);
        }
      }
      _catalogo = await DBService.instance.readAllCatalogo();
    } catch (e) {
      debugPrint("Error importando lista: $e");
      throw Exception("El código no es válido.");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarListaDesdeHistorial(HistorialCompra h, {bool sustituir = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (sustituir) {
        await DBService.instance.deleteAllProductos();
        _productos.clear();
      }

      if (h.productosJson != null && h.productosJson!.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(h.productosJson!);
        for (var item in decoded) {
          final importedP = Producto.fromMap(item as Map<String, dynamic>);
          importedP.id = null; 
          importedP.comprado = false;
        
          final index = _productos.indexWhere((p) => p.nombre.toLowerCase().trim() == importedP.nombre.toLowerCase().trim());
          if (index != -1) {
            final pBase = _productos[index];
            pBase.cantidad += importedP.cantidad;
            await DBService.instance.update(pBase);
          } else {
            final nuevoP = await DBService.instance.create(importedP);
            _productos.add(nuevoP);
          }
        }
      }
    } catch (e) {
      debugPrint("Error cargando historial: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
