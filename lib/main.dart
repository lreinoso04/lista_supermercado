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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: kVerdeMenta.withValues(alpha: 0.5),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded, color: kVerde),
            label: 'Agregar',
          ),
          NavigationDestination(
            icon: Opacity(opacity: 0.5, child: Image.asset('assets/icon.png', height: 28, errorBuilder: (c,e,s) => const Icon(Icons.shopping_cart_outlined))),
            selectedIcon: Image.asset('assets/icon.png', height: 32, errorBuilder: (c,e,s) => const Icon(Icons.shopping_cart, color: kVerde)),
            label: 'Mi Lista',
          ),
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: kVerde),
            label: 'Categorías',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: kVerde),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
