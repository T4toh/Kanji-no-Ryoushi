import 'package:flutter/material.dart';
import 'screens/ocr_page.dart';
import 'screens/dictionary_page.dart';

void main() {
  runApp(const KanjiNoRyoushiApp());
}

class KanjiNoRyoushiApp extends StatelessWidget {
  const KanjiNoRyoushiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '漢字の漁師 🎣 🗾',
      debugShowCheckedModeBanner: false,

      // Tema claro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Tema oscuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Usar el tema del sistema
      themeMode: ThemeMode.system,

      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _idx = 0;
  String? _dictionarySearchText;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OCRPage(onSearchInDictionary: _searchInDictionary),
      DictionaryPage(initialSearchText: _dictionarySearchText),
    ];
  }

  void _searchInDictionary(String text) {
    setState(() {
      _idx = 1; // Cambiar a pestaña de diccionario
      _dictionarySearchText = text;
      // Recrear la página del diccionario con el nuevo texto
      _pages[1] = DictionaryPage(
        key: ValueKey(text + DateTime.now().toString()),
        initialSearchText: text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera), label: 'OCR'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Diccionario'),
        ],
      ),
    );
  }
}
