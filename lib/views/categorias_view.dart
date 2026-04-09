import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
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
    final provider = context.watch<ListaProvider>();
    final catalogo = provider.catalogo;
    final activos = provider.productos.map((e) => e.nombre).toList();

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
          final items  = catalogo.where((p) => p.categoria == nombre).toList();

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
                    ? 'Sin productos guardados'
                    : '${items.length} en historial',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text('Las cosas que compres en esta categoría aparecerán aquí para fácil acceso futuro.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  ...items.map((p) {
                      final yaEnLista = activos.contains(p.nombre);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        leading: Icon(
                          yaEnLista ? Icons.playlist_add_check_circle : Icons.history,
                          color: yaEnLista ? kVerde : color.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        title: Text(p.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            color: yaEnLista ? kVerde : Colors.black87,
                            fontWeight: yaEnLista ? FontWeight.bold : FontWeight.normal,
                          )),
                        subtitle: Text('\$${p.precioEstimado.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: IconButton(
                          icon: Icon(Icons.add_circle_outline, color: color),
                          onPressed: () => _mostrarAgregarDesdeCategoria(context, p, provider),
                        ),
                      );
                  }),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.add_box_outlined, color: color, size: 20),
                    ),
                    title: Text('Crear nuevo producto...', style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
                    onTap: () => _mostrarCrearNuevoEnCatalogo(context, nombre, color, provider),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _mostrarAgregarDesdeCategoria(BuildContext context, Producto baseP, ListaProvider provider) {
    int editCantidad = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Agregar ${baseP.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Último precio estimado: \$${baseP.precioEstimado.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
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
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerde),
              onPressed: () {
                Navigator.pop(ctx);
                final nuevoProducto = Producto(
                  nombre: baseP.nombre,
                  categoria: baseP.categoria,
                  prioridad: baseP.prioridad,
                  precioEstimado: baseP.precioEstimado,
                  cantidad: editCantidad,
                  comprado: false,
                );
                provider.agregarProducto(nuevoProducto);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${baseP.nombre} agregado a la lista'), backgroundColor: kVerde));
              },
              child: const Text('Agregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCrearNuevoEnCatalogo(BuildContext context, String categoria, Color color, ListaProvider provider) {
    final nombreCtrl = TextEditingController();
    double editPrecio = 0.0;
    String editPrioridad = 'Media';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nuevo - $categoria', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto',
                  filled: true, fillColor: kFondo,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('PRECIO ESTIMADO (Opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
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
              const Text('PRIORIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(children: ['Alta', 'Media', 'Baja'].map((pri) {
                final isSelected = editPrioridad == pri;
                final priColor = pri == 'Alta' ? kNaranja : (pri == 'Media' ? kAmarillo : kVerdeClaro);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setDlg(() => editPrioridad = pri),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: isSelected ? priColor.withValues(alpha: 0.15) : kFondo, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? priColor : Colors.transparent, width: 2)),
                        child: Text(pri, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? priColor : Colors.grey)),
                      ),
                    ),
                  ),
                );
              }).toList()),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color),
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final nuevoProducto = Producto(
                  nombre: nombreCtrl.text.trim(),
                  categoria: categoria,
                  prioridad: editPrioridad,
                  precioEstimado: editPrecio,
                  cantidad: 1,
                  comprado: false,
                );
                provider.agregarAlCatalogoDirecto(nuevoProducto);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Producto guardado en el catálogo'), backgroundColor: color));
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
