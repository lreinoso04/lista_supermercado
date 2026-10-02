import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/services/auth_service.dart';
import 'package:lista_supermercado/widgets/human_verification_tile.dart';

void main() {
  group('Security & Brute Force Lockout Tests', () {
    test('Lockout triggers after 3 consecutive failed login attempts', () {
      final auth = AuthService.instance;
      auth.resetFailedLoginAttempts();

      expect(auth.isLoginLocked(), isFalse);
      expect(auth.getLockoutRemainingSeconds(), equals(0));

      // Primer y segundo intento fallido
      auth.recordFailedLoginAttempt();
      expect(auth.isLoginLocked(), isFalse);

      auth.recordFailedLoginAttempt();
      expect(auth.isLoginLocked(), isFalse);

      // Tercer intento fallido activa el bloqueo
      auth.recordFailedLoginAttempt();
      expect(auth.isLoginLocked(), isTrue);
      expect(auth.getLockoutRemainingSeconds(), greaterThan(0));

      // Reset limpia el bloqueo
      auth.resetFailedLoginAttempts();
      expect(auth.isLoginLocked(), isFalse);
      expect(auth.getLockoutRemainingSeconds(), equals(0));
    });
  });

  group('HumanVerificationTile (Anti-Bot) Widget Tests', () {
    testWidgets('Tapping tile verifies human and triggers callback', (tester) async {
      bool isHuman = false;
      final key = GlobalKey<HumanVerificationTileState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HumanVerificationTile(
                key: key,
                onVerificationChanged: (val) => isHuman = val,
              ),
            ),
          ),
        ),
      );

      expect(find.text('No soy un robot'), findsOneWidget);
      expect(isHuman, isFalse);

      // Tocar el checkbox de verificación
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(); // Inicia spinner

      // Esperar la animación/retraso simulado (650ms)
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Verificación humana completada'), findsOneWidget);
      expect(isHuman, isTrue);

      // Reset
      key.currentState?.reset();
      await tester.pumpAndSettle();

      expect(find.text('No soy un robot'), findsOneWidget);
      expect(isHuman, isFalse);
    });
  });
}
