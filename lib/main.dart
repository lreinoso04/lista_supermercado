import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

void main() => runApp(const MarketApp());

// ─────────────────────────────────────────────────
// MODELO DE DATOS
// ─────────────────────────────────────────────────
class Producto {
  String nombre;
  String categoria;
  int cantidad;
  bool comprado;
  String prioridad; // Alta / Media / Baja

  Producto({
    required this.nombre,
    required this.categoria,
    this.cantidad = 1,
    this.comprado = false,
    this.prioridad = 'Media',
  });
}

// ─────────────────────────────────────────────────
// COLORES Y TEMA
// ─────────────────────────────────────────────────
const kVerde        = Color(0xFF2E7D32);
const kVerdeClaro   = Color(0xFF4CAF50);
const kVerdeMenta   = Color(0xFFE8F5E9);
const kVerdeMedio   = Color(0xFF388E3C);
const kAmarillo     = Color(0xFFFFC107);
const kNaranja      = Color(0xFFFF7043);
const kFondo        = Color(0xFFF1F8F1);
const kBlanco       = Colors.white;

// ─────────────────────────────────────────────────
// APP PRINCIPAL
// ─────────────────────────────────────────────────
class MarketApp extends StatelessWidget {
  const MarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCart',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kVerde,
        scaffoldBackgroundColor: kFondo,
        cardTheme: const CardThemeData(
          elevation: 0,
          color: kBlanco,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBlanco,
          surfaceTintColor: kBlanco,
          elevation: 0,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// ─────────────────────────────────────────────────
// NAVEGACIÓN PRINCIPAL (estado global compartido)
// ─────────────────────────────────────────────────
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  // Lista global de productos compartida entre pantallas
  final List<Producto> _productos = [
    Producto(nombre: 'Leche entera', categoria: 'Lácteos', cantidad: 2, prioridad: 'Alta'),
    Producto(nombre: 'Pechuga de pollo', categoria: 'Carnes', cantidad: 1, prioridad: 'Alta'),
    Producto(nombre: 'Pan integral', categoria: 'Panadería', cantidad: 1, prioridad: 'Media'),
    Producto(nombre: 'Manzanas rojas', categoria: 'Frutas y Verduras', cantidad: 6, prioridad: 'Media'),
    Producto(nombre: 'Arroz blanco', categoria: 'Granos', cantidad: 1, prioridad: 'Baja'),
    Producto(nombre: 'Yogurt griego', categoria: 'Lácteos', cantidad: 3, prioridad: 'Media'),
    Producto(nombre: 'Tomates', categoria: 'Frutas y Verduras', cantidad: 4, prioridad: 'Media'),
    Producto(nombre: 'Queso amarillo', categoria: 'Lácteos', cantidad: 1, prioridad: 'Baja'),
  ];

  void _agregarProducto(Producto p) {
    setState(() => _productos.add(p));
  }

  void _toggleComprado(int index) {
    setState(() => _productos[index].comprado = !_productos[index].comprado);
  }

  void _eliminarProducto(int index) {
    setState(() => _productos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AgregarVozView(onProductoAgregado: _agregarProducto),
      ListaComprasView(
        productos: _productos,
        onToggle: _toggleComprado,
        onEliminar: _eliminarProducto,
      ),
      CategoriasView(productos: _productos),
      PerfilView(productos: _productos),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: kBlanco,
        indicatorColor: kVerdeMenta,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded, color: kVerde),
            label: 'Agregar',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: kVerde),
            label: 'Mi Lista',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: kVerde),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: kVerde),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// PANTALLA 1: AGREGAR POR VOZ (STT)
// ─────────────────────────────────────────────────
class AgregarVozView extends StatefulWidget {
  final Function(Producto) onProductoAgregado;
  const AgregarVozView({super.key, required this.onProductoAgregado});

  @override
  State<AgregarVozView> createState() => _AgregarVozViewState();
}

class _AgregarVozViewState extends State<AgregarVozView> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isInitializing = true;
  bool _isRecording = false;
  int _sec = 0;
  Timer? _timer;
  String _textoCapturado = '';
  double _confianza = 0.0;
  String _localeId = '';

  // Producto a configurar antes de guardar
  String _categoriaSeleccionada = 'Lácteos';
  String _prioridadSeleccionada = 'Media';
  int _cantidadSeleccionada = 1;

  static const List<String> _categorias = [
    'Lácteos', 'Carnes', 'Frutas y Verduras', 'Panadería',
    'Granos', 'Bebidas', 'Limpieza', 'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _safe(VoidCallback fn) { if (mounted) setState(fn); }

  Future<void> _initSpeech() async {
    _safe(() => _isInitializing = true);
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) {
          _safe(() => _isRecording = false);
          if (_isRecording && e.permanent == false) {
            Future.delayed(const Duration(milliseconds: 500), _restartListening);
          }
        },
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && _isRecording) {
            Future.delayed(const Duration(milliseconds: 300), _restartListening);
          }
        },
        debugLogging: false,
      );
      if (_speechAvailable && mounted) {
        final locales = await _speech.locales();
        final esLocales = locales.where((l) => l.localeId.toLowerCase().startsWith('es')).toList();
        if (esLocales.isNotEmpty) {
          final esEs = esLocales.firstWhere(
            (l) => l.localeId == 'es_ES' || l.localeId == 'es-ES' || l.localeId == 'es',
            orElse: () => esLocales.first,
          );
          _localeId = esEs.localeId;
        } else if (locales.isNotEmpty) {
          _localeId = locales.first.localeId;
        }
      }
    } catch (_) { _speechAvailable = false; }
    _safe(() => _isInitializing = false);
  }

  Future<void> _restartListening() async {
    if (!mounted || !_isRecording || !_speechAvailable || _speech.isListening) return;
    await _speech.listen(
      onResult: _onResult,
      localeId: _localeId.isNotEmpty ? _localeId : null,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true, cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _textoCapturado = result.recognizedWords;
      if (result.confidence > 0) _confianza = result.confidence;
    });
  }

  Future<void> _toggleRecording() async {
    if (_isInitializing) return;
    if (!_speechAvailable) {
      _showError();
      return;
    }
    if (!_isRecording) {
      _safe(() { _isRecording = true; _sec = 0; _textoCapturado = ''; _confianza = 0; });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _sec++);
      });
      await _speech.listen(
        onResult: _onResult,
        localeId: _localeId.isNotEmpty ? _localeId : null,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true, cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } else {
      await _speech.stop();
      _timer?.cancel();
      _safe(() => _isRecording = false);
      if (mounted && _textoCapturado.trim().isNotEmpty) _showGuardarDialog();
    }
  }

  void _showError() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: kNaranja),
          SizedBox(width: 8),
          Text('Micrófono no disponible', style: TextStyle(fontSize: 16)),
        ]),
        content: const Text(
          '1. Otorga permisos de micrófono\n'
          '2. Verifica conexión a internet\n'
          '3. En emulador: activa el micrófono en configuración AVD',
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _initSpeech(); }, child: const Text('Reintentar')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showGuardarDialog() {
    if (!mounted) return;
    final nombreProducto = _textoCapturado.trim();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kVerdeMenta, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.shopping_bag_outlined, color: kVerde),
            ),
            const SizedBox(width: 12),
            const Text('Agregar producto', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Nombre detectado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kVerdeMenta,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kVerdeClaro.withValues(alpha: 0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Producto detectado:', style: TextStyle(color: kVerdeMedio, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(nombreProducto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (_confianza > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: kVerdeClaro, size: 14),
                        const SizedBox(width: 4),
                        Text('Precisión: ${(_confianza * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, color: kVerdeClaro)),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 16),

              // Cantidad
              const Text('CANTIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _btnCantidad(Icons.remove, () {
                  if (_cantidadSeleccionada > 1) setDlg(() => _cantidadSeleccionada--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('$_cantidadSeleccionada',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kVerde)),
                ),
                _btnCantidad(Icons.add, () => setDlg(() => _cantidadSeleccionada++)),
              ]),
              const SizedBox(height: 16),

              // Categoría
              const Text('CATEGORÍA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setDlg(() => _categoriaSeleccionada = v); },
                decoration: InputDecoration(
                  filled: true, fillColor: kFondo,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Prioridad
              const Text('PRIORIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(children: ['Alta', 'Media', 'Baja'].map((p) {
                final isSelected = _prioridadSeleccionada == p;
                final color = p == 'Alta' ? kNaranja : (p == 'Media' ? kAmarillo : kVerdeClaro);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setDlg(() => _prioridadSeleccionada = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.15) : kFondo,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                        ),
                        child: Text(p, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: isSelected ? color : Colors.grey)),
                      ),
                    ),
                  ),
                );
              }).toList()),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kVerde, foregroundColor: kBlanco,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Agregar a lista'),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onProductoAgregado(Producto(
                  nombre: nombreProducto,
                  categoria: _categoriaSeleccionada,
                  cantidad: _cantidadSeleccionada,
                  prioridad: _prioridadSeleccionada,
                ));
                _safe(() { _textoCapturado = ''; _cantidadSeleccionada = 1; });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ "$nombreProducto" agregado a tu lista'),
                    backgroundColor: kVerde,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _btnCantidad(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: kVerdeMenta, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: kVerde, size: 22),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${(_sec ~/ 60).toString().padLeft(2, '0')}:${(_sec % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: kVerde,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 30),

            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SmartCart 🛒',
                  style: TextStyle(color: kBlanco, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(
                  _isInitializing ? 'Iniciando...' : (_isRecording ? 'Escuchando...' : 'Toca y habla'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.mic, color: kBlanco, size: 14),
                  const SizedBox(width: 4),
                  Text(_localeId.isEmpty ? 'auto' : _localeId,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ),
            ]),

            const SizedBox(height: 32),

            // Cronómetro
            Text(time,
              style: const TextStyle(
                color: kBlanco, fontSize: 72,
                fontWeight: FontWeight.bold, letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 24),

            // Caja de transcripción
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: _isInitializing
                  ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white54),
                        SizedBox(height: 16),
                        Text('Verificando micrófono...',
                          style: TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ))
                  : _textoCapturado.isEmpty
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(
                          _isRecording ? Icons.graphic_eq : Icons.shopping_basket_outlined,
                          color: Colors.white38, size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isRecording
                            ? 'Di el nombre del producto...\n"Leche", "Arroz", "Pollo"...'
                            : _speechAvailable
                              ? 'Toca el micrófono y di\nqué necesitas comprar'
                              : '⚠ Servicio de voz\nno disponible',
                          style: TextStyle(
                            color: _speechAvailable ? Colors.white54 : Colors.orangeAccent,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ])
                    : SingleChildScrollView(
                        reverse: true,
                        child: Text(
                          _textoCapturado,
                          style: const TextStyle(color: kBlanco, fontSize: 20, height: 1.6),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 36),

            // Botón micrófono
            GestureDetector(
              onTap: _isInitializing ? null : _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(_isRecording ? 20 : 26),
                decoration: BoxDecoration(
                  color: _isInitializing
                    ? Colors.white38
                    : (_isRecording ? kNaranja : kBlanco),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: _isRecording ? 8 : 0,
                  )],
                ),
                child: Icon(
                  _isInitializing
                    ? Icons.hourglass_top
                    : (_isRecording ? Icons.stop_rounded : Icons.mic),
                  color: _isRecording ? kBlanco : kVerde,
                  size: _isRecording ? 50 : 46,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              _isInitializing ? 'Espera...' : (_isRecording ? 'Toca para finalizar' : 'Toca para iniciar'),
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// PANTALLA 2: LISTA DE COMPRAS (con TTS)
// ─────────────────────────────────────────────────
class ListaComprasView extends StatefulWidget {
  final List<Producto> productos;
  final Function(int) onToggle;
  final Function(int) onEliminar;

  const ListaComprasView({
    super.key,
    required this.productos,
    required this.onToggle,
    required this.onEliminar,
  });

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
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() { _ttsActivo = false; _ttsPausado = false; });
    });
  }

  Future<void> _leerLista() async {
    final pendientes = widget.productos.where((p) => !p.comprado).toList();
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

  int get _totalComprados => widget.productos.where((p) => p.comprado).length;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = widget.productos.where((p) => !p.comprado).toList();
    final comprados  = widget.productos.where((p) => p.comprado).toList();
    final progreso   = widget.productos.isEmpty
      ? 0.0
      : _totalComprados / widget.productos.length;

    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        backgroundColor: kBlanco,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mi Lista 🛒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text('${widget.productos.length} productos • $_totalComprados comprados',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          // Botón leer lista en voz alta
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _leerLista,
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
      body: Column(children: [
        // Barra de progreso
        Container(
          color: kBlanco,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progreso', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          child: widget.productos.isEmpty
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
                      final idx = widget.productos.indexOf(p);
                      return _buildProductoCard(p, idx);
                    }),
                    const SizedBox(height: 16),
                  ],
                  if (comprados.isNotEmpty) ...[
                    _sectionHeader('Comprados ✓', comprados.length, Colors.grey),
                    const SizedBox(height: 8),
                    ...comprados.map((p) {
                      final idx = widget.productos.indexOf(p);
                      return _buildProductoCard(p, idx);
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

  Widget _buildProductoCard(Producto p, int idx) {
    final colorPrioridad = p.prioridad == 'Alta' ? kNaranja : (p.prioridad == 'Media' ? kAmarillo : kVerdeClaro);
    final iconoCategoria = _iconoCategoria(p.categoria);

    return Dismissible(
      key: Key('${p.nombre}_$idx'),
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
      onDismissed: (_) => widget.onEliminar(idx),
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
            onTap: () => widget.onToggle(idx),
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

// ─────────────────────────────────────────────────
// PANTALLA 3: CATEGORÍAS
// ─────────────────────────────────────────────────
class CategoriasView extends StatelessWidget {
  final List<Producto> productos;
  const CategoriasView({super.key, required this.productos});

  static const List<Map<String, dynamic>> _cats = [
    {'nombre': 'Lácteos',          'icon': Icons.egg_outlined,            'color': Color(0xFF29B6F6)},
    {'nombre': 'Carnes',           'icon': Icons.restaurant_outlined,     'color': Color(0xFFEF5350)},
    {'nombre': 'Frutas y Verduras','icon': Icons.eco_outlined,            'color': Color(0xFF66BB6A)},
    {'nombre': 'Panadería',        'icon': Icons.bakery_dining_outlined,  'color': Color(0xFFFF8A65)},
    {'nombre': 'Granos',           'icon': Icons.grain,                   'color': Color(0xFFFFCA28)},
    {'nombre': 'Bebidas',          'icon': Icons.local_drink_outlined,    'color': Color(0xFF7E57C2)},
    {'nombre': 'Limpieza',         'icon': Icons.clean_hands_outlined,    'color': Color(0xFF26C6DA)},
    {'nombre': 'Otros',            'icon': Icons.shopping_bag_outlined,   'color': Color(0xFF8D6E63)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _cats.map((cat) {
          final nombre = cat['nombre'] as String;
          final color  = cat['color'] as Color;
          final icon   = cat['icon'] as IconData;
          final items  = productos.where((p) => p.categoria == nombre).toList();
          final pendientes = items.where((p) => !p.comprado).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: kBlanco,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(
                  items.isEmpty
                    ? 'Sin productos'
                    : '$pendientes pendientes de ${items.length}',
                  style: TextStyle(fontSize: 12, color: pendientes > 0 ? kVerdeMedio : Colors.grey),
                ),
                trailing: items.isEmpty
                  ? const Icon(Icons.chevron_right, color: Colors.grey)
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${items.length}',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const Icon(Icons.expand_more, color: Colors.grey),
                    ]),
                children: items.isEmpty
                  ? [const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text('No hay productos en esta categoría.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )]
                  : items.map((p) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: Icon(
                        p.comprado ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: p.comprado ? kVerde : Colors.grey,
                        size: 20,
                      ),
                      title: Text(p.nombre,
                        style: TextStyle(
                          fontSize: 14,
                          color: p.comprado ? Colors.grey : Colors.black87,
                          decoration: p.comprado ? TextDecoration.lineThrough : null,
                        )),
                      trailing: Text('×${p.cantidad}',
                        style: const TextStyle(color: kVerdeMedio, fontWeight: FontWeight.bold)),
                    )).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// PANTALLA 4: PERFIL / ESTADÍSTICAS
// ─────────────────────────────────────────────────
class PerfilView extends StatelessWidget {
  final List<Producto> productos;
  const PerfilView({super.key, required this.productos});

  @override
  Widget build(BuildContext context) {
    final comprados  = productos.where((p) => p.comprado).length;
    final pendientes = productos.where((p) => !p.comprado).length;
    final alta       = productos.where((p) => p.prioridad == 'Alta' && !p.comprado).length;
    final progreso   = productos.isEmpty ? 0.0 : comprados / productos.length;

    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        backgroundColor: kFondo,
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // Avatar + nombre
          Center(child: Column(children: [
            Stack(children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kVerde, width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: kVerdeMenta,
                  child: const Icon(Icons.person_rounded, size: 55, color: kVerde),
                ),
              ),
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: kVerde, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: kBlanco, size: 13),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            const Text('Luis Reinoso', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Comprador frecuente 🛒',
              style: TextStyle(fontSize: 14, color: kVerdeMedio, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('100070497@p.uapa.edu.do', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ])),

          const SizedBox(height: 28),

          // Estadísticas de compras
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('RESUMEN DE COMPRAS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 12),

          Row(children: [
            _statCard('${productos.length}', 'Total', Icons.list_alt_rounded, kVerde),
            const SizedBox(width: 12),
            _statCard('$comprados', 'Comprados', Icons.check_circle_rounded, kVerdeClaro),
            const SizedBox(width: 12),
            _statCard('$pendientes', 'Pendientes', Icons.pending_rounded, kAmarillo),
          ]),

          const SizedBox(height: 12),

          // Progreso general
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kBlanco,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kVerdeMenta, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Progreso de compras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${(progreso * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: kVerde, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 10,
                  backgroundColor: kVerdeMenta,
                  valueColor: const AlwaysStoppedAnimation<Color>(kVerde),
                ),
              ),
              if (alta > 0) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: kNaranja, size: 16),
                  const SizedBox(width: 6),
                  Text('$alta productos de alta prioridad pendientes',
                    style: const TextStyle(fontSize: 12, color: kNaranja)),
                ]),
              ],
            ]),
          ),

          const SizedBox(height: 24),

          // Menú de opciones
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('CONFIGURACIÓN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 12),
          _menuItem(Icons.notifications_outlined, kNaranja, 'Notificaciones'),
          _menuItem(Icons.share_outlined, kVerdeClaro, 'Compartir lista'),
          _menuItem(Icons.history_rounded, kVerde, 'Historial de compras'),
          _menuItem(Icons.help_outline_rounded, Colors.blueGrey, 'Ayuda y Soporte'),
        ]),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kBlanco,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _menuItem(IconData icon, Color color, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}