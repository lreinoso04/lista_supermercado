import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _enviarRecordatorioSMS(List<Producto> pendientes) async {
    final prefs = await SharedPreferences.getInstance();
    final bool smsActivo = prefs.getBool('perfil_notifs') ?? true;
    final String telefono = prefs.getString('perfil_telefono') ?? "";

    if (!smsActivo) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los mensajes SMS están desactivados en tu perfil.')));
      return;
    }

    if (telefono.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configura el teléfono del comprador en tu Perfil primero.')));
      return;
    }

    if (pendientes.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay productos pendientes para recordar.')));
      return;
    }

    final sb = StringBuffer('🛒 Recordatorio SmartCart:\nTienes ${pendientes.length} productos por comprar.\n');
    final numParaMostrar = pendientes.length > 5 ? 5 : pendientes.length;
    for (int i=0; i<numParaMostrar; i++) {
      sb.writeln('- ${pendientes[i].nombre} (x${pendientes[i].cantidad})');
    }
    if (pendientes.length > 5) sb.writeln('...y ${pendientes.length - 5} más.');
    sb.writeln('\n¡Por favor, no lo olvides!');

    final uri = Uri(scheme: 'sms', path: telefono, queryParameters: {'body': sb.toString()});
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la app de mensajes.')));
    }
  }

  Future<void> _notificarImportacionSMS() async {
    final prefs = await SharedPreferences.getInstance();
    final bool smsActivo = prefs.getBool('perfil_notifs') ?? true;
    final String telefono = prefs.getString('perfil_telefono') ?? "";

    if (smsActivo && telefono.isNotEmpty) {
      final uri = Uri(scheme: 'sms', path: telefono, queryParameters: {'body': '✅ He recibido tu código de lista en SmartCart. ¡Pronto haré la compra!'});
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  List<Widget> _buildCategoriasGrupos(BuildContext context, List<Producto> pendientes, ListaProvider provider) {
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
      final cModel = provider.categorias.where((c) => c.nombre == key).firstOrNull;
      final colorBase = cModel != null ? Color(cModel.colorValue) : Colors.blueGrey;
      
      widgets.add(_sectionHeader(key, entryValue.length, colorBase));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(entryValue.map((p) => _buildProductoCard(context, p)));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        toolbarHeight: 64, 
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SmartCart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: kVerde)),
          Text('${productos.length} productos • ${comprados.length} comprados',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          IconButton(
             icon: const Icon(Icons.download_rounded, color: kVerdeMedio),
             tooltip: 'Conectarse a una lista',
             onPressed: () {
                final ctrl = TextEditingController();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Conectarse a una Lista ☁️'),
                    content: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(hintText: 'Ingresa el PIN de 6 letras', prefixIcon: Icon(Icons.pin)),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kVerde, foregroundColor: Colors.white),
                        onPressed: () async {
                           if (ctrl.text.length != 6) return;
                           Navigator.pop(ctx);
                           try {
                             await provider.conectarFirebase(ctrl.text.toUpperCase());
                             if (!context.mounted) return;
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Conectado exitosamente en vivo.')));
                           } catch (e) {
                             if (!context.mounted) return;
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                           }
                        },
                        child: const Text('Conectar'),
                      )
                    ]
                  )
                );
             }
          ),
          IconButton(
             icon: const Icon(Icons.share_rounded, color: kVerdeMedio),
             tooltip: 'Compartir mi Lista',
             onPressed: () async {
               if (provider.productos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La lista está vacía.')));
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
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   title: const Text('Compartir en Vivo ☁️', style: TextStyle(fontWeight: FontWeight.bold)),
                   content: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Text('Tus familiares pueden unirse usando este PIN en la app:'),
                       const SizedBox(height: 16),
                       Text(pin, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: kNaranja), textAlign: TextAlign.center,),
                     ],
                   ),
                   actions: [
                     ElevatedButton.icon(
                       style: ElevatedButton.styleFrom(backgroundColor: kVerde),
                       onPressed: () {
                         Share.share('🛒 ¡Únete a mi lista de compras en SmartCart!\nAbre la app, dale a "Recibir" e ingresa este PIN: $pin');
                       },
                       icon: const Icon(Icons.share, color: Colors.white, size: 20),
                       label: const Text('Enviar PIN', style: TextStyle(color: Colors.white)),
                     ),
                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
                   ],
                 ),
               );
             },
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
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Opacity(
                    opacity: 0.4,
                    child: Image.asset('assets/icon.png', height: 96, errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tu lista está vacía', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Usa el micrófono para agregar productos',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (pendientes.isNotEmpty) ..._buildCategoriasGrupos(context, pendientes, provider),
                  if (comprados.isNotEmpty) ...[
                    _sectionHeader('Comprados ✓', comprados.length, Colors.grey),
                    const SizedBox(height: 8),
                    ...comprados.map((p) {
                      return _buildProductoCard(context, p);
                    }),
                  ],
                  const SizedBox(height: 24),
                  if (productos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kVerde,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text('Terminar Compra', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          provider.terminarCompra();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Compra terminada y guardada en el historial'), backgroundColor: kVerde),
                          );
                        },
                      ),
                    ),
                ],
              ),
        ),

        // Barra de progreso (Movida abajo)
        if (productos.isNotEmpty)
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
              if (provider.gastoTotal > 0) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Gasto en carrito', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('\$${provider.gastoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kVerdeMedio)),
                ]),
              ],
            ]),
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

  void _mostrarConfirmacionReinicio(BuildContext context, ListaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Reiniciar Carrito?'),
        content: const Text('Esto vaciará tu carrito y pondrá todos los productos como "Pendientes" nuevamente. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
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
        content: const Text('Esto eliminará TODOS los productos de tu lista actual desde cero. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
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




  void _mostrarEditarProducto(BuildContext context, Producto p, ListaProvider provider) {
    String editCategoria = p.categoria;
    String editPrioridad = p.prioridad;
    int editCantidad = p.cantidad;
    double editPrecio = p.precioEstimado;
    final nombreCtrl = TextEditingController(text: p.nombre);

    final categorias = provider.categorias.isEmpty 
        ? ['Otros'] 
        : provider.categorias.map((c) => c.nombre).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Editar Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  filled: true, fillColor: kFondo,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('CANTIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () { if (editCantidad > 1) setDlg(() => editCantidad--); },
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kVerdeMenta, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.remove, color: kVerde, size: 22)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('$editCantidad', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kVerde)),
                ),
                GestureDetector(
                  onTap: () { setDlg(() => editCantidad++); },
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kVerdeMenta, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: kVerde, size: 22)),
                ),
              ]),
              const SizedBox(height: 16),

              const Text('PRECIO ESTIMADO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: editPrecio > 0 ? editPrecio.toString() : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Ej. 150.50',
                  prefixIcon: const Icon(Icons.attach_money, color: kVerde, size: 18),
                  filled: true, fillColor: kFondo,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (v) { editPrecio = double.tryParse(v) ?? 0.0; },
              ),
              const SizedBox(height: 16),

              const Text('CATEGORÍA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: categorias.contains(editCategoria) ? editCategoria : categorias.first,
                items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { if (v != null) setDlg(() => editCategoria = v); },
                decoration: InputDecoration(filled: true, fillColor: kFondo, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),

              const Text('PRIORIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(children: ['Alta', 'Media', 'Baja'].map((pri) {
                final isSelected = editPrioridad == pri;
                final color = pri == 'Alta' ? kNaranja : (pri == 'Media' ? kAmarillo : kVerdeClaro);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setDlg(() => editPrioridad = pri),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: isSelected ? color.withValues(alpha: 0.15) : kFondo, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)),
                        child: Text(pri, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey)),
                      ),
                    ),
                  ),
                );
              }).toList()),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.eliminarProducto(p);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('🗑️ Producto eliminado'), backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating));
              }, 
              child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerde),
              onPressed: () {
                Navigator.pop(ctx);
                p.nombre = nombreCtrl.text.trim().isNotEmpty ? nombreCtrl.text.trim() : p.nombre;
                p.cantidad = editCantidad;
                p.precioEstimado = editPrecio;
                p.categoria = editCategoria;
                p.prioridad = editPrioridad;
                provider.actualizarProducto(p);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
          color: p.comprado ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: p.comprado ? Colors.grey.withValues(alpha: 0.2) : kVerdeMenta,
            width: 1.5,
          ),
          boxShadow: p.comprado ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: ListTile(
          onTap: () => _mostrarEditarProducto(context, p, context.read<ListaProvider>()),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
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
              color: p.comprado ? Colors.grey : Theme.of(context).colorScheme.onSurface,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('×${p.cantidad}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kVerdeMedio, fontSize: 13)),
                ),
                if (p.precioEstimado > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('\$${(p.precioEstimado * p.cantidad).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
              ]),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade400),
            ],
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
