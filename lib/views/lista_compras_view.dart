import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class ListaComprasView extends StatefulWidget {
  const ListaComprasView({super.key});

  @override
  State<ListaComprasView> createState() => _ListaComprasViewState();
}

class _ListaComprasViewState extends State<ListaComprasView> {
  final FlutterTts _tts = FlutterTts();
  bool _ttsActivo = false;
  bool _ttsPausado = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    // 1. Configurar el motor primero
    try {
      await _tts.setEngine("com.google.android.tts");
    } catch (e) {
      debugPrint('Motor no disponible: $e');
    }

    // 2. Configurar el idioma cuidando los tipos dinámicos de flutter_tts (puede devolver int o bool)
    try {
      var isEsAvailable = await _tts.isLanguageAvailable("es-ES");
      var isMxAvailable = await _tts.isLanguageAvailable("es-MX");
      var isUsAvailable = await _tts.isLanguageAvailable("es-US");

      if (isEsAvailable == true || isEsAvailable == 1) {
        await _tts.setLanguage("es-ES");
      } else if (isMxAvailable == true || isMxAvailable == 1) {
        await _tts.setLanguage("es-MX");
      } else if (isUsAvailable == true || isUsAvailable == 1) {
        await _tts.setLanguage("es-US");
      } else {
        await _tts.setLanguage("es");
      }
    } catch (e) {
      debugPrint('Error al verificar idioma: $e');
      await _tts.setLanguage("es"); // Fallback seguro
    }

    try {
      await _tts.setSpeechRate(0.5); 
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint('Error ajustando volumen/velocidad: $e');
    }

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() { _ttsActivo = false; _ttsPausado = false; });
    });
  }

  Future<void> _leerLista(List<Producto> productos) async {
    final pendientes = productos.where((p) => !p.comprado).toList();
    if (pendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Lista completada! No hay productos pendientes.'),
          backgroundColor: kVerde,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_ttsActivo) {
      await _tts.pause();
      if (!mounted) return;
      setState(() { _ttsActivo = false; _ttsPausado = true; });
      return;
    }

    if (_ttsPausado) {
      await _tts.speak(_buildTextoLectura(pendientes));
      if (!mounted) return;
      setState(() { _ttsActivo = true; _ttsPausado = false; });
      return;
    }

    final texto = _buildTextoLectura(pendientes);
    await _tts.speak(texto);
    if (!mounted) return;
    setState(() { _ttsActivo = true; _ttsPausado = false; });
  }

  String _buildTextoLectura(List<Producto> lista) {
    final sb = StringBuffer('Tu lista de compras tiene ${lista.length} productos pendientes. ');
    for (final p in lista) {
      sb.write('${p.cantidad} ${p.nombre}, categoría ${p.categoria}. ');
    }
    sb.write('Fin de la lista.');
    return sb.toString();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListaProvider>();
    final productos = provider.productos;

    final pendientes = productos.where((p) => !p.comprado).toList();
    final comprados  = productos.where((p) => p.comprado).toList();
    final progreso   = productos.isEmpty
      ? 0.0
      : comprados.length / productos.length;

    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        backgroundColor: kBlanco,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mi Lista 🛒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text('${productos.length} productos • ${comprados.length} comprados',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          // Botón leer lista en voz alta
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _leerLista(productos),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _ttsActivo ? kNaranja.withValues(alpha: 0.15) : kVerdeMenta,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _ttsActivo ? kNaranja : kVerdeClaro,
                    width: 1.5,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _ttsActivo ? Icons.pause_rounded : Icons.volume_up_rounded,
                    size: 16,
                    color: _ttsActivo ? kNaranja : kVerde,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _ttsActivo ? 'Pausar' : (_ttsPausado ? 'Reanudar' : 'Escuchar'),
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: _ttsActivo ? kNaranja : kVerde,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: provider.isLoading 
      ? const Center(child: CircularProgressIndicator())
      : Column(children: [
        // Barra de progreso
        Container(
          color: kBlanco,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Progreso', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${(progreso * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kVerde)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 8,
                backgroundColor: kVerdeMenta,
                valueColor: const AlwaysStoppedAnimation<Color>(kVerde),
              ),
            ),
          ]),
        ),

        // Indicador TTS activo
        if (_ttsActivo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: kNaranja.withValues(alpha: 0.1),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.graphic_eq, color: kNaranja, size: 16),
              SizedBox(width: 6),
              Text('Leyendo lista en voz alta...',
                style: TextStyle(color: kNaranja, fontSize: 12, fontStyle: FontStyle.italic)),
            ]),
          ),

        // Lista
        Expanded(
          child: productos.isEmpty
            ? const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tu lista está vacía', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Usa el micrófono para agregar productos',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (pendientes.isNotEmpty) ...[
                    _sectionHeader('Por comprar', pendientes.length, kVerde),
                    const SizedBox(height: 8),
                    ...pendientes.map((p) {
                      return _buildProductoCard(context, p);
                    }),
                    const SizedBox(height: 16),
                  ],
                  if (comprados.isNotEmpty) ...[
                    _sectionHeader('Comprados ✓', comprados.length, Colors.grey),
                    const SizedBox(height: 8),
                    ...comprados.map((p) {
                      return _buildProductoCard(context, p);
                    }),
                  ],
                ],
              ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _buildProductoCard(BuildContext context, Producto p) {
    final colorPrioridad = p.prioridad == 'Alta' ? kNaranja : (p.prioridad == 'Media' ? kAmarillo : kVerdeClaro);
    final iconoCategoria = _iconoCategoria(p.categoria);

    return Dismissible(
      key: Key('prod_${p.id}_${p.nombre}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) {
        context.read<ListaProvider>().eliminarProducto(p);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: p.comprado ? const Color(0xFFF9F9F9) : kBlanco,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: p.comprado ? Colors.grey.shade200 : kVerdeMenta,
            width: 1.5,
          ),
          boxShadow: p.comprado ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: GestureDetector(
            onTap: () {
              context.read<ListaProvider>().toggleComprado(p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: p.comprado ? kVerde : kVerdeMenta,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                p.comprado ? Icons.check_rounded : iconoCategoria,
                color: p.comprado ? kBlanco : kVerde,
                size: 22,
              ),
            ),
          ),
          title: Text(
            p.nombre,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: p.comprado ? Colors.grey : Colors.black87,
              decoration: p.comprado ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Row(children: [
            Text(p.categoria,
              style: TextStyle(fontSize: 12, color: p.comprado ? Colors.grey.shade400 : Colors.grey)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colorPrioridad.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(p.prioridad,
                style: TextStyle(fontSize: 10, color: colorPrioridad, fontWeight: FontWeight.bold)),
            ),
          ]),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kFondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('×${p.cantidad}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: kVerdeMedio, fontSize: 14)),
          ),
        ),
      ),
    );
  }

  IconData _iconoCategoria(String cat) {
    switch (cat) {
      case 'Lácteos': return Icons.egg_outlined;
      case 'Carnes': return Icons.restaurant_outlined;
      case 'Frutas y Verduras': return Icons.eco_outlined;
      case 'Panadería': return Icons.bakery_dining_outlined;
      case 'Granos': return Icons.grain;
      case 'Bebidas': return Icons.local_drink_outlined;
      case 'Limpieza': return Icons.clean_hands_outlined;
      default: return Icons.shopping_bag_outlined;
    }
  }
}
