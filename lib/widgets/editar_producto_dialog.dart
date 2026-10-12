import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class EditarProductoDialog {
  static void mostrar(
    BuildContext context,
    Producto p,
    ListaProvider provider,
  ) {
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
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final inputFill = isDark ? const Color(0xFF282828) : kFondo;
        final btnQtyBg = isDark ? kVerde.withValues(alpha: 0.25) : kVerdeMenta;
        final chipUnselectedBg = isDark ? const Color(0xFF282828) : kFondo;

        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Editar Producto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'CANTIDAD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (editCantidad > 1) {
                            setDlg(() => editCantidad--);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: btnQtyBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: kVerde,
                            size: 22,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$editCantidad',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kVerde,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setDlg(() => editCantidad++);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: btnQtyBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: kVerde, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'PRECIO ESTIMADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: editPrecio > 0 ? editPrecio.toString() : '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej. 150.50',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: kVerde,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) {
                      editPrecio = double.tryParse(v) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'CATEGORÍA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: categorias.contains(editCategoria)
                        ? editCategoria
                        : categorias.first,
                    items: categorias
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlg(() => editCategoria = v);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'PRIORIDAD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Alta', 'Media', 'Baja'].map((pri) {
                      final isSelected = editPrioridad == pri;
                      final color = pri == 'Alta'
                          ? kNaranja
                          : (pri == 'Media' ? kAmarillo : kVerdeClaro);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () => setDlg(() => editPrioridad = pri),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.15)
                                    : chipUnselectedBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? color : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                pri,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? color : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.eliminarProducto(p);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('🗑️ Producto eliminado'),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerde),
              onPressed: () {
                Navigator.pop(ctx);
                p.nombre = nombreCtrl.text.trim().isNotEmpty
                    ? nombreCtrl.text.trim()
                    : p.nombre;
                p.cantidad = editCantidad;
                p.precioEstimado = editPrecio;
                p.categoria = editCategoria;
                p.prioridad = editPrioridad;
                provider.actualizarProducto(p);
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
  }
}
