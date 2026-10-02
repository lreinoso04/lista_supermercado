import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/views/login_view.dart';
import 'package:lista_supermercado/widgets/google_logo.dart';

void main() {
  group('LoginView Widget Tests', () {
    testWidgets('LoginView renders initial login form elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginView(),
        ),
      );

      // Título y logo
      expect(find.text('SmartCart'), findsOneWidget);
      expect(find.text('Tu lista de compras inteligente y colaborativa'), findsOneWidget);

      // Botones del switcher
      expect(find.text('Iniciar Sesión'), findsNWidgets(2)); // Switcher tab + primary button
      expect(find.text('Crear Cuenta'), findsOneWidget);

      // Campos visibles en modo Login
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

      // Botón de Google
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
    });

    testWidgets('Toggling to register shows name and confirm password fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginView(),
        ),
      );

      // Cambiar a pestaña Crear Cuenta
      await tester.tap(find.text('Crear Cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsNothing);
    });

    testWidgets('Guest mode button invokes callback when pressed', (tester) async {
      bool guestPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            onGuestContinue: () => guestPressed = true,
          ),
        ),
      );

      expect(find.text('Continuar como invitado'), findsOneWidget);
      await tester.ensureVisible(find.text('Continuar como invitado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar como invitado'));
      await tester.pump();

      expect(guestPressed, isTrue);
    });
  });
}
