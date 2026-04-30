import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String generarPin() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Stream<List<Producto>> streamLista(String pin) {
    return _db.collection('listas').doc(pin).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return [];
      final data = doc.data()!;
      final prods = data['productos'] as List<dynamic>? ?? [];
      return prods.map((e) => Producto.fromMap(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> syncListaCompleta(String pin, List<Producto> productos) async {
    final jsonList = productos.map((p) => p.toMap()).toList();
    await _db.collection('listas').doc(pin).set({
      'productos': jsonList,
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    });
  }
  
  Future<bool> verificarPin(String pin) async {
    final doc = await _db.collection('listas').doc(pin).get();
    return doc.exists;
  }
}
