import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/lista_provider.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../views/email_verification_view.dart';
import '../views/login_view.dart';
import '../main.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isGuest = false;
  bool _checkedGuest = false;

  @override
  void initState() {
    super.initState();
    _loadGuestMode();
  }

  Future<void> _loadGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGuest = prefs.getBool('smartcart_guest_mode') ?? false;
        _checkedGuest = true;
      });
    }
  }

  Future<void> _setGuestMode(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString('current_session_uid');
    if (enable && lastUid != null && lastUid != 'guest') {
      if (mounted) {
        final listaProvider = Provider.of<ListaProvider>(context, listen: false);
        await listaProvider.limpiarDatosLocalesPorCierreDeSesion();
      }
    }
    await prefs.setBool('smartcart_guest_mode', enable);
    if (enable) {
      await prefs.setString('current_session_uid', 'guest');
    }
    if (mounted) {
      setState(() {
        _isGuest = enable;
      });
      if (enable) {
        Provider.of<ListaProvider>(context, listen: false).cargarListas();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // Pantalla de carga mientras se verifica el estado inicial
        if (snapshot.connectionState == ConnectionState.waiting || !_checkedGuest) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: kVerde),
            ),
          );
        }

        // Si el usuario está autenticado en Firebase
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');

          // Si es cuenta de correo y no está verificada, exigir verificación
          if (!user.emailVerified && !isGoogle) {
            return const EmailVerificationView();
          }

          return const MainNavigation();
        }

        // Si está en modo invitado (almacenamiento local SQLite)
        if (_isGuest) {
          return const MainNavigation();
        }

        // Si no está autenticado ni es invitado, mostrar Login
        return LoginView(
          onGuestContinue: () => _setGuestMode(true),
        );
      },
    );
  }
}
