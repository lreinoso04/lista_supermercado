import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class DialogosSincronizacion {
  static const String dominioWeb = 'https://smartcart-a4013.web.app/join';

  /// Genera la URL oficial de invitación a la lista
  static String construirUrlLista(String pin) {
    return '$dominioWeb?pin=${pin.trim().toUpperCase()}';
  }

  /// Conecta a una lista compartida, solicitando confirmación si ya existen productos locales
  static Future<void> procesarConexionConConfirmacion({
    required BuildContext context,
    required ListaProvider provider,
    required String pin,
  }) async {
    final cleanPin = pin.trim().toUpperCase();

    // Si ya estamos conectados a ese mismo PIN, no hacer nada
    if (provider.pinActual == cleanPin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ya estás conectado a la lista $cleanPin')),
        );
      }
      return;
    }

    // Si hay productos locales, pedir confirmación antes de conectarse
    if (provider.productos.isNotEmpty) {
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.link_rounded, color: kVerde),
              SizedBox(width: 8),
              Text('¿Unirse a la lista?'),
            ],
          ),
          content: Text(
            'Tienes ${provider.productos.length} productos en tu lista actual. '
            'Al unirte a la lista compartida ($cleanPin), sincronizarás en vivo los productos de esa lista.\n\n'
            '¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerde),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, Unirme', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    try {
      await provider.conectarFirebase(cleanPin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Te has conectado exitosamente a la lista $cleanPin.'),
          backgroundColor: kVerde,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al conectar con la lista: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static void mostrarConectar({
    required BuildContext context,
    required ListaProvider provider,
    required String? Function(String) extraerPin,
  }) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conectarse a una Lista ☁️'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Pega el enlace o ingresa el PIN de lista',
            prefixIcon: Icon(Icons.pin),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kVerde,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final String rawInput = ctrl.text.trim();
              if (rawInput.isEmpty) return;

              Navigator.pop(ctx);

              // 1. Detectar si es un enlace con query param pin
              final uri = Uri.tryParse(rawInput);
              if (uri != null) {
                final pinFromUri = uri.queryParameters['pin'] ?? uri.queryParameters['code'];
                if (pinFromUri != null && pinFromUri.isNotEmpty) {
                  await procesarConexionConConfirmacion(
                    context: context,
                    provider: provider,
                    pin: pinFromUri,
                  );
                  return;
                }
              }

              // 2. Detectar si es un código Base64 (listas exportadas)
              if (rawInput.length > 15 && !rawInput.startsWith('http')) {
                try {
                  await provider.importarListaBase64(rawInput);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Lista importada localmente con éxito.'),
                      backgroundColor: kVerde,
                    ),
                  );
                  return;
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al importar la lista: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
              }

              // 3. Extraer un PIN estándar de 4 a 8 caracteres
              final String? pin = extraerPin(rawInput);
              if (pin == null || pin.length < 4 || pin.length > 8) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: No se encontró ningún PIN válido en el texto.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              await procesarConexionConConfirmacion(
                context: context,
                provider: provider,
                pin: pin,
              );
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  static Future<void> mostrarCompartir({
    required BuildContext context,
    required ListaProvider provider,
  }) async {
    if (provider.productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La lista está vacía.')),
      );
      return;
    }

    String pin = provider.pinActual ?? "";
    if (pin.isEmpty) {
      pin = await provider.compartirListaEnNube();
    }

    final urlEnlace = construirUrlLista(pin);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Compartir Lista en Vivo ☁️',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Invita a tus familiares a unirse con un solo toque:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kNaranja.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNaranja.withValues(alpha: 0.3)),
              ),
              child: Text(
                pin,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: kNaranja,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enlace interactivo:\n$urlEnlace',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kVerdeMedio,
                    side: const BorderSide(color: kVerdeMedio),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: urlEnlace));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Enlace copiado al portapapeles.'),
                        backgroundColor: kVerde,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVerde,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.share(
                      '🛒 ¡Únete a mi lista de compras en SmartCart!\n\n'
                      '👉 Toca este enlace para abrir la lista directamente:\n$urlEnlace\n\n'
                      '(O ingresa el PIN manualmente en la app: $pin)',
                    );
                  },
                  icon: const Icon(Icons.share, color: Colors.white, size: 18),
                  label: const Text('Compartir', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
