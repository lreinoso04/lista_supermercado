import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    // Read from Provider
    final productos = context.watch<ListaProvider>().productos;

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
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/foto_luis.jpg'),
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
                  const Text('Dinero en Carrito', style: TextStyle(fontSize: 12, color: kVerdeMedio, fontWeight: FontWeight.bold)),
                  Text('\$${context.watch<ListaProvider>().gastoTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kVerde)),
                ]),
              ]),
            ),
          ],

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
