import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lista_supermercado/models/notificacion_evento.dart';
import 'package:lista_supermercado/services/notification_service.dart';
import 'package:lista_supermercado/widgets/in_app_notification_banner.dart';
import 'package:lista_supermercado/widgets/historial_cambios_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationService.instance.mockMode = true;
    NotificationService.instance.limpiarBufferParaTests();
  });

  group('NotificacionEvento Model Tests', () {
    test('Serializa y deserializa correctamente desde Map', () {
      final ahora = DateTime.now();
      final evento = NotificacionEvento(
        id: 'test-uuid-123',
        autorUid: 'user-abc',
        autorNombre: 'Joan',
        tipo: TipoNotificacionLista.productoAgregado,
        productoNombre: 'Leche entera',
        detalle: 'x2',
        timestamp: ahora,
      );

      final map = evento.toMap();
      expect(map['id'], 'test-uuid-123');
      expect(map['autorUid'], 'user-abc');
      expect(map['autorNombre'], 'Joan');
      expect(map['tipo'], 'productoAgregado');
      expect(map['productoNombre'], 'Leche entera');
      expect(map['detalle'], 'x2');
      expect(map['timestamp'], ahora.millisecondsSinceEpoch);

      final restaurado = NotificacionEvento.fromMap(map);
      expect(restaurado.id, evento.id);
      expect(restaurado.autorUid, evento.autorUid);
      expect(restaurado.autorNombre, evento.autorNombre);
      expect(restaurado.tipo, TipoNotificacionLista.productoAgregado);
      expect(restaurado.productoNombre, 'Leche entera');
      expect(restaurado.detalle, 'x2');
    });

    test('Genera títulos y descripciones correctas para cada tipo de acción', () {
      final eAgregado = NotificacionEvento(
        autorUid: 'u1',
        autorNombre: 'María',
        tipo: TipoNotificacionLista.productoAgregado,
        productoNombre: 'Arroz',
        detalle: 'x1',
      );
      expect(eAgregado.obtenerTitulo(), 'Producto agregado');
      expect(eAgregado.obtenerDescripcion(), contains('María agregó "Arroz" (x1)'));

      final eComprado = NotificacionEvento(
        autorUid: 'u2',
        autorNombre: 'Carlos',
        tipo: TipoNotificacionLista.productoComprado,
        productoNombre: 'Manzanas',
      );
      expect(eComprado.obtenerTitulo(), 'Producto comprado');
      expect(eComprado.obtenerDescripcion(), contains('Carlos marcó como comprado "Manzanas"'));

      final eFinalizado = NotificacionEvento(
        autorUid: 'u3',
        autorNombre: 'Joan',
        tipo: TipoNotificacionLista.compraFinalizada,
        detalle: '5 productos',
      );
      expect(eFinalizado.obtenerTitulo(), '¡Compra finalizada!');
      expect(eFinalizado.obtenerDescripcion(), contains('Joan finalizó la compra (5 productos)'));
    });

    test('tiempoRelativo retorna cadenas adecuadas', () {
      final ahora = DateTime.now();
      final eventoReciente = NotificacionEvento(
        autorUid: 'u1',
        autorNombre: 'Test',
        tipo: TipoNotificacionLista.productoAgregado,
        timestamp: ahora.subtract(const Duration(seconds: 15)),
      );
      expect(eventoReciente.tiempoRelativo(), 'Hace un momento');

      final eventoMinutos = NotificacionEvento(
        autorUid: 'u1',
        autorNombre: 'Test',
        tipo: TipoNotificacionLista.productoAgregado,
        timestamp: ahora.subtract(const Duration(minutes: 5)),
      );
      expect(eventoMinutos.tiempoRelativo(), 'Hace 5 minutos');
    });
  });

  group('NotificationService Anti-Spam & Delivery Logic Tests', () {
    test('Filtra auto-notificaciones cuando autorUid es el actor actual', () async {
      SharedPreferences.setMockInitialValues({
        'guest_actor_uuid': 'mi_propio_id',
      });

      final service = NotificationService.instance;
      final miUid = await service.obtenerMiActorUid();
      expect(miUid, 'mi_propio_id');

      final eventoPropio = NotificacionEvento(
        id: 'ev-propio-1',
        autorUid: 'mi_propio_id',
        autorNombre: 'Yo Mismo',
        tipo: TipoNotificacionLista.productoComprado,
        productoNombre: 'Pan',
      );

      // No debe procesar ni lanzar excepción
      await service.procesarEvento(eventoPropio);
    });

    test('Filtra eventos duplicados con el mismo ID', () async {
      SharedPreferences.setMockInitialValues({
        'guest_actor_uuid': 'otro_id',
        'guest_notifs': true,
      });

      final service = NotificationService.instance;
      final evento = NotificacionEvento(
        id: 'mismo-id-123',
        autorUid: 'remoto_uid',
        autorNombre: 'Carlos',
        tipo: TipoNotificacionLista.productoAgregado,
        productoNombre: 'Café',
      );

      await service.procesarEvento(evento);
      // Segunda llamada con el mismo ID debe ser ignorada
      await service.procesarEvento(evento);
    });

    test('Respeta preferencia de notificaciones apagada en ajustes', () async {
      SharedPreferences.setMockInitialValues({
        'guest_actor_uuid': 'yo_actor',
        'guest_notifs': false, // Desactivadas por el usuario
      });

      final service = NotificationService.instance;
      final activas = await service.estanNotificacionesActivas();
      expect(activas, isFalse);

      final eventoRemoto = NotificacionEvento(
        id: 'ev-silencioso-1',
        autorUid: 'remoto_999',
        autorNombre: 'Familiar',
        tipo: TipoNotificacionLista.productoAgregado,
        productoNombre: 'Azúcar',
      );

      // Al estar inactivas se descarta
      await service.procesarEvento(eventoRemoto);
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('InAppNotificationBanner renders properly and handles dismiss', (tester) async {
      bool dismissed = false;
      bool tapped = false;

      final evento = NotificacionEvento(
        id: 'banner-test-1',
        autorUid: 'u-remoto',
        autorNombre: 'María',
        tipo: TipoNotificacionLista.productoComprado,
        productoNombre: 'Cereal',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppNotificationBanner(
              evento: evento,
              onDismiss: () => dismissed = true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Producto comprado'), findsOneWidget);
      expect(find.textContaining('María marcó como comprado "Cereal"'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Simular tap para interactuar
      await tester.tap(find.text('Producto comprado'));
      await tester.pump();
      expect(tapped, isTrue);

      // Simular botón cerrar
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('HistorialCambiosModal renders empty state and list items', (tester) async {
      // 1. Estado Vacío
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistorialCambiosModal(
              pin: '9X2K7B',
              actividad: [],
            ),
          ),
        ),
      );

      expect(find.text('Historial de Cambios'), findsOneWidget);
      expect(find.text('9X2K7B'), findsOneWidget);
      expect(find.text('Sin cambios registrados aún'), findsOneWidget);

      // 2. Con eventos registrados
      final eventos = [
        NotificacionEvento(
          id: 'ev-1',
          autorUid: 'u1',
          autorNombre: 'Joan',
          tipo: TipoNotificacionLista.productoAgregado,
          productoNombre: 'Leche',
          detalle: 'x2',
        ),
        NotificacionEvento(
          id: 'ev-2',
          autorUid: 'u2',
          autorNombre: 'Carlos',
          tipo: TipoNotificacionLista.productoComprado,
          productoNombre: 'Arroz',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorialCambiosModal(
              pin: '9X2K7B',
              actividad: eventos,
            ),
          ),
        ),
      );

      expect(find.text('Producto agregado'), findsOneWidget);
      expect(find.text('Producto comprado'), findsOneWidget);
      expect(find.textContaining('Joan agregó "Leche" (x2)'), findsOneWidget);
      expect(find.textContaining('Carlos marcó como comprado "Arroz"'), findsOneWidget);
    });
  });
}
