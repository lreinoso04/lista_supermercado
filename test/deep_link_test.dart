import 'package:flutter_test/flutter_test.dart';
import 'package:lista_supermercado/services/deep_link_service.dart';
import 'package:lista_supermercado/widgets/dialogos_sincronizacion.dart';

void main() {
  group('DeepLinkService & URLs Tests', () {
    test('extraerPinDeUri extrae correctamente PIN desde URL web con query param pin', () {
      final uri = Uri.parse('https://smartcart-a4013.web.app/join?pin=ABCDEF');
      final pin = DeepLinkService.extraerPinDeUri(uri);
      expect(pin, 'ABCDEF');
    });

    test('extraerPinDeUri extrae correctamente PIN desde custom scheme smartcart://', () {
      final uri = Uri.parse('smartcart://join?pin=7X9K2M');
      final pin = DeepLinkService.extraerPinDeUri(uri);
      expect(pin, '7X9K2M');
    });

    test('extraerPinDeUri extrae con parámetro code alternativo', () {
      final uri = Uri.parse('smartcart://join?code=XYZ987');
      final pin = DeepLinkService.extraerPinDeUri(uri);
      expect(pin, 'XYZ987');
    });

    test('extraerPinDeUri extrae PIN desde path segment', () {
      final uri = Uri.parse('https://smartcart-a4013.web.app/join/A1B2C3');
      final pin = DeepLinkService.extraerPinDeUri(uri);
      expect(pin, 'A1B2C3');
    });

    test('extraerPinDeUri retorna null para URIs sin PIN válido', () {
      final uri = Uri.parse('https://smartcart-a4013.web.app/otra_ruta');
      final pin = DeepLinkService.extraerPinDeUri(uri);
      expect(pin, isNull);
    });

    test('DialogosSincronizacion.construirUrlLista genera la URL oficial correcta', () {
      final url = DialogosSincronizacion.construirUrlLista('k8f2a9');
      expect(url, 'https://smartcart-a4013.web.app/join?pin=K8F2A9');
    });
  });
}
