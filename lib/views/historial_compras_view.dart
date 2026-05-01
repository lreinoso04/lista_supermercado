import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/historial_compra.dart';
import '../models/producto.dart';
import '../services/db_service.dart';
import '../theme/colors.dart';
import 'package:provider/provider.dart';
import '../providers/lista_provider.dart';

class HistorialComprasView extends StatefulWidget {
  const HistorialComprasView({super.key});

  @override
  State<HistorialComprasView> createState() => _HistorialComprasViewState();
}

class _HistorialComprasViewState extends State<HistorialComprasView> {
  List<HistorialCompra> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final res = await DBService.instance.readAllHistorial();
    setState(() {
      _historial = res;
      _isLoading = false;
    });
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  void _mostrarDetalleCompra(BuildContext context, HistorialCompra h, List<Producto> productos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalle de compra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kVerde)),
                    const SizedBox(height: 6),
                    Text(_formatDate(h.fecha), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: \$${h.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kVerdeMedio)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kVerdeMenta, borderRadius: BorderRadius.circular(10)),
                      child: Text('${h.cantidadProductos} Prods', style: const TextStyle(color: kVerde, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: productos.length,
                  itemBuilder: (ctx, i) {
                    final p = productos[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: kVerde.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.check_circle_outline, color: kVerde, size: 20),
                      ),
                      title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(p.categoria, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('x${p.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, color: kVerdeMedio)),
                          if (p.precioEstimado > 0)
                            Text('\$${(p.precioEstimado * p.cantidad).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ]
          )
        )
      )
    );
  }

  Future<void> _eliminarHistorial(int id, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Historial?'),
        content: const Text('Esta acción quitará el registro de tus compras.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );

    if (confirm == true) {
      await DBService.instance.deleteHistorial(id);
      setState(() {
        _historial.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
      }
    }
  }

  void _abrirDetalle(HistorialCompra h) {
    if (h.productosJson != null && h.productosJson!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(h.productosJson!);
        final prods = decoded.map((p) => Producto.fromMap(p as Map<String, dynamic>)).toList();
        _mostrarDetalleCompra(context, h, prods);
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudieron cargar los detalles de esta compra antigua.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta compra no tiene detalles registrados.')));
    }
  }

  void _reutilizarHistorial(BuildContext context, HistorialCompra h) {
    if (h.productosJson == null || h.productosJson!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta compra no tiene productos para reutilizar.')));
      return;
    }

    final provider = context.read<ListaProvider>();
    final hayProductos = provider.productos.isNotEmpty;

    if (hayProductos) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Sustituir lista actual?'),
          content: const Text('Ya tienes productos en tu lista de compras. Esto va a sustituir lo que está en la lista actualmente. ¿Deseas continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('No', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerde),
              onPressed: () {
                Navigator.pop(ctx);
                provider.cargarListaDesdeHistorial(h, sustituir: true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista sustituida correctamente.'), backgroundColor: kVerde));
              },
              child: const Text('Sí', style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      );
    } else {
      provider.cargarListaDesdeHistorial(h, sustituir: false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Productos agregados a la lista.'), backgroundColor: kVerde));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Historial de Compras', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _historial.isEmpty
          ? const Center(
              child: Text('No hay compras registradas.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: _historial.length,
              itemBuilder: (context, index) {
                final h = _historial[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kVerde.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/icon.png', height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: kVerde)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(h.fecha), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.shopping_cart_checkout_rounded, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${h.cantidadProductos} productos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${h.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: kVerde, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _abrirDetalle(h),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: kVerdeMenta, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Ver', style: TextStyle(color: kVerde, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _reutilizarHistorial(context, h),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: kNaranja.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Reutilizar', style: TextStyle(color: kNaranja, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (h.id != null) _eliminarHistorial(h.id!, index);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

