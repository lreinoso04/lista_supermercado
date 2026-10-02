import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/lista_provider.dart';
import 'theme/colors.dart';
import 'views/agregar_voz_view.dart';
import 'views/lista_compras_view.dart';
import 'views/categorias_view.dart';
import 'views/perfil_view.dart';

import 'firebase_options.dart';
import 'widgets/auth_gate.dart';
import 'services/deep_link_service.dart';
import 'widgets/dialogos_sincronizacion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {}
  }

  // Inicializar captura de Deep Links (Cold & Warm starts)
  await DeepLinkService.instance.inicializar();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ListaProvider()..cargarListas(),
          lazy: false,
        ),
      ],
      child: const MarketApp(),
    ),
  );
}

class MarketApp extends StatelessWidget {
  const MarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCart',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kVerde,
        brightness: Brightness.light,
        scaffoldBackgroundColor: kFondo,
        cardTheme: const CardThemeData(elevation: 0, color: kBlanco),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBlanco,
          surfaceTintColor: kBlanco,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kVerde,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xFF1E1E1E),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final List<Widget> _pages = const [
    AgregarVozView(),
    ListaComprasView(),
    CategoriasView(),
    PerfilView(),
  ];

  @override
  void initState() {
    super.initState();
    // 1. Escuchar Deep Links entrantes
    DeepLinkService.instance.pinRecibidoNotifier.addListener(_onDeepLinkPinReceived);

    // 2. Comprobar si ya había un PIN pendiente de arranque en frío
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingDeepLink();
      _setupCompraCompartidaListener();
    });
  }

  void _setupCompraCompartidaListener() {
    final provider = context.read<ListaProvider>();
    provider.compraCompartidaFinalizadaNotifier.addListener(_onCompraCompartidaFinalizada);
  }

  void _onCompraCompartidaFinalizada() {
    final msg = context.read<ListaProvider>().compraCompartidaFinalizadaNotifier.value;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: kVerde,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      // Limpiar para permitir futuras notificaciones
      context.read<ListaProvider>().compraCompartidaFinalizadaNotifier.value = null;
    }
  }

  void _checkPendingDeepLink() {
    final pin = DeepLinkService.instance.pinRecibidoNotifier.value;
    if (pin != null && mounted) {
      _onDeepLinkPinReceived();
    }
  }

  void _onDeepLinkPinReceived() {
    final pin = DeepLinkService.instance.pinRecibidoNotifier.value;
    if (pin != null && mounted) {
      setState(() => _index = 1); // Cambiar a la pestaña de 'Mi Lista'
      final provider = context.read<ListaProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DialogosSincronizacion.procesarConexionConConfirmacion(
          context: context,
          provider: provider,
          pin: pin,
        );
        DeepLinkService.instance.limpiarPinPendiente();
      });
    }
  }

  @override
  void dispose() {
    DeepLinkService.instance.pinRecibidoNotifier.removeListener(_onDeepLinkPinReceived);
    try {
      context.read<ListaProvider>().compraCompartidaFinalizadaNotifier.removeListener(_onCompraCompartidaFinalizada);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F4EB);
    final navBorder = isDark ? Border.all(color: Colors.white12, width: 1) : null;
    final inactiveColor = isDark ? Colors.white60 : Colors.black54;

    final activeBgColor = _index == 0
        ? (isDark ? const Color(0xFF101A12) : kVerde)
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: activeBgColor,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: navBgColor,
              borderRadius: BorderRadius.circular(40),
              border: navBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.mic_none_rounded,
                  Icons.mic_rounded,
                  'Agregar',
                  isDark ? kVerdeClaro : const Color(0xFF0D3269),
                  inactiveColor,
                ),
                _buildNavItem(
                  1,
                  Icons.shopping_cart_outlined,
                  Icons.shopping_cart,
                  'Mi Lista',
                  isDark ? kVerdeClaro : const Color(0xFF0D3269),
                  inactiveColor,
                ),
                _buildNavItem(
                  2,
                  Icons.category_outlined,
                  Icons.category,
                  'Categorías',
                  isDark ? const Color(0xFFCE93D8) : const Color(0xFF6B2D5C),
                  inactiveColor,
                ),
                _buildNavItem(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Perfil',
                  isDark ? const Color(0xFFFFB74D) : const Color(0xFF8B4513),
                  inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    Color activeColor,
    Color inactiveColor, {
    bool isLogo = false,
  }) {
    final isSelected = _index == index;

    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: isLogo
                  ? Image.asset(
                      'assets/icon.png',
                      height: isSelected ? 28 : 24,
                      color: isSelected ? null : inactiveColor,
                      colorBlendMode: isSelected ? null : BlendMode.srcIn,
                      errorBuilder: (c, e, s) => Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected ? activeColor : inactiveColor,
                        size: 26,
                      ),
                    )
                  : Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 26,
                    ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
