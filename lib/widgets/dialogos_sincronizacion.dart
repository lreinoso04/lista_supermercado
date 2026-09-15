import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class DialogosSincronizacion {
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
            hintText: 'Ingresa el PIN de 6 caracteres o código de lista',
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

              // 1. Detectar si es un código Base64 (listas exportadas)
              if (rawInput.length > 15) {
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

              // 2. Si es corto, extraer un PIN de 4 a 6 caracteres
              final String? pin = extraerPin(rawInput);
              if (pin == null || pin.length < 4 || pin.length > 6) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: No se encontró ningún PIN válido en el texto.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              try {
                await provider.conectarFirebase(pin);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Conectado exitosamente en vivo.'),
                    backgroundColor: kVerde,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
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

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Compartir en Vivo ☁️',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tus familiares pueden unirse usando este PIN en la app:',
            ),
            const SizedBox(height: 16),
            Text(
              pin,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: kNaranja,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kVerde),
            onPressed: () {
              Share.share(
                '🛒 ¡Únete a mi lista de compras en SmartCart!\nAbre la app, dale a "Recibir" e ingresa este PIN: $pin',
              );
            },
            icon: const Icon(
              Icons.share,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Enviar PIN',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
