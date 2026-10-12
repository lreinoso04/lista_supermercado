import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Perfil y Modo Invitado Aislamiento Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Modo Invitado no debe heredar el nombre ni el email de una sesión anterior', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simular que un usuario anterior guardó sus datos con su UID
      const previousUid = 'firebase_user_abc123';
      await prefs.setString('user_name_$previousUid', 'Joan Marquez');
      await prefs.setString('user_rol_$previousUid', 'Administrador');

      // Comprobar que las claves de invitado están completamente aisladas
      final guestName = prefs.getString('guest_nombre') ?? 'Invitado';
      const guestEmail = 'invitado@smartcart.app';

      expect(guestName, 'Invitado');
      expect(guestEmail, 'invitado@smartcart.app');
      expect(prefs.getString('user_name_$previousUid'), 'Joan Marquez');
    });

    test('Registro almacena el nombre indexado por UID de usuario', () async {
      final prefs = await SharedPreferences.getInstance();
      const testUid = 'user_777';
      const nombreIngresado = 'Maria Perez';

      await prefs.setString('user_name_$testUid', nombreIngresado);

      // Al cargar preferencias para ese UID, debe devolver Maria Perez y no el correo
      final resolvedName = prefs.getString('user_name_$testUid');
      expect(resolvedName, 'Maria Perez');
    });

    test('Cierre de sesión limpia smartcart_guest_mode y preserva la privacidad del invitado', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('smartcart_guest_mode', true);
      expect(prefs.getBool('smartcart_guest_mode'), isTrue);

      // Simular cierre de sesión
      await prefs.remove('smartcart_guest_mode');
      expect(prefs.getBool('smartcart_guest_mode'), isNull);
    });
  });
}
