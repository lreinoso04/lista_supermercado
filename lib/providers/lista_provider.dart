import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';
import '../models/historial_compra.dart';
import '../models/categoria_model.dart';
import '../models/notificacion_evento.dart';
import '../services/db_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class ListaProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Producto> _catalogo = [];
  List<CategoriaModel> _categorias = [];
  List<NotificacionEvento> _actividadReciente = [];
  bool _isLoading = false;
  String? _pinActual;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subFirebase;
  bool _isSyncing = false;
  bool _esPrimerSnapshotStream = true;
  String? _ultimoCambioIdProcesado;

  // Notificador para eventos de compras finalizadas por otros miembros en listas compartidas
  final ValueNotifier<String?> compraCompartidaFinalizadaNotifier = ValueNotifier<String?>(null);

  List<Producto> get productos => _productos;
  List<Producto> get catalogo => _catalogo;
  List<CategoriaModel> get categorias => _categorias;
  List<NotificacionEvento> get actividadReciente => _actividadReciente;
  bool get isLoading => _isLoading;
  String? get pinActual => _pinActual;

  Future<Map<String, String>> _obtenerActorInfo() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      final nombre = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Familiar');
      return {'uid': user.uid, 'nombre': nombre};
    }
    final prefs = await SharedPreferences.getInstance();
    var guestId = prefs.getString('guest_actor_uuid');
    if (guestId == null || guestId.isEmpty) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('guest_actor_uuid', guestId);
    }
    final guestNombre = prefs.getString('guest_user_name') ?? 'Invitado';
    return {'uid': guestId, 'nombre': guestNombre};
  }

  void _syncNube({NotificacionEvento? eventoCambio}) async {
    if (_pinActual != null) {
      _isSyncing = true;
      await FirebaseService.instance.syncListaCompleta(
        _pinActual!,
        _productos,
        categorias: _categorias,
        eventoCambio: eventoCambio,
      );
      _isSyncing = false;
    }
  }

  void _escucharCambiosFirebase(String pin) {
    _subFirebase?.cancel();
    _subFirebase = FirebaseService.instance.streamListaDoc(pin).listen((doc) async {
      if (_isSyncing) return;
      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final prodsRaw = data['productos'] as List<dynamic>? ?? [];
      final remotos = prodsRaw.map((e) => Producto.fromMap(e as Map<String, dynamic>)).toList();
      final catsRaw = data['categorias'] as List<dynamic>? ?? [];

      // --- 1. Sincronización automática de Categorías (Req 3) ---
      bool categoriasActualizadas = false;
      for (final cJson in catsRaw) {
        if (cJson is Map<String, dynamic>) {
          final catRemota = CategoriaModel.fromMap(cJson);
          final existe = _categorias.any(
            (c) => c.nombre.trim().toLowerCase() == catRemota.nombre.trim().toLowerCase(),
          );
          if (!existe) {
            catRemota.id = null; // SQLite autoincrement ID
            final nuevaCat = await DBService.instance.createCategoria(catRemota);
            _categorias.add(nuevaCat);
            categoriasActualizadas = true;
          }
        }
      }

      // --- 2. Sincronización de Productos ---
      final locales = await DBService.instance.readAllProductos();
      final localMap = {for (var p in locales) p.uuid: p};
      final remotosUuids = remotos.map((r) => r.uuid).toSet();

      bool cambio = false;

      // Eliminar de local lo que no está en remoto
      for (var l in locales) {
        if (!remotosUuids.contains(l.uuid)) {
          if (l.id != null) {
            await DBService.instance.delete(l.id!);
          } else {
            await DBService.instance.deleteByUuid(l.uuid);
          }
          _productos.removeWhere((p) => p.uuid == l.uuid);
          cambio = true;
        }
      }

      // Agregar o actualizar locales con los remotos
      for (var r in remotos) {
        final localProd = localMap[r.uuid];
        if (localProd != null) {
          if (localProd.nombre != r.nombre ||
              localProd.comprado != r.comprado ||
              localProd.cantidad != r.cantidad ||
              localProd.prioridad != r.prioridad ||
              localProd.precioEstimado != r.precioEstimado ||
              localProd.categoria != r.categoria ||
              localProd.tipoLista != r.tipoLista) {
            
            localProd.nombre = r.nombre;
            localProd.comprado = r.comprado;
            localProd.cantidad = r.cantidad;
            localProd.prioridad = r.prioridad;
            localProd.precioEstimado = r.precioEstimado;
            localProd.categoria = r.categoria;
            localProd.tipoLista = r.tipoLista;

            await DBService.instance.update(localProd);

            final idx = _productos.indexWhere((p) => p.uuid == localProd.uuid);
            if (idx != -1) {
              _productos[idx] = localProd;
            }
            cambio = true;
          }
        } else {
          r.id = null;
          final nuevoP = await DBService.instance.create(r);
          _productos.add(nuevoP);
          cambio = true;
        }
      }

      // --- 3. Detección de Compra Compartida Finalizada (Req 2) ---
      final isFinalizada = data['finalizada'] == true;
      final ultimaCompra = data['ultimaCompraFinalizada'] as Map<String, dynamic>?;
      if (ultimaCompra != null || isFinalizada) {
        String? nombreFinalizador;
        if (ultimaCompra != null) {
          final String? compraUuid = ultimaCompra['uuid'] as String?;
          if (compraUuid != null && compraUuid.isNotEmpty) {
            final yaExisteLocal = await DBService.instance.historialExistsByUuid(compraUuid);
            if (!yaExisteLocal) {
              final nuevaCompra = HistorialCompra.fromMap(ultimaCompra);
              await DBService.instance.upsertHistorial(nuevaCompra);

              // Sincronizar en Firestore del usuario si está autenticado
              final currentUser = AuthService.instance.currentUser;
              if (currentUser != null) {
                await FirebaseService.instance.guardarHistorialUsuario(currentUser.uid, nuevaCompra);
              }
            }
          }
          nombreFinalizador = ultimaCompra['finalizadoPorNombre'] ?? 'Un familiar';
        }

        // Limpiar productos locales en SQLite y en memoria del participante
        await DBService.instance.deleteAllProductos();
        _productos.clear();
        _actividadReciente.clear();

        if (nombreFinalizador != null) {
          compraCompartidaFinalizadaNotifier.value =
              '🛒 ¡$nombreFinalizador ha finalizado la compra! Guardada en tu historial.';
        }

        // Desvincular de la lista en la nube para limpiar la pantalla y no quedar enlazado
        desconectarFirebase();
        notifyListeners();
        return;
      }

      // --- 4. Sincronización de Actividad y Notificaciones Bidireccionales ---
      final actRaw = data['actividadReciente'] as List<dynamic>? ?? [];
      _actividadReciente = actRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => NotificacionEvento.fromMap(m))
          .toList();

      final ultimoCambioRaw = data['ultimoCambio'] as Map<String, dynamic>?;
      if (ultimoCambioRaw != null) {
        final evento = NotificacionEvento.fromMap(ultimoCambioRaw);
        if (_esPrimerSnapshotStream) {
          _ultimoCambioIdProcesado = evento.id;
        } else if (evento.id != _ultimoCambioIdProcesado) {
          _ultimoCambioIdProcesado = evento.id;
          NotificationService.instance.procesarEvento(evento);
        }
      }
      _esPrimerSnapshotStream = false;

      if (cambio || categoriasActualizadas) {
        notifyListeners();
      }
    });
  }

  Future<void> conectarFirebase(String pin) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cleanPin = pin.trim().toUpperCase();
      final datosLista = await FirebaseService.instance.obtenerDatosLista(cleanPin);
      if (datosLista == null) throw Exception('El PIN no existe.');
      if (datosLista['finalizada'] == true) {
        throw Exception('Esta lista de compras ya fue finalizada y cerrada.');
      }

      _pinActual = cleanPin;
      _productos.clear();
      _actividadReciente.clear();
      _esPrimerSnapshotStream = true;
      _ultimoCambioIdProcesado = null;
      await DBService.instance.deleteAllProductos();
      notifyListeners();

      // Registrar membresía en la lista
      final user = AuthService.instance.currentUser;
      await FirebaseService.instance.unirseALista(cleanPin, user?.uid);

      _escucharCambiosFirebase(cleanPin);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> compartirListaEnNube() async {
    final pin = await FirebaseService.instance.generarPinUnico();
    _pinActual = pin;
    _actividadReciente.clear();
    _esPrimerSnapshotStream = true;
    _ultimoCambioIdProcesado = null;
    _syncNube();

    final user = AuthService.instance.currentUser;
    await FirebaseService.instance.unirseALista(pin, user?.uid);
    
    _escucharCambiosFirebase(pin);
    notifyListeners();
    return pin;
  }

  void desconectarFirebase() {
    _pinActual = null;
    _subFirebase?.cancel();
    _actividadReciente.clear();
    _esPrimerSnapshotStream = true;
    _ultimoCambioIdProcesado = null;
    notifyListeners();
  }

  /// Limpia los datos de la base de datos local SQLite y estado en memoria al cerrar sesión
  /// para evitar fugas hacia el modo invitado o hacia otros usuarios.
  Future<void> limpiarDatosLocalesPorCierreDeSesion() async {
    desconectarFirebase();
    _productos.clear();
    _actividadReciente.clear();
    _ultimoCambioIdProcesado = null;
    await DBService.instance.limpiarDatosUsuario();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_session_uid');
    notifyListeners();
  }

  /// Verifica si la sesión activa actual difiere de la sesión anterior guardada.
  /// Si cambió (ej: de Usuario A a Invitado, o de Invitado a Usuario B),
  /// limpia la base de datos local para garantizar el aislamiento absoluto sin cruce de datos.
  Future<void> verificarYLimpiarSesionSiCambioUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUid = prefs.getString('current_session_uid');
      final currentUser = AuthService.instance.currentUser;
      final currentUid = currentUser?.uid ?? (prefs.getBool('smartcart_guest_mode') == true ? 'guest' : null);

      if (currentUid != null) {
        if (lastUid != null && lastUid != currentUid) {
          debugPrint('Cambio de sesión detectado ($lastUid -> $currentUid). Limpiando base de datos local para evitar cruce de datos.');
          desconectarFirebase();
          _productos.clear();
          _actividadReciente.clear();
          _ultimoCambioIdProcesado = null;
          await DBService.instance.limpiarDatosUsuario();
        }
        await prefs.setString('current_session_uid', currentUid);
      }
    } catch (e) {
      debugPrint('Error verificando cambio de sesión: $e');
    }
  }

  double get gastoTotal {
    return productos
        .where((p) => p.comprado)
        .fold(0.0, (subtotal, p) => subtotal + (p.precioEstimado * p.cantidad));
  }

  Future<void> cargarListas() async {
    _isLoading = true;
    notifyListeners();

    await verificarYLimpiarSesionSiCambioUsuario();

    _productos = await DBService.instance.readAllProductos();
    _catalogo = await DBService.instance.readAllCatalogo();
    _categorias = await DBService.instance.readAllCategorias();

    _isLoading = false;
    notifyListeners();

    // Sincronizar historial con Firebase si el usuario está conectado
    await sincronizarHistorialConFirebase();
  }

  Future<void> sincronizarHistorialConFirebase() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    try {
      final locales = await DBService.instance.readAllHistorial();
      final remotasFaltantes = await FirebaseService.instance.sincronizarHistorialUsuario(
        userId: user.uid,
        locales: locales,
      );
      for (final r in remotasFaltantes) {
        await DBService.instance.upsertHistorial(r);
      }
    } catch (e) {
      debugPrint('Error sincronizando historial con Firebase: $e');
    }
  }

  Future<void> agregarProducto(Producto p) async {
    final nuevoP = await DBService.instance.create(p);
    _productos.add(nuevoP);
    await _upsertCatalogo(nuevoP);
    notifyListeners();
    final actor = await _obtenerActorInfo();
    _syncNube(
      eventoCambio: NotificacionEvento(
        autorUid: actor['uid']!,
        autorNombre: actor['nombre']!,
        tipo: TipoNotificacionLista.productoAgregado,
        productoNombre: p.nombre,
        detalle: 'x${p.cantidad}',
      ),
    );
  }

  Future<void> toggleComprado(Producto p) async {
    p.comprado = !p.comprado;
    await DBService.instance.update(p);
    
    final index = _productos.indexWhere((item) => item.uuid == p.uuid);
    if (index != -1) {
      _productos[index] = p;
      notifyListeners();
      final actor = await _obtenerActorInfo();
      _syncNube(
        eventoCambio: NotificacionEvento(
          autorUid: actor['uid']!,
          autorNombre: actor['nombre']!,
          tipo: p.comprado ? TipoNotificacionLista.productoComprado : TipoNotificacionLista.productoDesmarcado,
          productoNombre: p.nombre,
        ),
      );
    }
  }

  Future<void> actualizarProducto(Producto p) async {
    await DBService.instance.update(p);
    final index = _productos.indexWhere((item) => item.uuid == p.uuid);
    if (index != -1) {
      _productos[index] = p;
      await _upsertCatalogo(p);
      notifyListeners();
      final actor = await _obtenerActorInfo();
      _syncNube(
        eventoCambio: NotificacionEvento(
          autorUid: actor['uid']!,
          autorNombre: actor['nombre']!,
          tipo: TipoNotificacionLista.productoEditado,
          productoNombre: p.nombre,
          detalle: 'x${p.cantidad}',
        ),
      );
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
    } else {
      await DBService.instance.deleteByUuid(p.uuid);
    }
    _productos.removeWhere((item) => item.uuid == p.uuid);
    notifyListeners();
    final actor = await _obtenerActorInfo();
    _syncNube(
      eventoCambio: NotificacionEvento(
        autorUid: actor['uid']!,
        autorNombre: actor['nombre']!,
        tipo: TipoNotificacionLista.productoEliminado,
        productoNombre: p.nombre,
      ),
    );
  }

  // --- CATEGORIAS ---
  Future<void> agregarCategoria(CategoriaModel c) async {
    final nueva = await DBService.instance.createCategoria(c);
    _categorias.add(nueva);
    notifyListeners();
    _syncNube();
  }

  Future<void> actualizarCategoria(CategoriaModel c) async {
    await DBService.instance.updateCategoria(c);
    final idx = _categorias.indexWhere((cat) => cat.id == c.id);
    if (idx != -1) {
      _categorias[idx] = c;
      notifyListeners();
      _syncNube();
    }
  }

  Future<void> eliminarCategoria(CategoriaModel c) async {
    if (c.id != null) {
      await DBService.instance.deleteCategoria(c.id!);
      _categorias.removeWhere((cat) => cat.id == c.id);
      notifyListeners();
      _syncNube();
    }
  }

  Future<void> reiniciarLista() async {
    _isLoading = true;
    notifyListeners();
    try {
      for (var p in _productos) {
        if (p.comprado) {
          p.comprado = false;
          await DBService.instance.update(p);
        }
      }
      final actor = await _obtenerActorInfo();
      _syncNube(
        eventoCambio: NotificacionEvento(
          autorUid: actor['uid']!,
          autorNombre: actor['nombre']!,
          tipo: TipoNotificacionLista.listaReiniciada,
        ),
      );
    } catch (e) {
      debugPrint('Error reiniciando lista: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> vaciarListaDesdeCero() async {
    _isLoading = true;
    notifyListeners();
    try {
      final productosActuales = _productos.toList();
      for (var p in productosActuales) {
        if (p.id != null) {
          await DBService.instance.delete(p.id!);
        } else {
          await DBService.instance.deleteByUuid(p.uuid);
        }
        _productos.removeWhere((item) => item.uuid == p.uuid);
      }
      final actor = await _obtenerActorInfo();
      _syncNube(
        eventoCambio: NotificacionEvento(
          autorUid: actor['uid']!,
          autorNombre: actor['nombre']!,
          tipo: TipoNotificacionLista.listaVaciada,
        ),
      );
    } catch (e) {
      debugPrint('Error vaciando lista: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marcarTodosComoComprados() async {
    for (var p in _productos) {
      if (!p.comprado) {
        p.comprado = true;
        await DBService.instance.update(p);
      }
    }
    notifyListeners();
    _syncNube();
  }

  Future<int> terminarCompra() async {
    if (_productos.isEmpty) return 0;
    
    _isLoading = true;
    notifyListeners();

    try {
      final comprados = productos.where((p) => p.comprado).toList();

      if (comprados.isNotEmpty) {
        double total = comprados.fold(0.0, (acc, p) => acc + (p.precioEstimado * p.cantidad));
        int cantidad = comprados.fold(0, (acc, p) => acc + p.cantidad);
        final fecha = DateTime.now().toIso8601String();
        final user = AuthService.instance.currentUser;
        final userNombre = user?.displayName ?? user?.email?.split('@').first ?? 'Yo';

        final pinCompartido = _pinActual;

        final nuevoHistorial = HistorialCompra(
          fecha: fecha,
          total: total,
          cantidadProductos: cantidad,
          productosJson: jsonEncode(comprados.map((p) => p.toMap()).toList()),
          pinLista: pinCompartido,
          finalizadoPorNombre: userNombre,
        );

        // 1. Guardar primero en SQLite local (éxito garantizado offline)
        await DBService.instance.createHistorial(nuevoHistorial);

        // Actualizamos catálogo con los productos comprados
        for (var p in comprados) {
          await DBService.instance.upsertCatalogo(p);
        }
        _catalogo = await DBService.instance.readAllCatalogo();

        // 2. Sincronización en la nube protegida e independiente con timeout
        if (user != null) {
          try {
            await FirebaseService.instance
                .guardarHistorialUsuario(user.uid, nuevoHistorial)
                .timeout(const Duration(seconds: 4));
          } catch (e) {
            debugPrint('Aviso: Error sincronizando historial con usuario en nube: $e');
          }
        }

        if (pinCompartido != null) {
          try {
            await FirebaseService.instance
                .registrarCompraFinalizadaCompartida(
                  pin: pinCompartido,
                  historial: nuevoHistorial,
                  userId: user?.uid,
                  userNombre: userNombre,
                )
                .timeout(const Duration(seconds: 4));
          } catch (e) {
            debugPrint('Aviso: Error notificando compra compartida en nube: $e');
          }

          // Para la lista compartida finalizada: limpiar completamente productos y desvincular
          await DBService.instance.deleteAllProductos();
          _productos.clear();
          desconectarFirebase();
        } else {
          // En lista local individual: eliminar solo los comprados
          for (var p in comprados) {
            if (p.id != null) {
              await DBService.instance.delete(p.id!);
            } else {
              await DBService.instance.deleteByUuid(p.uuid);
            }
          }
          _productos.removeWhere((item) => item.comprado);
        }

        return comprados.length;
      }
      return 0;
    } catch (e, stack) {
      debugPrint('Error en terminarCompra: $e\n$stack');
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String exportarListaBase64() {
    final pendientes = productos.where((p) => !p.comprado).toList();
    if (pendientes.isEmpty) return "";
    
    final map = {
      'v': 2,
      'productos': pendientes.map((p) => p.toMap()).toList(),
      'categorias': _categorias.map((c) => c.toMap()).toList(),
    };
    final jsonString = jsonEncode(map);
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
      final dynamic decoded = jsonDecode(jsonString);

      List<dynamic> productosRaw;
      List<dynamic> categoriasRaw = [];

      if (decoded is Map<String, dynamic> && decoded.containsKey('productos')) {
        productosRaw = decoded['productos'] as List<dynamic>? ?? [];
        categoriasRaw = decoded['categorias'] as List<dynamic>? ?? [];
      } else if (decoded is List<dynamic>) {
        productosRaw = decoded;
      } else {
        throw Exception("El código no tiene formato válido.");
      }

      // Sincronizar categorías si venían en el código
      for (final cJson in categoriasRaw) {
        if (cJson is Map<String, dynamic>) {
          final cat = CategoriaModel.fromMap(cJson);
          final existe = _categorias.any((localCat) => localCat.nombre.trim().toLowerCase() == cat.nombre.trim().toLowerCase());
          if (!existe) {
            cat.id = null;
            final inserted = await DBService.instance.createCategoria(cat);
            _categorias.add(inserted);
          }
        }
      }

      for (var item in productosRaw) {
        final importedP = Producto.fromMap(item as Map<String, dynamic>);
        importedP.id = null; // Forza a SQLite a crear una nueva llave primaria
        importedP.uuid = Producto.generarUuid();
        importedP.comprado = false; 
        
        // Creación silente de categoría de respaldo si no existía
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
          importedP.uuid = Producto.generarUuid();
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

  @override
  void dispose() {
    _subFirebase?.cancel();
    compraCompartidaFinalizadaNotifier.dispose();
    super.dispose();
  }
}
