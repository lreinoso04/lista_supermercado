import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/lista_provider.dart';
import 'theme/colors.dart';
import 'views/agregar_voz_view.dart';
import 'views/lista_compras_view.dart';
import 'views/categorias_view.dart';
import 'views/perfil_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
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
        cardTheme: const CardThemeData(elevation: 0, color: Color(0xFF1E1E1E)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          surfaceTintColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: const MainNavigation(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EB), // Color beige similar a la imagen
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                  const Color(0xFF0D3269),
                ),
                _buildNavItem(
                  1,
                  Icons.shopping_cart_outlined,
                  Icons.shopping_cart,
                  'Mi Lista',
                  const Color(0xFF0D3269),
                ),
                _buildNavItem(
                  2,
                  Icons.category_outlined,
                  Icons.category,
                  'Categorías',
                  const Color(0xFF6B2D5C),
                ),
                _buildNavItem(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Perfil',
                  const Color(0xFF8B4513),
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
    Color activeColor, {
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
                      color: isSelected ? null : Colors.black54,
                      colorBlendMode: isSelected ? null : BlendMode.srcIn,
                      errorBuilder: (c, e, s) => Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected ? activeColor : Colors.black54,
                        size: 26,
                      ),
                    )
                  : Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? activeColor : Colors.black54,
                      size: 26,
                    ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Colors.black54,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
