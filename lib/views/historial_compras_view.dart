import 'package:flutter/material.dart';
import '../models/historial_compra.dart';
import '../services/db_service.dart';
import '../theme/colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: const Text('Historial de Compras', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _historial.isEmpty
          ? const Center(
              child: Text('No hay compras registradas.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _historial.length,
              itemBuilder: (context, index) {
                final h = _historial[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBlanco,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kVerdeMenta, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kVerde.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: kVerde),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(h.fecha), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${h.cantidadProductos} productos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        '\$${h.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: kVerde, fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
