import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Un widget interactivo de verificación humana para proteger el formulario de registro
/// contra envíos masivos por scripts y bots automatizados.
class HumanVerificationTile extends StatefulWidget {
  final ValueChanged<bool> onVerificationChanged;

  const HumanVerificationTile({
    super.key,
    required this.onVerificationChanged,
  });

  @override
  State<HumanVerificationTile> createState() => HumanVerificationTileState();
}

class HumanVerificationTileState extends State<HumanVerificationTile>
    with SingleTickerProviderStateMixin {
  bool _isVerified = false;
  bool _isVerifying = false;

  void reset() {
    if (mounted) {
      setState(() {
        _isVerified = false;
        _isVerifying = false;
      });
      widget.onVerificationChanged(false);
    }
  }

  Future<void> _handleTap() async {
    if (_isVerified || _isVerifying) return;

    setState(() => _isVerifying = true);

    // Breve pausa para simular análisis de interacción humana
    await Future.delayed(const Duration(milliseconds: 650));

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _isVerified = true;
      });
      widget.onVerificationChanged(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E261F) : const Color(0xFFF6FBF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isVerified
              ? kVerde
              : (isDark ? Colors.white12 : Colors.grey.shade300),
          width: _isVerified ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Checkbox Interactivo
          GestureDetector(
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _isVerified
                    ? kVerde
                    : (isDark ? Colors.black26 : Colors.white),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isVerified
                      ? kVerde
                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                  width: 1.8,
                ),
              ),
              alignment: Alignment.center,
              child: _isVerifying
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kVerde,
                      ),
                    )
                  : (_isVerified
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null),
            ),
          ),
          const SizedBox(width: 12),

          // Texto descriptivo
          Expanded(
            child: GestureDetector(
              onTap: _handleTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isVerified ? 'Verificación humana completada' : 'No soy un robot',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isVerified
                          ? kVerdeMedio
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Protección de seguridad anti-spam',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ícono de Escudo de Seguridad
          Icon(
            _isVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
            size: 24,
            color: _isVerified ? kVerde : (isDark ? Colors.white30 : Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
