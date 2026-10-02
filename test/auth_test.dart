import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lista_supermercado/services/auth_service.dart';
import 'package:lista_supermercado/widgets/google_logo.dart';

void main() {
  group('AuthService error translation tests', () {
    test('Translates standard FirebaseAuthException codes accurately into Spanish', () {
      final invalidCredential = FirebaseAuthException(code: 'invalid-credential');
      expect(
        AuthService.getReadableAuthError(invalidCredential),
        contains('incorrectos'),
      );

      final userNotFound = FirebaseAuthException(code: 'user-not-found');
      expect(
        AuthService.getReadableAuthError(userNotFound),
        contains('No existe ninguna cuenta'),
      );

      final wrongPassword = FirebaseAuthException(code: 'wrong-password');
      expect(
        AuthService.getReadableAuthError(wrongPassword),
        contains('incorrecta'),
      );

      final emailInUse = FirebaseAuthException(code: 'email-already-in-use');
      expect(
        AuthService.getReadableAuthError(emailInUse),
        contains('Ya existe una cuenta'),
      );

      final weakPassword = FirebaseAuthException(code: 'weak-password');
      expect(
        AuthService.getReadableAuthError(weakPassword),
        contains('al menos 8 caracteres'),
      );
    });
  });

  group('GoogleLogo Widget tests', () {
    testWidgets('GoogleLogo renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GoogleLogo(size: 24),
            ),
          ),
        ),
      );

      expect(find.byType(GoogleLogo), findsOneWidget);
    });
  });
}
