import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/producto.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';
import 'historial_compras_view.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  String _nombre = "Luis Reinoso";
  String _rol = "Comprador frecuente";
  String _email = "100070497@p.uapa.edu.do";
  bool _notificacionesActivas = true;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('perfil_nombre') ?? "Luis Reinoso";
      _rol = prefs.getString('perfil_rol') ?? "Comprador frecuente";
      _email = prefs.getString('perfil_email') ?? "100070497@p.uapa.edu.do";
      _notificacionesActivas = prefs.getBool('perfil_notifs') ?? true;
    });
  }

  Future<void> _guardarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfil_nombre', _nombre);
    await prefs.setString('perfil_rol', _rol);
    await prefs.setString('perfil_email', _email);
    await prefs.setBool('perfil_notifs', _notificacionesActivas);
  }

  void _editarPerfil() {
    final nombreCtrl = TextEditingController(text: _nombre);
    final rolCtrl = TextEditingController(text: _rol);
    final emailCtrl = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: rolCtrl, decoration: const InputDecoration(labelText: 'Rol o Título')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo Electrónico')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerde),
            onPressed: () {
              setState(() {
                _nombre = nombreCtrl.text.trim();
                _rol = rolCtrl.text.trim();
                _email = emailCtrl.text.trim();
              });
              _guardarPreferencias();
              Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
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
    final productos = context.watch<ListaProvider>().productos;

    final comprados  = productos.where((p) => p.comprado).length;
    final pendientes = productos.where((p) => !p.comprado).length;
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        backgroundColor: kFondo,
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/foto_luis.jpg'),
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
                color: kVerdeMenta,
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
                  const Text('Dinero Gasto', style: TextStyle(fontSize: 12, color: kVerdeMedio, fontWeight: FontWeight.bold)),
                  Text('\$${context.watch<ListaProvider>().gastoTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kVerde)),
                ]),
              ]),
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

  Widget _menuItem(IconData icon, Color color, String label, {VoidCallback? onTap}) {
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
        onTap: onTap,
      ),
    );
  }

  Widget _menuItemSwitch(IconData icon, Color color, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5E9)),
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
}
