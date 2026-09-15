import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String generarPin() {
    // Caracteres legibles sin 0/O ni 1/I para evitar confusiones
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<String> generarPinUnico() async {
    for (int i = 0; i < 5; i++) {
      final pin = generarPin();
      final existe = await verificarPin(pin);
      if (!existe) return pin;
    }
    return generarPin();
  }

  Stream<List<Producto>> streamLista(String pin) {
    final cleanPin = pin.trim().toUpperCase();
    return _db.collection('listas').doc(cleanPin).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return [];
      final data = doc.data()!;
      final prods = data['productos'] as List<dynamic>? ?? [];
      return prods.map((e) => Producto.fromMap(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> syncListaCompleta(String pin, List<Producto> productos) async {
    final cleanPin = pin.trim().toUpperCase();
    final jsonList = productos.map((p) => p.toMap()).toList();
    await _db.collection('listas').doc(cleanPin).set({
      'productos': jsonList,
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    });
  }
  
  Future<bool> verificarPin(String pin) async {
    final cleanPin = pin.trim().toUpperCase();
    final doc = await _db.collection('listas').doc(cleanPin).get();
    return doc.exists;
  }
}
