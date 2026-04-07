import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/producto.dart';

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
      version: 1,
      onCreate: _createDB,
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
        prioridad TEXT NOT NULL
      )
    ''');
  }

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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
