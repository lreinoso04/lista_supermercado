import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/historial_compra.dart';
import '../models/producto.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
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
  bool _wasSyncing = false;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final res = await DBService.instance.readAllHistorial();
    if (mounted) {
      setState(() {
        _historial = res;
        _isLoading = false;
      });
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeBg = isDark ? kVerde.withValues(alpha: 0.25) : kVerdeMenta;
    final handleColor = isDark ? Colors.white24 : Colors.grey.shade300;

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
                  decoration: BoxDecoration(color: handleColor, borderRadius: BorderRadius.circular(10)),
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
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
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

  Future<void> _eliminarHistorial(HistorialCompra h, int index) async {
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
      if (mounted) {
        await context.read<ListaProvider>().eliminarHistorial(h);
      } else {
        if (h.id != null) {
          await DBService.instance.deleteHistorial(h.id!);
        } else {
          await DBService.instance.deleteHistorialByUuid(h.uuid);
        }
        final user = AuthService.instance.currentUser;
        if (user != null) {
          await FirebaseService.instance.eliminarHistorialUsuario(user.uid, h.uuid);
        }
      }

      if (mounted) {
        setState(() {
          _historial.removeAt(index);
        });
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
    final listaProvider = context.watch<ListaProvider>();

    if (_wasSyncing && !listaProvider.isSyncingHistorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cargarHistorial();
      });
    }
    _wasSyncing = listaProvider.isSyncingHistorial;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Historial de Compras', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: listaProvider.isSyncingHistorial
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kVerde),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sincronizar historial con la nube',
            onPressed: listaProvider.isSyncingHistorial
                ? null
                : () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text('Sincronizando compras desde la nube...'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                        backgroundColor: kVerde,
                      ),
                    );
                    await listaProvider.sincronizarHistorialConFirebase();
                    await _cargarHistorial();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historial sincronizado correctamente.'),
                          duration: Duration(seconds: 2),
                          backgroundColor: kVerde,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (listaProvider.isSyncingHistorial)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: kVerde.withValues(alpha: 0.12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kVerde),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Sincronizando compras desde la nube...',
                    style: TextStyle(
                      color: kVerde,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historial.isEmpty
                    ? const Center(
                        child: Text('No hay compras registradas.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        itemCount: _historial.length,
                        itemBuilder: (context, index) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final verBtnBg = isDark ? kVerde.withValues(alpha: 0.25) : kVerdeMenta;
                          final h = _historial[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabecera: Fecha y Precio Total
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _formatDate(h.fecha),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\$${h.total.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, color: kVerde, fontSize: 17),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Metadatos y Badges en Wrap (Totalmente responsivo a textos largos)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.shopping_cart_checkout_rounded, size: 13, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${h.cantidadProductos} productos',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (h.pinLista != null && h.pinLista!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: kNaranja.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.share_rounded, size: 12, color: kNaranja),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Lista: ${h.pinLista}',
                                              style: const TextStyle(fontSize: 11, color: kNaranja, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (h.finalizadoPorNombre != null && h.finalizadoPorNombre!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: kVerde.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person_rounded, size: 12, color: kVerdeMedio),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Por: ${h.finalizadoPorNombre}',
                                              style: const TextStyle(fontSize: 11, color: kVerdeMedio, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Divider(height: 1, thickness: 1, color: Colors.grey.withValues(alpha: 0.1)),
                                const SizedBox(height: 10),

                                // Fila de Acciones inferior (Espaciosa y adaptable)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _abrirDetalle(h),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: verBtnBg, borderRadius: BorderRadius.circular(8)),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.visibility_outlined, size: 14, color: kVerde),
                                            SizedBox(width: 4),
                                            Text('Ver', style: TextStyle(color: kVerde, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _reutilizarHistorial(context, h),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: kNaranja.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.replay_rounded, size: 14, color: kNaranja),
                                            SizedBox(width: 4),
                                            Text('Reutilizar', style: TextStyle(color: kNaranja, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _eliminarHistorial(h, index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                                            SizedBox(width: 4),
                                            Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

