import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/producto.dart';
import '../models/historial_compra.dart';

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
      version: 3,
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
        cantidadProductos INTEGER NOT NULL
      )
    ''');
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
          cantidadProductos INTEGER NOT NULL
        )
      ''');
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
