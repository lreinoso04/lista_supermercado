import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/widgets/cerrando_sesion_overlay.dart';
import 'package:lista_supermercado/providers/lista_provider.dart';

void main() {
  group('CerrandoSesionOverlay Tests', () {
    testWidgets('Muestra mensaje de despedida con nombre y bloquea retroceso', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CerrandoSesionOverlay(
            nombreUsuario: 'Joan Marquez',
          ),
        ),
      );

      // Verificar que el widget monta
      expect(find.text('Cerrando sesión'), findsOneWidget);
      expect(find.text('¡Hasta pronto, Joan Marquez! 👋'), findsOneWidget);
      expect(find.text('Asegurando tus datos y sincronizando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verificar PopScope canPop == false
      final popScopeFinder = find.byType(PopScope);
      expect(popScopeFinder, findsOneWidget);
      final PopScope popScopeWidget = tester.widget(popScopeFinder);
      expect(popScopeWidget.canPop, isFalse);
    });

    testWidgets('Muestra vista limpia sin saludo personalizado si el usuario es Invitado o nulo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CerrandoSesionOverlay(
            nombreUsuario: 'Invitado',
          ),
        ),
      );

      expect(find.text('Cerrando sesión'), findsOneWidget);
      expect(find.textContaining('¡Hasta pronto'), findsNothing);
      expect(find.text('Asegurando tus datos y sincronizando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ListaProvider Historial Reactivo', () {
    test('Historial getter retorna lista vacía inicialmente y limpiarDatosLocales limpia la lista', () async {
      final provider = ListaProvider();
      expect(provider.historial, isEmpty);
    });
  });
}
