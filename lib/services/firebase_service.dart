import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../models/historial_compra.dart';
import '../models/categoria_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  FirebaseFirestore? _customDb;
  
  @visibleForTesting
  set customFirestore(FirebaseFirestore db) => _customDb = db;

  FirebaseFirestore get _db {
    if (_customDb != null) return _customDb!;
    return FirebaseFirestore.instance;
  }

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

  // --- STREAM EN VIVO DE LISTAS COMPARTIDAS ---

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamListaDoc(String pin) {
    final cleanPin = pin.trim().toUpperCase();
    return _db.collection('listas').doc(cleanPin).snapshots();
  }

  Stream<List<Producto>> streamLista(String pin) {
    return streamListaDoc(pin).map((doc) {
      if (!doc.exists || doc.data() == null) return [];
      final data = doc.data()!;
      final prods = data['productos'] as List<dynamic>? ?? [];
      return prods.map((e) => Producto.fromMap(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> syncListaCompleta(
    String pin,
    List<Producto> productos, {
    List<CategoriaModel>? categorias,
  }) async {
    final cleanPin = pin.trim().toUpperCase();
    final jsonProds = productos.map((p) => p.toMap()).toList();
    final jsonCats = categorias?.map((c) => c.toMap()).toList() ?? [];

    await _db.collection('listas').doc(cleanPin).set({
      'productos': jsonProds,
      'categorias': jsonCats,
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  Future<bool> verificarPin(String pin) async {
    final cleanPin = pin.trim().toUpperCase();
    final doc = await _db.collection('listas').doc(cleanPin).get();
    return doc.exists;
  }

  // --- GESTIÓN DE MIEMBROS EN LISTAS COMPARTIDAS ---

  Future<void> unirseALista(String pin, String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final cleanPin = pin.trim().toUpperCase();
      await _db.collection('listas').doc(cleanPin).set({
        'miembros': FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error registrando miembro en lista $pin: $e');
    }
  }

  // --- FINALIZACIÓN DE COMPRAS COMPARTIDAS MULTI-DISPOSITIVO ---

  Future<void> registrarCompraFinalizadaCompartida({
    required String pin,
    required HistorialCompra historial,
    required String? userId,
    required String? userNombre,
  }) async {
    final cleanPin = pin.trim().toUpperCase();
    final docRef = _db.collection('listas').doc(cleanPin);

    // 1. Guardar evento en la subcolección de compras de la lista
    final compraData = historial.toMap();
    compraData['finalizadoPorUid'] = userId;
    compraData['finalizadoPorNombre'] = userNombre ?? 'Familiar';
    compraData['timestamp'] = FieldValue.serverTimestamp();

    await docRef.collection('historial').doc(historial.uuid).set(compraData);

    // 2. Notificar en el documento principal para activación de streams en otros dispositivos
    await docRef.set({
      'ultimaCompraFinalizada': {
        'uuid': historial.uuid,
        'fecha': historial.fecha,
        'total': historial.total,
        'cantidadProductos': historial.cantidadProductos,
        'productosJson': historial.productosJson,
        'pinLista': cleanPin,
        'finalizadoPorUid': userId,
        'finalizadoPorNombre': userNombre ?? 'Familiar',
      },
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Replicar la compra a los historiales personales de los miembros autenticados
    try {
      final snap = await docRef.get();
      if (snap.exists && snap.data() != null) {
        final miembros = (snap.data()!['miembros'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];

        // Si el usuario actual no estaba en miembros, añadirlo
        if (userId != null && !miembros.contains(userId)) {
          miembros.add(userId);
        }

        final batch = _db.batch();
        for (final mUid in miembros) {
          final userHistRef = _db
              .collection('usuarios')
              .doc(mUid)
              .collection('historial_compras')
              .doc(historial.uuid);
          batch.set(userHistRef, compraData);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error replicando compra a miembros de la lista: $e');
    }
  }

  // --- SINCRONIZACIÓN DE HISTORIAL DE COMPRAS POR USUARIO ---

  Future<void> guardarHistorialUsuario(String userId, HistorialCompra historial) async {
    try {
      final docData = historial.toMap();
      docData['timestamp'] = FieldValue.serverTimestamp();
      await _db
          .collection('usuarios')
          .doc(userId)
          .collection('historial_compras')
          .doc(historial.uuid)
          .set(docData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando historial de usuario en Firebase: $e');
    }
  }

  Future<List<HistorialCompra>> obtenerHistorialUsuario(String userId) async {
    try {
      final querySnap = await _db
          .collection('usuarios')
          .doc(userId)
          .collection('historial_compras')
          .get();

      return querySnap.docs.map((doc) {
        final data = doc.data();
        return HistorialCompra.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo historial de usuario en Firebase: $e');
      return [];
    }
  }

  Future<void> eliminarHistorialUsuario(String userId, String uuid) async {
    try {
      await _db
          .collection('usuarios')
          .doc(userId)
          .collection('historial_compras')
          .doc(uuid)
          .delete();
    } catch (e) {
      debugPrint('Error eliminando historial de usuario en Firebase: $e');
    }
  }

  /// Sincronización bidireccional entre SQLite local y Firestore
  /// Sube compras locales faltantes y devuelve compras remotas para guardar en SQLite
  Future<List<HistorialCompra>> sincronizarHistorialUsuario({
    required String userId,
    required List<HistorialCompra> locales,
  }) async {
    try {
      final remotas = await obtenerHistorialUsuario(userId);
      final setUuidsRemotos = remotas.map((r) => r.uuid).toSet();
      final setUuidsLocales = locales.map((l) => l.uuid).toSet();

      // 1. Subir locales que faltan en la nube
      for (final local in locales) {
        if (!setUuidsRemotos.contains(local.uuid)) {
          await guardarHistorialUsuario(userId, local);
        }
      }

      // 2. Retornar remotas que faltan en local
      final faltantesEnLocal = remotas.where((r) => !setUuidsLocales.contains(r.uuid)).toList();
      return faltantesEnLocal;
    } catch (e) {
      debugPrint('Error en sincronización bidireccional de historial: $e');
      return [];
    }
  }
}
