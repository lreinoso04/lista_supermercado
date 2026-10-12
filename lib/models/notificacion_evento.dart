import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'producto.dart';

enum TipoNotificacionLista {
  productoAgregado,
  productoComprado,
  productoDesmarcado,
  productoEditado,
  productoEliminado,
  compraFinalizada,
  listaReiniciada,
  listaVaciada,
}

class NotificacionEvento {
  final String id;
  final String autorUid;
  final String autorNombre;
  final TipoNotificacionLista tipo;
  final String? productoNombre;
  final String? detalle;
  final DateTime timestamp;

  NotificacionEvento({
    String? id,
    required this.autorUid,
    required this.autorNombre,
    required this.tipo,
    this.productoNombre,
    this.detalle,
    DateTime? timestamp,
  })  : id = (id != null && id.isNotEmpty) ? id : Producto.generarUuid(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'autorUid': autorUid,
      'autorNombre': autorNombre,
      'tipo': tipo.name,
      'productoNombre': productoNombre,
      'detalle': detalle,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory NotificacionEvento.fromMap(Map<String, dynamic> map) {
    TipoNotificacionLista tipoParsed;
    final tipoRaw = map['tipo'] as String?;
    try {
      tipoParsed = TipoNotificacionLista.values.firstWhere(
        (t) => t.name == tipoRaw,
        orElse: () => TipoNotificacionLista.productoEditado,
      );
    } catch (_) {
      tipoParsed = TipoNotificacionLista.productoEditado;
    }

    DateTime parsedTimestamp;
    final rawTs = map['timestamp'];
    if (rawTs is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is String) {
      parsedTimestamp = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return NotificacionEvento(
      id: map['id'] as String?,
      autorUid: map['autorUid'] as String? ?? 'desconocido',
      autorNombre: map['autorNombre'] as String? ?? 'Un miembro',
      tipo: tipoParsed,
      productoNombre: map['productoNombre'] as String?,
      detalle: map['detalle'] as String?,
      timestamp: parsedTimestamp,
    );
  }

  String obtenerTitulo() {
    switch (tipo) {
      case TipoNotificacionLista.productoAgregado:
        return 'Producto agregado';
      case TipoNotificacionLista.productoComprado:
        return 'Producto comprado';
      case TipoNotificacionLista.productoDesmarcado:
        return 'Producto desmarcado';
      case TipoNotificacionLista.productoEditado:
        return 'Producto editado';
      case TipoNotificacionLista.productoEliminado:
        return 'Producto eliminado';
      case TipoNotificacionLista.compraFinalizada:
        return '¡Compra finalizada!';
      case TipoNotificacionLista.listaReiniciada:
        return 'Lista reiniciada';
      case TipoNotificacionLista.listaVaciada:
        return 'Lista vaciada';
    }
  }

  String obtenerDescripcion() {
    final prod = productoNombre != null && productoNombre!.isNotEmpty
        ? '"$productoNombre"'
        : 'un producto';
    final extra = detalle != null && detalle!.isNotEmpty ? ' ($detalle)' : '';

    switch (tipo) {
      case TipoNotificacionLista.productoAgregado:
        return '$autorNombre agregó $prod$extra';
      case TipoNotificacionLista.productoComprado:
        return '$autorNombre marcó como comprado $prod$extra';
      case TipoNotificacionLista.productoDesmarcado:
        return '$autorNombre desmarcó $prod$extra';
      case TipoNotificacionLista.productoEditado:
        return '$autorNombre modificó $prod$extra';
      case TipoNotificacionLista.productoEliminado:
        return '$autorNombre eliminó $prod de la lista';
      case TipoNotificacionLista.compraFinalizada:
        return '$autorNombre finalizó la compra$extra. ¡Guardada en tu historial!';
      case TipoNotificacionLista.listaReiniciada:
        return '$autorNombre desmarcó todos los productos';
      case TipoNotificacionLista.listaVaciada:
        return '$autorNombre vació la lista de compras';
    }
  }

  IconData obtenerIcono() {
    switch (tipo) {
      case TipoNotificacionLista.productoAgregado:
        return Icons.add_shopping_cart_rounded;
      case TipoNotificacionLista.productoComprado:
        return Icons.check_circle_rounded;
      case TipoNotificacionLista.productoDesmarcado:
        return Icons.remove_shopping_cart_rounded;
      case TipoNotificacionLista.productoEditado:
        return Icons.edit_note_rounded;
      case TipoNotificacionLista.productoEliminado:
        return Icons.delete_outline_rounded;
      case TipoNotificacionLista.compraFinalizada:
        return Icons.shopping_bag_rounded;
      case TipoNotificacionLista.listaReiniciada:
        return Icons.refresh_rounded;
      case TipoNotificacionLista.listaVaciada:
        return Icons.cleaning_services_rounded;
    }
  }

  Color obtenerColor() {
    switch (tipo) {
      case TipoNotificacionLista.productoAgregado:
        return Colors.blue;
      case TipoNotificacionLista.productoComprado:
        return kVerde;
      case TipoNotificacionLista.productoDesmarcado:
        return Colors.blueGrey;
      case TipoNotificacionLista.productoEditado:
        return Colors.deepPurple;
      case TipoNotificacionLista.productoEliminado:
        return Colors.redAccent;
      case TipoNotificacionLista.compraFinalizada:
        return kNaranja;
      case TipoNotificacionLista.listaReiniciada:
        return Colors.amber.shade800;
      case TipoNotificacionLista.listaVaciada:
        return Colors.red.shade400;
    }
  }

  String tiempoRelativo() {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(timestamp);

    if (diferencia.inSeconds < 45) {
      return 'Hace un momento';
    } else if (diferencia.inMinutes < 60) {
      final min = diferencia.inMinutes;
      return 'Hace $min ${min == 1 ? 'minuto' : 'minutos'}';
    } else if (diferencia.inHours < 24) {
      final h = diferencia.inHours;
      return 'Hace $h ${h == 1 ? 'hora' : 'horas'}';
    } else {
      final d = diferencia.inDays;
      if (d == 1) return 'Ayer';
      return 'Hace $d días';
    }
  }
}
