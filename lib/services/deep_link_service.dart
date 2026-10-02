import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._init();
  DeepLinkService._init();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  // Notificador para informar cuando llega un PIN vía enlace
  final ValueNotifier<String?> pinRecibidoNotifier = ValueNotifier<String?>(null);

  /// Extrae el PIN desde un objeto [Uri] soportando:
  /// - https://smartcart-a4013.web.app/join?pin=ABCDEF
  /// - smartcart://join?pin=ABCDEF
  /// - https://smartcart-a4013.web.app/join/ABCDEF
  /// - smartcart://join/ABCDEF
  static String? extraerPinDeUri(Uri uri) {
    // 1. Buscar en query parameters
    final pinQuery = uri.queryParameters['pin'] ?? uri.queryParameters['code'];
    if (pinQuery != null && pinQuery.trim().isNotEmpty) {
      final clean = pinQuery.trim().toUpperCase();
      if (RegExp(r'^[A-Z0-9]{4,8}$').hasMatch(clean)) {
        return clean;
      }
    }

    // 2. Buscar en path segments (ej: /join/ABCDEF)
    if (uri.pathSegments.isNotEmpty) {
      for (final segment in uri.pathSegments) {
        final clean = segment.trim().toUpperCase();
        if (clean != 'JOIN' && RegExp(r'^[A-Z0-9]{4,8}$').hasMatch(clean)) {
          return clean;
        }
      }
    }

    return null;
  }

  /// Inicializa la escucha de enlaces entrantes (Cold start y Warm start)
  Future<void> inicializar({Function(String pin)? onPinDetectado}) async {
    _appLinks = AppLinks();

    // 1. Manejo en caliente (App en segundo plano o abierta)
    _linkSubscription = _appLinks?.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _procesarUri(uri, onPinDetectado);
      }
    }, onError: (err) {
      debugPrint('Error en stream de deep link: $err');
    });

    // 2. Manejo en frío (App cerrada que se abre al tocar el enlace)
    try {
      final Uri? initialUri = await _appLinks?.getInitialLink();
      if (initialUri != null) {
        _procesarUri(initialUri, onPinDetectado);
      }
    } catch (e) {
      debugPrint('Error obteniendo initial deep link: $e');
    }
  }

  void _procesarUri(Uri uri, Function(String pin)? onPinDetectado) {
    final pin = extraerPinDeUri(uri);
    if (pin != null) {
      debugPrint('🔗 Deep Link detectado con PIN: $pin');
      pinRecibidoNotifier.value = pin;
      if (onPinDetectado != null) {
        onPinDetectado(pin);
      }
    }
  }

  void limpiarPinPendiente() {
    pinRecibidoNotifier.value = null;
  }

  void dispose() {
    _linkSubscription?.cancel();
    pinRecibidoNotifier.dispose();
  }
}
