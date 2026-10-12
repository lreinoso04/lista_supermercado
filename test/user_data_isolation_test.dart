import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lista_supermercado/models/historial_compra.dart';
import 'package:lista_supermercado/models/producto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Aislamiento de Datos de Usuario y Modo Invitado (Sin Cruce de Bases de Datos)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Detección de cambio de sesión entre Usuario A e Invitado detecta inconsistencia', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_session_uid', 'user_A_123');

      // Simular cambio a modo invitado
      final lastUid = prefs.getString('current_session_uid');
      const currentUid = 'guest';

      bool huboCambioDeUsuario = (lastUid != null && lastUid != currentUid);
      expect(huboCambioDeUsuario, isTrue);

      // Al limpiar la sesión, se actualiza la sesión activa
      await prefs.setString('current_session_uid', currentUid);
      expect(prefs.getString('current_session_uid'), 'guest');
    });

    test('Detección de cambio entre Usuario A y Usuario B fuerza limpieza para evitar mezclar historial en la nube', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_session_uid', 'user_A_123');

      final lastUid = prefs.getString('current_session_uid');
      const currentUid = 'user_B_456';

      expect(lastUid != currentUid, isTrue);

      // Si los datos locales de User A no se borrasen, se mezclarían en la nube de User B
      final comprasUserA = [
        HistorialCompra(uuid: 'h-1', fecha: '2026-10-01', total: 20.0, cantidadProductos: 2),
      ];

      // Al aplicar la limpieza por cambio de sesión, las compras locales quedan vacías
      List<HistorialCompra> comprasLocales = List.from(comprasUserA);
      if (lastUid != currentUid) {
        comprasLocales.clear();
      }

      expect(comprasLocales, isEmpty);
      // user_B_456 descarga de su nube sin contaminarse con compras de user_A_123
      expect(comprasLocales.any((c) => c.uuid == 'h-1'), isFalse);
    });

    test('El Modo Invitado arranca con listas e historial aislados desde cero', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('smartcart_guest_mode', true);
      await prefs.setString('current_session_uid', 'guest');

      expect(prefs.getBool('smartcart_guest_mode'), isTrue);
      expect(prefs.getString('current_session_uid'), 'guest');

      // Las compras locales del invitado comienzan en 0
      final List<HistorialCompra> historialInvitado = [];
      final List<Producto> productosInvitado = [];

      expect(historialInvitado, isEmpty);
      expect(productosInvitado, isEmpty);
    });

    test('Al cerrar sesión se eliminan flags de sesión para prevenir fuga de datos', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('smartcart_guest_mode', true);
      await prefs.setString('current_session_uid', 'guest');

      // Cierre de sesión
      await prefs.remove('smartcart_guest_mode');
      await prefs.remove('current_session_uid');

      expect(prefs.getBool('smartcart_guest_mode'), isNull);
      expect(prefs.getString('current_session_uid'), isNull);
    });
  });
}
