import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class CategoriasView extends StatelessWidget {
  const CategoriasView({super.key});

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
    // Read from Provider
    final productos = context.watch<ListaProvider>().productos;

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
