import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notificacion_evento.dart';

class InAppNotificationBanner extends StatelessWidget {
  final NotificacionEvento evento;
  final String? tituloLote;
  final String? descripcionLote;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const InAppNotificationBanner({
    super.key,
    required this.evento,
    this.tituloLote,
    this.descripcionLote,
    required this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titulo = tituloLote ?? evento.obtenerTitulo();
    final descripcion = descripcionLote ?? evento.obtenerDescripcion();
    final icono = evento.obtenerIcono();
    final color = evento.obtenerColor();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Dismissible(
          key: Key('in_app_banner_${evento.id}'),
          direction: DismissDirection.up,
          onDismissed: (_) {
            HapticFeedback.lightImpact();
            onDismiss();
          },
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
            borderRadius: BorderRadius.circular(18),
            color: isDark ? const Color(0xFF252525) : Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.selectionClick();
                if (onTap != null) {
                  onTap!();
                }
                onDismiss();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.4 : 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icono, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                titulo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Ahora',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            descripcion,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
