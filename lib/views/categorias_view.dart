import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../models/categoria_model.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class CategoriasView extends StatelessWidget {
  const CategoriasView({super.key});

  static const List<IconData> iconOptions = [
     Icons.label_important, Icons.egg_outlined, Icons.restaurant_outlined, Icons.eco_outlined,
     Icons.bakery_dining_outlined, Icons.grain, Icons.local_drink_outlined, Icons.clean_hands_outlined,
     Icons.shopping_bag_outlined, Icons.fastfood_outlined, Icons.local_cafe_outlined, Icons.pets_outlined,
     Icons.child_care, Icons.medical_services_outlined, Icons.home_outlined
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListaProvider>();
    final catalogo = provider.catalogo;
    final activos = provider.productos.map((e) => e.nombre).toList();
    final categorias = provider.categorias;

    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          backgroundColor: kVerde,
          tooltip: 'Crear nueva categoría',
          onPressed: () => _mostrarDialogoCategoria(context, provider, null),
          child: const Icon(Icons.add, color: kBlanco),
        ),
      ),
      body: categorias.isEmpty 
        ? const Center(child: Text('No hay categorías guardadas', style: TextStyle(color: Colors.grey)))
        : ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: categorias.map((cat) {
          final nombre = cat.nombre;
          final color  = Color(cat.colorValue);
          final icon   = CategoriasView.iconOptions.firstWhere((i) => i.codePoint == cat.iconCode, orElse: () => Icons.label_important);
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
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
                    onPressed: () => _mostrarDialogoCategoria(context, provider, cat),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: Colors.red.shade300),
                    onPressed: () => _eliminarCategoria(context, provider, cat, items.length),
                  ),
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

  void _eliminarCategoria(BuildContext context, ListaProvider provider, CategoriaModel cat, int itemsCount) {
    if (itemsCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No puedes eliminar una categoría con productos. Borra o recategoriza los productos primero.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Eliminar Categoría'),
      content: Text('¿Seguro que deseas eliminar la categoría "${cat.nombre}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () { provider.eliminarCategoria(cat); Navigator.pop(ctx); },
          child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        )
      ]
    ));
  }

  void _mostrarDialogoCategoria(BuildContext context, ListaProvider provider, CategoriaModel? existingCat) {
    final nombreCtrl = TextEditingController(text: existingCat?.nombre ?? '');
    int iconCode = existingCat?.iconCode ?? Icons.label_important.codePoint;
    Color colorSelection = existingCat != null ? Color(existingCat.colorValue) : kVerdeMedio;

    final List<Color> colorOptions = [
       kVerdeMedio, Colors.blue.shade400, Colors.red.shade400, Colors.orange.shade400, 
       Colors.purple.shade400, Colors.teal.shade400, Colors.brown.shade400, Colors.pink.shade400,
       Colors.amber.shade600, Colors.indigo.shade400, Colors.cyan.shade400
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existingCat == null ? 'Nueva Categoría' : 'Editar Categoría', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre de categoría',
                  filled: true, fillColor: kFondo,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Ícono', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: CategoriasView.iconOptions.map((i) => ChoiceChip(
                label: Icon(i, color: iconCode == i.codePoint ? Colors.white : Colors.grey.shade700, size: 20),
                selected: iconCode == i.codePoint,
                selectedColor: colorSelection,
                backgroundColor: kFondo,
                showCheckmark: false,
                onSelected: (val) { if(val) setDlg(() => iconCode = i.codePoint); }
              )).toList()),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 12, children: colorOptions.map((c) => GestureDetector(
                onTap: () => setDlg(() => colorSelection = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: colorSelection == c ? Border.all(color: Colors.black26, width: 2) : null,
                  ),
                  child: colorSelection == c ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                ),
              )).toList()),
            ])
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorSelection),
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                if (existingCat == null) {
                  provider.agregarCategoria(CategoriaModel(
                    nombre: nombreCtrl.text.trim(), 
                    colorValue: colorSelection.toARGB32(), 
                    iconCode: iconCode
                  ));
                } else {
                  existingCat.nombre = nombreCtrl.text.trim();
                  existingCat.colorValue = colorSelection.toARGB32();
                  existingCat.iconCode = iconCode;
                  provider.actualizarCategoria(existingCat);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white))
            )
          ]
        )
      )
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
