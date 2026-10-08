import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/producto.dart';
import '../models/historial_compra.dart';
import '../providers/lista_provider.dart';
import '../services/auth_service.dart';
import '../widgets/google_logo.dart';
import '../widgets/cerrando_sesion_overlay.dart';
import '../main.dart';
import '../theme/colors.dart';
import 'historial_compras_view.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  String _nombre = "Cargando...";
  String _rol = "Comprador frecuente";
  String _email = "";
  String _telefonoSMS = "";
  String _emoji = "👤";
  String? _fotoPath;
  bool _notificacionesActivas = true;
  StreamSubscription<User?>? _authSubscription;

  static const List<String> _emojisDisponibles = [
    '👤', '🧑', '👨', '👩', '👴', '👵', '👶', 
    '🧑‍⚕️', '🧑‍🎓', '🧑‍🏫', '🧑‍⚖️', '🧑‍🌾', '🧑‍🍳', 
    '🧑‍🔧', '🧑‍🏭', '🧑‍💼', '🧑‍🔬', '🧑‍💻', '🧑‍🎤', 
    '🧑‍🎨', '🧑‍✈️', '🧑‍🚀', '🧑‍🚒', '👮', '🕵️', 
    '💂', '🥷', '🦸', '🦹'
  ];

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
    _authSubscription = AuthService.instance.authStateChanges.listen((_) {
      if (mounted) {
        _cargarPreferencias();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final user = AuthService.instance.currentUser;
    if (!mounted) return;

    setState(() {
      if (user != null) {
        // 1. Usuario autenticado (Email o Google)
        final uid = user.uid;
        final localSavedName = prefs.getString('user_name_$uid');

        if (localSavedName != null && localSavedName.trim().isNotEmpty) {
          _nombre = localSavedName.trim();
        } else if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          _nombre = user.displayName!.trim();
          prefs.setString('user_name_$uid', _nombre);
        } else {
          _nombre = user.email?.split('@').first ?? "Usuario";
        }

        _email = user.email ?? "";
        _rol = prefs.getString('user_rol_$uid') ?? "Comprador frecuente";
        _emoji = prefs.getString('user_emoji_$uid') ?? "👤";
        _fotoPath = prefs.getString('user_foto_$uid');
        _telefonoSMS = prefs.getString('user_telefono_$uid') ?? "";
        _notificacionesActivas = prefs.getBool('user_notifs_$uid') ?? true;
      } else {
        // 2. Modo Invitado (Aislado de cuentas de usuario anteriores)
        _nombre = prefs.getString('guest_nombre') ?? "Invitado";
        _email = "invitado@smartcart.app";
        _rol = prefs.getString('guest_rol') ?? "Comprador invitado";
        _emoji = prefs.getString('guest_emoji') ?? "👤";
        _fotoPath = prefs.getString('guest_foto_path');
        _telefonoSMS = prefs.getString('guest_telefono') ?? "";
        _notificacionesActivas = prefs.getBool('guest_notifs') ?? true;
      }
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cerrar tu sesión en SmartCart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) return;
      final nav = rootNavigatorKey.currentState;
      final listaProvider = Provider.of<ListaProvider>(context, listen: false);
      final nombreCierre = _nombre;

      // 1. Desplegar pantalla de transición animada a pantalla completa
      nav?.push(
        PageRouteBuilder(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          pageBuilder: (context, animation, secondaryAnimation) => CerrandoSesionOverlay(
            nombreUsuario: nombreCierre,
          ),
        ),
      );

      // 2. Limpieza de datos en segundo plano mientras corre la animación
      try {
        await Future.wait([
          Future<void>(() async {
            await listaProvider.limpiarDatosLocalesPorCierreDeSesion();

            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('smartcart_guest_mode');
            await prefs.remove('current_session_uid');

            await AuthService.instance.signOut();
          }),
          Future.delayed(const Duration(milliseconds: 1500)),
        ]);
      } catch (e) {
        debugPrint("Error cerrando sesión: $e");
        await AuthService.instance.signOut();
      } finally {
        // 3. Remover el overlay para revelar la pantalla de Login limpia
        if (nav != null && nav.canPop()) {
          nav.pop();
        }
      }
    }
  }

  Widget _buildAuthBadge(User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kNaranja.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kNaranja.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, size: 14, color: kNaranja),
            SizedBox(width: 6),
            Text('Modo Invitado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kNaranja)),
          ],
        ),
      );
    }

    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGoogle) ...[
            const GoogleLogo(size: 14),
            const SizedBox(width: 6),
            const Text('Cuenta Google', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ] else if (user.emailVerified) ...[
            const Icon(Icons.verified_user_rounded, size: 14, color: kVerde),
            const SizedBox(width: 6),
            const Text('Correo Verificado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kVerde)),
          ] else ...[
            const Icon(Icons.warning_amber_rounded, size: 14, color: kNaranja),
            const SizedBox(width: 6),
            const Text('Correo Pendiente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kNaranja)),
          ],
        ],
      ),
    );
  }

  Future<void> _guardarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final user = AuthService.instance.currentUser;

    if (user != null) {
      final uid = user.uid;
      await prefs.setString('user_name_$uid', _nombre);
      await prefs.setString('user_rol_$uid', _rol);
      await prefs.setString('user_telefono_$uid', _telefonoSMS);
      await prefs.setString('user_emoji_$uid', _emoji);
      if (_fotoPath != null) {
        await prefs.setString('user_foto_$uid', _fotoPath!);
      } else {
        await prefs.remove('user_foto_$uid');
      }
      await prefs.setBool('user_notifs_$uid', _notificacionesActivas);

      if (user.displayName != _nombre && _nombre.isNotEmpty) {
        try {
          await user.updateDisplayName(_nombre);
        } catch (_) {}
      }
    } else {
      await prefs.setString('guest_nombre', _nombre);
      await prefs.setString('guest_rol', _rol);
      await prefs.setString('guest_telefono', _telefonoSMS);
      await prefs.setString('guest_emoji', _emoji);
      if (_fotoPath != null) {
        await prefs.setString('guest_foto_path', _fotoPath!);
      } else {
        await prefs.remove('guest_foto_path');
      }
      await prefs.setBool('guest_notifs', _notificacionesActivas);
    }
  }

  void _editarPerfil() {
    final user = AuthService.instance.currentUser;
    final nombreCtrl = TextEditingController(text: _nombre);
    final rolCtrl = TextEditingController(text: _rol);
    final emailCtrl = TextEditingController(text: _email);
    final telefonoCtrl = TextEditingController(text: _telefonoSMS);
    String selectedEmoji = _emoji;
    String? selectedFotoPath = _fotoPath;
    final picker = ImagePicker();

    Future<void> pickImage(StateSetter setStateDialog) async {
      try {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final directory = await getApplicationDocumentsDirectory();
          final String path = directory.path;
          final fileName = 'perfil_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File localFile = await File(image.path).copy('$path/$fileName');
          
          setStateDialog(() {
            selectedFotoPath = localFile.path;
          });
        }
      } catch (e) {
        debugPrint("Error al seleccionar imagen: $e");
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vista previa de Foto / Emoji
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: kVerdeMenta,
                    backgroundImage: selectedFotoPath != null ? FileImage(File(selectedFotoPath!)) : null,
                    child: selectedFotoPath == null
                        ? Text(
                            selectedEmoji,
                            style: const TextStyle(fontSize: 44),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Botones para subir foto o eliminar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kVerdeMenta,
                        foregroundColor: kVerde,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => pickImage(setStateDialog),
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: const Text('Galería', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    if (selectedFotoPath != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: () {
                          setStateDialog(() {
                            selectedFotoPath = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Usar Emoji', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecciona un Emoji de Avatar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _emojisDisponibles.map((em) {
                      final isSelected = em == selectedEmoji;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedEmoji = em;
                            selectedFotoPath = null; 
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? kVerde.withValues(alpha: 0.15) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? kVerde : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            em,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: rolCtrl, decoration: const InputDecoration(labelText: 'Rol o Título')),
                TextField(
                  controller: emailCtrl,
                  readOnly: user != null,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    helperText: user != null ? 'Vinculado a tu cuenta de autenticación' : null,
                  ),
                ),
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono para SMS',
                    helperText: 'Destinatario de la lista que realizará la compra.',
                    helperMaxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerde),
              onPressed: () {
                setState(() {
                  _emoji = selectedEmoji;
                  _fotoPath = selectedFotoPath;
                  _nombre = nombreCtrl.text.trim();
                  _rol = rolCtrl.text.trim();
                  if (user == null) {
                    _email = emailCtrl.text.trim();
                  }
                  _telefonoSMS = telefonoCtrl.text.trim();
                });
                _guardarPreferencias();
                Navigator.pop(ctx);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _compartirLista(List<Producto> productos) {
    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tu lista está vacía.')));
      return;
    }
    final sb = StringBuffer();
    sb.writeln('🛒 *Mi Lista de Compras (SmartCart)*\n');
    for (var p in productos) {
      final estado = p.comprado ? '✅' : '⏳';
      sb.writeln('$estado ${p.nombre} (x${p.cantidad})');
    }
    Share.share(sb.toString());
  }

  Future<void> _abrirSoporte() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'soporte@gmail.com',
      queryParameters: {
        'subject': 'Soporte Técnico - SmartCart App',
      },
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el cliente de correo. Escribe directamente a soporte@gmail.com')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaProvider = context.watch<ListaProvider>();
    final productos = listaProvider.productos;
    final historial = listaProvider.historial;
    final user = AuthService.instance.currentUser;

    ImageProvider? avatarImg;
    if (_fotoPath != null && _fotoPath!.isNotEmpty) {
      avatarImg = FileImage(File(_fotoPath!));
    } else if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      avatarImg = NetworkImage(user.photoURL!);
    }

    final comprados  = productos.where((p) => p.comprado).length;
    final pendientes = productos.where((p) => !p.comprado).length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(children: [

          // Avatar + nombre
          Center(child: Column(children: [
            Stack(children: [
              GestureDetector(
                onTap: _editarPerfil,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kVerde, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).cardColor,
                    backgroundImage: avatarImg,
                    child: avatarImg == null
                        ? Text(
                            _emoji,
                            style: const TextStyle(fontSize: 52),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 2, right: 2,
                child: GestureDetector(
                  onTap: _editarPerfil,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: kVerde, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: kBlanco, size: 13),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text(_nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$_rol 🛒', style: const TextStyle(fontSize: 14, color: kVerdeMedio, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(_email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildAuthBadge(user),
          ])),

          const SizedBox(height: 28),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('RESUMEN ACTUAL',
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

          if (context.watch<ListaProvider>().gastoTotal > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kVerdeClaro.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kVerde.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.monetization_on_rounded, color: kVerde),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gasto en curso', style: TextStyle(fontSize: 12, color: kVerdeMedio, fontWeight: FontWeight.bold)),
                  Text('\$${context.watch<ListaProvider>().gastoTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kVerde)),
                ]),
              ]),
            ),
          ],

          if (historial.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('TENDENCIA DE GASTOS (ÚLTIMAS 5 COMPRAS)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _buildChartBars(historial),
              ),
            ),
          ],

          const SizedBox(height: 24),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('CONFIGURACIÓN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 12),
          
          _menuItemSwitch(Icons.notifications_outlined, kNaranja, 'Notificaciones', _notificacionesActivas, (val) {
            setState(() { _notificacionesActivas = val; });
            _guardarPreferencias();
          }),
          _menuItem(Icons.share_outlined, kVerdeClaro, 'Compartir lista', onTap: () => _compartirLista(productos)),
          _menuItem(Icons.history_rounded, kVerde, 'Historial de compras', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialComprasView()));
          }),
          _menuItem(Icons.help_outline_rounded, Colors.blueGrey, 'Ayuda y Soporte', onTap: _abrirSoporte),
          const SizedBox(height: 6),
          if (user != null)
            _menuItem(Icons.logout_rounded, Colors.redAccent, 'Cerrar sesión', onTap: _cerrarSesion)
          else
            _menuItem(Icons.login_rounded, kVerde, 'Iniciar sesión / Registrarse', onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('smartcart_guest_mode');
              if (context.mounted) {
                // Forzar reconstrucción de AuthGate al volver
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            }),
        ]),
      ),
    ),
  );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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

  Widget _menuItem(IconData icon, Color color, String label, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
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
        onTap: onTap,
      ),
    );
  }

  Widget _menuItemSwitch(IconData icon, Color color, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: kVerde,
      ),
    );
  }

  List<Widget> _buildChartBars(List<HistorialCompra> historial) {
    final list = historial.take(5).toList().reversed.toList();
    if (list.isEmpty) return [];
    
    final maxTotal = list.fold<double>(0.0, (m, h) => h.total > m ? h.total : m);
    
    return list.map((h) {
      final height = maxTotal > 0 ? (h.total / maxTotal) * 70 : 0.0;
      final date = DateTime.tryParse(h.fecha);
      final label = date != null ? '${date.day}/${date.month}' : '';
      
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('\$${h.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: kVerdeMedio, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: height > 0 ? height : 4,
            decoration: BoxDecoration(
              color: kVerde,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      );
    }).toList();
  }
}
