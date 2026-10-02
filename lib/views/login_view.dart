import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../widgets/google_logo.dart';
import '../widgets/human_verification_tile.dart';

class LoginView extends StatefulWidget {
  final VoidCallback? onGuestContinue;

  const LoginView({super.key, this.onGuestContinue});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isHumanVerified = false;

  // Temporizador para bloqueo de fuerza bruta
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  // Campo trampa (Honeypot) anti-bot
  final TextEditingController _honeypotController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  void _checkLockout() {
    if (AuthService.instance.isLoginLocked()) {
      _startLockoutTimer(AuthService.instance.getLockoutRemainingSeconds());
    }
  }

  void _startLockoutTimer(int seconds) {
    setState(() => _lockoutSeconds = seconds);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSeconds > 1) {
        if (mounted) setState(() => _lockoutSeconds--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _lockoutSeconds = 0);
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _honeypotController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: kVerdeMedio,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitEmailAuth() async {
    // 1. Detección de Bots con Honeypot
    if (_honeypotController.text.trim().isNotEmpty) {
      debugPrint("Intento de envío de bot bloqueado por trampa honeypot.");
      return;
    }

    // 2. Validación Humana (Captcha) obligatoria en registro
    if (!_isLogin && !_isHumanVerified) {
      _showError('Por favor marca la casilla de verificación de seguridad ("No soy un robot").');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.instance.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _showSuccess('¡Bienvenido de nuevo!');
      } else {
        await AuthService.instance.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
        _showSuccess('¡Cuenta creada! Enviamos un enlace de confirmación a tu correo.');
      }
    } catch (e) {
      _showError(e.toString());
      if (_isLogin) {
        _checkLockout();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    final pass = _passwordController.text;
    if (pass.isEmpty) return const SizedBox.shrink();

    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[a-z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) score++;

    Color barColor;
    String label;
    double percent;

    if (score <= 1) {
      barColor = Colors.redAccent;
      label = 'Contraseña Débil (mínimo 8 caracteres con mayúscula y número)';
      percent = 0.33;
    } else if (score == 2 || score == 3) {
      barColor = kAmarillo;
      label = 'Contraseña Media (agrega números o símbolos para mayor seguridad)';
      percent = 0.66;
    } else {
      barColor = kVerde;
      label = 'Contraseña Fuerte y Segura';
      percent = 1.0;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _submitGoogleAuth() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential != null) {
        final name = credential.user?.displayName ?? 'Usuario';
        _showSuccess('¡Hola, $name!');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _dialogRecuperarContrasena() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: kVerde),
              SizedBox(width: 10),
              Text('Recuperar contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa tu correo para recibir un enlace de restablecimiento:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kVerde,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor ingresa un correo válido.')),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      setStateDialog(() => isSending = true);
                      try {
                        await AuthService.instance.sendPasswordReset(email: email);
                        if (ctx.mounted) nav.pop();
                        _showSuccess('Enlace enviado. Revisa tu bandeja de entrada o spam.');
                      } catch (e) {
                        setStateDialog(() => isSending = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final bgScaffold = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgScaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo + Nombre de la App
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D20) : kVerdeMenta,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kVerde.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icon.png',
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.shopping_cart_rounded,
                        color: kVerde,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SmartCart',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: kVerde,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu lista de compras inteligente y colaborativa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Contenedor del Formulario
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Selector Iniciar Sesión / Registrarse
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLogin = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isLogin
                                            ? (isDark ? const Color(0xFF2E3D30) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _isLogin
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.06),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontWeight: _isLogin ? FontWeight.bold : FontWeight.w500,
                                          color: _isLogin
                                              ? kVerde
                                              : (isDark ? Colors.white60 : Colors.black54),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _isLogin = false;
                                      _isHumanVerified = false;
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !_isLogin
                                            ? (isDark ? const Color(0xFF2E3D30) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: !_isLogin
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.06),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Crear Cuenta',
                                        style: TextStyle(
                                          fontWeight: !_isLogin ? FontWeight.bold : FontWeight.w500,
                                          color: !_isLogin
                                              ? kVerde
                                              : (isDark ? Colors.white60 : Colors.black54),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Campo Nombre (solo en registro)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nombre completo',
                                hintText: 'Ej. Juan Pérez',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: kVerde, width: 2),
                                ),
                              ),
                              validator: (val) {
                                if (!_isLogin && (val == null || val.trim().isEmpty)) {
                                  return 'Por favor ingresa tu nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Campo Correo Electrónico
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              hintText: 'ejemplo@correo.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAF9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: kVerde, width: 2),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingresa tu correo electrónico';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Ingresa un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo Contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAF9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: kVerde, width: 2),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              if (!_isLogin) {
                                if (val.length < 8) {
                                  return 'La contraseña debe tener al menos 8 caracteres';
                                }
                                if (!RegExp(r'[A-Z]').hasMatch(val)) {
                                  return 'Debe incluir al menos una letra mayúscula (A-Z)';
                                }
                                if (!RegExp(r'[0-9]').hasMatch(val)) {
                                  return 'Debe incluir al menos un número (0-9)';
                                }
                              } else {
                                if (val.length < 6) {
                                  return 'La contraseña debe tener mínimo 6 caracteres';
                                }
                              }
                              return null;
                            },
                            onChanged: (_) {
                              if (!_isLogin) setState(() {});
                            },
                          ),

                          // Medidor de fortaleza de contraseña (solo en registro)
                          if (!_isLogin) _buildPasswordStrengthIndicator(),

                          // Campo Confirmar Contraseña (solo registro)
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: const Icon(Icons.lock_reset_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: kVerde, width: 2),
                                ),
                              ),
                              validator: (val) {
                                if (!_isLogin) {
                                  if (val == null || val.isEmpty) {
                                    return 'Confirma tu contraseña';
                                  }
                                  if (val != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Verificación Humana (Captcha Anti-Bot)
                            HumanVerificationTile(
                              onVerificationChanged: (val) => setState(() => _isHumanVerified = val),
                            ),
                          ],

                          // Campo Honeypot invisible contra bots
                          Opacity(
                            opacity: 0,
                            child: SizedBox(
                              height: 0,
                              width: 0,
                              child: TextFormField(
                                controller: _honeypotController,
                                focusNode: FocusNode(canRequestFocus: false),
                                decoration: const InputDecoration(labelText: 'WebExtraUrl'),
                              ),
                            ),
                          ),

                          // Enlace "¿Olvidaste tu contraseña?"
                          if (_isLogin) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  foregroundColor: kVerdeMedio,
                                ),
                                onPressed: _dialogRecuperarContrasena,
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 20),
                          ],

                          // Botón Principal (Iniciar Sesión / Registrarse) con soporte de bloqueo por fuerza bruta
                          Builder(
                            builder: (context) {
                              final isLocked = _isLogin && _lockoutSeconds > 0;

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLocked ? Colors.grey.shade600 : kVerde,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: (_isLoading || _isGoogleLoading || isLocked)
                                    ? null
                                    : _submitEmailAuth,
                                child: isLocked
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Bloqueado por seguridad (${_lockoutSeconds}s)',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )
                                    : (_isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                          )
                                        : Text(
                                            _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          )),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // Separador "O continúa con"
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'o continúa con',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Botón Google Sign-In
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF252525) : Colors.white,
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading || _isGoogleLoading ? null : _submitGoogleAuth,
                            child: _isGoogleLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: kVerde),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GoogleLogo(size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        'Continuar con Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botón "Continuar como invitado"
                  if (widget.onGuestContinue != null) ...[
                    const SizedBox(height: 18),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: widget.onGuestContinue,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text(
                        'Continuar como invitado',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
