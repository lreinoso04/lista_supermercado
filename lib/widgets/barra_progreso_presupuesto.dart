import 'package:flutter/material.dart';
import '../theme/colors.dart';

class BarraProgresoPresupuesto extends StatelessWidget {
  final double progreso;
  final double gastoTotal;

  const BarraProgresoPresupuesto({
    super.key,
    required this.progreso,
    required this.gastoTotal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? Colors.white12 : kVerdeMenta;

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${(progreso * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kVerde,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: trackColor,
              valueColor: const AlwaysStoppedAnimation<Color>(kVerde),
            ),
          ),
          if (gastoTotal > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gasto en carrito',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '\$${gastoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: kVerdeMedio,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
