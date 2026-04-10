import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/producto.dart';
import '../models/historial_compra.dart';
import '../models/categoria_model.dart';
import 'package:flutter/material.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('supermercado.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        comprado INTEGER NOT NULL,
        prioridad TEXT NOT NULL,
        precioEstimado REAL NOT NULL DEFAULT 0.0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE catalogo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        prioridad TEXT NOT NULL,
        precioEstimado REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE historial_compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        cantidadProductos INTEGER NOT NULL,
        productosJson TEXT
      )
    ''');
    
    await _initCategoriasTable(db);
  }

  Future<void> _initCategoriasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        iconCode INTEGER NOT NULL
      )
    ''');

    final batch = db.batch();
    final defaultCats = [
      {'nombre': 'Lácteos',          'iconCode': Icons.egg_outlined.codePoint,            'colorValue': 0xFF29B6F6},
      {'nombre': 'Carnes',           'iconCode': Icons.restaurant_outlined.codePoint,     'colorValue': 0xFFEF5350},
      {'nombre': 'Frutas y Verduras','iconCode': Icons.eco_outlined.codePoint,            'colorValue': 0xFF66BB6A},
      {'nombre': 'Panadería',        'iconCode': Icons.bakery_dining_outlined.codePoint,  'colorValue': 0xFFFF8A65},
      {'nombre': 'Granos',           'iconCode': Icons.grain.codePoint,                   'colorValue': 0xFFFFCA28},
      {'nombre': 'Bebidas',          'iconCode': Icons.local_drink_outlined.codePoint,    'colorValue': 0xFF7E57C2},
      {'nombre': 'Limpieza',         'iconCode': Icons.clean_hands_outlined.codePoint,    'colorValue': 0xFF26C6DA},
      {'nombre': 'Otros',            'iconCode': Icons.shopping_bag_outlined.codePoint,   'colorValue': 0xFF8D6E63},
    ];

    for (var cat in defaultCats) {
      batch.insert('categorias', cat);
    }
    await batch.commit();
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE productos ADD COLUMN precioEstimado REAL NOT NULL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS catalogo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          categoria TEXT NOT NULL,
          prioridad TEXT NOT NULL,
          precioEstimado REAL NOT NULL DEFAULT 0.0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historial_compras (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          total REAL NOT NULL,
          cantidadProductos INTEGER NOT NULL,
          productosJson TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      // Intento seguro por si la columna ya existe de alguna caída previa
      try {
        await db.execute('ALTER TABLE historial_compras ADD COLUMN productosJson TEXT');
      } catch (e) {
        // La columna posiblemente ya exista, continuamos.
      }
    }
    if (oldVersion < 5) {
      await _initCategoriasTable(db);
    }
  }

  // --- PRODUCTOS CRUD ---
  Future<Producto> create(Producto producto) async {
    final db = await instance.database;
    final id = await db.insert('productos', producto.toMap());
    producto.id = id;
    return producto;
  }

  Future<List<Producto>> readAllProductos() async {
    final db = await instance.database;
    final result = await db.query('productos', orderBy: 'id ASC');
    return result.map((json) => Producto.fromMap(json)).toList();
  }

  Future<int> update(Producto producto) async {
    final db = await instance.database;
    return db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllProductos() async {
    final db = await instance.database;
    return await db.delete('productos');
  }

  // --- CATALOGO CRUD ---
  Future<void> upsertCatalogo(Producto p) async {
    final db = await instance.database;
    final res = await db.query('catalogo', where: 'nombre = ? COLLATE NOCASE', whereArgs: [p.nombre]);
    
    if (res.isNotEmpty) {
      final id = res.first['id'] as int;
      await db.update('catalogo', {
        'categoria': p.categoria,
        'prioridad': p.prioridad,
        'precioEstimado': p.precioEstimado,
      }, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.insert('catalogo', {
        'nombre': p.nombre,
        'categoria': p.categoria,
        'prioridad': p.prioridad,
        'precioEstimado': p.precioEstimado,
      });
    }
  }

  Future<List<Producto>> readAllCatalogo() async {
    final db = await instance.database;
    final result = await db.query('catalogo', orderBy: 'nombre ASC');
    return result.map((json) => Producto(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String,
      prioridad: json['prioridad'] as String,
      precioEstimado: (json['precioEstimado'] as num).toDouble(),
      cantidad: 1,
      comprado: false,
    )).toList();
  }

  // --- HISTORIAL CRUD ---
  Future<HistorialCompra> createHistorial(HistorialCompra hc) async {
    final db = await instance.database;
    final id = await db.insert('historial_compras', hc.toMap());
    hc.id = id;
    return hc;
  }

  Future<List<HistorialCompra>> readAllHistorial() async {
    final db = await instance.database;
    final result = await db.query('historial_compras', orderBy: 'id DESC');
    return result.map((json) => HistorialCompra.fromMap(json)).toList();
  }

  Future<void> deleteHistorial(int id) async {
    final db = await instance.database;
    await db.delete('historial_compras', where: 'id = ?', whereArgs: [id]);
  }

  // --- CATEGORIAS CRUD ---
  Future<CategoriaModel> createCategoria(CategoriaModel categoria) async {
    final db = await instance.database;
    final id = await db.insert('categorias', categoria.toMap());
    categoria.id = id;
    return categoria;
  }

  Future<List<CategoriaModel>> readAllCategorias() async {
    final db = await instance.database;
    final result = await db.query('categorias', orderBy: 'id ASC');
    return result.map((json) => CategoriaModel.fromMap(json)).toList();
  }

  Future<int> updateCategoria(CategoriaModel categoria) async {
    final db = await instance.database;
    return db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> deleteCategoria(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
