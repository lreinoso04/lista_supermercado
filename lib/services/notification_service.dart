import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notificacion_evento.dart';
import '../widgets/in_app_notification_banner.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;
  bool isAppInForeground = true;

  GlobalKey<NavigatorState>? navigatorKey;
  VoidCallback? onNavigateToLista;

  // Anti-Spam: Buffer y Cooldown
  final List<NotificacionEvento> _bufferEventos = [];
  Timer? _debounceTimer;
  DateTime? _ultimoBannerTimestamp;
  static const Duration _debounceDuration = Duration(milliseconds: 1200);
  static const Duration _cooldownDuration = Duration(milliseconds: 2500);

  // Registro de IDs para evitar duplicados
  final Set<String> _idsProcesados = {};

  // Overlay activo para el banner In-App
  OverlayEntry? _currentOverlay;
  Timer? _overlayDismissTimer;

  bool _mockMode = false;
  @visibleForTesting
  set mockMode(bool v) => _mockMode = v;

  Future<void> inicializar({GlobalKey<NavigatorState>? navKey}) async {
    if (_inicializado) return;
    if (navKey != null) navigatorKey = navKey;

    if (_mockMode) {
      _inicializado = true;
      return;
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          onNavigateToLista?.call();
        },
      );

      // Solicitar permisos en Android 13+
      final androidPlatform = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      _inicializado = true;
    } catch (e) {
      debugPrint('Error inicializando NotificationService: $e');
    }
  }

  /// Verifica si el usuario actual tiene activas las notificaciones en sus ajustes
  Future<bool> estanNotificacionesActivas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = AuthService.instance.currentUser;
      if (user != null) {
        return prefs.getBool('user_notifs_${user.uid}') ?? true;
      } else {
        return prefs.getBool('guest_notifs') ?? true;
      }
    } catch (e) {
      return true;
    }
  }

  /// Obtiene el identificador del usuario o invitado actual para filtrar auto-notificaciones
  Future<String> obtenerMiActorUid() async {
    final user = AuthService.instance.currentUser;
    if (user != null) return user.uid;

    final prefs = await SharedPreferences.getInstance();
    var guestActor = prefs.getString('guest_actor_uuid');
    if (guestActor == null || guestActor.isEmpty) {
      guestActor = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('guest_actor_uuid', guestActor);
    }
    return guestActor;
  }

  /// Procesa un evento recibido desde Firestore con filtrado anti-spam y entrega inteligente
  Future<void> procesarEvento(NotificacionEvento evento) async {
    // 1. Filtrar si ya fue procesado
    if (_idsProcesados.contains(evento.id)) return;
    _idsProcesados.add(evento.id);
    if (_idsProcesados.length > 200) {
      _idsProcesados.remove(_idsProcesados.first);
    }

    // 2. Filtrar auto-notificación (si yo mismo hice el cambio)
    final miUid = await obtenerMiActorUid();
    if (evento.autorUid == miUid) {
      return;
    }

    // 3. Filtrar si el usuario desactivó notificaciones en ajustes
    final activas = await estanNotificacionesActivas();
    if (!activas) return;

    // 4. Si es finalización de compra, tiene máxima prioridad (se despacha de inmediato)
    if (evento.tipo == TipoNotificacionLista.compraFinalizada) {
      _despacharEventoInmediato(evento);
      return;
    }

    // 5. Anti-Spam: Acumular en el buffer de ráfaga
    _bufferEventos.add(evento);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _procesarBuffer();
    });
  }

  void _despacharEventoInmediato(NotificacionEvento evento) {
    if (isAppInForeground) {
      _mostrarBannerInApp(evento);
    } else {
      _mostrarNotificacionSistema(evento);
    }
  }

  void _procesarBuffer() {
    if (_bufferEventos.isEmpty) return;

    final lote = List<NotificacionEvento>.from(_bufferEventos);
    _bufferEventos.clear();

    final primerEvento = lote.first;
    String? tituloLote;
    String? descripcionLote;

    if (lote.length > 1) {
      tituloLote = 'Cambios en la lista';
      final autor = primerEvento.autorNombre;
      descripcionLote = '$autor realizó ${lote.length} cambios en la lista compartida.';
    }

    // Verificar Cooldown
    final ahora = DateTime.now();
    if (_ultimoBannerTimestamp != null &&
        ahora.difference(_ultimoBannerTimestamp!) < _cooldownDuration) {
      // Esperar el remanente de cooldown antes de mostrar
      final delay = _cooldownDuration - ahora.difference(_ultimoBannerTimestamp!);
      Timer(delay, () {
        _entregarEvento(primerEvento, tituloLote: tituloLote, descripcionLote: descripcionLote);
      });
      return;
    }

    _entregarEvento(primerEvento, tituloLote: tituloLote, descripcionLote: descripcionLote);
  }

  void _entregarEvento(
    NotificacionEvento evento, {
    String? tituloLote,
    String? descripcionLote,
  }) {
    _ultimoBannerTimestamp = DateTime.now();

    if (isAppInForeground) {
      _mostrarBannerInApp(evento, tituloLote: tituloLote, descripcionLote: descripcionLote);
    } else {
      _mostrarNotificacionSistema(evento, tituloLote: tituloLote, descripcionLote: descripcionLote);
    }
  }

  void _mostrarBannerInApp(
    NotificacionEvento evento, {
    String? tituloLote,
    String? descripcionLote,
  }) {
    final overlayState = navigatorKey?.currentState?.overlay;
    if (overlayState == null) return;

    // Remover banner anterior si existe
    _overlayDismissTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;

    HapticFeedback.lightImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: InAppNotificationBanner(
            evento: evento,
            tituloLote: tituloLote,
            descripcionLote: descripcionLote,
            onDismiss: () {
              _overlayDismissTimer?.cancel();
              if (_currentOverlay == entry) {
                entry.remove();
                _currentOverlay = null;
              }
            },
            onTap: () {
              onNavigateToLista?.call();
            },
          ),
        );
      },
    );

    _currentOverlay = entry;
    overlayState.insert(entry);

    // Auto-cierre tras 3.8 segundos
    _overlayDismissTimer = Timer(const Duration(milliseconds: 3800), () {
      if (_currentOverlay == entry) {
        entry.remove();
        _currentOverlay = null;
      }
    });
  }

  Future<void> _mostrarNotificacionSistema(
    NotificacionEvento evento, {
    String? tituloLote,
    String? descripcionLote,
  }) async {
    if (_mockMode) return;

    final titulo = tituloLote ?? evento.obtenerTitulo();
    final descripcion = descripcionLote ?? evento.obtenerDescripcion();

    const androidDetails = AndroidNotificationDetails(
      'smartcart_shared_lists',
      'Listas Compartidas',
      channelDescription: 'Notificaciones de cambios y finalizaciones en listas compartidas',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _localNotifications.show(
        id: evento.id.hashCode,
        title: 'SmartCart: $titulo',
        body: descripcion,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error mostrando notificación local del sistema: $e');
    }
  }

  @visibleForTesting
  void limpiarBufferParaTests() {
    _bufferEventos.clear();
    _debounceTimer?.cancel();
    _idsProcesados.clear();
    _ultimoBannerTimestamp = null;
  }
}
