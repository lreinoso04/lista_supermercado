import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/lista_provider.dart';
import 'theme/colors.dart';
import 'views/agregar_voz_view.dart';
import 'views/lista_compras_view.dart';
import 'views/categorias_view.dart';
import 'views/perfil_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ListaProvider()..cargarProductos()),
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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kVerde,
        scaffoldBackgroundColor: kFondo,
        cardTheme: const CardThemeData(
          elevation: 0,
          color: kBlanco,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBlanco,
          surfaceTintColor: kBlanco,
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
        backgroundColor: kBlanco,
        indicatorColor: kVerdeMenta,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded, color: kVerde),
            label: 'Agregar',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: kVerde),
            label: 'Mi Lista',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: kVerde),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: kVerde),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}