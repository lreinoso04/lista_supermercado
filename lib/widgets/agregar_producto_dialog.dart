import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/lista_provider.dart';
import '../theme/colors.dart';

class AgregarProductoDialog {
  static void mostrar({
    required BuildContext context,
    required String nombreProducto,
    double confianza = 0.0,
    VoidCallback? onCompletado,
  }) {
    if (nombreProducto.trim().isEmpty) return;

    final provider = context.read<ListaProvider>();
    final categoriasList = provider.categorias.isEmpty
        ? ['Otros']
        : provider.categorias.map((c) => c.nombre).toList();

    String categoriaSeleccionada = 'Lácteos';
    String prioridadSeleccionada = 'Media';
    int cantidadSeleccionada = 1;
    double precioSeleccionado = 0.0;

    // Autocompletado desde el catálogo
    final prodCatalogo = provider.catalogo
        .where((p) => p.nombre.toLowerCase() == nombreProducto.trim().toLowerCase())
        .firstOrNull;

    if (prodCatalogo != null) {
      if (categoriasList.contains(prodCatalogo.categoria)) {
        categoriaSeleccionada = prodCatalogo.categoria;
      }
      precioSeleccionado = prodCatalogo.precioEstimado;
      prioridadSeleccionada = prodCatalogo.prioridad;
    } else {
      if (!categoriasList.contains(categoriaSeleccionada)) {
        categoriaSeleccionada = categoriasList.first;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final inputFill = isDark ? const Color(0xFF282828) : kFondo;
        final btnQtyBg = isDark ? kVerde.withValues(alpha: 0.25) : kVerdeMenta;
        final detectedBg = isDark ? kVerde.withValues(alpha: 0.2) : kVerdeMenta;
        final detectedBorder = isDark ? kVerde.withValues(alpha: 0.4) : kVerdeClaro.withValues(alpha: 0.4);
        final chipUnselectedBg = isDark ? const Color(0xFF282828) : kFondo;
        final iconBoxBg = isDark ? kVerde.withValues(alpha: 0.25) : kVerdeMenta;

        Widget btnCantidad(IconData icon, VoidCallback onTap) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: btnQtyBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kVerde, size: 22),
            ),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBoxBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: kVerde),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Agregar producto',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: detectedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: detectedBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Producto detectado:',
                          style: TextStyle(
                            color: kVerdeMedio,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nombreProducto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (confianza > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: kVerdeClaro,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Precisión: ${(confianza * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kVerdeClaro,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                    btnCantidad(Icons.remove, () {
                      if (cantidadSeleccionada > 1) {
                        setDlg(() => cantidadSeleccionada--);
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '$cantidadSeleccionada',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kVerde,
                        ),
                      ),
                    ),
                    btnCantidad(
                      Icons.add,
                      () => setDlg(() => cantidadSeleccionada++),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'PRECIO ESTIMADO (Opcionado)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: precioSeleccionado > 0
                      ? precioSeleccionado.toString()
                      : '',
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
                    precioSeleccionado = double.tryParse(v) ?? 0.0;
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
                  initialValue: categoriaSeleccionada,
                  items: categoriasList
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlg(() => categoriaSeleccionada = v);
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
                  children: ['Alta', 'Media', 'Baja'].map((p) {
                    final isSelected = prioridadSeleccionada == p;
                    final color = p == 'Alta'
                        ? kNaranja
                        : (p == 'Media' ? kAmarillo : kVerdeClaro);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setDlg(() => prioridadSeleccionada = p),
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
                              p,
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kVerde,
                foregroundColor: kBlanco,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Agregar a lista'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx);
                context.read<ListaProvider>().agregarProducto(
                  Producto(
                    nombre: nombreProducto.trim(),
                    categoria: categoriaSeleccionada,
                    cantidad: cantidadSeleccionada,
                    prioridad: prioridadSeleccionada,
                    precioEstimado: precioSeleccionado,
                  ),
                );
                onCompletado?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ "${nombreProducto.trim()}" agregado a tu lista'),
                    backgroundColor: kVerde,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
  }
}
