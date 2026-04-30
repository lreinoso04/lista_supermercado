import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/producto.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class AgregarVozView extends StatefulWidget {
  const AgregarVozView({super.key});

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

  String _categoriaSeleccionada = 'Lácteos';
  String _prioridadSeleccionada = 'Media';
  int _cantidadSeleccionada = 1;
  double _precioSeleccionado = 0.0;

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

  void _showKeyboardInput() {
    String manualName = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Escribir Producto', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Ej. Manzanas',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => manualName = val,
          onSubmitted: (val) {
            Navigator.pop(ctx);
            if (val.trim().isNotEmpty) {
              setState(() => _textoCapturado = val.trim());
              _showGuardarDialog();
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerde, foregroundColor: kBlanco),
            onPressed: () {
              Navigator.pop(ctx);
              if (manualName.trim().isNotEmpty) {
                setState(() => _textoCapturado = manualName.trim());
                _showGuardarDialog();
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
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

  Future<void> _escanearCodigo() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScanner(),
      ),
    );
    if (res is String && res != '-1') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buscando producto...')));
      try {
        final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$res.json');
        final response = await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 1 && data['product'] != null) {
            final nombre = data['product']['product_name_es'] ?? data['product']['product_name'] ?? '';
            if (nombre.isNotEmpty) {
              setState(() {
                _textoCapturado = nombre;
              });
              _showGuardarDialog();
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('Error buscando código: $e');
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto no encontrado en la base de datos.')));
    }
  }

  void _showGuardarDialog() {
    if (!mounted) return;
    final nombreProducto = _textoCapturado.trim();
    final provider = context.read<ListaProvider>();
    final categoriasList = provider.categorias.isEmpty 
        ? ['Otros'] 
        : provider.categorias.map((c) => c.nombre).toList();

    // Autocompletado desde el catálogo
    final prodCatalogo = provider.catalogo.where((p) => p.nombre.toLowerCase() == nombreProducto.toLowerCase()).firstOrNull;
    if (prodCatalogo != null) {
      if (categoriasList.contains(prodCatalogo.categoria)) {
        _categoriaSeleccionada = prodCatalogo.categoria;
      }
      _precioSeleccionado = prodCatalogo.precioEstimado;
      _prioridadSeleccionada = prodCatalogo.prioridad;
    } else {
      if (!categoriasList.contains(_categoriaSeleccionada)) {
        _categoriaSeleccionada = categoriasList.first;
      }
    }

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

              const Text('PRECIO ESTIMADO (Opcionado)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _precioSeleccionado > 0 ? _precioSeleccionado.toString() : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Ej. 150.50',
                  prefixIcon: const Icon(Icons.attach_money, color: kVerde, size: 18),
                  filled: true, fillColor: kFondo,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (v) {
                  _precioSeleccionado = double.tryParse(v) ?? 0.0;
                },
              ),
              const SizedBox(height: 16),

              const Text('CATEGORÍA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _categoriaSeleccionada,
                items: categoriasList.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { if (v != null) setDlg(() => _categoriaSeleccionada = v); },
                decoration: InputDecoration(
                  filled: true, fillColor: kFondo,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

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
                HapticFeedback.lightImpact();
                Navigator.pop(ctx);
                // Call Provider method here instead of callback
                context.read<ListaProvider>().agregarProducto(Producto(
                  nombre: nombreProducto,
                  categoria: _categoriaSeleccionada,
                  cantidad: _cantidadSeleccionada,
                  prioridad: _prioridadSeleccionada,
                  precioEstimado: _precioSeleccionado,
                ));
                _safe(() { _textoCapturado = ''; _cantidadSeleccionada = 1; _precioSeleccionado = 0.0; });
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

            Text(time,
              style: const TextStyle(
                color: kBlanco, fontSize: 72,
                fontWeight: FontWeight.bold, letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 24),

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
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _showKeyboardInput,
                  icon: const Icon(Icons.keyboard_alt_outlined, color: kBlanco, size: 20),
                  label: const Text('Manual', style: TextStyle(color: kBlanco)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _escanearCodigo,
                  icon: const Icon(Icons.qr_code_scanner_outlined, color: kBlanco, size: 20),
                  label: const Text('Escanear', style: TextStyle(color: kBlanco)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
