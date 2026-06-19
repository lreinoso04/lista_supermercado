import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../theme/colors.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTapEdit;
  final VoidCallback onToggleComprado;
  final VoidCallback onDismissed;
  final bool isReadOnly;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onTapEdit,
    required this.onToggleComprado,
    required this.onDismissed,
    this.isReadOnly = false,
  });

  IconData _iconoCategoria(String cat) {
    switch (cat) {
      case 'Lácteos':
        return Icons.egg_outlined;
      case 'Carnes':
        return Icons.restaurant_outlined;
      case 'Frutas y Verduras':
        return Icons.eco_outlined;
      case 'Panadería':
        return Icons.bakery_dining_outlined;
      case 'Granos':
        return Icons.grain;
      case 'Bebidas':
        return Icons.local_drink_outlined;
      case 'Limpieza':
        return Icons.clean_hands_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrioridad = producto.prioridad == 'Alta'
        ? kNaranja
        : (producto.prioridad == 'Media' ? kAmarillo : kVerdeClaro);
    final iconoCategoria = _iconoCategoria(producto.categoria);

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: producto.comprado
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: producto.comprado
              ? Colors.grey.withValues(alpha: 0.2)
              : kVerdeMenta,
          width: 1.5,
        ),
        boxShadow: producto.comprado
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        onTap: isReadOnly ? null : onTapEdit,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: GestureDetector(
          onTap: isReadOnly
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onToggleComprado();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: producto.comprado ? kVerde : kVerdeMenta,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              producto.comprado ? Icons.check_rounded : iconoCategoria,
              color: producto.comprado ? kBlanco : kVerde,
              size: 22,
            ),
          ),
        ),
        title: Text(
          producto.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: producto.comprado
                ? Colors.grey
                : Theme.of(context).colorScheme.onSurface,
            decoration: producto.comprado ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              producto.categoria,
              style: TextStyle(
                fontSize: 12,
                color: producto.comprado ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colorPrioridad.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                producto.prioridad,
                style: TextStyle(
                  fontSize: 10,
                  color: colorPrioridad,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '×${producto.cantidad}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kVerdeMedio,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (producto.precioEstimado > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '\$${(producto.precioEstimado * producto.cantidad).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isReadOnly) ...[
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade400),
            ]
          ],
        ),
      ),
    );

    if (isReadOnly) {
      return cardContent;
    }

    return Dismissible(
      key: Key('prod_${producto.id}_${producto.nombre}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => onDismissed(),
      child: cardContent,
    );
  }
}
