import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/producto.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';
import '../widgets/producto_card.dart';
import '../widgets/editar_producto_dialog.dart';
import '../widgets/barra_progreso_presupuesto.dart';
import '../widgets/dialogos_sincronizacion.dart';

class ListaComprasView extends StatefulWidget {
  const ListaComprasView({super.key});

  @override
  State<ListaComprasView> createState() => _ListaComprasViewState();
}

class _ListaComprasViewState extends State<ListaComprasView> {
  final FlutterTts _tts = FlutterTts();
  bool _ttsActivo = false;
  bool _ttsPausado = false;

  String? _extraerPin(String input) {
    final regex = RegExp(r'\b[A-Za-z0-9]{4,6}\b'); 
    final match = regex.firstMatch(input);
    return match?.group(0)?.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setEngine("com.google.android.tts");
    } catch (e) {
      debugPrint('Motor no disponible: $e');
    }

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
      await _tts.setLanguage("es");
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
      setState(() {
        _ttsActivo = false;
        _ttsPausado = false;
      });
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
      setState(() {
        _ttsActivo = false;
        _ttsPausado = true;
      });
      return;
    }

    if (_ttsPausado) {
      await _tts.speak(_buildTextoLectura(pendientes));
      if (!mounted) return;
      setState(() {
        _ttsActivo = true;
        _ttsPausado = false;
      });
      return;
    }

    final texto = _buildTextoLectura(pendientes);
    await _tts.speak(texto);
    if (!mounted) return;
    setState(() {
      _ttsActivo = true;
      _ttsPausado = false;
    });
  }

  String _buildTextoLectura(List<Producto> lista) {
    final sb = StringBuffer(
      'Tu lista de compras tiene ${lista.length} productos pendientes. ',
    );
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

  Future<void> _enviarRecordatorioSMS(List<Producto> pendientes) async {
    final prefs = await SharedPreferences.getInstance();
    final bool smsActivo = prefs.getBool('perfil_notifs') ?? true;
    final String telefono = prefs.getString('perfil_telefono') ?? "";

    if (!smsActivo) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los mensajes SMS están desactivados en tu perfil.'),
        ),
      );
      return;
    }

    if (telefono.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configura el teléfono del comprador en tu Perfil primero.',
          ),
        ),
      );
      return;
    }

    if (pendientes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos pendientes para recordar.'),
        ),
      );
      return;
    }

    final sb = StringBuffer(
      '🛒 Recordatorio SmartCart:\nTienes ${pendientes.length} productos por comprar.\n',
    );
    final numParaMostrar = pendientes.length > 5 ? 5 : pendientes.length;
    for (int i = 0; i < numParaMostrar; i++) {
      sb.writeln('- ${pendientes[i].nombre} (x${pendientes[i].cantidad})');
    }
    if (pendientes.length > 5) sb.writeln('...y ${pendientes.length - 5} más.');
    sb.writeln('\n¡Por favor, no lo olvides!');

    final uri = Uri(
      scheme: 'sms',
      path: telefono,
      queryParameters: {'body': sb.toString()},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de mensajes.')),
      );
    }
  }

  List<Widget> _buildCategoriasGrupos(
    BuildContext context,
    List<Producto> pendientes,
    ListaProvider provider,
  ) {
    final Map<String, List<Producto>> grupos = {};
    for (var p in pendientes) {
      if (!grupos.containsKey(p.categoria)) grupos[p.categoria] = [];
      grupos[p.categoria]!.add(p);
    }

    for (var cat in grupos.keys) {
      grupos[cat]!.sort((a, b) {
        int pa = a.prioridad == 'Alta' ? 0 : (a.prioridad == 'Media' ? 1 : 2);
        int pb = b.prioridad == 'Alta' ? 0 : (b.prioridad == 'Media' ? 1 : 2);
        return pa.compareTo(pb);
      });
    }

    final sortedKeys = grupos.keys.toList()..sort((a, b) => a.compareTo(b));
    final widgets = <Widget>[];
    for (var key in sortedKeys) {
      final entryValue = grupos[key]!;
      final cModel = provider.categorias
          .where((c) => c.nombre == key)
          .firstOrNull;
      final colorBase = cModel != null
          ? Color(cModel.colorValue)
          : Colors.blueGrey;

      widgets.add(_sectionHeader(key, entryValue.length, colorBase));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(entryValue.map((p) => ProductoCard(
        producto: p,
        onToggleComprado: () => provider.toggleComprado(p),
        onEliminar: () => provider.eliminarProducto(p),
        onTapEditar: () => EditarProductoDialog.mostrar(context, p, provider),
      )));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarConfirmacionReinicio(BuildContext context, ListaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Reiniciar Carrito?'),
        content: const Text(
          'Esto vaciará tu carrito y pondrá todos los productos como "Pendientes" nuevamente. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerde),
            onPressed: () {
              Navigator.pop(ctx);
              provider.reiniciarLista();
            },
            child: const Text('Sí, Reiniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacionVaciar(BuildContext context, ListaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Vaciar Lista?'),
        content: const Text(
          'Esto eliminará TODOS los productos de tu lista actual desde cero. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              provider.vaciarListaDesdeCero();
            },
            child: const Text('Sí, Vaciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListaProvider>();
    final productos = provider.productos;

    final pendientes = productos.where((p) => !p.comprado).toList();
    final comprados = productos.where((p) => p.comprado).toList();
    final progreso = productos.isEmpty
        ? 0.0
        : comprados.length / productos.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SmartCart',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: kVerde,
              ),
            ),
            Text(
              '${productos.length} productos • ${comprados.length} comprados',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: kVerdeMedio),
            tooltip: 'Conectarse a una lista',
            onPressed: () => DialogosSincronizacion.mostrarConectar(
              context: context,
              provider: provider,
              extraerPin: _extraerPin,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: kVerdeMedio),
            tooltip: 'Compartir mi Lista',
            onPressed: () => DialogosSincronizacion.mostrarCompartir(
              context: context,
              provider: provider,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sms_rounded, color: Colors.blueAccent),
            tooltip: 'Enviar Recordatorio SMS',
            onPressed: () => _enviarRecordatorioSMS(pendientes),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
            tooltip: 'Reiniciar carrito',
            onPressed: () => _mostrarConfirmacionReinicio(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            tooltip: 'Vaciar lista',
            onPressed: () => _mostrarConfirmacionVaciar(context, provider),
          ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _ttsActivo ? Icons.pause_rounded : Icons.volume_up_rounded,
                      size: 16,
                      color: _ttsActivo ? kNaranja : kVerde,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _ttsActivo
                          ? 'Pausar'
                          : (_ttsPausado ? 'Reanudar' : 'Escuchar'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _ttsActivo ? kNaranja : kVerde,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_ttsActivo)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: kNaranja.withValues(alpha: 0.1),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.graphic_eq, color: kNaranja, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Leyendo lista en voz alta...',
                            style: TextStyle(
                              color: kNaranja,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: productos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 96,
                                  color: Colors.grey.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Tu lista está vacía',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Usa el micrófono para agregar productos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          children: [
                            if (pendientes.isNotEmpty)
                              ..._buildCategoriasGrupos(
                                context,
                                pendientes,
                                provider,
                              ),
                            if (comprados.isNotEmpty) ...[
                              _sectionHeader(
                                'Comprados ✓',
                                comprados.length,
                                Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              ...comprados.map((p) => ProductoCard(
                                producto: p,
                                onToggleComprado: () => provider.toggleComprado(p),
                                onEliminar: () => provider.eliminarProducto(p),
                                onTapEditar: () => EditarProductoDialog.mostrar(context, p, provider),
                              )),
                            ],
                            const SizedBox(height: 24),
                            if (productos.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kVerde,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Terminar Compra',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    provider.terminarCompra();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ Compra terminada y guardada en el historial',
                                        ),
                                        backgroundColor: kVerde,
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                ),

                if (productos.isNotEmpty)
                  BarraProgresoPresupuesto(
                    progreso: progreso,
                    gastoTotal: provider.gastoTotal,
                  ),
              ],
            ),
      ),
    );
  }
}
