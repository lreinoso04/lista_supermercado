import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CerrandoSesionOverlay extends StatefulWidget {
  final String? nombreUsuario;

  const CerrandoSesionOverlay({
    super.key,
    this.nombreUsuario,
  });

  @override
  State<CerrandoSesionOverlay> createState() => _CerrandoSesionOverlayState();
}

class _CerrandoSesionOverlayState extends State<CerrandoSesionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nombreValido = widget.nombreUsuario != null &&
        widget.nombreUsuario!.trim().isNotEmpty &&
        widget.nombreUsuario!.trim().toLowerCase() != 'invitado';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kVerde.withValues(alpha: isDark ? 0.35 : 0.2),
                          blurRadius: 36,
                          spreadRadius: 6,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 72,
                      height: 72,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Cerrando sesión',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                if (nombreValido) ...[
                  const SizedBox(height: 8),
                  Text(
                    '¡Hasta pronto, ${widget.nombreUsuario!.trim()}! 👋',
                    style: const TextStyle(
                      fontSize: 15,
                      color: kVerdeMedio,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Asegurando tus datos y sincronizando...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(kVerde),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
